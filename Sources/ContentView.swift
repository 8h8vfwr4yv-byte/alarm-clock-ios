import SwiftUI
import UserNotifications

// 闹钟：到点用本地通知响铃（App 在后台也能响）。闹钟列表存在本机。
struct Alarm: Identifiable, Codable, Equatable {
    var id = UUID()
    var hour: Int
    var minute: Int
    var label: String = "闹钟"
    var repeatsDaily: Bool = true
    var enabled: Bool = true

    var timeText: String { String(format: "%02d:%02d", hour, minute) }
    var date: Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }
}

final class AlarmStore: ObservableObject {
    @Published var alarms: [Alarm] = [] {
        didSet { save() }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: "alarms"),
           let decoded = try? JSONDecoder().decode([Alarm].self, from: data) {
            alarms = decoded
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(alarms) {
            UserDefaults.standard.set(data, forKey: "alarms")
        }
    }

    func schedule(_ alarm: Alarm) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [alarm.id.uuidString])
        guard alarm.enabled else { return }
        let content = UNMutableNotificationContent()
        content.title = "⏰ " + (alarm.label.isEmpty ? "闹钟" : alarm.label)
        content.body = "时间到了"
        content.sound = .default
        var comps = DateComponents()
        comps.hour = alarm.hour
        comps.minute = alarm.minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: alarm.repeatsDaily)
        let request = UNNotificationRequest(identifier: alarm.id.uuidString, content: content, trigger: trigger)
        center.add(request)
    }

    func cancel(_ alarm: Alarm) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [alarm.id.uuidString])
    }

    func rescheduleAll() {
        for alarm in alarms { schedule(alarm) }
    }
}

struct ContentView: View {
    @StateObject private var store = AlarmStore()
    @State private var showingAdd = false
    @State private var newTime = Date()
    @State private var newLabel = ""
    @State private var newRepeat = true

    var body: some View {
        NavigationStack {
            Group {
                if store.alarms.isEmpty {
                    VStack(spacing: 10) {
                        Text("⏰").font(.system(size: 56))
                        Text("还没有闹钟").font(.headline)
                        Text("点右上角 + 添加一个").foregroundStyle(.secondary)
                    }
                } else {
                    List {
                        ForEach($store.alarms) { $alarm in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(alarm.timeText)
                                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                                    Text(subtitle(alarm))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Toggle("", isOn: $alarm.enabled)
                                    .labelsHidden()
                                    .onChange(of: alarm.enabled) { _ in store.schedule(alarm) }
                            }
                            .opacity(alarm.enabled ? 1 : 0.45)
                            .padding(.vertical, 4)
                        }
                        .onDelete { indexSet in
                            for i in indexSet { store.cancel(store.alarms[i]) }
                            store.alarms.remove(atOffsets: indexSet)
                        }
                    }
                }
            }
            .navigationTitle("闹钟")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingAdd) {
                NavigationStack {
                    Form {
                        DatePicker("时间", selection: $newTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                        TextField("标签（可不填）", text: $newLabel)
                        Toggle("每天重复", isOn: $newRepeat)
                    }
                    .navigationTitle("添加闹钟")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("取消") { showingAdd = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("保存") { addAlarm() }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
            .onAppear {
                UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
                store.rescheduleAll()
            }
        }
    }

    private func subtitle(_ alarm: Alarm) -> String {
        let label = alarm.label.isEmpty ? "闹钟" : alarm.label
        return label + " · " + (alarm.repeatsDaily ? "每天" : "仅一次")
    }

    private func addAlarm() {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: newTime)
        let alarm = Alarm(hour: comps.hour ?? 7, minute: comps.minute ?? 0,
                          label: newLabel.trimmingCharacters(in: .whitespaces),
                          repeatsDaily: newRepeat, enabled: true)
        store.alarms.append(alarm)
        store.alarms.sort { ($0.hour, $0.minute) < ($1.hour, $1.minute) }
        store.schedule(alarm)
        newLabel = ""
        showingAdd = false
    }
}
