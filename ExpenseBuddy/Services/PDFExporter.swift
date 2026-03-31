//
//  PDFExporter.swift
//  ExpenseBuddy
//
//  Generates beautifully formatted PDF reports for groups or friends.
//

import SwiftUI
import UIKit

@MainActor
class PDFExporter {
    
    /// Generates a PDF report for a group's expenses and returns the file URL.
    static func generateGroupReport(
        group: ExpenseGroup,
        expenses: [Expense],
        settlements: [Settlement],
        balance: Double,
        currencyManager: CurrencyManager,
        userCache: UserCache
    ) -> URL? {
        let title = "\(group.name) — Expense Report"
        let subtitle = "Generated on \(Date().formattedWithStyle(.full))"
        
        var rows: [(date: String, title: String, category: String, amount: String, paidBy: String)] = []
        for expense in expenses.sorted(by: { $0.createdAt > $1.createdAt }) {
            rows.append((
                date: expense.createdAt.formattedWithStyle(.short),
                title: expense.title,
                category: expense.category.rawValue,
                amount: currencyManager.format(expense.amount),
                paidBy: userCache.name(for: expense.paidByUserId)
            ))
        }
        
        var settlementRows: [(date: String, from: String, to: String, amount: String)] = []
        let groupSettlements = settlements.filter { $0.groupId == group.id }
        for settlement in groupSettlements.sorted(by: { $0.date > $1.date }) {
            settlementRows.append((
                date: settlement.date.formattedWithStyle(.short),
                from: userCache.name(for: settlement.fromUserId),
                to: userCache.name(for: settlement.toUserId),
                amount: currencyManager.format(settlement.amount)
            ))
        }
        
        let totalExpenses = expenses.reduce(0.0) { $0 + $1.amount }
        let summary = [
            ("Total Expenses", currencyManager.format(totalExpenses)),
            ("Number of Expenses", "\(expenses.count)"),
            ("Members", "\(group.memberIds.count)"),
            ("Your Balance", currencyManager.format(balance))
        ]
        
        return renderPDF(
            title: title,
            subtitle: subtitle,
            expenseRows: rows,
            settlementRows: settlementRows,
            summary: summary
        )
    }
    
    /// Generates a PDF report for expenses shared with a friend.
    static func generateFriendReport(
        friendName: String,
        expenses: [Expense],
        balance: Double,
        currencyManager: CurrencyManager,
        userCache: UserCache
    ) -> URL? {
        let title = "Expenses with \(friendName)"
        let subtitle = "Generated on \(Date().formattedWithStyle(.full))"
        
        var rows: [(date: String, title: String, category: String, amount: String, paidBy: String)] = []
        for expense in expenses.sorted(by: { $0.createdAt > $1.createdAt }) {
            rows.append((
                date: expense.createdAt.formattedWithStyle(.short),
                title: expense.title,
                category: expense.category.rawValue,
                amount: currencyManager.format(expense.amount),
                paidBy: userCache.name(for: expense.paidByUserId)
            ))
        }
        
        let totalExpenses = expenses.reduce(0.0) { $0 + $1.amount }
        let summary = [
            ("Total Expenses", currencyManager.format(totalExpenses)),
            ("Number of Expenses", "\(expenses.count)"),
            ("Current Balance", currencyManager.format(balance))
        ]
        
        return renderPDF(
            title: title,
            subtitle: subtitle,
            expenseRows: rows,
            settlementRows: [],
            summary: summary
        )
    }
    
    // MARK: - PDF Rendering
    
