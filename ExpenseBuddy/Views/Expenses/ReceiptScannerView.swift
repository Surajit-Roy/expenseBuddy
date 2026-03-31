//
//  ReceiptScannerView.swift
//  ExpenseBuddy
//
//  3-step receipt scanning flow:
//  1. Capture: Take photo or pick from library
//  2. Review: Edit extracted items and prices
//  3. Assign: Each participant claims their items
//

import SwiftUI
import PhotosUI

struct ReceiptScannerView: View {
    @EnvironmentObject var dataService: DataService
    @EnvironmentObject var currencyManager: CurrencyManager
    @StateObject private var scanner = ReceiptScanner()
    @Environment(\.dismiss) private var dismiss
    
    /// Callback when scanning is complete — passes (title, total, splits per user)
    let onComplete: (_ title: String, _ total: Double, _ splits: [String: Double]) -> Void
    
    /// The participants who will split the receipt
    let participants: [User]
    
    @State private var step: ScanStep = .capture
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var selectedImage: UIImage?
    @State private var showSourcePicker = false
    @State private var appearAnimate = false
    
    enum ScanStep: Int {
        case capture = 0
        case review = 1
        case assign = 2
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ModernBackground()
                
                VStack(spacing: 0) {
                    // Step indicator
                    stepIndicator
                        .padding(.top, 8)
                    
                    switch step {
                    case .capture:
                        captureStep
                    case .review:
                        reviewStep
                    case .assign:
                        assignStep
                    }
                }
            }
            .navigationTitle("Scan Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColors.textPrimary)
                }
                
