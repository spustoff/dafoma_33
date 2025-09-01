//
//  TeamManagementView.swift
//  TaskVantage Road
//
//  Created by Developer on 1/9/25.
//

import SwiftUI

struct TeamManagementView: View {
    @StateObject private var teamViewModel = TeamViewModel()
    @State private var showingAddMember = false
    @State private var showingFilters = false
    @State private var selectedMember: TeamMemberModel?
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColorScheme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with search and actions
                    TeamHeaderView(
                        teamViewModel: teamViewModel,
                        showingFilters: $showingFilters,
                        showingAddMember: $showingAddMember
                    )
                    
                    // Team stats
                    TeamStatsView(teamViewModel: teamViewModel)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                    
                    // Team members list
                    if teamViewModel.filteredMembers.isEmpty {
                        TeamEmptyStateView(
                            hasFilters: !teamViewModel.searchText.isEmpty ||
                            teamViewModel.selectedRole != nil ||
                            !teamViewModel.showInactiveMembers
                        )
                    } else {
                        TeamMembersListView(
                            members: teamViewModel.filteredMembers,
                            onMemberTap: { member in
                                selectedMember = member
                            }
                        )
                    }
                }
            }
            .navigationTitle("Team")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAddMember) {
                AddTeamMemberView()
            }
            .sheet(isPresented: $showingFilters) {
                TeamFiltersView(teamViewModel: teamViewModel)
            }
            .sheet(item: Binding<TeamMemberModel?>(
                get: { selectedMember },
                set: { _ in selectedMember = nil }
            )) { member in
                TeamMemberDetailView(member: member)
            }
        }
    }
}

struct TeamHeaderView: View {
    @ObservedObject var teamViewModel: TeamViewModel
    @Binding var showingFilters: Bool
    @Binding var showingAddMember: Bool
    
    var body: some View {
        VStack(spacing: 15) {
            // Search bar
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColorScheme.textSecondary)
                    
                    TextField("Search team members...", text: $teamViewModel.searchText)
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
                // Add member button
                Button(action: { showingAddMember = true }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Add Member")
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
                    ForEach(TeamViewModel.TeamSortOption.allCases, id: \.self) { option in
                        Button(option.rawValue) {
                            teamViewModel.sortOption = option
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
        teamViewModel.selectedRole != nil || !teamViewModel.showInactiveMembers
    }
}

struct TeamStatsView: View {
    @ObservedObject var teamViewModel: TeamViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            TeamStatCardView(
                title: "Total",
                value: "\(teamViewModel.totalMembers)",
                color: AppColorScheme.info
            )
            
            TeamStatCardView(
                title: "Active",
                value: "\(teamViewModel.activeMembers)",
                color: AppColorScheme.success
            )
            
            TeamStatCardView(
                title: "Avg Score",
                value: "\(Int(teamViewModel.averageProductivityScore))",
                color: AppColorScheme.primaryAction
            )
            
            TeamStatCardView(
                title: "Completed",
                value: "\(teamViewModel.totalTasksCompleted)",
                color: AppColorScheme.secondaryAction
            )
        }
    }
}

struct TeamStatCardView: View {
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

struct TeamMembersListView: View {
    let members: [TeamMemberModel]
    let onMemberTap: (TeamMemberModel) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(members, id: \.id) { member in
                    TeamMemberRowView(member: member) {
                        onMemberTap(member)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
    }
}

struct TeamMemberRowView: View {
    let member: TeamMemberModel
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 15) {
                // Avatar
                Circle()
                    .fill(AppColorScheme.cardBackground)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(member.initials)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColorScheme.textPrimary)
                    )
                    .overlay(
                        Circle()
                            .stroke(member.isActive ? AppColorScheme.success : AppColorScheme.textTertiary, lineWidth: 3)
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    // Name and role
                    HStack {
                        Text(member.name)
                            .font(.headline)
                            .foregroundColor(AppColorScheme.textPrimary)
                        
                        Spacer()
                        
                        if !member.isActive {
                            Text("Inactive")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(AppColorScheme.textTertiary.opacity(0.2))
                                )
                                .foregroundColor(AppColorScheme.textTertiary)
                        }
                    }
                    
