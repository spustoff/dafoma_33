//
//  ProjectModel.swift
//  TaskVantage Road
//
//  Created by Developer on 1/9/25.
//

import Foundation
import SwiftUI

enum ProjectStatus: String, CaseIterable, Codable {
    case planning = "Planning"
    case active = "Active"
    case onHold = "On Hold"
    case completed = "Completed"
    case cancelled = "Cancelled"
    
    var color: Color {
        switch self {
        case .planning:
            return Color.blue
        case .active:
            return Color.green
        case .onHold:
            return Color.orange
        case .completed:
            return Color.purple
        case .cancelled:
            return Color.red
        }
    }
}

struct ProjectInsight: Codable {
    let id = UUID()
    var title: String
    var description: String
    var category: String // "Performance", "Team", "Timeline", "Quality"
    var impact: String // "High", "Medium", "Low"
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

struct ProjectMetrics: Codable {
    var totalTasks: Int = 0
    var completedTasks: Int = 0
    var overdueTasks: Int = 0
    var averageTaskCompletionTime: Double = 0.0
    var budgetSpent: Double = 0.0
    var timeSpent: Double = 0.0
    var teamProductivityScore: Double = 0.0
    
    var completionPercentage: Double {
        guard totalTasks > 0 else { return 0.0 }
        return Double(completedTasks) / Double(totalTasks) * 100.0
    }
    
    var onTimePerformance: Double {
        guard totalTasks > 0 else { return 100.0 }
        let onTimeTasks = totalTasks - overdueTasks
        return Double(onTimeTasks) / Double(totalTasks) * 100.0
    }
}

struct ProjectModel: Identifiable, Codable {
    let id = UUID()
    var name: String
    var description: String
    var status: ProjectStatus
    var startDate: Date
    var endDate: Date?
    var estimatedEndDate: Date?
    var createdDate: Date
    var ownerId: UUID?
    var teamMemberIds: [UUID]
    var budget: Double?
    var color: String // Hex color for visual identification
    var tags: [String]
    var metrics: ProjectMetrics
    var insights: [ProjectInsight]
    var notes: String
    
    init(name: String, description: String, estimatedEndDate: Date? = nil) {
        self.name = name
        self.description = description
        self.status = .planning
        self.startDate = Date()
        self.estimatedEndDate = estimatedEndDate
        self.createdDate = Date()
        self.teamMemberIds = []
        self.color = "#3cc45b"
        self.tags = []
        self.metrics = ProjectMetrics()
        self.insights = []
        self.notes = ""
    }
    
    var isOverdue: Bool {
        guard let endDate = estimatedEndDate else { return false }
        return endDate < Date() && status != .completed
    }
    
    var daysRemaining: Int {
        guard let endDate = estimatedEndDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
    }
    
    mutating func generateInsights(from tasks: [TaskModel]) {
        insights.removeAll()
        
        // Performance insight
        let completionRate = metrics.completionPercentage
        if completionRate < 50 {
            insights.append(ProjectInsight(
                title: "Low Completion Rate",
                description: "Project completion rate is \(String(format: "%.1f", completionRate))%",
                category: "Performance",
                impact: "High",
                recommendation: "Consider redistributing tasks or extending timeline"
            ))
        }
        
        // Timeline insight
        if isOverdue {
            insights.append(ProjectInsight(
                title: "Project Overdue",
                description: "Project has exceeded its estimated completion date",
                category: "Timeline",
                impact: "High",
                recommendation: "Review timeline and adjust scope or resources"
            ))
        }
        
        // Team productivity insight
        let avgTasksPerMember = Double(metrics.totalTasks) / Double(max(teamMemberIds.count, 1))
        if avgTasksPerMember > 10 {
            insights.append(ProjectInsight(
                title: "High Task Load",
                description: "Average of \(String(format: "%.1f", avgTasksPerMember)) tasks per team member",
                category: "Team",
                impact: "Medium",
                recommendation: "Consider adding more team members or reducing scope"
            ))
        }
    }
}