    private static func renderPDF(
        title: String,
        subtitle: String,
        expenseRows: [(date: String, title: String, category: String, amount: String, paidBy: String)],
        settlementRows: [(date: String, from: String, to: String, amount: String)],
        summary: [(String, String)]
    ) -> URL? {
        
        let pageWidth: CGFloat = 595.0   // A4 width in points
        let pageHeight: CGFloat = 842.0  // A4 height in points
        let margin: CGFloat = 40.0
        let contentWidth = pageWidth - (margin * 2)
        
        let titleFont = UIFont.systemFont(ofSize: 22, weight: .bold)
        let subtitleFont = UIFont.systemFont(ofSize: 11, weight: .regular)
        let headerFont = UIFont.systemFont(ofSize: 14, weight: .bold)
        let bodyFont = UIFont.systemFont(ofSize: 10, weight: .regular)
        let boldBodyFont = UIFont.systemFont(ofSize: 10, weight: .semibold)
        
        let primaryColor = UIColor(red: 0.357, green: 0.369, blue: 0.651, alpha: 1) // #5B5EA6
        let textColor = UIColor(red: 0.12, green: 0.16, blue: 0.24, alpha: 1)
        let lightGray = UIColor(red: 0.95, green: 0.96, blue: 0.97, alpha: 1)
        
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
        
        let data = pdfRenderer.pdfData { context in
            context.beginPage()
            
            var currentY: CGFloat = margin
            
            // --- Logo/App Name ---
            let appName = "ExpenseBuddy"
            let appNameAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .black),
                .foregroundColor: primaryColor
            ]
            let appNameStr = NSAttributedString(string: "📱 \(appName)", attributes: appNameAttrs)
            appNameStr.draw(at: CGPoint(x: margin, y: currentY))
            currentY += 28
            
