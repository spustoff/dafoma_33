//
//  ProjectDetailView.swift
//  TaskVantage Road
//
//  Created by Developer on 1/9/25.
//

import SwiftUI

struct ProjectDetailView: View {
    let project: ProjectModel
    @StateObject private var projectViewModel = ProjectViewModel()
    @StateObject private var taskViewModel = TaskViewModel()
    @StateObject private var teamViewModel = TeamViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingAddTask = false
    @State private var showingTeamManagement = false
    @State private var showingInsights = false
    @State private var selectedTab = 0
    
    private var projectTasks: [TaskModel] {
        taskViewModel.tasks.filter { $0.projectId == project.id }
    }
    
    private var projectTeamMembers: [TeamMemberModel] {
        teamViewModel.teamMembers.filter { project.teamMemberIds.contains($0.id) }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColorScheme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Project header
                    ProjectHeaderView(project: project, projectViewModel: projectViewModel)
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    
                    // Tab selector
                    ProjectTabSelector(selectedTab: $selectedTab)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 15)
                    
                    // Tab content
                    TabView(selection: $selectedTab) {
                        // Overview tab
                        ProjectOverviewTab(
                            project: project,
                            tasks: projectTasks,
                            teamMembers: projectTeamMembers,
                            showingAddTask: $showingAddTask,
                            showingInsights: $showingInsights
                        )
                        .tag(0)
                        
                        // Tasks tab
                        ProjectTasksTab(
                            tasks: projectTasks,
                            showingAddTask: $showingAddTask
                        )
                        .tag(1)
                        
                        // Team tab
                        ProjectTeamTab(
                            teamMembers: projectTeamMembers,
                            showingTeamManagement: $showingTeamManagement
                        )
                        .tag(2)
                        
                        // Insights tab
                        ProjectInsightsTab(project: project)
                            .tag(3)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationTitle(project.name)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                trailing: Button("Done") {
                    dismiss()
                }
                .foregroundColor(AppColorScheme.primaryAction)
            )
            .sheet(isPresented: $showingAddTask) {
                AddProjectTaskView(projectId: project.id)
            }
            .sheet(isPresented: $showingTeamManagement) {
                ProjectTeamManagementView(project: project)
            }
            .sheet(isPresented: $showingInsights) {
                ProjectInsightsDetailView(project: project)
            }
        }
    }
}

struct ProjectHeaderView: View {
    let project: ProjectModel
    @ObservedObject var projectViewModel: ProjectViewModel
    
    var body: some View {
        VStack(spacing: 15) {
            // Status and progress
            HStack {
                // Status badge
                HStack {
                    Circle()
                        .fill(project.status.color)
                        .frame(width: 12, height: 12)
                    
                    Text(project.status.rawValue)
                        .font(.headline)
                        .foregroundColor(project.status.color)
                }
                
                Spacer()
                
                // Progress percentage
                Text("\(Int(project.metrics.completionPercentage))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColorScheme.textPrimary)
            }
            
            // Progress bar
            NeumorphicProgressBar(progress: project.metrics.completionPercentage / 100.0, height: 12)
            
            // Key metrics
            HStack(spacing: 20) {
                MetricView(
                    title: "Tasks",
                    value: "\(project.metrics.totalTasks)",
                    subtitle: "\(project.metrics.completedTasks) completed"
                )
                
                MetricView(
                    title: "Team",
                    value: "\(project.teamMemberIds.count)",
                    subtitle: "members"
                )
                
                if let endDate = project.estimatedEndDate {
                    MetricView(
                        title: "Due",
                        value: project.isOverdue ? "Overdue" : "\(project.daysRemaining)d",
                        subtitle: DateFormatter.shortDate.string(from: endDate),
                        isWarning: project.isOverdue
                    )
                }
            }
        }
        .padding(20)
        .neumorphicCard()
    }
}

struct MetricView: View {
    let title: String
    let value: String
    let subtitle: String
    let isWarning: Bool
    
