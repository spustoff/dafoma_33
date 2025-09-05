//
//  ProjectViewModel.swift
//  TaskVantage Road
//
//  Created by Developer on 1/9/25.
//

import Foundation
import Combine
import SwiftUI

class ProjectViewModel: ObservableObject {
    @Published var projects: [ProjectModel] = []
    @Published var filteredProjects: [ProjectModel] = []
    @Published var searchText: String = ""
    @Published var selectedStatus: ProjectStatus?
    @Published var sortOption: ProjectSortOption = .dueDate
    @Published var selectedProject: ProjectModel?
    
    private var cancellables = Set<AnyCancellable>()
    private let dataService = DataService.shared
    
    enum ProjectSortOption: String, CaseIterable {
        case dueDate = "Due Date"
        case name = "Name"
        case createdDate = "Created Date"
        case status = "Status"
        case completion = "Completion"
    }
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        // Bind to DataService projects
        dataService.$projects
            .receive(on: DispatchQueue.main)
            .sink { [weak self] projects in
                self?.projects = projects
                self?.applyFiltersAndSort()
            }
            .store(in: &cancellables)
        
        // Update filtered projects when search or filter criteria change
        Publishers.CombineLatest($searchText, $selectedStatus)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _, _ in
                self?.applyFiltersAndSort()
            }
            .store(in: &cancellables)
        
        $sortOption
            .sink { [weak self] _ in
                self?.applyFiltersAndSort()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Project Management
    func addProject(_ project: ProjectModel) {
        dataService.addProject(project)
    }
    
    func updateProject(_ project: ProjectModel) {
        dataService.updateProject(project)
    }
    
    func deleteProject(_ project: ProjectModel) {
        dataService.deleteProject(project)
    }
    
    func addTeamMemberToProject(_ project: ProjectModel, memberId: UUID) {
        var updatedProject = project
        if !updatedProject.teamMemberIds.contains(memberId) {
            updatedProject.teamMemberIds.append(memberId)
            updateProject(updatedProject)
        }
    }
    
    func removeTeamMemberFromProject(_ project: ProjectModel, memberId: UUID) {
        var updatedProject = project
        updatedProject.teamMemberIds.removeAll { $0 == memberId }
        updateProject(updatedProject)
    }
    
    func updateProjectStatus(_ project: ProjectModel, status: ProjectStatus) {
        var updatedProject = project
        updatedProject.status = status
        
        // Set end date when project is completed
        if status == .completed && updatedProject.endDate == nil {
            updatedProject.endDate = Date()
        }
        
        updateProject(updatedProject)
    }
    
    // MARK: - Filtering and Sorting
    private func applyFiltersAndSort() {
        var filtered = projects
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { project in
                project.name.localizedCaseInsensitiveContains(searchText) ||
                project.description.localizedCaseInsensitiveContains(searchText) ||
                project.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Apply status filter
        if let status = selectedStatus {
            filtered = filtered.filter { $0.status == status }
        }
        
        // Apply sorting
        filtered = sortProjects(filtered)
        
        filteredProjects = filtered
    }
    
    private func sortProjects(_ projects: [ProjectModel]) -> [ProjectModel] {
        switch sortOption {
        case .dueDate:
            return projects.sorted { project1, project2 in
                guard let date1 = project1.estimatedEndDate, let date2 = project2.estimatedEndDate else {
                    return project1.estimatedEndDate != nil
                }
                return date1 < date2
            }
        case .name:
            return projects.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .createdDate:
            return projects.sorted { $0.createdDate > $1.createdDate }
        case .status:
            return projects.sorted { project1, project2 in
                let status1 = statusValue(project1.status)
                let status2 = statusValue(project2.status)
                return status1 < status2
            }
        case .completion:
            return projects.sorted { $0.metrics.completionPercentage > $1.metrics.completionPercentage }
        }
    }
    
    private func statusValue(_ status: ProjectStatus) -> Int {
        switch status {
        case .planning: return 1
        case .active: return 2
        case .onHold: return 3
        case .completed: return 4
        case .cancelled: return 5
        }
    }
    
    // MARK: - Project Analytics
    func getProjectTasks(_ project: ProjectModel) -> [TaskModel] {
        return dataService.getTasksForProject(project.id)
    }
    
    func getProjectProgress(_ project: ProjectModel) -> Double {
        return project.metrics.completionPercentage
    }
    
    func getProjectTeamMembers(_ project: ProjectModel) -> [TeamMemberModel] {
        return dataService.teamMembers.filter { project.teamMemberIds.contains($0.id) }
    }
    
    func getActiveProjects() -> [ProjectModel] {
        return projects.filter { $0.status == .active }
    }
    
    func getOverdueProjects() -> [ProjectModel] {
        return projects.filter { $0.isOverdue }
    }
    
    func getProjectsDueThisWeek() -> [ProjectModel] {
        let today = Date()
        let weekFromToday = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: today)!
        
        return projects.filter { project in
            guard let dueDate = project.estimatedEndDate else { return false }
            return dueDate >= today && dueDate <= weekFromToday
        }
    }
    
    // MARK: - Statistics
    var totalProjects: Int {
        return projects.count
    }
    
    var activeProjectsCount: Int {
        return projects.filter { $0.status == .active }.count
    }
    
    var completedProjectsCount: Int {
        return projects.filter { $0.status == .completed }.count
    }
    
    var overdueProjectsCount: Int {
        return getOverdueProjects().count
    }
    
    var averageProjectCompletion: Double {
        guard !projects.isEmpty else { return 0.0 }
        let totalCompletion = projects.map { $0.metrics.completionPercentage }.reduce(0, +)
        return totalCompletion / Double(projects.count)
    }
    
    var projectsCompletionRate: Double {
        guard !projects.isEmpty else { return 0.0 }
        return Double(completedProjectsCount) / Double(totalProjects) * 100.0
    }
    
    // MARK: - Insights Generation
    func generateProjectInsights(_ project: ProjectModel) -> [ProjectInsight] {
        var insights: [ProjectInsight] = []
        let tasks = getProjectTasks(project)
        
        // Timeline insights
        if project.isOverdue {
            insights.append(ProjectInsight(
                title: "Project Overdue",
                description: "This project has exceeded its estimated completion date by \(-project.daysRemaining) days",
                category: "Timeline",
                impact: "High",
                recommendation: "Consider extending the timeline or reducing scope to get back on track"
            ))
        } else if project.daysRemaining <= 7 && project.daysRemaining > 0 {
            insights.append(ProjectInsight(
                title: "Approaching Deadline",
                description: "Project deadline is in \(project.daysRemaining) days",
                category: "Timeline",
                impact: "Medium",
                recommendation: "Focus on critical tasks and ensure team is aware of approaching deadline"
            ))
        }
        
        // Performance insights
        let completionRate = project.metrics.completionPercentage
        if completionRate < 25 && project.status == .active {
            insights.append(ProjectInsight(
                title: "Low Progress",
                description: "Project completion is only \(String(format: "%.1f", completionRate))%",
                category: "Performance",
                impact: "High",
                recommendation: "Review project scope and team allocation. Consider breaking down tasks further"
            ))
        }
        
        // Team insights
        let teamSize = project.teamMemberIds.count
        let tasksPerMember = Double(tasks.count) / Double(max(teamSize, 1))
        if tasksPerMember > 15 {
            insights.append(ProjectInsight(
                title: "High Task Load",
                description: "Average of \(String(format: "%.1f", tasksPerMember)) tasks per team member",
                category: "Team",
                impact: "Medium",
                recommendation: "Consider adding more team members or redistributing tasks"
            ))
        }
        
        // Quality insights
        let overdueTasks = tasks.filter { $0.isOverdue }.count
        if overdueTasks > 0 {
            insights.append(ProjectInsight(
                title: "Overdue Tasks",
                description: "\(overdueTasks) tasks are overdue",
                category: "Quality",
                impact: overdueTasks > 5 ? "High" : "Medium",
                recommendation: "Address overdue tasks immediately and review task estimation process"
            ))
        }
        
        return insights
    }
    
    // MARK: - Project Templates
    func createProjectFromTemplate(_ template: ProjectTemplate) -> ProjectModel {
        var project = ProjectModel(
            name: template.name,
            description: template.description,
            estimatedEndDate: Calendar.current.date(byAdding: .day, value: template.estimatedDuration, to: Date())
        )
        
        project.tags = template.tags
        project.color = template.color
        
        return project
    }
}

