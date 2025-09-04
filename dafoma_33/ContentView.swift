//
//  ContentView.swift
//  TaskVantage Road
//
//  Created by Developer on 1/9/25.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView()
            } else {
                MainAppView(selectedTab: $selectedTab)
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct MainAppView: View {
    @Binding var selectedTab: Int
    @StateObject private var taskViewModel = TaskViewModel()
    @StateObject private var projectViewModel = ProjectViewModel()
    @StateObject private var teamViewModel = TeamViewModel()
    
    var body: some View {
        MainTabView(
            selectedTab: $selectedTab,
            taskViewModel: taskViewModel,
            projectViewModel: projectViewModel,
            teamViewModel: teamViewModel
        )
    }
}

struct MainTabView: View {
    @Binding var selectedTab: Int
    @ObservedObject var taskViewModel: TaskViewModel
    @ObservedObject var projectViewModel: ProjectViewModel
    @ObservedObject var teamViewModel: TeamViewModel
    
    var body: some View {
        ZStack {
            AppColorScheme.background.ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                // Dashboard
                DashboardView(
                    taskViewModel: taskViewModel,
                    projectViewModel: projectViewModel,
                    teamViewModel: teamViewModel
                )
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Dashboard")
                }
                .tag(0)
                
                // Tasks
                TaskListView()
                    .tabItem {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Tasks")
                    }
                    .tag(1)
                
                // Projects
                ProjectsView(projectViewModel: projectViewModel)
                    .tabItem {
                        Image(systemName: "folder.fill")
                        Text("Projects")
                    }
                    .tag(2)
                
                // Team
                TeamManagementView()
                    .tabItem {
                        Image(systemName: "person.3.fill")
                        Text("Team")
                    }
                    .tag(3)
                
                // Settings
                SettingsView()
                    .tabItem {
                        Image(systemName: "gear.circle.fill")
                        Text("Settings")
                    }
                    .tag(4)
            }
            .accentColor(AppColorScheme.primaryAction)
            .onAppear {
                setupTabBarAppearance()
            }
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppColorScheme.cardBackground)
        appearance.selectionIndicatorTintColor = UIColor(AppColorScheme.primaryAction)
        
        // Selected tab item
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(AppColorScheme.primaryAction)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(AppColorScheme.primaryAction)
        ]
        
        // Normal tab item
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(AppColorScheme.textSecondary)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(AppColorScheme.textSecondary)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @ObservedObject var taskViewModel: TaskViewModel
    @ObservedObject var projectViewModel: ProjectViewModel
    @ObservedObject var teamViewModel: TeamViewModel
    @State private var selectedTask: TaskModel?
    @State private var selectedProject: ProjectModel?
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColorScheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Welcome header
                        DashboardHeaderView()
                        
                        // Quick stats
                        DashboardStatsView(
                            taskViewModel: taskViewModel,
                            projectViewModel: projectViewModel,
                            teamViewModel: teamViewModel
                        )
                        
                        // Recent tasks
                        DashboardRecentTasksView(
                            tasks: Array(taskViewModel.tasks.prefix(5)),
                            onTaskTap: { task in
                                selectedTask = task
                            }
                        )
                        
                        // Active projects
                        DashboardActiveProjectsView(
                            projects: Array(projectViewModel.getActiveProjects().prefix(3)),
                            onProjectTap: { project in
                                selectedProject = project
                            }
                        )
                        
                        // Team overview
                        DashboardTeamOverviewView(teamViewModel: teamViewModel)
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: Binding<TaskModel?>(
                get: { selectedTask },
                set: { _ in selectedTask = nil }
            )) { task in
                TaskDetailView(task: task)
            }
            .sheet(item: Binding<ProjectModel?>(
                get: { selectedProject },
                set: { _ in selectedProject = nil }
            )) { project in
                ProjectDetailView(project: project)
            }
        }
    }
}

struct DashboardHeaderView: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome back!")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColorScheme.textPrimary)
                    
                    Text("Here's what's happening today")
                        .font(.subheadline)
                        .foregroundColor(AppColorScheme.textSecondary)
                }
                
                Spacer()
                
                // Current date
                VStack(alignment: .trailing, spacing: 4) {
                    Text(Date(), style: .date)
                        .font(.headline)
                        .foregroundColor(AppColorScheme.textPrimary)
                    
                    Text(Date(), style: .time)
                        .font(.subheadline)
                        .foregroundColor(AppColorScheme.textSecondary)
                }
            }
        }
        .padding(20)
        .neumorphicCard()
    }
}

