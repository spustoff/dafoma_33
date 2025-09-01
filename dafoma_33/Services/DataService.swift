//
//  DataService.swift
//  TaskVantage Road
//
//  Created by Developer on 1/9/25.
//

import Foundation
import Combine

class DataService: ObservableObject {
    static let shared = DataService()
    
    @Published var tasks: [TaskModel] = []
    @Published var projects: [ProjectModel] = []
    @Published var teamMembers: [TeamMemberModel] = []
    
    private let userDefaults = UserDefaults.standard
    private let tasksKey = "TaskVantage_Tasks"
    private let projectsKey = "TaskVantage_Projects"
    private let teamMembersKey = "TaskVantage_TeamMembers"
    
    private init() {
        loadData()
        setupSampleData()
    }
    
    // MARK: - Data Persistence
    private func loadData() {
        loadTasks()
        loadProjects()
        loadTeamMembers()
    }
    
    private func saveData() {
        saveTasks()
        saveProjects()
        saveTeamMembers()
    }
    
    private func loadTasks() {
        if let data = userDefaults.data(forKey: tasksKey),
           let decodedTasks = try? JSONDecoder().decode([TaskModel].self, from: data) {
            tasks = decodedTasks
        }
    }
    
    private func saveTasks() {
        if let encodedTasks = try? JSONEncoder().encode(tasks) {
            userDefaults.set(encodedTasks, forKey: tasksKey)
        }
    }
    
    private func loadProjects() {
        if let data = userDefaults.data(forKey: projectsKey),
           let decodedProjects = try? JSONDecoder().decode([ProjectModel].self, from: data) {
            projects = decodedProjects
        }
    }
    
    private func saveProjects() {
        if let encodedProjects = try? JSONEncoder().encode(projects) {
            userDefaults.set(encodedProjects, forKey: projectsKey)
        }
    }
    
    private func loadTeamMembers() {
        if let data = userDefaults.data(forKey: teamMembersKey),
           let decodedMembers = try? JSONDecoder().decode([TeamMemberModel].self, from: data) {
            teamMembers = decodedMembers
        }
    }
    
    private func saveTeamMembers() {
        if let encodedMembers = try? JSONEncoder().encode(teamMembers) {
            userDefaults.set(encodedMembers, forKey: teamMembersKey)
        }
    }
    
    // MARK: - Task Management
    func addTask(_ task: TaskModel) {
        tasks.append(task)
        updateProjectMetrics(for: task.projectId)
        saveTasks()
        saveProjects()
    }
    
