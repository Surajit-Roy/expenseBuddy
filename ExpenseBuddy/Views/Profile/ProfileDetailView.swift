//
//  ProfileDetailView.swift
//  ExpenseBuddy
//
//  Created by Surajit Roy on 05/03/26.
//

import SwiftUI

struct ProfileDetailView: View {
    let user: User
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header Card
                    VStack(spacing: 16) {
                        AvatarView(name: user.name, size: 100)
                            .padding(.top, 24)
                        
                        VStack(spacing: 8) {
                            Text(user.name)
                                .font(AppFonts.title2())
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("Member since \(user.createdAt.formatted(as: .monthDay))")
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
                    
                    // Details Card
                    VStack(spacing: 0) {
                        detailRow(title: "Name", value: user.name, icon: "person.fill")
                        Divider().padding(.leading, 52)
                        detailRow(title: "Email", value: user.email, icon: "envelope.fill")
                        Divider().padding(.leading, 52)
                        detailRow(title: "Mobile Number", value: user.mobileNumber.isEmpty ? "Not provided" : user.mobileNumber, icon: "phone.fill")
                    }
                    .background(AppColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: AppColors.shadow, radius: 8, x: 0, y: 2)
                    .padding(.horizontal, 20)
                }
            }
        }
        .navigationTitle("Profile Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
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