                    HStack {
                        Image(systemName: member.role.icon)
                            .foregroundColor(member.role.color)
                            .font(.subheadline)
                        
                        Text(member.role.rawValue)
                            .font(.subheadline)
                            .foregroundColor(AppColorScheme.textSecondary)
                    }
                    
                    // Stats
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Text("\(member.stats.tasksCompleted)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColorScheme.success)
                            Text("completed")
                                .font(.caption)
                                .foregroundColor(AppColorScheme.textTertiary)
                        }
                        
                        HStack(spacing: 4) {
                            Text("\(member.stats.tasksAssigned)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColorScheme.info)
                            Text("assigned")
                                .font(.caption)
                                .foregroundColor(AppColorScheme.textTertiary)
                        }
                        
                        HStack(spacing: 4) {
                            Text("\(Int(member.stats.productivityScore))")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColorScheme.primaryAction)
                            Text("score")
                                .font(.caption)
                                .foregroundColor(AppColorScheme.textTertiary)
                        }
                    }
                    
                    // Skills
                    if !member.skills.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(Array(member.skills.prefix(3)), id: \.self) { skill in
                                    Text(skill)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(AppColorScheme.secondaryAction.opacity(0.2))
                                        )
                                        .foregroundColor(AppColorScheme.secondaryAction)
                                }
                                
                                if member.skills.count > 3 {
                                    Text("+\(member.skills.count - 3)")
                                        .font(.caption)
                                        .foregroundColor(AppColorScheme.textTertiary)
                                }
                            }
                        }
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
}

