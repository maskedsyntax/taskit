import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Query private var allTasks: [Task]
    @Query private var projects: [Project]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Stats
                summaryHeader
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 350))], spacing: 24) {
                    // Completion Rate
                    ChartCard(title: "Task Completion") {
                        completionChart
                    }
                    
                    // Tasks by Project
                    ChartCard(title: "Tasks by Project") {
                        projectChart
                    }
                    
                    // Productivity Trend (7 days)
                    ChartCard(title: "Productivity Trend (7 Days)") {
                        trendChart
                    }
                    
                    // Priority Distribution
                    ChartCard(title: "Priority Distribution") {
                        priorityChart
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Dashboard")
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private var summaryHeader: some View {
        HStack(spacing: 20) {
            SummaryStat(title: "Total", value: "\(allTasks.count)", icon: "list.bullet", color: .blue)
            SummaryStat(title: "Completed", value: "\(allTasks.filter { $0.isCompleted }.count)", icon: "checkmark.circle.fill", color: .green)
            SummaryStat(title: "Pending", value: "\(allTasks.filter { !$0.isCompleted }.count)", icon: "circle", color: .orange)
            SummaryStat(title: "Overdue", value: "\(overdueCount)", icon: "exclamationmark.circle.fill", color: .red)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var completionChart: some View {
        let completed = allTasks.filter { $0.isCompleted }.count
        let pending = allTasks.count - completed
        let data = [
            (status: "Completed", count: completed, color: Color.green),
            (status: "Pending", count: pending, color: Color.orange)
        ]
        
        return Chart(data, id: \.status) { item in
            SectorMark(
                angle: .value("Count", item.count),
                innerRadius: .ratio(0.6),
                angularInset: 2
            )
            .foregroundStyle(item.color)
            .annotation(position: .overlay) {
                if item.count > 0 {
                    Text("\(item.count)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
        }
        .frame(height: 200)
    }
    
    private var projectChart: some View {
        Chart(projects) { project in
            BarMark(
                x: .value("Project", project.name),
                y: .value("Tasks", project.tasks?.count ?? 0)
            )
            .foregroundStyle(project.color)
        }
        .frame(height: 200)
    }
    
    private var trendChart: some View {
        let last7Days = (0..<7).reversed().map { dayOffset -> Date in
            Calendar.current.date(byAdding: .day, value: -dayOffset, to: Calendar.current.startOfDay(for: Date()))!
        }
        
        struct DailyCount: Identifiable {
            let id = UUID()
            let date: Date
            let count: Int
        }
        
        let trendData = last7Days.map { date -> DailyCount in
            let count = allTasks.filter { task in
                task.isCompleted && Calendar.current.isDate(task.dueDate ?? Date(), inSameDayAs: date)
            }.count
            return DailyCount(date: date, count: count)
        }
        
        return Chart(trendData) { item in
            AreaMark(
                x: .value("Day", item.date, unit: .day),
                y: .value("Completed", item.count)
            )
            .foregroundStyle(LinearGradient(colors: [.blue.opacity(0.3), .blue.opacity(0)], startPoint: .top, endPoint: .bottom))
            
            LineMark(
                x: .value("Day", item.date, unit: .day),
                y: .value("Completed", item.count)
            )
            .foregroundStyle(.blue)
            .symbol(.circle)
        }
        .frame(height: 200)
    }
    
    private var priorityChart: some View {
        let priorities = [
            (label: "Low", count: allTasks.filter { $0.priority == 1 }.count, color: Color.blue),
            (label: "Medium", count: allTasks.filter { $0.priority == 2 }.count, color: Color.orange),
            (label: "High", count: allTasks.filter { $0.priority == 3 }.count, color: Color.red)
        ]
        
        return Chart(priorities, id: \.label) { item in
            BarMark(
                x: .value("Count", item.count),
                stacking: .normalized
            )
            .foregroundStyle(item.color)
        }
        .frame(height: 50)
        .chartXAxis(.hidden)
    }
    
    private var overdueCount: Int {
        allTasks.filter { task in
            guard let dueDate = task.dueDate, !task.isCompleted else { return false }
            return dueDate < Date()
        }.count
    }
}

struct SummaryStat: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.title)
                .fontWeight(.bold)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct ChartCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            content
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
