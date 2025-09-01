//
//  OnboardingView.swift
//  TaskVantage Road
//
//  Created by Developer on 1/9/25.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @State private var userName = ""
    @State private var userEmail = ""
    @State private var selectedRole = TeamRole.member
    @State private var showingRolePicker = false
    
    private let pages = OnboardingPage.allPages
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    AppColorScheme.background,
                    AppColorScheme.gradientEnd
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if currentPage < pages.count {
                // Onboarding pages
                OnboardingPageView(page: pages[currentPage])
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                // User setup page
                UserSetupView(
                    userName: $userName,
                    userEmail: $userEmail,
                    selectedRole: $selectedRole,
                    showingRolePicker: $showingRolePicker
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
            
            VStack {
                Spacer()
                
                // Navigation controls
                OnboardingNavigationView(
                    currentPage: $currentPage,
                    totalPages: pages.count + 1,
                    userName: userName,
                    userEmail: userEmail,
                    selectedRole: selectedRole,
                    onComplete: completeOnboarding
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentPage)
    }
    
    private func completeOnboarding() {
        print("completeOnboarding called")
        print("Current hasCompletedOnboarding value: \(hasCompletedOnboarding)")
        
        // Simple completion - just set the flag
        hasCompletedOnboarding = true
        
        print("hasCompletedOnboarding set to: \(hasCompletedOnboarding)")
        print("completeOnboarding finished")
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon
            Image(systemName: page.iconName)
                .font(.system(size: 80, weight: .light))
                .foregroundColor(.blue)
                .frame(width: 120, height: 120)
            
            VStack(spacing: 20) {
                // Title
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Description
                Text(page.description)
                    .font(.title3)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            Spacer()
        }
    }
}

struct UserSetupView: View {
    @Binding var userName: String
    @Binding var userEmail: String
    @Binding var selectedRole: TeamRole
    @Binding var showingRolePicker: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Welcome icon
            Image(systemName: "person.badge.plus")
                .font(.system(size: 60, weight: .light))
                .foregroundColor(AppColorScheme.primaryAction)
                .neumorphicStyle(cornerRadius: 30, shadowRadius: 15, shadowOffset: 8)
                .frame(width: 100, height: 100)
            
            VStack(spacing: 15) {
                Text("Set Up Your Profile")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(AppColorScheme.textPrimary)
                
                Text("Help us personalize your experience")
                    .font(.title3)
                    .foregroundColor(AppColorScheme.textSecondary)
            }
            
            VStack(spacing: 20) {
                // Name input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Full Name")
                        .font(.headline)
                        .foregroundColor(AppColorScheme.textPrimary)
                    
                    TextField("Enter your name", text: $userName)
                        .textFieldStyle(NeumorphicTextFieldStyle())
                }
                
                // Email input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email Address")
                        .font(.headline)
                        .foregroundColor(AppColorScheme.textPrimary)
                    
                    TextField("Enter your email", text: $userEmail)
                        .textFieldStyle(NeumorphicTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                // Role selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Role")
                        .font(.headline)
                        .foregroundColor(AppColorScheme.textPrimary)
                    
                    Button(action: { showingRolePicker = true }) {
                        HStack {
                            Image(systemName: selectedRole.icon)
                                .foregroundColor(selectedRole.color)
                            
                            Text(selectedRole.rawValue)
                                .foregroundColor(AppColorScheme.textPrimary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .foregroundColor(AppColorScheme.textSecondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .neumorphicStyle()
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
            Spacer()
        }
        .sheet(isPresented: $showingRolePicker) {
            RolePickerView(selectedRole: $selectedRole)
        }
    }
}

struct RolePickerView: View {
    @Binding var selectedRole: TeamRole
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColorScheme.background.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Select Your Role")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppColorScheme.textPrimary)
                        .padding(.top, 20)
                    
                    LazyVStack(spacing: 12) {
                        ForEach(TeamRole.allCases, id: \.self) { role in
                            RoleOptionView(
                                role: role,
                                isSelected: selectedRole == role
                            ) {
                                selectedRole = role
                                dismiss()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
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

struct RoleOptionView: View {
    let role: TeamRole
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 15) {
                Image(systemName: role.icon)
                    .font(.title2)
                    .foregroundColor(role.color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(role.rawValue)
                        .font(.headline)
                        .foregroundColor(AppColorScheme.textPrimary)
                    
                    Text(roleDescription(for: role))
                        .font(.caption)
                        .foregroundColor(AppColorScheme.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(AppColorScheme.secondaryAction)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .neumorphicCard()
    }
    
    private func roleDescription(for role: TeamRole) -> String {
        switch role {
        case .owner:
            return "Project owner and decision maker"
        case .projectManager:
            return "Manages projects and coordinates team"
        case .developer:
            return "Develops and implements solutions"
        case .designer:
            return "Creates designs and user experiences"
        case .analyst:
            return "Analyzes data and provides insights"
        case .tester:
            return "Tests and ensures quality"
        case .member:
            return "General team member"
        }
    }
}

struct OnboardingNavigationView: View {
    @Binding var currentPage: Int
    let totalPages: Int
    let userName: String
    let userEmail: String
    let selectedRole: TeamRole
    let onComplete: () -> Void
    
    private var isLastPage: Bool {
        currentPage == totalPages - 1
    }
    
    private var canProceed: Bool {
        if isLastPage {
            return !userName.isEmpty && !userEmail.isEmpty
        }
        return true
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Circle()
                        .fill(index <= currentPage ? AppColorScheme.primaryAction : AppColorScheme.textTertiary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(index == currentPage ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: currentPage)
                }
            }
            
            // Navigation buttons
            HStack(spacing: 20) {
                // Back button
                if currentPage > 0 {
                    Button("Back") {
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                    .font(.headline)
                    .foregroundColor(AppColorScheme.textSecondary)
                    .frame(width: 100, height: 50)
                    .neumorphicButton()
                } else {
                    Spacer()
                        .frame(width: 100)
                }
                
                Spacer()
                
                // Next/Complete button
                Button(isLastPage ? "Get Started" : "Next") {
                    print("Button tapped - isLastPage: \(isLastPage)")
                    if isLastPage {
                        print("About to call onComplete")
                        onComplete()
                        print("onComplete called successfully")
                    } else {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 120, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(canProceed ? Color.blue : Color.gray)
                )
                .disabled(!canProceed)
            }
        }
    }
}

// MARK: - Onboarding Page Model
struct OnboardingPage {
    let title: String
    let description: String
    let iconName: String
    
    static let allPages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to TaskVantage Road",
            description: "Your comprehensive solution for task management, project oversight, and team collaboration.",
            iconName: "flag.checkered"
        ),
        OnboardingPage(
            title: "Manage Tasks Efficiently",
            description: "Create, prioritize, and track tasks with color-coded urgency levels and real-time updates.",
            iconName: "checkmark.circle.badge.xmark"
        ),
        OnboardingPage(
            title: "Oversee Multiple Projects",
            description: "Monitor project progress, allocate resources, and gain valuable insights from past data.",
            iconName: "chart.bar.doc.horizontal"
        ),
        OnboardingPage(
            title: "Collaborate with Your Team",
            description: "Add team members, assign roles, and communicate effectively with integrated chat features.",
            iconName: "person.3.sequence"
        ),
        OnboardingPage(
            title: "Smart Document Scanning",
            description: "Use your camera to scan documents and convert them into actionable tasks automatically.",
            iconName: "doc.viewfinder"
        ),
        OnboardingPage(
            title: "Educational Insights",
            description: "Learn from your project data with AI-powered insights and recommendations for better planning.",
            iconName: "lightbulb.max"
        )
    ]
}

#Preview {
    OnboardingView()
}
