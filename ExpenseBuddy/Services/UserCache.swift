//
//  UserCache.swift
//  ExpenseBuddy
//

import Foundation
import FirebaseFirestore
import Combine

/// A lightweight in-memory cache that resolves user IDs → User profiles.
/// Automatically fetches unknown users from the `users` Firestore collection.
/// Publishes changes so SwiftUI views re-render when profiles arrive.
@MainActor
class UserCache: ObservableObject {
    @Published private(set) var cache: [String: User] = [:]
    
    private let db = Firestore.firestore()
    private var pendingFetches: Set<String> = []
    
    /// Synchronous cache lookup — returns nil if user is not yet cached.
    func user(for id: String) -> User? {
        cache[id]
    }
    
    /// Returns the display name for a user ID, or a short fallback.
    func name(for id: String) -> String {
        cache[id]?.name ?? "User"
    }
    
    /// Returns the User for an ID, or a placeholder User for display purposes.
    func userOrPlaceholder(for id: String) -> User {
        cache[id] ?? User(id: id, name: "User", email: "", profileImage: "person.circle.fill", createdAt: Date())
    }
    
    /// Resolve a list of user IDs to User objects (cached ones only).
    func users(for ids: [String]) -> [User] {
        ids.compactMap { cache[$0] }
    }
    
    /// Seed the cache with a known user (e.g., current user, friends).
    func seed(_ user: User) {
        cache[user.id] = user
    }
    
    /// Seed multiple users at once.
    func seed(_ users: [User]) {
        for user in users {
            cache[user.id] = user
        }
    }
    
    /// Batch-fetch users from Firestore that aren't already cached.
    /// Firestore `in` queries support max 30 items, so we chunk automatically.
    func fetchIfNeeded(ids: [String]) {
        let unknownIds = ids.filter { cache[$0] == nil && !pendingFetches.contains($0) }
        guard !unknownIds.isEmpty else { return }
        
        // Mark as pending to avoid duplicate fetches
        pendingFetches.formUnion(unknownIds)
        
        // Firestore `in` queries support max 30 items per query
        let chunks = unknownIds.chunked(into: 30)
        
        for chunk in chunks {
            Task {
                await fetchChunk(chunk)
            }
        }
    }
    
    private func fetchChunk(_ ids: [String]) async {
        do {
            let snapshot = try await db.collection("users")
                .whereField(FieldPath.documentID(), in: ids)
                .getDocuments()
            
            for document in snapshot.documents {
                if let user = try? document.data(as: User.self) {
                    cache[user.id] = user
                    pendingFetches.remove(user.id)
                }
            }
            
            // Remove any IDs that weren't found (deleted users, etc.)
            for id in ids where cache[id] == nil {
                pendingFetches.remove(id)
            }
        } catch {
            print("UserCache: Failed to fetch users: \(error)")
            // Remove from pending so they can be retried
            for id in ids {
                pendingFetches.remove(id)
            }
        }
    }
}

// MARK: - Array Chunking Helper

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