struct TeamEmptyStateView: View {
    let hasFilters: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: hasFilters ? "person.2.slash" : "person.3")
                .font(.system(size: 60, weight: .light))
                .foregroundColor(AppColorScheme.textTertiary)
            
            VStack(spacing: 8) {
                Text(hasFilters ? "No Team Members Match Filters" : "No Team Members Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColorScheme.textPrimary)
                
                Text(hasFilters ? "Try adjusting your search or filter criteria" : "Add your first team member to get started")
                    .font(.body)
                    .foregroundColor(AppColorScheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if !hasFilters {
                Button("Add Your First Team Member") {
                    // This would trigger the add member sheet
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

// MARK: - Add Team Member View
struct AddTeamMemberView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var teamViewModel = TeamViewModel()
    @State private var name = ""
    @State private var email = ""
    @State private var role = TeamRole.member
    @State private var department = ""
    @State private var phoneNumber = ""
    @State private var skills = ""
    @State private var notes = ""
    @State private var showingRolePicker = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColorScheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Basic info
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.headline)
                                .foregroundColor(AppColorScheme.textPrimary)
                            
                            TextField("Enter full name", text: $name)
                                .textFieldStyle(NeumorphicTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.headline)
                                .foregroundColor(AppColorScheme.textPrimary)
                            
                            TextField("Enter email address", text: $email)
                                .textFieldStyle(NeumorphicTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        
                        // Role selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Role")
                                .font(.headline)
                                .foregroundColor(AppColorScheme.textPrimary)
                            
                            Button(action: { showingRolePicker = true }) {
                                HStack {
                                    Image(systemName: role.icon)
                                        .foregroundColor(role.color)
                                    
                                    Text(role.rawValue)
                                        .foregroundColor(AppColorScheme.textPrimary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(AppColorScheme.textSecondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                            .neumorphicStyle()
                        }
                        
                        // Optional fields
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Department (Optional)")
                                .font(.headline)
                                .foregroundColor(AppColorScheme.textPrimary)
                            
                            TextField("Enter department", text: $department)
                                .textFieldStyle(NeumorphicTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Phone Number (Optional)")
                                .font(.headline)
                                .foregroundColor(AppColorScheme.textPrimary)
                            
                            TextField("Enter phone number", text: $phoneNumber)
                                .textFieldStyle(NeumorphicTextFieldStyle())
                                .keyboardType(.phonePad)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Skills (Optional)")
                                .font(.headline)
                                .foregroundColor(AppColorScheme.textPrimary)
                            
                            TextField("Enter skills separated by commas", text: $skills)
                                .textFieldStyle(NeumorphicTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes (Optional)")
                                .font(.headline)
                                .foregroundColor(AppColorScheme.textPrimary)
                            
                            TextField("Enter additional notes", text: $notes)
                                .textFieldStyle(NeumorphicTextFieldStyle())
                        }
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("New Team Member")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(AppColorScheme.textSecondary),
                trailing: Button("Save") {
                    saveTeamMember()
                }
                .foregroundColor(canSave ? AppColorScheme.primaryAction : AppColorScheme.textTertiary)
                .disabled(!canSave)
            )
            .sheet(isPresented: $showingRolePicker) {
                RolePickerView(selectedRole: Binding(
                    get: { role },
                    set: { role = $0 }
                ))
            }
        }
    }
    
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func saveTeamMember() {
        var member = TeamMemberModel(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            role: role
        )
        
        if !department.isEmpty {
            member.department = department.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        if !phoneNumber.isEmpty {
            member.phoneNumber = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        if !skills.isEmpty {
            member.skills = skills.components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        
        if !notes.isEmpty {
            member.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        teamViewModel.addTeamMember(member)
        dismiss()
    }
}

// MARK: - Team Filters View
struct TeamFiltersView: View {
    @ObservedObject var teamViewModel: TeamViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColorScheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Role filter
                        FilterSectionView(title: "Role") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    FilterChip(
                                        title: "All",
                                        isSelected: teamViewModel.selectedRole == nil
                                    ) {
                                        teamViewModel.selectedRole = nil
                                    }
                                    
                                    ForEach(TeamRole.allCases, id: \.self) { role in
                                        FilterChip(
                                            title: role.rawValue,
                                            isSelected: teamViewModel.selectedRole == role,
                                            color: role.color
                                        ) {
                                            teamViewModel.selectedRole = role
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // Show inactive members toggle
                        FilterSectionView(title: "Display Options") {
                            HStack {
                                Text("Show Inactive Members")
                                    .font(.body)
                                    .foregroundColor(AppColorScheme.textPrimary)
                                
                                Spacer()
                                
                                NeumorphicToggle(isOn: $teamViewModel.showInactiveMembers)
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
                    teamViewModel.selectedRole = nil
                    teamViewModel.showInactiveMembers = false
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

// MARK: - Team Member Detail View
struct TeamMemberDetailView: View {
    let member: TeamMemberModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var taskViewModel = TaskViewModel()
    
    private var memberTasks: [TaskModel] {
        taskViewModel.tasks.filter { $0.assignedToMemberId == member.id }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColorScheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Member header
                        TeamMemberHeaderView(member: member)
                        
                        // Stats overview
                        TeamMemberStatsView(member: member)
                        
                        // Recent tasks
                        if !memberTasks.isEmpty {
                            TeamMemberTasksView(tasks: Array(memberTasks.prefix(5)))
                        }
                        
                        // Skills
                        if !member.skills.isEmpty {
                            TeamMemberSkillsView(skills: member.skills)
                        }
                        
                        // Contact info
                        TeamMemberContactView(member: member)
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Team Member")
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

struct TeamMemberHeaderView: View {
    let member: TeamMemberModel
    
    var body: some View {
        VStack(spacing: 15) {
            // Avatar and basic info
            HStack(spacing: 20) {
                Circle()
                    .fill(AppColorScheme.cardBackground)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text(member.initials)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(AppColorScheme.textPrimary)
                    )
                    .overlay(
                        Circle()
                            .stroke(member.isActive ? AppColorScheme.success : AppColorScheme.textTertiary, lineWidth: 4)
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(member.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppColorScheme.textPrimary)
                    
                    HStack {
                        Image(systemName: member.role.icon)
                            .foregroundColor(member.role.color)
                        
                        Text(member.role.rawValue)
                            .font(.headline)
                            .foregroundColor(AppColorScheme.textSecondary)
                    }
                    
                    Text(member.email)
                        .font(.subheadline)
                        .foregroundColor(AppColorScheme.textTertiary)
                    
                    if !member.isActive {
                        Text("Inactive")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(AppColorScheme.textTertiary.opacity(0.2))
                            )
                            .foregroundColor(AppColorScheme.textTertiary)
                    }
                }
                
                Spacer()
            }
        }
        .padding(20)
        .neumorphicCard()
    }
}

struct TeamMemberStatsView: View {
    let member: TeamMemberModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Performance Stats")
                .font(.headline)
                .foregroundColor(AppColorScheme.textPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatItemView(
                    title: "Tasks Completed",
                    value: "\(member.stats.tasksCompleted)",
                    color: AppColorScheme.success
                )
                
                StatItemView(
                    title: "Tasks Assigned",
                    value: "\(member.stats.tasksAssigned)",
                    color: AppColorScheme.info
                )
                
                StatItemView(
                    title: "Completion Rate",
                    value: "\(Int(member.stats.completionRate))%",
                    color: member.stats.completionRate > 80 ? AppColorScheme.success : AppColorScheme.warning
                )
                
                StatItemView(
                    title: "Productivity Score",
                    value: "\(Int(member.stats.productivityScore))",
                    color: AppColorScheme.primaryAction
                )
            }
        }
        .padding(20)
        .neumorphicCard()
    }
}

struct StatItemView: View {
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

struct TeamMemberTasksView: View {
    let tasks: [TaskModel]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Tasks")
                    .font(.headline)
                    .foregroundColor(AppColorScheme.textPrimary)
                
                Spacer()
                
                Text("\(tasks.count) tasks")
                    .font(.subheadline)
                    .foregroundColor(AppColorScheme.textSecondary)
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

struct TeamMemberSkillsView: View {
    let skills: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Skills")
                .font(.headline)
                .foregroundColor(AppColorScheme.textPrimary)
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 100))
            ], spacing: 8) {
                ForEach(skills, id: \.self) { skill in
                    Text(skill)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppColorScheme.secondaryAction.opacity(0.2))
                        )
                        .foregroundColor(AppColorScheme.secondaryAction)
                }
            }
        }
        .padding(20)
        .neumorphicCard()
    }
}

struct TeamMemberContactView: View {
    let member: TeamMemberModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Contact Information")
                .font(.headline)
                .foregroundColor(AppColorScheme.textPrimary)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "envelope")
                        .foregroundColor(AppColorScheme.textSecondary)
                        .frame(width: 20)
                    
                    Text(member.email)
                        .foregroundColor(AppColorScheme.textPrimary)
                }
                
                if let phone = member.phoneNumber, !phone.isEmpty {
                    HStack {
                        Image(systemName: "phone")
                            .foregroundColor(AppColorScheme.textSecondary)
                            .frame(width: 20)
                        
                        Text(phone)
                            .foregroundColor(AppColorScheme.textPrimary)
                    }
                }
                
                if let department = member.department, !department.isEmpty {
                    HStack {
                        Image(systemName: "building.2")
                            .foregroundColor(AppColorScheme.textSecondary)
                            .frame(width: 20)
                        
                        Text(department)
                            .foregroundColor(AppColorScheme.textPrimary)
                    }
                }
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(AppColorScheme.textSecondary)
                        .frame(width: 20)
                    
                    Text("Joined \(member.joinDate, style: .date)")
                        .foregroundColor(AppColorScheme.textPrimary)
                }
            }
        }
        .padding(20)
        .neumorphicCard()
    }
}

#Preview {
    TeamManagementView()
}