    init(title: String, value: String, subtitle: String, isWarning: Bool = false) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.isWarning = isWarning
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(AppColorScheme.textTertiary)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(isWarning ? AppColorScheme.error : AppColorScheme.textPrimary)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(AppColorScheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ProjectTabSelector: View {
    @Binding var selectedTab: Int
    
    private let tabs = ["Overview", "Tasks", "Team", "Insights"]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = index
                    }
                }) {
                    Text(tabs[index])
                        .font(.subheadline)
                        .fontWeight(selectedTab == index ? .semibold : .regular)
                        .foregroundColor(selectedTab == index ? AppColorScheme.primaryAction : AppColorScheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
            }
        }
        .background(
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColorScheme.primaryAction.opacity(0.2))
                    .frame(width: geometry.size.width / CGFloat(tabs.count))
                    .offset(x: geometry.size.width / CGFloat(tabs.count) * CGFloat(selectedTab))
                    .animation(.easeInOut(duration: 0.2), value: selectedTab)
            }
        )
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppColorScheme.cardBackground)
        )
        .neumorphicStyle()
    }
}

// MARK: - Overview Tab
struct ProjectOverviewTab: View {
    let project: ProjectModel
    let tasks: [TaskModel]
    let teamMembers: [TeamMemberModel]
    @Binding var showingAddTask: Bool
    @Binding var showingInsights: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Quick actions
                QuickActionsView(showingAddTask: $showingAddTask, showingInsights: $showingInsights)
                
                // Recent tasks
                if !tasks.isEmpty {
                    RecentTasksView(tasks: Array(tasks.prefix(3)))
                }
                
                // Team overview
                if !teamMembers.isEmpty {
                    TeamOverviewView(teamMembers: teamMembers)
                }
                
                // Project timeline
                ProjectTimelineView(project: project)
                
                Spacer(minLength: 50)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
    }
}

struct QuickActionsView: View {
    @Binding var showingAddTask: Bool
    @Binding var showingInsights: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(AppColorScheme.textPrimary)
            
            HStack(spacing: 12) {
                Button(action: { showingAddTask = true }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Task")
                    }
                    .font(.subheadline)
                    .foregroundColor(AppColorScheme.background)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AppColorScheme.primaryAction)
                    .cornerRadius(8)
                }
                
                Button(action: { showingInsights = true }) {
                    HStack {
                        Image(systemName: "lightbulb")
                        Text("Insights")
                    }
                    .font(.subheadline)
                    .foregroundColor(AppColorScheme.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .neumorphicButton(cornerRadius: 8)
                
                Spacer()
            }
        }
        .padding(20)
        .neumorphicCard()
    }
}

struct RecentTasksView: View {
    let tasks: [TaskModel]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Tasks")
                    .font(.headline)
                    .foregroundColor(AppColorScheme.textPrimary)
                
                Spacer()
                
                Text("View All")
                    .font(.subheadline)
                    .foregroundColor(AppColorScheme.primaryAction)
            }
            
            VStack(spacing: 8) {
                ForEach(tasks, id: \.id) { task in
                    CompactTaskRowView(task: task)
                }
            }
        }
        .padding(20)
        .neumorphicCard()
    }
}

struct CompactTaskRowView: View {
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
        .padding(.vertical, 4)
    }
}

struct TeamOverviewView: View {
    let teamMembers: [TeamMemberModel]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Team")
                    .font(.headline)
                    .foregroundColor(AppColorScheme.textPrimary)
                
                Spacer()
                
                Text("\(teamMembers.count) members")
                    .font(.subheadline)
                    .foregroundColor(AppColorScheme.textSecondary)
            }
            
            HStack(spacing: -8) {
                ForEach(Array(teamMembers.prefix(5)), id: \.id) { member in
                    Circle()
                        .fill(AppColorScheme.cardBackground)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(member.initials)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColorScheme.textPrimary)
                        )
                        .overlay(
                            Circle()
                                .stroke(AppColorScheme.background, lineWidth: 2)
                        )
                }
                
                if teamMembers.count > 5 {
                    Circle()
                        .fill(AppColorScheme.textTertiary)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text("+\(teamMembers.count - 5)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColorScheme.background)
                        )
                }
                
                Spacer()
            }
        }
        .padding(20)
        .neumorphicCard()
    }
}

struct ProjectTimelineView: View {
    let project: ProjectModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timeline")
                .font(.headline)
                .foregroundColor(AppColorScheme.textPrimary)
            
            VStack(spacing: 8) {
                TimelineItemView(
                    title: "Project Started",
                    date: project.startDate,
                    isCompleted: true
                )
                
                if let endDate = project.estimatedEndDate {
                    TimelineItemView(
                        title: "Estimated Completion",
                        date: endDate,
                        isCompleted: false,
                        isOverdue: project.isOverdue
                    )
                }
                
                if let actualEndDate = project.endDate {
                    TimelineItemView(
                        title: "Actual Completion",
                        date: actualEndDate,
                        isCompleted: true
                    )
                }
            }
        }
        .padding(20)
        .neumorphicCard()
    }
}