struct DashboardStatsView: View {
    @ObservedObject var taskViewModel: TaskViewModel
    @ObservedObject var projectViewModel: ProjectViewModel
    @ObservedObject var teamViewModel: TeamViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Overview")
                .font(.headline)
                .foregroundColor(AppColorScheme.textPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                DashboardStatCard(
                    title: "Active Tasks",
                    value: "\(taskViewModel.tasksInProgressCount)",
                    subtitle: "in progress",
                    color: AppColorScheme.primaryAction,
                    icon: "checkmark.circle"
                )
                
                DashboardStatCard(
                    title: "Active Projects",
                    value: "\(projectViewModel.activeProjectsCount)",
                    subtitle: "ongoing",
                    color: AppColorScheme.secondaryAction,
                    icon: "folder"
                )
                
                DashboardStatCard(
                    title: "Team Members",
                    value: "\(teamViewModel.activeMembers)",
                    subtitle: "active",
                    color: AppColorScheme.info,
                    icon: "person.3"
                )
                
                DashboardStatCard(
                    title: "Overdue",
                    value: "\(taskViewModel.overdueTasksCount)",
                    subtitle: "tasks",
                    color: AppColorScheme.error,
                    icon: "exclamationmark.triangle"
                )
            }
        }
        .padding(20)
        .neumorphicCard()
    }
}

struct DashboardStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColorScheme.textPrimary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(AppColorScheme.textSecondary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(AppColorScheme.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .neumorphicStyle(cornerRadius: 12, shadowRadius: 6, shadowOffset: 4)
    }
}

struct DashboardRecentTasksView: View {
    let tasks: [TaskModel]
    let onTaskTap: (TaskModel) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Recent Tasks")
                    .font(.headline)
                    .foregroundColor(AppColorScheme.textPrimary)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to tasks tab
                }
                .font(.subheadline)
                .foregroundColor(AppColorScheme.primaryAction)
            }
            
            if tasks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 40, weight: .light))
                        .foregroundColor(AppColorScheme.textTertiary)
                    
                    Text("No recent tasks")
                        .font(.subheadline)
                        .foregroundColor(AppColorScheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(tasks, id: \.id) { task in
                        Button(action: { onTaskTap(task) }) {
                            DashboardTaskRowView(task: task)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding(20)
        .neumorphicCard()
    }
}

struct DashboardTaskRowView: View {
    let task: TaskModel
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(task.priority.color)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)
                    .foregroundColor(AppColorScheme.textPrimary)
                    .lineLimit(1)
                
                Text(task.status.rawValue)
                    .font(.caption)
                    .foregroundColor(AppColorScheme.textSecondary)
            }
            
            Spacer()
            
            if let dueDate = task.dueDate {
                Text(dueDate, style: .date)
                    .font(.caption)
                    .foregroundColor(task.isOverdue ? AppColorScheme.error : AppColorScheme.textTertiary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }
}

struct DashboardActiveProjectsView: View {
    let projects: [ProjectModel]
    let onProjectTap: (ProjectModel) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Active Projects")
                    .font(.headline)
                    .foregroundColor(AppColorScheme.textPrimary)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to projects tab
                }
                .font(.subheadline)
                .foregroundColor(AppColorScheme.primaryAction)
            }
            
            if projects.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "folder")
                        .font(.system(size: 40, weight: .light))
                        .foregroundColor(AppColorScheme.textTertiary)
                    
                    Text("No active projects")
                        .font(.subheadline)
                        .foregroundColor(AppColorScheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(projects, id: \.id) { project in
                        Button(action: { onProjectTap(project) }) {
                            DashboardProjectRowView(project: project)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding(20)
        .neumorphicCard()
    }
}

struct DashboardProjectRowView: View {
    let project: ProjectModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(project.name)
                    .font(.headline)
                    .foregroundColor(AppColorScheme.textPrimary)
                    .lineLimit(1)
                
                Spacer()
                
                Text("\(Int(project.metrics.completionPercentage))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColorScheme.primaryAction)
            }
            
            NeumorphicProgressBar(progress: project.metrics.completionPercentage / 100.0, height: 6)
            
            HStack {
                Text("\(project.metrics.completedTasks)/\(project.metrics.totalTasks) tasks")
                    .font(.caption)
                    .foregroundColor(AppColorScheme.textSecondary)
                
                Spacer()
                
                if let dueDate = project.estimatedEndDate {
                    Text(dueDate, style: .date)
                        .font(.caption)
                        .foregroundColor(project.isOverdue ? AppColorScheme.error : AppColorScheme.textTertiary)
                }
            }
        }
        .padding(16)
        .neumorphicStyle(cornerRadius: 10, shadowRadius: 4, shadowOffset: 3)
    }
}

