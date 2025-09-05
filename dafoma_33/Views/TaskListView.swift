//
//  TaskListView.swift
//  TaskVantage Road
//
//  Created by Developer on 1/9/25.
//

import SwiftUI

struct TaskListView: View {
    @StateObject private var taskViewModel = TaskViewModel()
    @State private var showingAddTask = false
    @State private var showingFilters = false
    @State private var selectedTask: TaskModel?
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColorScheme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with search and filters
                    TaskListHeaderView(
                        taskViewModel: taskViewModel,
                        showingFilters: $showingFilters,
                        showingAddTask: $showingAddTask
                    )
                    
                    // Quick stats
                    TaskQuickStatsView(taskViewModel: taskViewModel)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                    
                    // Task list
                    if taskViewModel.filteredTasks.isEmpty {
                        TaskEmptyStateView(
                            hasFilters: !taskViewModel.searchText.isEmpty ||
                            taskViewModel.selectedPriority != nil ||
                            taskViewModel.selectedStatus != nil
                        )
                    } else {
                        TaskListContentView(
                            tasks: taskViewModel.filteredTasks,
                                                    onTaskTap: { task in
                            selectedTask = task
                        },
                            onTaskToggle: taskViewModel.toggleTaskCompletion
                        )
                    }
                }
            }
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAddTask) {
                AddTaskView()
            }
            .sheet(isPresented: $showingFilters) {
                TaskFiltersView(taskViewModel: taskViewModel)
            }
            .sheet(item: Binding<TaskModel?>(
                get: { selectedTask },
                set: { _ in selectedTask = nil }
            )) { task in
                TaskDetailView(task: task)
            }
        }
    }
    
}

struct TaskListHeaderView: View {
    @ObservedObject var taskViewModel: TaskViewModel
    @Binding var showingFilters: Bool
    @Binding var showingAddTask: Bool
    
    var body: some View {
        VStack(spacing: 15) {
            // Search bar
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColorScheme.textSecondary)
                    
                    TextField("Search tasks...", text: $taskViewModel.searchText)
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
                // Add task button
                Button(action: { showingAddTask = true }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Task")
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
                    ForEach(TaskViewModel.TaskSortOption.allCases, id: \.self) { option in
                        Button(option.rawValue) {
                            taskViewModel.sortOption = option
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
        taskViewModel.selectedPriority != nil ||
        taskViewModel.selectedStatus != nil ||
        taskViewModel.selectedProject != nil ||
        !taskViewModel.showCompletedTasks
    }
}

struct TaskQuickStatsView: View {
    @ObservedObject var taskViewModel: TaskViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            StatCardView(
                title: "Total",
                value: "\(taskViewModel.tasks.count)",
                color: AppColorScheme.info
            )
            
            StatCardView(
                title: "Completed",
                value: "\(taskViewModel.tasks.filter { $0.status == .completed }.count)",
                color: AppColorScheme.success
            )
            
            StatCardView(
                title: "In Progress",
                value: "\(taskViewModel.tasksInProgressCount)",
                color: AppColorScheme.primaryAction
            )
            
            StatCardView(
                title: "Overdue",
                value: "\(taskViewModel.overdueTasksCount)",
                color: AppColorScheme.error
            )
        }
    }
}

struct StatCardView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(AppColorScheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .neumorphicCard(cornerRadius: 8, shadowRadius: 4, shadowOffset: 3)
    }
}