struct TimelineItemView: View {
    let title: String
    let date: Date
    let isCompleted: Bool
    let isOverdue: Bool
    
    init(title: String, date: Date, isCompleted: Bool, isOverdue: Bool = false) {
        self.title = title
        self.date = date
        self.isCompleted = isCompleted
        self.isOverdue = isOverdue
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(isCompleted ? AppColorScheme.success : (isOverdue ? AppColorScheme.error : AppColorScheme.textTertiary))
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(AppColorScheme.textPrimary)
                
                Text(date, style: .date)
                    .font(.caption)
                    .foregroundColor(isOverdue ? AppColorScheme.error : AppColorScheme.textSecondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Tasks Tab
struct ProjectTasksTab: View {
    let tasks: [TaskModel]
    @Binding var showingAddTask: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with add button
            HStack {
                Text("\(tasks.count) Tasks")
                    .font(.headline)
                    .foregroundColor(AppColorScheme.textPrimary)
                
                Spacer()
                
                Button("Add Task") {
                    showingAddTask = true
                }
                .font(.subheadline)
                .foregroundColor(AppColorScheme.primaryAction)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
            
            // Tasks list
            if tasks.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 50, weight: .light))
                        .foregroundColor(AppColorScheme.textTertiary)
                    
                    Text("No Tasks Yet")
                        .font(.title3)
                        .foregroundColor(AppColorScheme.textPrimary)
                    
                    Text("Add your first task to get started")
                        .font(.body)
                        .foregroundColor(AppColorScheme.textSecondary)
                    
                    Button("Add Task") {
                        showingAddTask = true
                    }
                    .font(.headline)
                    .foregroundColor(AppColorScheme.background)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppColorScheme.primaryAction)
                    .cornerRadius(10)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 40)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(tasks, id: \.id) { task in
                            ProjectTaskRowView(task: task)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 50)
                }
            }
        }
    }
}

struct ProjectTaskRowView: View {
    let task: TaskModel
    
    var body: some View {
        HStack(spacing: 15) {
            // Priority indicator
            Rectangle()
                .fill(task.priority.color)
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(AppColorScheme.textPrimary)
                    .lineLimit(1)
                
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.subheadline)
                        .foregroundColor(AppColorScheme.textSecondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Text(task.status.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(statusColor(for: task.status).opacity(0.2))
                        )
                        .foregroundColor(statusColor(for: task.status))
                    
                    if let dueDate = task.dueDate {
                        Text(dueDate, style: .date)
                            .font(.caption)
                            .foregroundColor(task.isOverdue ? AppColorScheme.error : AppColorScheme.textTertiary)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(16)
        .neumorphicCard()
    }
    
    private func statusColor(for status: TaskStatus) -> Color {
        switch status {
        case .todo: return AppColorScheme.textSecondary
        case .inProgress: return AppColorScheme.primaryAction
        case .completed: return AppColorScheme.success
        case .onHold: return AppColorScheme.warning
        }
    }
}

// MARK: - Team Tab
struct ProjectTeamTab: View {
    let teamMembers: [TeamMemberModel]
    @Binding var showingTeamManagement: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("\(teamMembers.count) Team Members")
                    .font(.headline)
                    .foregroundColor(AppColorScheme.textPrimary)
                
                Spacer()
                
                Button("Manage") {
                    showingTeamManagement = true
                }
                .font(.subheadline)
                .foregroundColor(AppColorScheme.primaryAction)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
            
            // Team members list
            if teamMembers.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "person.3")
                        .font(.system(size: 50, weight: .light))
                        .foregroundColor(AppColorScheme.textTertiary)
                    
                    Text("No Team Members")
                        .font(.title3)
                        .foregroundColor(AppColorScheme.textPrimary)
                    
                    Text("Add team members to collaborate")
                        .font(.body)
                        .foregroundColor(AppColorScheme.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 40)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(teamMembers, id: \.id) { member in
                            ProjectTeamMemberRowView(member: member)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 50)
                }
            }
        }
    }
}

struct ProjectTeamMemberRowView: View {
    let member: TeamMemberModel
    