// MARK: - Project Template
struct ProjectTemplate {
    let name: String
    let description: String
    let estimatedDuration: Int // in days
    let tags: [String]
    let color: String
    let taskTemplates: [TaskTemplate]
    
    static let defaultTemplates: [ProjectTemplate] = [
        ProjectTemplate(
            name: "Mobile App Development",
            description: "Complete mobile application development project",
            estimatedDuration: 90,
            tags: ["Mobile", "Development", "iOS"],
            color: "#3cc45b",
            taskTemplates: [
                TaskTemplate(title: "UI/UX Design", priority: .high),
                TaskTemplate(title: "Backend API Development", priority: .high),
                TaskTemplate(title: "Frontend Implementation", priority: .medium),
                TaskTemplate(title: "Testing & QA", priority: .medium),
                TaskTemplate(title: "App Store Submission", priority: .low)
            ]
        ),
        ProjectTemplate(
            name: "Website Redesign",
            description: "Complete website redesign and development",
            estimatedDuration: 60,
            tags: ["Web", "Design", "Frontend"],
            color: "#fcc418",
            taskTemplates: [
                TaskTemplate(title: "Design Mockups", priority: .high),
                TaskTemplate(title: "Frontend Development", priority: .high),
                TaskTemplate(title: "Content Migration", priority: .medium),
                TaskTemplate(title: "SEO Optimization", priority: .medium),
                TaskTemplate(title: "Launch & Testing", priority: .low)
            ]
        )
    ]
}

struct TaskTemplate {
    let title: String
    let priority: TaskPriority
    let estimatedHours: Double?
    
    init(title: String, priority: TaskPriority, estimatedHours: Double? = nil) {
        self.title = title
        self.priority = priority
        self.estimatedHours = estimatedHours
    }
}


