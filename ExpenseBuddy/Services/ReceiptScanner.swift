//
//  ReceiptScanner.swift
//  ExpenseBuddy
//
//  Uses Apple's Vision framework to perform on-device OCR on receipt images
//  and extract individual line items with prices.
//

import Foundation
import Vision
import UIKit
import Combine

@MainActor
class ReceiptScanner: ObservableObject {
    @Published var scannedItems: [ScannedItem] = []
    @Published var receiptTitle: String = ""
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    // MARK: - Public API
    
    /// Processes a UIImage of a receipt and extracts line items.
    func scanReceipt(image: UIImage) {
        guard let cgImage = image.cgImage else {
            errorMessage = "Could not process the image. Please try again."
            return
        }
        
        isProcessing = true
        errorMessage = nil
        scannedItems = []
        receiptTitle = ""
        
        Task.detached(priority: .userInitiated) { [weak self] in
            do {
                let lines = try await self?.performOCR(on: cgImage) ?? []
                let items = self?.parseLineItems(from: lines) ?? []
                let title = self?.extractTitle(from: lines) ?? "Scanned Expense"
                
                await MainActor.run {
                    self?.scannedItems = items
                    self?.receiptTitle = title
                    self?.isProcessing = false
                    
                    if items.isEmpty {
                        self?.errorMessage = "No items found. Please take a clearer photo."
                    }
                }
            } catch {
                await MainActor.run {
                    self?.errorMessage = "OCR failed: \(error.localizedDescription)"
                    self?.isProcessing = false
                }
            }
        }
    }
    
    // MARK: - Vision OCR
    
    /// Performs OCR on a CGImage and returns an array of recognized text lines.
    private nonisolated func performOCR(on image: CGImage) async throws -> [String] {
        let requestHandler = VNImageRequestHandler(cgImage: image, options: [:])
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US"]
        request.usesLanguageCorrection = true
        
        try requestHandler.perform([request])
        
        guard let observations = request.results else { return [] }
        
        return observations.compactMap { observation in
            observation.topCandidates(1).first?.string
        }
    }
    
    // MARK: - Parsing
    
    /// Extracts a store/restaurant name from the first few lines.
    private nonisolated func extractTitle(from lines: [String]) -> String {
        // The store name is usually one of the first few lines
        // Look for a line that's not a number, not an address, and not too long
        for line in lines.prefix(5) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            // Skip lines that are mostly numbers (phone, date, address numbers)
            let digitCount = trimmed.filter { $0.isNumber }.count
            let digitRatio = Double(digitCount) / max(Double(trimmed.count), 1)
            
            if trimmed.count >= 3 && trimmed.count <= 40 && digitRatio < 0.5 {
                // Skip common non-name lines
                let lowered = trimmed.lowercased()
                if !lowered.contains("receipt") && !lowered.contains("invoice") &&
                   !lowered.contains("date") && !lowered.contains("time") &&
                   !lowered.contains("tel") && !lowered.contains("phone") &&
                   !lowered.contains("address") && !lowered.contains("welcome") {
                    return trimmed
                }
            }
        }
        return "Scanned Expense"
    }
    
    /// Parses recognized text lines to extract items and their prices.
    /// Looks for patterns like: "Item Name ... ₹123.45" or "Item Name 123.45"
    private nonisolated func parseLineItems(from lines: [String]) -> [ScannedItem] {
        var items: [ScannedItem] = []
        
        // Common patterns for price at end of line:
        // "Pasta Alfredo    ₹450.00"
        // "Coffee x2        $12.50"
        // "Burger            250"
        // "ITEM NAME        12.99"
        
        // Currency symbols to look for
        let currencySymbols: Set<Character> = ["₹", "$", "€", "£", "¥"]
        
        // Keywords to skip (these are totals/tax/tips, not items)
        let skipKeywords = ["total", "subtotal", "sub total", "sub-total", "tax", "gst", "sgst", "cgst",
                           "vat", "tip", "gratuity", "service charge", "service tax", "discount",
                           "change", "cash", "card", "visa", "mastercard", "amex", "payment",
                           "balance", "amount due", "grand total", "net total", "round off",
                           "thank you", "thanks", "visit again", "have a nice"]
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.count >= 3 else { continue }
            
            let lowered = trimmed.lowercased()
            
            // Skip header/footer/total lines
            if skipKeywords.contains(where: { lowered.contains($0) }) { continue }
            
            // Try to extract a price from the end of the line
            if let (itemName, price) = extractItemAndPrice(from: trimmed, currencySymbols: currencySymbols) {
                let cleanName = itemName
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .trimmingCharacters(in: CharacterSet(charactersIn: ".-_*"))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Validate: name should have at least 2 chars and price should be reasonable
                if cleanName.count >= 2 && price > 0 && price < 100_000 {
                    items.append(ScannedItem(name: cleanName, price: price))
                }
            }
        }
        
        return items
    }
    
    /// Attempt to split a line into (itemName, price).
    private nonisolated func extractItemAndPrice(from line: String, currencySymbols: Set<Character>) -> (String, Double)? {
        // Strategy 1: Look for a number pattern at the end of the line
        // Pattern: anything followed by optional currency symbol, then digits with optional decimal
        let pricePattern = #"^(.+?)\s+[₹$€£¥]?\s*(\d{1,6}(?:[.,]\d{1,2})?)\s*$"#
        
        if let regex = try? NSRegularExpression(pattern: pricePattern, options: []),
           let match = regex.firstMatch(in: line, options: [], range: NSRange(line.startIndex..., in: line)),
           match.numberOfRanges >= 3,
           let nameRange = Range(match.range(at: 1), in: line),
           let priceRange = Range(match.range(at: 2), in: line) {
            
            let name = String(line[nameRange])
            let priceStr = String(line[priceRange]).replacingOccurrences(of: ",", with: ".")
            
            if let price = Double(priceStr) {
                return (name, price)
            }
        }
        
        // Strategy 2: Split by multiple spaces and check if last component is a number
        let components = line.components(separatedBy: "  ").filter { !$0.isEmpty }
        if components.count >= 2 {
            let lastComponent = components.last!
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Remove currency symbol
            var priceStr = lastComponent
            for symbol in currencySymbols {
                priceStr = priceStr.replacingOccurrences(of: String(symbol), with: "")
            }
            priceStr = priceStr.trimmingCharacters(in: .whitespacesAndNewlines)
            priceStr = priceStr.replacingOccurrences(of: ",", with: ".")
            
            if let price = Double(priceStr), price > 0 {
                let name = components.dropLast().joined(separator: " ")
                return (name, price)
            }
        }
        
        return nil
    }
}