struct TaskListContentView: View {
    let tasks: [TaskModel]
    let onTaskTap: (TaskModel) -> Void
    let onTaskToggle: (TaskModel) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(tasks, id: \.id) { task in
                    TaskRowView(
                        task: task,
                        onTap: { onTaskTap(task) },
                        onToggle: { onTaskToggle(task) }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
    }
}

struct TaskRowView: View {
    let task: TaskModel
    let onTap: () -> Void
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: {
            print("TaskRowView button tapped for: \(task.title)")
            onTap()
        }) {
            HStack(spacing: 15) {
                // Completion toggle
                Button(action: onToggle) {
                    Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(task.status == .completed ? AppColorScheme.success : AppColorScheme.textSecondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                VStack(alignment: .leading, spacing: 6) {
                    // Title and priority
                    HStack {
                        Text(task.title)
                            .font(.headline)
                            .foregroundColor(AppColorScheme.textPrimary)
                            .strikethrough(task.status == .completed)
                        
                        Spacer()
                        
                        // Priority indicator
                        Circle()
                            .fill(task.priority.color)
                            .frame(width: 12, height: 12)
                    }
                    
                    // Description
                    if !task.description.isEmpty {
                        Text(task.description)
                            .font(.subheadline)
                            .foregroundColor(AppColorScheme.textSecondary)
                            .lineLimit(2)
                    }
                    
                    // Due date and status
                    HStack {
                        if let dueDate = task.dueDate {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.caption)
                                Text(dueDate, style: .date)
                                    .font(.caption)
                            }
                            .foregroundColor(task.isOverdue ? AppColorScheme.error : AppColorScheme.textTertiary)
                        }
                        
                        Spacer()
                        
                        // Status badge
                        Text(task.status.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(statusColor(for: task.status).opacity(0.2))
                            )
                            .foregroundColor(statusColor(for: task.status))
                    }
                }
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppColorScheme.textTertiary)
            }
            .padding(16)
        }
        .neumorphicCard()
    }
    
    private func statusColor(for status: TaskStatus) -> Color {
        switch status {
        case .todo:
            return AppColorScheme.textSecondary
        case .inProgress:
            return AppColorScheme.primaryAction
        case .completed:
            return AppColorScheme.success
        case .onHold:
            return AppColorScheme.warning
        }
    }
}

