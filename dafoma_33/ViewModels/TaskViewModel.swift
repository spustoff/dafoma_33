//
//  TaskViewModel.swift
//  TaskVantage Road
//
//  Created by Developer on 1/9/25.
//

import Foundation
import Combine
import SwiftUI

class TaskViewModel: ObservableObject {
    @Published var tasks: [TaskModel] = []
    @Published var filteredTasks: [TaskModel] = []
    @Published var searchText: String = ""
    @Published var selectedPriority: TaskPriority?
    @Published var selectedStatus: TaskStatus?
    @Published var selectedProject: ProjectModel?
    @Published var showCompletedTasks: Bool = true
    @Published var sortOption: TaskSortOption = .dueDate
    
    private var cancellables = Set<AnyCancellable>()
    private let dataService = DataService.shared
    
    enum TaskSortOption: String, CaseIterable {
        case dueDate = "Due Date"
        case priority = "Priority"
        case createdDate = "Created Date"
        case title = "Title"
        case status = "Status"
    }
    
    init() {
        setupBindings()
        setupNotificationObserver()
    }
    
    private func setupBindings() {
        // Bind to DataService tasks
        dataService.$tasks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tasks in
                self?.tasks = tasks
                self?.applyFiltersAndSort()
            }
            .store(in: &cancellables)
        
        // Update filtered tasks when search or filter criteria change
        Publishers.CombineLatest4($searchText, $selectedPriority, $selectedStatus, $showCompletedTasks)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _, _, _, _ in
                self?.applyFiltersAndSort()
            }
            .store(in: &cancellables)
        
        $sortOption
            .sink { [weak self] _ in
                self?.applyFiltersAndSort()
            }
            .store(in: &cancellables)
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTasksGeneratedFromText(_:)),
            name: .tasksGeneratedFromText,
            object: nil
        )
    }
    
    @objc private func handleTasksGeneratedFromText(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let generatedTasks = userInfo["tasks"] as? [TaskModel] else { return }
        
        DispatchQueue.main.async { [weak self] in
            for task in generatedTasks {
                self?.addTask(task)
            }
        }
    }
    
    // MARK: - Task Management
    func addTask(_ task: TaskModel) {
        dataService.addTask(task)
    }
    
    func updateTask(_ task: TaskModel) {
        dataService.updateTask(task)
    }
    
    func deleteTask(_ task: TaskModel) {
        dataService.deleteTask(task)
    }
    
    func toggleTaskCompletion(_ task: TaskModel) {
        var updatedTask = task
        if task.status == .completed {
            updatedTask.status = .todo
            updatedTask.completedDate = nil
        } else {
            updatedTask.status = .completed
            updatedTask.completedDate = Date()
        }
        updateTask(updatedTask)
    }
    
    func markTaskInProgress(_ task: TaskModel) {
        var updatedTask = task
        updatedTask.status = .inProgress
        updateTask(updatedTask)
    }
    
    func addTimeToTask(_ task: TaskModel, hours: Double) {
        var updatedTask = task
        updatedTask.actualHours = (updatedTask.actualHours ?? 0) + hours
        updateTask(updatedTask)
    }
    
    // MARK: - Filtering and Sorting
    private func applyFiltersAndSort() {
        var filtered = tasks
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { task in
                task.title.localizedCaseInsensitiveContains(searchText) ||
                task.description.localizedCaseInsensitiveContains(searchText) ||
                task.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Apply priority filter
        if let priority = selectedPriority {
            filtered = filtered.filter { $0.priority == priority }
        }
        
        // Apply status filter
        if let status = selectedStatus {
            filtered = filtered.filter { $0.status == status }
        }
        
        // Apply project filter
        if let project = selectedProject {
            filtered = filtered.filter { $0.projectId == project.id }
        }
        
        // Apply completed tasks filter
        if !showCompletedTasks {
            filtered = filtered.filter { $0.status != .completed }
        }
        
        // Apply sorting
        filtered = sortTasks(filtered)
        
        filteredTasks = filtered
    }
    
    private func sortTasks(_ tasks: [TaskModel]) -> [TaskModel] {
        switch sortOption {
        case .dueDate:
            return tasks.sorted { task1, task2 in
                guard let date1 = task1.dueDate, let date2 = task2.dueDate else {
                    return task1.dueDate != nil
                }
                return date1 < date2
            }
        case .priority:
            return tasks.sorted { task1, task2 in
                let priority1 = priorityValue(task1.priority)
                let priority2 = priorityValue(task2.priority)
                return priority1 > priority2
            }
        case .createdDate:
            return tasks.sorted { $0.createdDate > $1.createdDate }
        case .title:
            return tasks.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .status:
            return tasks.sorted { task1, task2 in
                let status1 = statusValue(task1.status)
                let status2 = statusValue(task2.status)
                return status1 < status2
            }
        }
    }
    
    private func priorityValue(_ priority: TaskPriority) -> Int {
        switch priority {
        case .critical: return 4
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
    
    private func statusValue(_ status: TaskStatus) -> Int {
        switch status {
        case .todo: return 1
        case .inProgress: return 2
        case .onHold: return 3
        case .completed: return 4
        }
    }
    
    // MARK: - Quick Actions
    func getOverdueTasks() -> [TaskModel] {
        return tasks.filter { $0.isOverdue }
    }
    
    func getTasksDueToday() -> [TaskModel] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate >= today && dueDate < tomorrow
        }
    }
    
    func getTasksDueThisWeek() -> [TaskModel] {
        let today = Date()
        let weekFromToday = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: today)!
        
        return tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate >= today && dueDate <= weekFromToday
        }
    }
    
    func getTasksWithHighPriority() -> [TaskModel] {
        return tasks.filter { $0.priority == .high || $0.priority == .critical }
    }
    
    func getTasksForProject(_ project: ProjectModel) -> [TaskModel] {
        return tasks.filter { $0.projectId == project.id }
    }
    
    func getTasksForMember(_ member: TeamMemberModel) -> [TaskModel] {
        return tasks.filter { $0.assignedToMemberId == member.id }
    }
    
    // MARK: - Statistics
    var completionRate: Double {
        guard !tasks.isEmpty else { return 0.0 }
        let completedCount = tasks.filter { $0.status == .completed }.count
        return Double(completedCount) / Double(tasks.count) * 100.0
    }
    
    var overdueTasksCount: Int {
        return getOverdueTasks().count
    }
    
    var tasksInProgressCount: Int {
        return tasks.filter { $0.status == .inProgress }.count
    }
    
    var averageCompletionTime: Double {
        let completedTasks = tasks.filter { $0.status == .completed && $0.completedDate != nil }
        guard !completedTasks.isEmpty else { return 0.0 }
        
        let totalTime = completedTasks.compactMap { task in
            guard let completedDate = task.completedDate else { return nil }
            return completedDate.timeIntervalSince(task.createdDate)
        }.reduce(0.0) { $0 + $1 }
        
        return totalTime / Double(completedTasks.count) / 3600 // Convert to hours
    }
    
    // MARK: - Cleanup
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
