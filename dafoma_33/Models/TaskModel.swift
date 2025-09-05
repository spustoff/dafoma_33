//
//  TaskModel.swift
//  TaskVantage Road
//
//  Created by Developer on 1/9/25.
//

import Foundation
import SwiftUI

enum TaskPriority: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    
    var color: Color {
        switch self {
        case .low:
            return Color.green
        case .medium:
            return Color.yellow
        case .high:
            return Color.orange
        case .critical:
            return Color.red
        }
    }
}

enum TaskStatus: String, CaseIterable, Codable {
    case todo = "To Do"
    case inProgress = "In Progress"
    case completed = "Completed"
    case onHold = "On Hold"
}

struct TaskModel: Identifiable, Codable, Hashable {
    let id = UUID()
    var title: String
    var description: String
    var priority: TaskPriority
    var status: TaskStatus
    var dueDate: Date?
    var createdDate: Date
    var completedDate: Date?
    var projectId: UUID?
    var assignedToMemberId: UUID?
    var tags: [String]
    var attachments: [String] // File paths or URLs
    var estimatedHours: Double?
    var actualHours: Double?
    var notes: String
    
    init(title: String, description: String, priority: TaskPriority = .medium, projectId: UUID? = nil) {
        self.title = title
        self.description = description
        self.priority = priority
        self.status = .todo
        self.createdDate = Date()
        self.projectId = projectId
        self.tags = []
        self.attachments = []
        self.notes = ""
    }
    
    var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return dueDate < Date() && status != .completed
    }
    
    var progressPercentage: Double {
        switch status {
        case .todo:
            return 0.0
        case .inProgress:
            return 0.5
        case .completed:
            return 1.0
        case .onHold:
            return 0.25
        }
    }
}


