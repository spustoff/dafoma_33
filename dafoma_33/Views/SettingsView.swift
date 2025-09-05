//
//  SettingsView.swift
//  TaskVantage Road
//
//  Created by Developer on 1/9/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showingDeleteConfirmation = false
    @State private var showingAbout = false
    @State private var notificationsEnabled = true
    @State private var darkModeEnabled = true
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColorScheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // App Info Section
                        SettingsSectionView(title: "App Information") {
                            VStack(spacing: 12) {
                                SettingsRowView(
                                    icon: "info.circle",
                                    title: "About TaskVantage Road",
                                    subtitle: "Version 1.0",
                                    action: { showingAbout = true }
                                )
                                
                                SettingsRowView(
                                    icon: "star.circle",
                                    title: "Rate the App",
                                    subtitle: "Help us improve",
                                    action: { /* Rate app action */ }
                                )
                            }
                        }
                        
                        // Account Section
                        SettingsSectionView(title: "Account") {
                            VStack(spacing: 12) {
                                SettingsRowView(
                                    icon: "person.crop.circle.badge.minus",
                                    title: "Delete Account",
                                    subtitle: "Permanently remove account and reset app",
                                    titleColor: AppColorScheme.error,
                                    action: { showingDeleteConfirmation = true }
                                )
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Delete Account", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete Account", role: .destructive) {
                    deleteAccount()
                }
            } message: {
                Text("This will permanently delete your account and reset the app to its initial state. All your tasks, projects, and team data will be removed. This action cannot be undone.")
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
    }
    
    private func deleteAccount() {
        // Clear all user data
        UserDefaults.standard.removeObject(forKey: "TaskVantage_Tasks")
        UserDefaults.standard.removeObject(forKey: "TaskVantage_Projects")
        UserDefaults.standard.removeObject(forKey: "TaskVantage_TeamMembers")
        UserDefaults.standard.removeObject(forKey: "TaskVantage_UserName")
        UserDefaults.standard.removeObject(forKey: "TaskVantage_UserEmail")
        UserDefaults.standard.removeObject(forKey: "TaskVantage_UserRole")
        
        // Reset onboarding flag
        hasCompletedOnboarding = false
        
        // Clear DataService data
        DataService.shared.tasks.removeAll()
        DataService.shared.projects.removeAll()
        DataService.shared.teamMembers.removeAll()
        
        print("Account deleted - app reset to onboarding")
    }
    
    private func clearAllData() {
        // Clear all data but keep account
        UserDefaults.standard.removeObject(forKey: "TaskVantage_Tasks")
        UserDefaults.standard.removeObject(forKey: "TaskVantage_Projects")
        UserDefaults.standard.removeObject(forKey: "TaskVantage_TeamMembers")
        
        // Clear DataService data
        DataService.shared.tasks.removeAll()
        DataService.shared.projects.removeAll()
        DataService.shared.teamMembers.removeAll()
        
        print("All data cleared")
    }
    
    private func exportUserData() {
        // Create export functionality
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let tasksData = try encoder.encode(DataService.shared.tasks)
            let projectsData = try encoder.encode(DataService.shared.projects)
            let membersData = try encoder.encode(DataService.shared.teamMembers)
            
            // In a real app, this would save to files or share
            print("Data exported successfully")
            print("Tasks: \(tasksData.count) bytes")
            print("Projects: \(projectsData.count) bytes")
            print("Team Members: \(membersData.count) bytes")
        } catch {
            print("Export failed: \(error)")
        }
    }
}

struct SettingsSectionView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(.headline)
                .foregroundColor(AppColorScheme.textPrimary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 0) {
                content
            }
            .neumorphicCard()
        }
    }
}

struct SettingsRowView: View {
    let icon: String
    let title: String
    let subtitle: String
    let titleColor: Color
    let action: () -> Void
    
    init(icon: String, title: String, subtitle: String, titleColor: Color = AppColorScheme.textPrimary, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.titleColor = titleColor
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(titleColor)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(titleColor)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(AppColorScheme.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppColorScheme.textTertiary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(AppColorScheme.textPrimary)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(AppColorScheme.textPrimary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(AppColorScheme.textSecondary)
            }
            
            Spacer()
            
            NeumorphicToggle(isOn: $isOn)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColorScheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // App icon and name
                        VStack(spacing: 15) {
                            Image(systemName: "flag.checkered")
                                .font(.system(size: 80, weight: .light))
                                .foregroundColor(AppColorScheme.primaryAction)
                                .frame(width: 100, height: 100)
                                .neumorphicStyle()
                            
                            Text("TaskVantage Road")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(AppColorScheme.textPrimary)
                            
                            Text("Version 1.0")
                                .font(.subheadline)
                                .foregroundColor(AppColorScheme.textSecondary)
                        }
                        
                        // Description
                        VStack(alignment: .leading, spacing: 15) {
                            Text("About")
                                .font(.headline)
                                .foregroundColor(AppColorScheme.textPrimary)
                            
                            Text("TaskVantage Road is a comprehensive task management and project oversight tool designed for business professionals. It combines traditional task management with educational insights and smart organization features to streamline your workflow.")
                                .font(.body)
                                .foregroundColor(AppColorScheme.textSecondary)
                                .lineSpacing(4)
                        }
                        .padding(20)
                        .neumorphicCard()
                        
                        // Features
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Key Features")
                                .font(.headline)
                                .foregroundColor(AppColorScheme.textPrimary)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                FeatureRow(icon: "checkmark.circle", text: "Task Management with Priority Levels")
                                FeatureRow(icon: "folder.circle", text: "Multi-Project Oversight")
                                FeatureRow(icon: "person.3.circle", text: "Team Collaboration Tools")
                                FeatureRow(icon: "doc.text", text: "Smart Task Organization")
                                FeatureRow(icon: "lightbulb.circle", text: "Educational Insights & Analytics")
                            }
                        }
                        .padding(20)
                        .neumorphicCard()
                        
                        // Copyright
                        Text("© 2025 TaskVantage Road. All rights reserved.")
                            .font(.caption)
                            .foregroundColor(AppColorScheme.textTertiary)
                            .padding(.bottom, 50)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                trailing: Button("Done") {
                    dismiss()
                }
                .foregroundColor(AppColorScheme.primaryAction)
            )
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(AppColorScheme.secondaryAction)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(AppColorScheme.textSecondary)
        }
    }
}

#Preview {
    SettingsView()
}