    func updateTask(_ task: TaskModel) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            updateProjectMetrics(for: task.projectId)
            updateTeamMemberStats(for: task.assignedToMemberId)
            saveTasks()
            saveProjects()
            saveTeamMembers()
        }
    }
    
    func deleteTask(_ task: TaskModel) {
        tasks.removeAll { $0.id == task.id }
        updateProjectMetrics(for: task.projectId)
        updateTeamMemberStats(for: task.assignedToMemberId)
        saveTasks()
        saveProjects()
        saveTeamMembers()
    }
    
    func getTasksForProject(_ projectId: UUID) -> [TaskModel] {
        return tasks.filter { $0.projectId == projectId }
    }
    
    func getTasksForMember(_ memberId: UUID) -> [TaskModel] {
        return tasks.filter { $0.assignedToMemberId == memberId }
    }
    
    // MARK: - Project Management
    func addProject(_ project: ProjectModel) {
        projects.append(project)
        saveProjects()
    }
    
    func updateProject(_ project: ProjectModel) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = project
            saveProjects()
        }
    }
    
    func deleteProject(_ project: ProjectModel) {
        // Remove all tasks associated with this project
        tasks.removeAll { $0.projectId == project.id }
        projects.removeAll { $0.id == project.id }
        saveTasks()
        saveProjects()
    }
    
    // MARK: - Team Management
    func addTeamMember(_ member: TeamMemberModel) {
        teamMembers.append(member)
        saveTeamMembers()
    }
    
    func updateTeamMember(_ member: TeamMemberModel) {
        if let index = teamMembers.firstIndex(where: { $0.id == member.id }) {
            teamMembers[index] = member
            saveTeamMembers()
        }
    }
    
    func deleteTeamMember(_ member: TeamMemberModel) {
        // Unassign tasks from this member
        for i in tasks.indices {
            if tasks[i].assignedToMemberId == member.id {
                tasks[i].assignedToMemberId = nil
            }
        }
        
        // Remove member from projects
        for i in projects.indices {
            projects[i].teamMemberIds.removeAll { $0 == member.id }
        }
        
        teamMembers.removeAll { $0.id == member.id }
        saveTasks()
        saveProjects()
        saveTeamMembers()
    }
    
    // MARK: - Analytics and Insights
    private func updateProjectMetrics(for projectId: UUID?) {
        guard let projectId = projectId,
              let projectIndex = projects.firstIndex(where: { $0.id == projectId }) else { return }
        
        let projectTasks = getTasksForProject(projectId)
        var metrics = projects[projectIndex].metrics
        
        metrics.totalTasks = projectTasks.count
        metrics.completedTasks = projectTasks.filter { $0.status == .completed }.count
        metrics.overdueTasks = projectTasks.filter { $0.isOverdue }.count
        
        // Calculate average completion time
        let completedTasks = projectTasks.filter { $0.status == .completed && $0.completedDate != nil }
        if !completedTasks.isEmpty {
            let totalTime = completedTasks.compactMap { task in
                guard let completedDate = task.completedDate else { return nil }
                return completedDate.timeIntervalSince(task.createdDate)
            }.reduce(0.0) { $0 + $1 }
            metrics.averageTaskCompletionTime = totalTime / Double(completedTasks.count) / 3600 // Convert to hours
        }
        
        // Calculate time spent
        metrics.timeSpent = projectTasks.compactMap { $0.actualHours }.reduce(0.0) { $0 + $1 }
        
        // Calculate team productivity score
        let teamSize = projects[projectIndex].teamMemberIds.count
        if teamSize > 0 {
            metrics.teamProductivityScore = metrics.completionPercentage / Double(teamSize) * 10
        }
        
        projects[projectIndex].metrics = metrics
        projects[projectIndex].generateInsights(from: projectTasks)
    }
    
    private func updateTeamMemberStats(for memberId: UUID?) {
        guard let memberId = memberId,
              let memberIndex = teamMembers.firstIndex(where: { $0.id == memberId }) else { return }
        
        let memberTasks = getTasksForMember(memberId)
        teamMembers[memberIndex].updateStats(tasks: memberTasks)
        
        // Update projects involved count
        let projectsInvolved = Set(memberTasks.compactMap { $0.projectId }).count
        teamMembers[memberIndex].stats.projectsInvolved = projectsInvolved
    }
    
    // MARK: - Sample Data
    private func setupSampleData() {
        guard tasks.isEmpty && projects.isEmpty && teamMembers.isEmpty else { return }
        
        // Create sample team members
        let john = TeamMemberModel(name: "John Smith", email: "john@company.com", role: .projectManager)
        let sarah = TeamMemberModel(name: "Sarah Johnson", email: "sarah@company.com", role: .developer)
        let mike = TeamMemberModel(name: "Mike Wilson", email: "mike@company.com", role: .designer)
        let lisa = TeamMemberModel(name: "Lisa Chen", email: "lisa@company.com", role: .analyst)
        
        teamMembers = [john, sarah, mike, lisa]
        
        // Create sample projects
        var mobileApp = ProjectModel(
            name: "Mobile App Redesign",
            description: "Complete redesign of the company mobile application with modern UI/UX",
            estimatedEndDate: Calendar.current.date(byAdding: .month, value: 3, to: Date())
        )
        mobileApp.teamMemberIds = [john.id, sarah.id, mike.id]
        mobileApp.status = .active
        mobileApp.budget = 50000
        
        var webPlatform = ProjectModel(
            name: "Web Platform Integration",
            description: "Integration of new analytics platform with existing web services",
            estimatedEndDate: Calendar.current.date(byAdding: .month, value: 2, to: Date())
        )
        webPlatform.teamMemberIds = [john.id, lisa.id]
        webPlatform.status = .planning
        webPlatform.budget = 30000
        
        projects = [mobileApp, webPlatform]
        
        // Create sample tasks
        var task1 = TaskModel(
            title: "Design new user interface",
            description: "Create modern, intuitive interface designs for mobile app",
            priority: .high,
            projectId: mobileApp.id
        )
        task1.assignedToMemberId = mike.id
        task1.dueDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())
        task1.estimatedHours = 40
        
        var task2 = TaskModel(
            title: "Implement user authentication",
            description: "Develop secure authentication system with biometric support",
            priority: .critical,
            projectId: mobileApp.id
        )
        task2.assignedToMemberId = sarah.id
        task2.dueDate = Calendar.current.date(byAdding: .day, value: 14, to: Date())
        task2.estimatedHours = 32
        task2.status = .inProgress
        
        var task3 = TaskModel(
            title: "Analytics integration research",
            description: "Research and document analytics platform integration requirements",
            priority: .medium,
            projectId: webPlatform.id
        )
        task3.assignedToMemberId = lisa.id
        task3.dueDate = Calendar.current.date(byAdding: .day, value: 5, to: Date())
        task3.estimatedHours = 16
        
        var task4 = TaskModel(
            title: "Database optimization",
            description: "Optimize database queries for better performance",
            priority: .medium,
            projectId: webPlatform.id
        )
        task4.assignedToMemberId = sarah.id
        task4.dueDate = Calendar.current.date(byAdding: .day, value: 10, to: Date())
        task4.estimatedHours = 24
        task4.status = .completed
        task4.completedDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())
        task4.actualHours = 20
        
        tasks = [task1, task2, task3, task4]
        
        // Update metrics for all projects
        for project in projects {
            updateProjectMetrics(for: project.id)
        }
        
        // Update stats for all team members
        for member in teamMembers {
            updateTeamMemberStats(for: member.id)
        }
        
        saveData()
    }
    
    // MARK: - Search and Filter
    func searchTasks(query: String) -> [TaskModel] {
        guard !query.isEmpty else { return tasks }
        return tasks.filter { task in
            task.title.localizedCaseInsensitiveContains(query) ||
            task.description.localizedCaseInsensitiveContains(query) ||
            task.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
    
    func getOverdueTasks() -> [TaskModel] {
        return tasks.filter { $0.isOverdue }
    }
    
    func getTasksWithPriority(_ priority: TaskPriority) -> [TaskModel] {
        return tasks.filter { $0.priority == priority }
    }
    
    func getTasksWithStatus(_ status: TaskStatus) -> [TaskModel] {
        return tasks.filter { $0.status == status }
    }
}
