//
//  TeamMemberModel.swift
//  TaskVantage Road
//
//  Created by Developer on 1/9/25.
//

import Foundation
import SwiftUI

enum TeamRole: String, CaseIterable, Codable {
    case owner = "Owner"
    case projectManager = "Project Manager"
    case developer = "Developer"
    case designer = "Designer"
    case analyst = "Analyst"
    case tester = "Tester"
    case member = "Member"
    
    var color: Color {
        switch self {
        case .owner:
            return Color.purple
        case .projectManager:
            return Color.blue
        case .developer:
            return Color.green
        case .designer:
            return Color.pink
        case .analyst:
            return Color.orange
        case .tester:
            return Color.red
        case .member:
            return Color.gray
        }
    }
    
    var icon: String {
        switch self {
        case .owner:
            return "crown.fill"
        case .projectManager:
            return "person.badge.key.fill"
        case .developer:
            return "laptopcomputer"
        case .designer:
            return "paintbrush.fill"
        case .analyst:
            return "chart.bar.fill"
        case .tester:
            return "checkmark.seal.fill"
        case .member:
            return "person.fill"
        }
    }
}

struct TeamMemberStats: Codable {
    var tasksAssigned: Int = 0
    var tasksCompleted: Int = 0
    var averageCompletionTime: Double = 0.0
    var productivityScore: Double = 0.0
    var projectsInvolved: Int = 0
    
    var completionRate: Double {
        guard tasksAssigned > 0 else { return 0.0 }
        return Double(tasksCompleted) / Double(tasksAssigned) * 100.0
    }
}

struct TeamMemberModel: Identifiable, Codable {
    let id = UUID()
    var name: String
    var email: String
    var role: TeamRole
    var avatarImageName: String?
    var joinDate: Date
    var isActive: Bool
    var skills: [String]
    var stats: TeamMemberStats
    var notes: String
    var phoneNumber: String?
    var department: String?
    
    init(name: String, email: String, role: TeamRole = .member) {
        self.name = name
        self.email = email
        self.role = role
        self.joinDate = Date()
        self.isActive = true
        self.skills = []
        self.stats = TeamMemberStats()
        self.notes = ""
    }
    
    var initials: String {
        let components = name.components(separatedBy: " ")
        let firstInitial = components.first?.prefix(1).uppercased() ?? ""
        let lastInitial = components.count > 1 ? components.last?.prefix(1).uppercased() ?? "" : ""
        return firstInitial + lastInitial
    }
    
    var displayName: String {
        return name.isEmpty ? email : name
    }
    
    mutating func updateStats(tasks: [TaskModel]) {
        let memberTasks = tasks.filter { $0.assignedToMemberId == self.id }
        stats.tasksAssigned = memberTasks.count
        stats.tasksCompleted = memberTasks.filter { $0.status == .completed }.count
        
        // Calculate average completion time
        let completedTasks = memberTasks.filter { $0.status == .completed && $0.completedDate != nil }
        if !completedTasks.isEmpty {
            let totalTime = completedTasks.compactMap { task in
                guard let completedDate = task.completedDate else { return nil }
                return completedDate.timeIntervalSince(task.createdDate)
            }.reduce(0.0) { $0 + $1 }
            stats.averageCompletionTime = totalTime / Double(completedTasks.count) / 3600 // Convert to hours
        }
        
        // Calculate productivity score (completion rate * quality factor)
        stats.productivityScore = stats.completionRate * 0.8 + (stats.averageCompletionTime > 0 ? min(100, 24 / stats.averageCompletionTime * 20) : 0)
    }
}
