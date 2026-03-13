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
    private var listeners: [String: ListenerRegistration] = [:]
    
    deinit {
        let currentListeners = listeners
        Task {
            for (_, listener) in currentListeners {
                listener.remove()
            }
        }
    }
    
    /// Publicly accessible cleanup if needed, but deinit handles listener removal.
    func clearCache() {
        cache.removeAll()
        pendingFetches.removeAll()
    }
    
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
        // If we seed a user, we should also ensure we have a listener for them if it's missing (optional, but good for real-time)
        setupListener(for: user.id)
    }
    
    /// Seed multiple users at once.
    func seed(_ users: [User]) {
        for user in users {
            seed(user)
        }
    }
    
    /// Batch-fetch users from Firestore that aren't already cached.
    func fetchIfNeeded(ids: [String]) {
        for id in ids {
            setupListener(for: id)
        }
    }
    
    private func setupListener(for id: String) {
        guard !id.isEmpty else { return }
        guard listeners[id] == nil else { return }
        
        // Use a snapshot listener instead of a one-time get
        let listener = db.collection("users").document(id)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("UserCache: Listener error for \(id): \(error)")
                    return
                }
                
                guard let document = snapshot, document.exists else {
                    // User might have been deleted
                    Task { @MainActor in
                        self.cache.removeValue(forKey: id)
                    }
                    return
                }
                
                if let user = try? document.data(as: User.self) {
                    Task { @MainActor in
                        self.cache[user.id] = user
                    }
                }
            }
            
        listeners[id] = listener
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