    var body: some View {
        HStack(spacing: 15) {
            // Avatar
            Circle()
                .fill(AppColorScheme.cardBackground)
                .frame(width: 50, height: 50)
                .overlay(
                    Text(member.initials)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColorScheme.textPrimary)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(member.name)
                    .font(.headline)
                    .foregroundColor(AppColorScheme.textPrimary)
                
                HStack {
                    Image(systemName: member.role.icon)
                        .foregroundColor(member.role.color)
                        .font(.caption)
                    
                    Text(member.role.rawValue)
                        .font(.subheadline)
                        .foregroundColor(AppColorScheme.textSecondary)
                }
                
                // Stats
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Text("\(member.stats.tasksCompleted)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColorScheme.success)
                        Text("completed")
                            .font(.caption)
                            .foregroundColor(AppColorScheme.textTertiary)
                    }
                    
                    HStack(spacing: 4) {
                        Text("\(Int(member.stats.productivityScore))")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColorScheme.primaryAction)
                        Text("score")
                            .font(.caption)
                            .foregroundColor(AppColorScheme.textTertiary)
                    }
                }
            }
            
            Spacer()
            
            // Status indicator
            Circle()
                .fill(member.isActive ? AppColorScheme.success : AppColorScheme.textTertiary)
                .frame(width: 12, height: 12)
        }
        .padding(16)
        .neumorphicCard()
    }
}

// MARK: - Insights Tab
struct ProjectInsightsTab: View {
    let project: ProjectModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Key metrics
                ProjectMetricsView(project: project)
                
                // Insights list
                if !project.insights.isEmpty {
                    ProjectInsightsListView(insights: project.insights)
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "lightbulb")
                            .font(.system(size: 50, weight: .light))
                            .foregroundColor(AppColorScheme.textTertiary)
                        
                        Text("No Insights Available")
                            .font(.title3)
                            .foregroundColor(AppColorScheme.textPrimary)
                        
                        Text("Insights will be generated as your project progresses")
                            .font(.body)
                            .foregroundColor(AppColorScheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 40)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                Spacer(minLength: 50)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
    }
}

struct ProjectMetricsView: View {
    let project: ProjectModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Project Metrics")
                .font(.headline)
                .foregroundColor(AppColorScheme.textPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                MetricCardView(
                    title: "Completion",
                    value: "\(Int(project.metrics.completionPercentage))%",
                    color: AppColorScheme.success
                )
                
                MetricCardView(
                    title: "On Time Performance",
                    value: "\(Int(project.metrics.onTimePerformance))%",
                    color: project.metrics.onTimePerformance > 80 ? AppColorScheme.success : AppColorScheme.warning
                )
                
                MetricCardView(
                    title: "Total Tasks",
                    value: "\(project.metrics.totalTasks)",
                    color: AppColorScheme.info
                )
                
                MetricCardView(
                    title: "Overdue Tasks",
                    value: "\(project.metrics.overdueTasks)",
                    color: project.metrics.overdueTasks > 0 ? AppColorScheme.error : AppColorScheme.success
                )
            }
        }
        .padding(20)
        .neumorphicCard()
    }
}

struct MetricCardView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(AppColorScheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .neumorphicStyle(cornerRadius: 8, shadowRadius: 4, shadowOffset: 3)
    }
}

struct ProjectInsightsListView: View {
    let insights: [ProjectInsight]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Insights & Recommendations")
                .font(.headline)
                .foregroundColor(AppColorScheme.textPrimary)
            
            VStack(spacing: 12) {
                ForEach(insights, id: \.id) { insight in
                    InsightRowView(insight: insight)
                }
            }
        }
        .padding(20)
        .neumorphicCard()
    }
}

struct InsightRowView: View {
    let insight: ProjectInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(insight.title)
                    .font(.headline)
                    .foregroundColor(AppColorScheme.textPrimary)
                
                Spacer()
                
                Text(insight.impact)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(impactColor(for: insight.impact).opacity(0.2))
                    )
                    .foregroundColor(impactColor(for: insight.impact))
            }
            
            Text(insight.description)
                .font(.subheadline)
                .foregroundColor(AppColorScheme.textSecondary)
            
            Text(insight.recommendation)
                .font(.subheadline)
                .foregroundColor(AppColorScheme.textPrimary)
                .padding(.top, 4)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppColorScheme.cardBackground.opacity(0.5))
        )
    }
    
    private func impactColor(for impact: String) -> Color {
        switch impact.lowercased() {
        case "high": return AppColorScheme.error
        case "medium": return AppColorScheme.warning
        case "low": return AppColorScheme.info
        default: return AppColorScheme.textSecondary
        }
    }
}