struct DashboardTeamOverviewView: View {
    @ObservedObject var teamViewModel: TeamViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Team Overview")
                    .font(.headline)
                    .foregroundColor(AppColorScheme.textPrimary)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to team tab
                }
                .font(.subheadline)
                .foregroundColor(AppColorScheme.primaryAction)
            }
            
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("\(teamViewModel.activeMembers)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppColorScheme.success)
                    
                    Text("Active Members")
                        .font(.caption)
                        .foregroundColor(AppColorScheme.textSecondary)
                }
                
                VStack(spacing: 4) {
                    Text("\(Int(teamViewModel.averageProductivityScore))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppColorScheme.primaryAction)
                    
                    Text("Avg Score")
                        .font(.caption)
                        .foregroundColor(AppColorScheme.textSecondary)
                }
                
                VStack(spacing: 4) {
                    Text("\(teamViewModel.totalTasksCompleted)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppColorScheme.secondaryAction)
                    
                    Text("Tasks Done")
                        .font(.caption)
                        .foregroundColor(AppColorScheme.textSecondary)
                }
                
                Spacer()
            }
        }
        .padding(20)
        .neumorphicCard()
    }
}

// MARK: - Projects View
struct ProjectsView: View {
    @ObservedObject var projectViewModel: ProjectViewModel
    @State private var showingAddProject = false
    @State private var showingFilters = false
    @State private var selectedProject: ProjectModel?
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColorScheme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    ProjectsHeaderView(
                        projectViewModel: projectViewModel,
                        showingFilters: $showingFilters,
                        showingAddProject: $showingAddProject
                    )
                    
                    // Projects list
                    if projectViewModel.filteredProjects.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "folder")
                                .font(.system(size: 60, weight: .light))
                                .foregroundColor(AppColorScheme.textTertiary)
                            
                            Text("No Projects Yet")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColorScheme.textPrimary)
                            
                            Text("Create your first project to get started")
                                .font(.body)
                                .foregroundColor(AppColorScheme.textSecondary)
                                .multilineTextAlignment(.center)
                            
                            Button("Create Project") {
                                showingAddProject = true
                            }
                            .font(.headline)
                            .foregroundColor(AppColorScheme.background)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(AppColorScheme.primaryAction)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal, 40)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(projectViewModel.filteredProjects, id: \.id) { project in
                                    Button(action: {
                                        selectedProject = project
                                    }) {
                                        ProjectCardView(project: project)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .navigationTitle("Projects")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAddProject) {
                AddProjectView()
            }
            .sheet(isPresented: $showingFilters) {
                ProjectFiltersView(projectViewModel: projectViewModel)
            }
            .sheet(item: Binding<ProjectModel?>(
                get: { selectedProject },
                set: { _ in selectedProject = nil }
            )) { project in
                ProjectDetailView(project: project)
            }
        }
    }
}

struct ProjectsHeaderView: View {
    @ObservedObject var projectViewModel: ProjectViewModel
    @Binding var showingFilters: Bool
    @Binding var showingAddProject: Bool
    
    var body: some View {
        VStack(spacing: 15) {
            // Search bar
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColorScheme.textSecondary)
                    
                    TextField("Search projects...", text: $projectViewModel.searchText)
                        .foregroundColor(AppColorScheme.textPrimary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppColorScheme.cardBackground)
                        .shadow(color: AppColorScheme.shadowDark.opacity(0.3), radius: 2, x: -2, y: -2)
                        .shadow(color: AppColorScheme.shadowLight.opacity(0.3), radius: 2, x: 2, y: 2)
                )
                