                if step == .assign {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { completeAssignment() }
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(isAssignmentValid ? AppColors.primary : AppColors.textTertiary)
                            .disabled(!isAssignmentValid)
                    }
                }
            }
            .confirmationDialog("Choose Photo Source", isPresented: $showSourcePicker) {
                Button("Camera") { showCamera = true }
                Button("Photo Library") { showPhotoLibrary = true }
                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $showCamera) {
                ImagePickerView(image: $selectedImage, sourceType: .camera)
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showPhotoLibrary) {
                ImagePickerView(image: $selectedImage, sourceType: .photoLibrary)
                    .ignoresSafeArea()
            }
            .onChange(of: selectedImage) { _ in
                if let image = selectedImage {
                    scanner.scanReceipt(image: image)
                    withAnimation(.spring(response: 0.4)) {
                        step = .review
                    }
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) {
                    appearAnimate = true
                }
            }
        }
    }
    
    // MARK: - Step Indicator
    
    private var stepIndicator: some View {
        HStack(spacing: 0) {
            ForEach(0..<3) { index in
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(index <= step.rawValue ? AppColors.primary : AppColors.secondaryBackground)
                            .frame(width: 32, height: 32)
                        
                        if index < step.rawValue {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("\(index + 1)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(index <= step.rawValue ? .white : AppColors.textTertiary)
                        }
                    }
                    
                    Text(["Capture", "Review", "Assign"][index])
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(index <= step.rawValue ? AppColors.textPrimary : AppColors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                
                if index < 2 {
                    Rectangle()
                        .fill(index < step.rawValue ? AppColors.primary : AppColors.divider)
                        .frame(height: 2)
                        .frame(maxWidth: 40)
                        .offset(y: -10)
                }
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 16)
    }
    
    // MARK: - Step 1: Capture
    
    private var captureStep: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(AppColors.primary.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [10, 6]))
                    .frame(width: 220, height: 280)
                
                VStack(spacing: 20) {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 60, weight: .light))
                        .foregroundStyle(AppColors.primaryGradient)
                    
                    Text("Scan a receipt")
                        .font(AppFonts.title3())
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Take a photo or pick from\nyour photo library")
                        .font(AppFonts.subheadline())
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .offset(y: appearAnimate ? 0 : 20)
            .opacity(appearAnimate ? 1 : 0)
            
            Button(action: { showSourcePicker = true }) {
                HStack(spacing: 10) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 18))
                    Text("Choose Photo")
                        .font(AppFonts.headline())
                }
                .primaryButton()
            }
            .padding(.horizontal, 40)
            .offset(y: appearAnimate ? 0 : 30)
            .opacity(appearAnimate ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.2), value: appearAnimate)
            
            Spacer()
        }
    }
    
    // MARK: - Step 2: Review
    
    private var reviewStep: some View {
        VStack(spacing: 0) {
            if scanner.isProcessing {
                VStack(spacing: 20) {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(AppColors.primary)
                    
                    Text("Scanning receipt...")
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Using AI to extract items")
                        .font(AppFonts.subheadline())
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                }
            } else if let error = scanner.errorMessage {
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    
                    Text(error)
                        .font(AppFonts.body())
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button("Try Again") {
                        withAnimation { step = .capture }
                        selectedImage = nil
                    }
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.primary)
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Receipt title
                        HStack(spacing: 12) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 18))
                                .foregroundColor(AppColors.primary)
                            TextField("Receipt Name", text: $scanner.receiptTitle)
                                .font(.system(size: 17, weight: .medium, design: .rounded))
                        }
                        .padding(18)
                        .glassStyle(cornerRadius: 18)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        
                        // Items count
                        HStack {
                            Text("\(scanner.scannedItems.count) items found")
                                .font(AppFonts.headline())
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            
                            let total = scanner.scannedItems.reduce(0.0) { $0 + $1.price }
                            Text("Total: \(currencyManager.formatInput(total))")
                                .font(AppFonts.subheadline())
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.primary)
                        }
                        .padding(.horizontal, 24)
                        
                        // Editable items list
                        VStack(spacing: 0) {
                            ForEach($scanner.scannedItems) { $item in
                                HStack(spacing: 12) {
                                    Image(systemName: "line.3.horizontal")
                                        .foregroundColor(AppColors.textTertiary)
                                        .font(.system(size: 14))
                                    
                                    TextField("Item name", text: $item.name)
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundColor(AppColors.textPrimary)
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 4) {
                                        Text(currencyManager.symbol)
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                            .foregroundColor(AppColors.textSecondary)
                                        
                                        TextField("0", value: $item.price, format: .number.precision(.fractionLength(2)))
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                            .keyboardType(.decimalPad)
                                            .multilineTextAlignment(.trailing)
                                            .frame(width: 70)
                                    }
                                    
                                    Button(action: {
                                        withAnimation {
                                            scanner.scannedItems.removeAll { $0.id == item.id }
                                        }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(AppColors.textTertiary)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                
                                if item.id != scanner.scannedItems.last?.id {
                                    Divider().padding(.leading, 44)
                                }
                            }
                        }
                        .background(AppColors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: AppColors.shadow, radius: 6, x: 0, y: 2)
                        .padding(.horizontal, 24)
                        
                        // Add item button
                        Button(action: {
                            withAnimation {
                                scanner.scannedItems.append(ScannedItem(name: "", price: 0))
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Item Manually")
                            }
                            .font(AppFonts.subheadline())
                            .fontWeight(.medium)
                            .foregroundColor(AppColors.primary)
                        }
                        .padding(.horizontal, 24)
                        
                        // Continue button
                        Button(action: {
                            withAnimation(.spring(response: 0.4)) {
                                step = .assign
                            }
                        }) {
                            Text("Continue to Assignment")
                                .primaryButton()
                        }
                        .padding(.horizontal, 24)
                        .disabled(scanner.scannedItems.isEmpty)
                        .opacity(scanner.scannedItems.isEmpty ? 0.5 : 1)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }
    
    // MARK: - Step 3: Assign
    
    private var assignStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Tap items for each person")
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.top, 16)
                
                ForEach($scanner.scannedItems) { $item in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(item.name.isEmpty ? "Unnamed Item" : item.name)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            Text(currencyManager.formatInput(item.price))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(AppColors.primary)
                        }
                        
                        // Participant chips
                        FlowLayout(spacing: 8) {
                            ForEach(participants) { participant in
                                let isAssigned = item.assignedToUserIds.contains(participant.id)
                                
                                Button(action: {
                                    withAnimation(.spring(response: 0.3)) {
                                        if isAssigned {
                                            item.assignedToUserIds.remove(participant.id)
                                        } else {
                                            item.assignedToUserIds.insert(participant.id)
                                        }
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        AvatarView(
                                            name: dataService.userCache.name(for: participant.id),
                                            size: 24,
                                            base64String: dataService.userCache.user(for: participant.id)?.profileImage
                                        )
                                        Text(dataService.userCache.name(for: participant.id).components(separatedBy: " ").first ?? "")
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .padding(.vertical, 8)
                                    .background(
                                        Group {
                                            if isAssigned {
                                                AppColors.primary.opacity(0.15)
                                            } else {
                                                Color.clear.background(.ultraThinMaterial)
                                            }
                                        }
                                    )
                                    .foregroundColor(isAssigned ? AppColors.primary : AppColors.textSecondary)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().stroke(isAssigned ? AppColors.primary.opacity(0.5) : Color.clear, lineWidth: 1)
                                    )
                                }
                            }
                        }
                        
                        if !item.assignedToUserIds.isEmpty {
                            Text("\(currencyManager.formatInput(item.perPersonShare)) each")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(AppColors.textTertiary)
                        }
                    }
                    .padding(16)
                    .glassStyle(cornerRadius: 18)
                    .padding(.horizontal, 24)
                }
                
                // Per-person summary
                if isAssignmentValid {
                    perPersonSummary
                }
            }
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Per-Person Summary
    
    private var perPersonSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Split Summary")
                .font(AppFonts.headline())
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 24)
            
            VStack(spacing: 0) {
                ForEach(participants) { participant in
                    let share = calculateShare(for: participant.id)
                    HStack(spacing: 12) {
                        AvatarView(
                            name: dataService.userCache.name(for: participant.id),
                            size: 36,
                            base64String: dataService.userCache.user(for: participant.id)?.profileImage
                        )
                        Text(dataService.userCache.name(for: participant.id))
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                        Text(currencyManager.formatInput(share))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.primary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
                    if participant.id != participants.last?.id {
                        Divider().padding(.leading, 64)
                    }
                }
            }
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: AppColors.shadow, radius: 6, x: 0, y: 2)
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Helpers
    
    private var isAssignmentValid: Bool {
        scanner.scannedItems.allSatisfy { !$0.assignedToUserIds.isEmpty }
        && !scanner.scannedItems.isEmpty
    }
    
    private func calculateShare(for userId: String) -> Double {
        var total = 0.0
        for item in scanner.scannedItems {
            if item.assignedToUserIds.contains(userId) {
                total += item.perPersonShare
            }
        }
        return total
    }
    
    private func completeAssignment() {
        var splits: [String: Double] = [:]
        for participant in participants {
            splits[participant.id] = calculateShare(for: participant.id)
        }
        
        let total = scanner.scannedItems.reduce(0.0) { $0 + $1.price }
        onComplete(scanner.receiptTitle, total, splits)
        dismiss()
    }
}

// MARK: - Flow Layout (for participant chips)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    
    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxRowHeight: CGFloat = 0
        var positions: [CGPoint] = []
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += maxRowHeight + spacing
                maxRowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            maxRowHeight = max(maxRowHeight, size.height)
            x += size.width + spacing
        }
        
        return (CGSize(width: maxWidth, height: y + maxRowHeight), positions)
    }
}

// MARK: - UIImagePickerController Wrapper

struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerView
        
        init(_ parent: ImagePickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