struct TaskEmptyStateView: View {
    let hasFilters: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: hasFilters ? "line.3.horizontal.decrease.circle" : "checkmark.circle")
                .font(.system(size: 60, weight: .light))
                .foregroundColor(AppColorScheme.textTertiary)
            
            VStack(spacing: 8) {
                Text(hasFilters ? "No Tasks Match Filters" : "No Tasks Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColorScheme.textPrimary)
                
                Text(hasFilters ? "Try adjusting your search or filter criteria" : "Add your first task to get started")
                    .font(.body)
                    .foregroundColor(AppColorScheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if !hasFilters {
                Button("Add Your First Task") {
                    // This would trigger the add task sheet
                }
                .font(.headline)
                .foregroundColor(AppColorScheme.background)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(AppColorScheme.primaryAction)
                .cornerRadius(10)
            }
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Add Task View
struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var taskViewModel = TaskViewModel()
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
        var task = TaskModel(title: title.trimmingCharacters(in: .whitespacesAndNewlines), description: description, priority: priority)
        
        if hasDueDate {
            task.dueDate = dueDate
        }
        
        taskViewModel.addTask(task)
        dismiss()
    }
}

// MARK: - Task Filters View
struct TaskFiltersView: View {
    @ObservedObject var taskViewModel: TaskViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColorScheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Priority filter
                        FilterSectionView(title: "Priority") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    FilterChip(
                                        title: "All",
                                        isSelected: taskViewModel.selectedPriority == nil
                                    ) {
                                        taskViewModel.selectedPriority = nil
                                    }
                                    
                                    ForEach(TaskPriority.allCases, id: \.self) { priority in
                                        FilterChip(
                                            title: priority.rawValue,
                                            isSelected: taskViewModel.selectedPriority == priority,
                                            color: priority.color
                                        ) {
                                            taskViewModel.selectedPriority = priority
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // Status filter
                        FilterSectionView(title: "Status") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    FilterChip(
                                        title: "All",
                                        isSelected: taskViewModel.selectedStatus == nil
                                    ) {
                                        taskViewModel.selectedStatus = nil
                                    }
                                    
                                    ForEach(TaskStatus.allCases, id: \.self) { status in
                                        FilterChip(
                                            title: status.rawValue,
                                            isSelected: taskViewModel.selectedStatus == status
                                        ) {
                                            taskViewModel.selectedStatus = status
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // Show completed tasks toggle
                        FilterSectionView(title: "Display Options") {
                            HStack {
                                Text("Show Completed Tasks")
                                    .font(.body)
                                    .foregroundColor(AppColorScheme.textPrimary)
                                
                                Spacer()
                                
                                NeumorphicToggle(isOn: $taskViewModel.showCompletedTasks)
                            }
                            .padding(.horizontal, 20)
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
                    taskViewModel.selectedPriority = nil
                    taskViewModel.selectedStatus = nil
                    taskViewModel.selectedProject = nil
                    taskViewModel.showCompletedTasks = true
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

struct FilterSectionView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(AppColorScheme.textPrimary)
                .padding(.horizontal, 20)
            
            content
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color?
    let action: () -> Void
    
    init(title: String, isSelected: Bool, color: Color? = nil, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(isSelected ? AppColorScheme.background : (color ?? AppColorScheme.textPrimary))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? (color ?? AppColorScheme.primaryAction) : AppColorScheme.cardBackground)
                        .shadow(
                            color: AppColorScheme.shadowDark.opacity(0.3),
                            radius: isSelected ? 1 : 2,
                            x: isSelected ? -1 : -2,
                            y: isSelected ? -1 : -2
                        )
                        .shadow(
                            color: AppColorScheme.shadowLight.opacity(0.3),
                            radius: isSelected ? 1 : 2,
                            x: isSelected ? 1 : 2,
                            y: isSelected ? 1 : 2
                        )
                )
        }
        .scaleEffect(isSelected ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isSelected)
    }
}

// MARK: - Task Detail View
struct TaskDetailView: View {
    let task: TaskModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColorScheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Task header
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Circle()
                                    .fill(task.priority.color)
                                    .frame(width: 16, height: 16)
                                
                                Text(task.priority.rawValue)
                                    .font(.headline)
                                    .foregroundColor(task.priority.color)
                                
                                Spacer()
                                
                                Text(task.status.rawValue)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(AppColorScheme.cardBackground)
                                    )
                                    .foregroundColor(AppColorScheme.textPrimary)
                            }
                            
                            Text(task.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(AppColorScheme.textPrimary)
                        }
                        .padding(20)
                        .neumorphicCard()
                        
                        // Task details
                        if !task.description.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Description")
                                    .font(.headline)
                                    .foregroundColor(AppColorScheme.textPrimary)
                                
                                Text(task.description)
                                    .font(.body)
                                    .foregroundColor(AppColorScheme.textSecondary)
                            }
                            .padding(20)
                            .neumorphicCard()
                        }
                        
                        // Due date and progress
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Timeline")
                                .font(.headline)
                                .foregroundColor(AppColorScheme.textPrimary)
                            
                            if let dueDate = task.dueDate {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(task.isOverdue ? AppColorScheme.error : AppColorScheme.textSecondary)
                                    
                                    Text("Due: \(dueDate, style: .date)")
                                        .foregroundColor(task.isOverdue ? AppColorScheme.error : AppColorScheme.textSecondary)
                                    
                                    if task.isOverdue {
                                        Text("(Overdue)")
                                            .foregroundColor(AppColorScheme.error)
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                            
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(AppColorScheme.textSecondary)
                                
                                Text("Created: \(task.createdDate, style: .date)")
                                    .foregroundColor(AppColorScheme.textSecondary)
                            }
                            
                            if let completedDate = task.completedDate {
                                HStack {
                                    Image(systemName: "checkmark.circle")
                                        .foregroundColor(AppColorScheme.success)
                                    
                                    Text("Completed: \(completedDate, style: .date)")
                                        .foregroundColor(AppColorScheme.success)
                                }
                            }
                        }
                        .padding(20)
                        .neumorphicCard()
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Task Details")
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

#Preview {
    TaskListView()
}
