//
//  TeamViewModel.swift
//  TaskVantage Road
//
//  Created by Developer on 1/9/25.
//

import Foundation
import Combine
import SwiftUI

class TeamViewModel: ObservableObject {
    @Published var teamMembers: [TeamMemberModel] = []
    @Published var filteredMembers: [TeamMemberModel] = []
    @Published var searchText: String = ""
    @Published var selectedRole: TeamRole?
    @Published var showInactiveMembers: Bool = false
    @Published var sortOption: TeamSortOption = .name
    @Published var selectedMember: TeamMemberModel?
    
    private var cancellables = Set<AnyCancellable>()
    private let dataService = DataService.shared
    
    enum TeamSortOption: String, CaseIterable {
        case name = "Name"
        case role = "Role"
        case joinDate = "Join Date"
        case productivity = "Productivity"
        case tasksCompleted = "Tasks Completed"
    }
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        // Bind to DataService team members
        dataService.$teamMembers
            .receive(on: DispatchQueue.main)
            .sink { [weak self] members in
                self?.teamMembers = members
                self?.applyFiltersAndSort()
            }
            .store(in: &cancellables)
        
        // Update filtered members when search or filter criteria change
        Publishers.CombineLatest3($searchText, $selectedRole, $showInactiveMembers)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _, _, _ in
                self?.applyFiltersAndSort()
            }
            .store(in: &cancellables)
        
        $sortOption
            .sink { [weak self] _ in
                self?.applyFiltersAndSort()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Team Member Management
    func addTeamMember(_ member: TeamMemberModel) {
        dataService.addTeamMember(member)
    }
    
    func updateTeamMember(_ member: TeamMemberModel) {
        dataService.updateTeamMember(member)
    }
    
    func deleteTeamMember(_ member: TeamMemberModel) {
        dataService.deleteTeamMember(member)
    }
    
    func toggleMemberActiveStatus(_ member: TeamMemberModel) {
        var updatedMember = member
        updatedMember.isActive.toggle()
        updateTeamMember(updatedMember)
    }
    
    func updateMemberRole(_ member: TeamMemberModel, role: TeamRole) {
        var updatedMember = member
        updatedMember.role = role
        updateTeamMember(updatedMember)
    }
    
    func addSkillToMember(_ member: TeamMemberModel, skill: String) {
        var updatedMember = member
        if !updatedMember.skills.contains(skill) {
            updatedMember.skills.append(skill)
            updateTeamMember(updatedMember)
        }
    }
    
    func removeSkillFromMember(_ member: TeamMemberModel, skill: String) {
        var updatedMember = member
        updatedMember.skills.removeAll { $0 == skill }
        updateTeamMember(updatedMember)
    }
    
    // MARK: - Filtering and Sorting
    private func applyFiltersAndSort() {
        var filtered = teamMembers
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { member in
                member.name.localizedCaseInsensitiveContains(searchText) ||
                member.email.localizedCaseInsensitiveContains(searchText) ||
                member.skills.contains { $0.localizedCaseInsensitiveContains(searchText) } ||
                (member.department?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Apply role filter
        if let role = selectedRole {
            filtered = filtered.filter { $0.role == role }
        }
        
        // Apply active status filter
        if !showInactiveMembers {
            filtered = filtered.filter { $0.isActive }
        }
        
        // Apply sorting
        filtered = sortMembers(filtered)
        
        filteredMembers = filtered
    }
    
    private func sortMembers(_ members: [TeamMemberModel]) -> [TeamMemberModel] {
        switch sortOption {
        case .name:
            return members.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .role:
            return members.sorted { member1, member2 in
                let role1 = roleValue(member1.role)
                let role2 = roleValue(member2.role)
                return role1 < role2
            }
        case .joinDate:
            return members.sorted { $0.joinDate < $1.joinDate }
        case .productivity:
            return members.sorted { $0.stats.productivityScore > $1.stats.productivityScore }
        case .tasksCompleted:
            return members.sorted { $0.stats.tasksCompleted > $1.stats.tasksCompleted }
        }
    }
    
    private func roleValue(_ role: TeamRole) -> Int {
        switch role {
        case .owner: return 1
        case .projectManager: return 2
        case .developer: return 3
        case .designer: return 4
        case .analyst: return 5
        case .tester: return 6
        case .member: return 7
        }
    }
    
    // MARK: - Team Analytics
    func getMemberTasks(_ member: TeamMemberModel) -> [TaskModel] {
        return dataService.getTasksForMember(member.id)
    }
    
    func getMemberProjects(_ member: TeamMemberModel) -> [ProjectModel] {
        return dataService.projects.filter { $0.teamMemberIds.contains(member.id) }
    }
    
    func getActiveMembersCount() -> Int {
        return teamMembers.filter { $0.isActive }.count
    }
    
    func getMembersWithRole(_ role: TeamRole) -> [TeamMemberModel] {
        return teamMembers.filter { $0.role == role }
    }
    
    func getTopPerformers(limit: Int = 5) -> [TeamMemberModel] {
        return teamMembers
            .filter { $0.isActive }
            .sorted { $0.stats.productivityScore > $1.stats.productivityScore }
            .prefix(limit)
            .map { $0 }
    }
    
    func getMembersNeedingAttention() -> [TeamMemberModel] {
        return teamMembers.filter { member in
            member.isActive &&
            (member.stats.completionRate < 70 ||
             member.stats.tasksAssigned > 10 ||
             member.stats.productivityScore < 50)
        }
    }
    
    // MARK: - Statistics
    var totalMembers: Int {
        return teamMembers.count
    }
    
    var activeMembers: Int {
        return getActiveMembersCount()
    }
    
    var averageProductivityScore: Double {
        let activeMembers = teamMembers.filter { $0.isActive }
        guard !activeMembers.isEmpty else { return 0.0 }
        
        let totalScore = activeMembers.map { $0.stats.productivityScore }.reduce(0, +)
        return totalScore / Double(activeMembers.count)
    }
    
    var averageCompletionRate: Double {
        let activeMembers = teamMembers.filter { $0.isActive }
        guard !activeMembers.isEmpty else { return 0.0 }
        
        let totalRate = activeMembers.map { $0.stats.completionRate }.reduce(0, +)
        return totalRate / Double(activeMembers.count)
    }
    
    var totalTasksCompleted: Int {
        return teamMembers.map { $0.stats.tasksCompleted }.reduce(0, +)
    }
    
    var totalTasksAssigned: Int {
        return teamMembers.map { $0.stats.tasksAssigned }.reduce(0, +)
    }
    
    // MARK: - Team Insights
    func generateTeamInsights() -> [TeamInsight] {
        var insights: [TeamInsight] = []
        
        // Productivity insights
        let lowPerformers = teamMembers.filter { $0.stats.productivityScore < 50 && $0.isActive }
        if !lowPerformers.isEmpty {
            insights.append(TeamInsight(
                title: "Low Productivity Alert",
                description: "\(lowPerformers.count) team members have productivity scores below 50%",
                category: "Performance",
                impact: "Medium",
                recommendation: "Consider one-on-one meetings to identify blockers and provide support"
            ))
        }
        
        // Workload insights
        let overloadedMembers = teamMembers.filter { $0.stats.tasksAssigned > 15 && $0.isActive }
        if !overloadedMembers.isEmpty {
            insights.append(TeamInsight(
                title: "Workload Imbalance",
                description: "\(overloadedMembers.count) team members have more than 15 assigned tasks",
                category: "Workload",
                impact: "High",
                recommendation: "Redistribute tasks or consider hiring additional team members"
            ))
        }
        
        // Skills diversity insights
        let allSkills = Set(teamMembers.flatMap { $0.skills })
        let skillCoverage = Double(allSkills.count) / Double(max(teamMembers.count, 1))
        if skillCoverage < 2.0 {
            insights.append(TeamInsight(
                title: "Limited Skill Diversity",
                description: "Team has limited skill diversity with \(String(format: "%.1f", skillCoverage)) skills per member",
                category: "Skills",
                impact: "Medium",
                recommendation: "Consider cross-training or hiring members with complementary skills"
            ))
        }
        
        // Team size insights
        if teamMembers.count < 3 {
            insights.append(TeamInsight(
                title: "Small Team Size",
                description: "Team has only \(teamMembers.count) members",
                category: "Team",
                impact: "Low",
                recommendation: "Consider expanding the team for better project coverage"
            ))
        }
        
        return insights
    }
    
    // MARK: - Team Communication
    func getMembersByProject(_ project: ProjectModel) -> [TeamMemberModel] {
        return teamMembers.filter { project.teamMemberIds.contains($0.id) }
    }
    
    func getAvailableMembers() -> [TeamMemberModel] {
        return teamMembers.filter { member in
            member.isActive && member.stats.tasksAssigned < 10
        }
    }
    
    func suggestMemberForTask(_ task: TaskModel) -> TeamMemberModel? {
        let availableMembers = getAvailableMembers()
        
        // Try to find member with relevant skills
        for member in availableMembers {
            if member.skills.contains(where: { skill in
                task.title.localizedCaseInsensitiveContains(skill) ||
                task.description.localizedCaseInsensitiveContains(skill)
            }) {
                return member
            }
        }
        
        // Return member with lowest workload
        return availableMembers.min(by: { $0.stats.tasksAssigned < $1.stats.tasksAssigned })
    }
}

// MARK: - Team Insight Model
struct TeamInsight {
    let id = UUID()
    var title: String
    var description: String
    var category: String
    var impact: String
    var recommendation: String
    var dateGenerated: Date
    
    init(title: String, description: String, category: String, impact: String, recommendation: String) {
        self.title = title
        self.description = description
        self.category = category
        self.impact = impact
        self.recommendation = recommendation
        self.dateGenerated = Date()
    }
}