// MARK: - Additional Views
struct AddProjectTaskView: View {
    let projectId: UUID
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var priority = TaskPriority.medium
    @State private var dueDate = Date()
    @State private var hasDueDate = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColorScheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Title input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(.headline)
                                .foregroundColor(AppColorScheme.textPrimary)
                            
                            TextField("Enter task title", text: $title)
                                .textFieldStyle(NeumorphicTextFieldStyle())
                        }
                        
                        // Description input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                                .foregroundColor(AppColorScheme.textPrimary)
                            
                            TextField("Enter task description", text: $description)
                                .textFieldStyle(NeumorphicTextFieldStyle())
                        }
                        
                        // Priority selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Priority")
                                .font(.headline)
                                .foregroundColor(AppColorScheme.textPrimary)
                            
                            HStack(spacing: 12) {
                                ForEach(TaskPriority.allCases, id: \.self) { taskPriority in
                                    Button(taskPriority.rawValue) {
                                        priority = taskPriority
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(priority == taskPriority ? AppColorScheme.background : taskPriority.color)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(priority == taskPriority ? taskPriority.color : Color.clear)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(taskPriority.color, lineWidth: 1)
                                            )
                                    )
                                }
                            }
                        }
                        
                        // Due date toggle and picker
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Due Date")
                                    .font(.headline)
                                    .foregroundColor(AppColorScheme.textPrimary)
                                
                                Spacer()
                                
                                NeumorphicToggle(isOn: $hasDueDate)
                            }
                            
                            if hasDueDate {
                                DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date])
                                    .datePickerStyle(.compact)
                                    .foregroundColor(AppColorScheme.textPrimary)
                            }
                        }
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(AppColorScheme.textSecondary),
                trailing: Button("Save") {
                    saveTask()
                }
                .foregroundColor(canSave ? AppColorScheme.primaryAction : AppColorScheme.textTertiary)
                .disabled(!canSave)
            )
        }
    }
    
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func saveTask() {
        var task = TaskModel(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description,
            priority: priority,
            projectId: projectId
        )
        
        if hasDueDate {
            task.dueDate = dueDate
        }
        
        DataService.shared.addTask(task)
        dismiss()
    }
}

struct ProjectTeamManagementView: View {
    let project: ProjectModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddMember = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColorScheme.background.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Current team members
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("Team Members")
                                .font(.headline)
                                .foregroundColor(AppColorScheme.textPrimary)
                            
                            Spacer()
                            
                            Button("Add Member") {
                                showingAddMember = true
                            }
                            .font(.subheadline)
                            .foregroundColor(AppColorScheme.primaryAction)
                        }
                        
                        if project.teamMemberIds.isEmpty {
                            Text("No team members assigned")
                                .foregroundColor(AppColorScheme.textSecondary)
                                .padding(.vertical, 20)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(DataService.shared.teamMembers.filter { project.teamMemberIds.contains($0.id) }, id: \.id) { member in
                                    ProjectTeamMemberRowView(member: member)
                                }
                            }
                        }
                    }
                    .padding(20)
                    .neumorphicCard()
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Team Management")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                trailing: Button("Done") {
                    dismiss()
                }
                .foregroundColor(AppColorScheme.primaryAction)
            )
            .sheet(isPresented: $showingAddMember) {
                AddTeamMemberView()
            }
        }
    }
}

struct ProjectInsightsDetailView: View {
    let project: ProjectModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColorScheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Project metrics
                        ProjectMetricsView(project: project)
                        
                        // Insights
                        if !project.insights.isEmpty {
                            ProjectInsightsListView(insights: project.insights)
                        } else {
                            VStack(spacing: 20) {
                                Image(systemName: "lightbulb")
                                    .font(.system(size: 50, weight: .light))
                                    .foregroundColor(AppColorScheme.textTertiary)
                                
                                Text("No Insights Available")
                                    .font(.title3)
                                    .foregroundColor(AppColorScheme.textPrimary)
                                
                                Text("Insights will be generated as your project progresses")
                                    .font(.body)
                                    .foregroundColor(AppColorScheme.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 40)
                            .padding(.vertical, 40)
                            .neumorphicCard()
                        }
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Project Insights")
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

// MARK: - Extensions
extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
}

#Preview {
    ProjectDetailView(project: ProjectModel(name: "Sample Project", description: "A sample project for preview"))
}