                // Filter button
                Button(action: { showingFilters = true }) {
                    Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .font(.title2)
                        .foregroundColor(hasActiveFilters ? AppColorScheme.primaryAction : AppColorScheme.textSecondary)
                }
                .neumorphicButton(cornerRadius: 8, shadowRadius: 4, shadowOffset: 3)
                .frame(width: 44, height: 44)
            }
            
            // Action buttons
            HStack(spacing: 12) {
                // Add project button
                Button(action: { showingAddProject = true }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("New Project")
                    }
                    .font(.headline)
                    .foregroundColor(AppColorScheme.background)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(AppColorScheme.primaryAction)
                    .cornerRadius(10)
                }
                
                Spacer()
                
                // Sort options
                Menu {
                    ForEach(ProjectViewModel.ProjectSortOption.allCases, id: \.self) { option in
                        Button(option.rawValue) {
                            projectViewModel.sortOption = option
                        }
                    }
                } label: {
                    HStack {
                        Text("Sort")
                        Image(systemName: "arrow.up.arrow.down")
                    }
                    .font(.headline)
                    .foregroundColor(AppColorScheme.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .neumorphicButton()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var hasActiveFilters: Bool {
        projectViewModel.selectedStatus != nil
    }
}

struct ProjectCardView: View {
    let project: ProjectModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.headline)
                        .foregroundColor(AppColorScheme.textPrimary)
                        .lineLimit(1)
                    
                    HStack {
                        Circle()
                            .fill(project.status.color)
                            .frame(width: 8, height: 8)
                        
                        Text(project.status.rawValue)
                            .font(.subheadline)
                            .foregroundColor(project.status.color)
                    }
                }
                
                Spacer()
                
                Text("\(Int(project.metrics.completionPercentage))%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(AppColorScheme.primaryAction)
            }
            
            // Description
            if !project.description.isEmpty {
                Text(project.description)
                    .font(.subheadline)
                    .foregroundColor(AppColorScheme.textSecondary)
                    .lineLimit(2)
            }
            
            // Progress bar
            NeumorphicProgressBar(progress: project.metrics.completionPercentage / 100.0, height: 8)
            
            // Footer
            HStack {
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle")
                            .font(.caption)
                        Text("\(project.metrics.completedTasks)/\(project.metrics.totalTasks)")
                            .font(.caption)
                    }
                    .foregroundColor(AppColorScheme.textSecondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "person.3")
                            .font(.caption)
                        Text("\(project.teamMemberIds.count)")
                            .font(.caption)
                    }
                    .foregroundColor(AppColorScheme.textSecondary)
                }
                
                Spacer()
                
                if let dueDate = project.estimatedEndDate {
                    Text(dueDate, style: .date)
                        .font(.caption)
                        .foregroundColor(project.isOverdue ? AppColorScheme.error : AppColorScheme.textTertiary)
                }
            }
        }
        .padding(16)
        .neumorphicCard()
    }
}

// MARK: - Placeholder Views
struct AddProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var estimatedEndDate = Date()
    @State private var hasEndDate = false
    @State private var budget = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColorScheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Project name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Project Name")
                                .font(.headline)
                                .foregroundColor(AppColorScheme.textPrimary)
                            
                            TextField("Enter project name", text: $name)
                                .textFieldStyle(NeumorphicTextFieldStyle())
                        }
                        
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                                .foregroundColor(AppColorScheme.textPrimary)
                            
                            TextField("Enter project description", text: $description)
                                .textFieldStyle(NeumorphicTextFieldStyle())
                        }
                        
                        // End date toggle and picker
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Estimated End Date")
                                    .font(.headline)
                                    .foregroundColor(AppColorScheme.textPrimary)
                                
                                Spacer()
                                
                                NeumorphicToggle(isOn: $hasEndDate)
                            }
                            
                            if hasEndDate {
                                DatePicker("End Date", selection: $estimatedEndDate, displayedComponents: [.date])
                                    .datePickerStyle(.compact)
                                    .foregroundColor(AppColorScheme.textPrimary)
                            }
                        }
                        
                        // Budget (optional)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Budget (Optional)")
                                .font(.headline)
                                .foregroundColor(AppColorScheme.textPrimary)
                            
                            TextField("Enter budget", text: $budget)
                                .textFieldStyle(NeumorphicTextFieldStyle())
                                .keyboardType(.decimalPad)
                        }
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(AppColorScheme.textSecondary),
                trailing: Button("Save") {
                    saveProject()
                }
                .foregroundColor(canSave ? AppColorScheme.primaryAction : AppColorScheme.textTertiary)
                .disabled(!canSave)
            )
        }
    }
    
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func saveProject() {
        var project = ProjectModel(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description,
            estimatedEndDate: hasEndDate ? estimatedEndDate : nil
        )
        
        if let budgetValue = Double(budget), !budget.isEmpty {
            project.budget = budgetValue
        }
        
        DataService.shared.addProject(project)
        dismiss()
    }
}

struct ProjectFiltersView: View {
    @ObservedObject var projectViewModel: ProjectViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColorScheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Status filter
                        FilterSectionView(title: "Status") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    FilterChip(
                                        title: "All",
                                        isSelected: projectViewModel.selectedStatus == nil
                                    ) {
                                        projectViewModel.selectedStatus = nil
                                    }
                                    
                                    ForEach(ProjectStatus.allCases, id: \.self) { status in
                                        FilterChip(
                                            title: status.rawValue,
                                            isSelected: projectViewModel.selectedStatus == status,
                                            color: status.color
                                        ) {
                                            projectViewModel.selectedStatus = status
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button("Clear All") {
                    projectViewModel.selectedStatus = nil
                }
                .foregroundColor(AppColorScheme.textSecondary),
                trailing: Button("Done") {
                    dismiss()
                }
                .foregroundColor(AppColorScheme.primaryAction)
            )
        }
    }
}

#Preview {
    ContentView()
}
