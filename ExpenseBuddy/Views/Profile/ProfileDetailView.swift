//
//  ProfileDetailView.swift
//  ExpenseBuddy
//
//  Created by Surajit Roy on 05/03/26.
//

import SwiftUI
import PhotosUI

struct ProfileDetailView: View {
    let user: User
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataService: DataService
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var isProcessingImage = false
    
    // Identifiable wrapper for item-based sheet presentation
    struct CropperItem: Identifiable {
        let id = UUID()
        let image: UIImage
    }
    @State private var activeCropperItem: CropperItem? = nil
    
    /// Use live data from cache so changes reflect instantly.
    private var displayUser: User {
        dataService.userCache.userOrPlaceholder(for: user.id)
    }
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    headerCard
                    detailsCard
                }
            }
        }
        .navigationTitle("Profile Details")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $activeCropperItem) { item in
            ImageCropperView(
                image: item.image,
                onCropped: { croppedImage in
                    activeCropperItem = nil
                    Task {
                        await uploadCroppedImage(croppedImage)
                    }
                },
                onCancel: {
                    activeCropperItem = nil
                }
            )
        }
    }
    
    // MARK: - Subviews
    
    private var headerCard: some View {
        VStack(spacing: 16) {
            avatarSection
            
            VStack(spacing: 8) {
                Text(displayUser.name)
                    .font(AppFonts.title2())
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Member since \(displayUser.createdAt.formattedWithStyle(.monthDay))")
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 28)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: AppColors.shadow, radius: 10, x: 0, y: 4)
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    @ViewBuilder
    private var avatarSection: some View {
        if user.id == dataService.currentUser.id {
            PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                ZStack(alignment: .bottomTrailing) {
                    AvatarView(name: displayUser.name, size: 100, base64String: displayUser.profileImage)
                        .overlay(
                            Group {
                                if isProcessingImage {
                                    ZStack {
                                        Color.black.opacity(0.4).clipShape(Circle())
                                        ProgressView().tint(.white)
                                    }
                                }
                            }
                        )
                    
                    Image(systemName: "camera.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(AppColors.primary)
                        .background(Color.white.clipShape(Circle()))
                        .offset(x: 4, y: 4)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 24)
            .disabled(isProcessingImage)
            .onChange(of: selectedItem) { newItem in
                Task {
                    await loadPickedImage(item: newItem)
                }
            }
        } else {
            AvatarView(name: displayUser.name, size: 100, base64String: displayUser.profileImage)
                .padding(.top, 24)
        }
    }
    
    private var detailsCard: some View {
        VStack(spacing: 0) {
            detailRow(title: "Name", value: displayUser.name, icon: "person.fill")
            Divider().padding(.leading, 52)
            detailRow(title: "Email", value: displayUser.email, icon: "envelope.fill")
            Divider().padding(.leading, 52)
            let mobile = displayUser.mobileNumber ?? ""
            detailRow(title: "Mobile Number", value: mobile.isEmpty ? "Not provided" : mobile, icon: "phone.fill")
        }
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppColors.shadow, radius: 8, x: 0, y: 2)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Photo Flow
    
    /// Step 1: Load the picked photo into a UIImage, then show the cropper.
    private func loadPickedImage(item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                // Clear selection immediately
                selectedItem = nil
                
                // Trigger presentation on next runloop to allow PhotosPicker to dismiss
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.activeCropperItem = CropperItem(image: uiImage)
                }
            }
        } catch {
            print("Failed to load picked image: \(error)")
        }
    }
    
    /// Step 2: After cropping, compress and upload.
    private func uploadCroppedImage(_ croppedImage: UIImage) async {
        isProcessingImage = true
        
        // Move expensive encoding to background
        let base64String = await Task.detached(priority: .userInitiated) { () -> String? in
            guard let compressedData = croppedImage.jpegData(compressionQuality: 0.5) else {
                return nil
            }
            return compressedData.base64EncodedString()
        }.value
        
        if let base64String {
            await dataService.updateUserProfileImage(base64String: base64String)
        }
        
        isProcessingImage = false
    }
    
    // MARK: - Detail Row
    
    private func detailRow(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.textSecondary)
                Text(value)
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.textPrimary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
