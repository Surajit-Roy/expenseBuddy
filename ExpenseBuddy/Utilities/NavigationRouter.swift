//
//  NavigationRouter.swift
//  ExpenseBuddy
//
//  Created by Antigravity
//

import SwiftUI
import Combine

class NavigationRouter: ObservableObject {
    @Published var friendsPath = NavigationPath()
    @Published var groupsPath = NavigationPath()
    @Published var activityPath = NavigationPath()
    @Published var profilePath = NavigationPath()
    
    func isRoot(for tab: Int) -> Bool {
        switch tab {
        case 0: return friendsPath.isEmpty
        case 1: return groupsPath.isEmpty
        case 2: return activityPath.isEmpty
        case 3: return profilePath.isEmpty
        default: return true
        }
    }
}

// Marker protocol to identify views that should hide the tab bar
protocol SubPageView: View {}