            // --- Title ---
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: textColor
            ]
            let titleStr = NSAttributedString(string: title, attributes: titleAttrs)
            titleStr.draw(in: CGRect(x: margin, y: currentY, width: contentWidth, height: 30))
            currentY += 32
            
            // --- Subtitle ---
            let subtitleAttrs: [NSAttributedString.Key: Any] = [
                .font: subtitleFont,
                .foregroundColor: UIColor.gray
            ]
            let subtitleStr = NSAttributedString(string: subtitle, attributes: subtitleAttrs)
            subtitleStr.draw(at: CGPoint(x: margin, y: currentY))
            currentY += 24
            
            // --- Divider ---
            drawLine(in: context.cgContext, from: CGPoint(x: margin, y: currentY), to: CGPoint(x: pageWidth - margin, y: currentY), color: primaryColor)
            currentY += 16
            
            // --- Summary Section ---
            let summaryTitle = NSAttributedString(string: "Summary", attributes: [.font: headerFont, .foregroundColor: textColor])
            summaryTitle.draw(at: CGPoint(x: margin, y: currentY))
            currentY += 22
            
            for (label, value) in summary {
                let labelStr = NSAttributedString(string: label, attributes: [.font: bodyFont, .foregroundColor: UIColor.darkGray])
                let valueStr = NSAttributedString(string: value, attributes: [.font: boldBodyFont, .foregroundColor: textColor])
                labelStr.draw(at: CGPoint(x: margin + 10, y: currentY))
                valueStr.draw(at: CGPoint(x: margin + 250, y: currentY))
                currentY += 18
            }
            currentY += 16
            
            // --- Expenses Table ---
            if !expenseRows.isEmpty {
                let expTitle = NSAttributedString(string: "Expenses", attributes: [.font: headerFont, .foregroundColor: textColor])
                expTitle.draw(at: CGPoint(x: margin, y: currentY))
                currentY += 22
                
                // Table header
                let colWidths: [CGFloat] = [65, 160, 80, 90, 120]
                let headers = ["Date", "Title", "Category", "Amount", "Paid By"]
                
                let bgRect = CGRect(x: margin, y: currentY, width: contentWidth, height: 20)
                context.cgContext.setFillColor(primaryColor.cgColor)
                context.cgContext.fill(bgRect)
                
                var xOffset = margin + 5
                for (index, header) in headers.enumerated() {
                    let attrs: [NSAttributedString.Key: Any] = [.font: boldBodyFont, .foregroundColor: UIColor.white]
                    let str = NSAttributedString(string: header, attributes: attrs)
                    str.draw(at: CGPoint(x: xOffset, y: currentY + 4))
                    xOffset += colWidths[index]
                }
                currentY += 22
                
                // Table rows
                for (rowIndex, row) in expenseRows.enumerated() {
                    // Check for page break
                    if currentY > pageHeight - 80 {
                        context.beginPage()
                        currentY = margin
                    }
                    
                    // Alternating row color
                    if rowIndex % 2 == 0 {
                        let rowRect = CGRect(x: margin, y: currentY, width: contentWidth, height: 18)
                        context.cgContext.setFillColor(lightGray.cgColor)
                        context.cgContext.fill(rowRect)
                    }
                    
                    let rowAttrs: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: textColor]
                    let values = [row.date, row.title, row.category, row.amount, row.paidBy]
                    
                    xOffset = margin + 5
                    for (index, value) in values.enumerated() {
                        let truncated = String(value.prefix(Int(colWidths[index] / 5)))
                        let str = NSAttributedString(string: truncated, attributes: rowAttrs)
                        str.draw(at: CGPoint(x: xOffset, y: currentY + 3))
                        xOffset += colWidths[index]
                    }
                    currentY += 18
                }
                currentY += 16
            }
            
            // --- Settlements Table ---
            if !settlementRows.isEmpty {
                if currentY > pageHeight - 120 {
                    context.beginPage()
                    currentY = margin
                }
                
                let settTitle = NSAttributedString(string: "Settlements", attributes: [.font: headerFont, .foregroundColor: textColor])
                settTitle.draw(at: CGPoint(x: margin, y: currentY))
                currentY += 22
                
                let settColWidths: [CGFloat] = [80, 170, 170, 95]
                let settHeaders = ["Date", "From", "To", "Amount"]
                
                let bgRect = CGRect(x: margin, y: currentY, width: contentWidth, height: 20)
                context.cgContext.setFillColor(primaryColor.cgColor)
                context.cgContext.fill(bgRect)
                
                var xOffset = margin + 5
                for (index, header) in settHeaders.enumerated() {
                    let attrs: [NSAttributedString.Key: Any] = [.font: boldBodyFont, .foregroundColor: UIColor.white]
                    let str = NSAttributedString(string: header, attributes: attrs)
                    str.draw(at: CGPoint(x: xOffset, y: currentY + 4))
                    xOffset += settColWidths[index]
                }
                currentY += 22
                
                for (rowIndex, row) in settlementRows.enumerated() {
                    if currentY > pageHeight - 80 {
                        context.beginPage()
                        currentY = margin
                    }
                    
                    if rowIndex % 2 == 0 {
                        let rowRect = CGRect(x: margin, y: currentY, width: contentWidth, height: 18)
                        context.cgContext.setFillColor(lightGray.cgColor)
                        context.cgContext.fill(rowRect)
                    }
                    
                    let rowAttrs: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: textColor]
                    let values = [row.date, row.from, row.to, row.amount]
                    
                    xOffset = margin + 5
                    for (index, value) in values.enumerated() {
                        let str = NSAttributedString(string: value, attributes: rowAttrs)
                        str.draw(at: CGPoint(x: xOffset, y: currentY + 3))
                        xOffset += settColWidths[index]
                    }
                    currentY += 18
                }
            }
            
            // --- Footer ---
            let footerY = pageHeight - 30
            let footerStr = NSAttributedString(
                string: "Generated by ExpenseBuddy • \(Date().formattedWithStyle(.full))",
                attributes: [.font: UIFont.systemFont(ofSize: 8, weight: .regular), .foregroundColor: UIColor.lightGray]
            )
            let footerSize = footerStr.size()
            footerStr.draw(at: CGPoint(x: (pageWidth - footerSize.width) / 2, y: footerY))
        }
        
        // Save to temp directory
        let fileName = title.replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "—", with: "-") + ".pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: url)
            return url
        } catch {
            print("PDF write error: \(error)")
            return nil
        }
    }
    
    private static func drawLine(in context: CGContext, from: CGPoint, to: CGPoint, color: UIColor) {
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(1.5)
        context.move(to: from)
        context.addLine(to: to)
        context.strokePath()
    }
}
