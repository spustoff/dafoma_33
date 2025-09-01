//
//  TaskVantageRoadApp.swift
//  TaskVantage Road
//
//  Created by Developer on 1/9/25.
//

import SwiftUI

@main
struct TaskVantageRoadApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    setupAppAppearance()
                }
        }
    }
    
    private func setupAppAppearance() {
        // Set up navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(AppColorScheme.background)
        navBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(AppColorScheme.textPrimary),
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        navBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(AppColorScheme.textPrimary),
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        
        // Set navigation bar tint color
        UINavigationBar.appearance().tintColor = UIColor(AppColorScheme.primaryAction)
        
        // Set up status bar style
        if #available(iOS 13.0, *) {
            UIApplication.shared.statusBarStyle = .lightContent
        }
    }
}
