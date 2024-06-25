import Cocoa
import FlutterMacOS
import EventKit

public class RemindersPlugin: NSObject, FlutterPlugin {
    let eventStore: EKEventStore = EKEventStore()
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "reminders_plugin", binaryMessenger: registrar.messenger)
    let instance = RemindersPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      switch call.method {
      case "getPlatformVersion":
          result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
      case "hasAccess":
          result(hasAccess())
      case "requestAccess": requestAccess(result)
      case "getDefaultList": result(getDefaultList())
      case "getReminderLists": result(getReminderLists())
          
      case "getReminders":
          if let args = call.arguments as? [String: String?] {
              if let id = args["id"] {
                  getReminders(id!, result)
              }
          }
          
      case "addReminder":
          if let args = call.arguments as? [String: Any?] {
              result(addReminder(args))
          }
          
      case "deleteReminder":
          if let args = call.arguments as? [String: Any?] {
              if let id = args["id"] as? String {
                  deleteReminder(id)
              }
          }
        
    default:
      result(FlutterMethodNotImplemented)
    }
  }
    
    // Check with access to reminders has been authorized. Using MacOS 10.x settings
    func hasAccess() -> Bool {
        return EKEventStore.authorizationStatus(for: .reminder) == .authorized
    }
    
    func requestAccess(_ result: @escaping FlutterResult) {
        if hasAccess() { result(true) }
        eventStore.requestAccess(to: .reminder) { (success: Bool, error: (any Error)? ) in
            if let error = error { print (error) }
            result(success)
        }
    }
    
    func getDefaultList() -> [String: String]? {
        let defaultList: EKCalendar? = self.eventStore.defaultCalendarForNewReminders()
        guard let defaultList = defaultList else { return nil }
        return [
            "id": defaultList.calendarIdentifier,
            "title": defaultList.title
        ]
    }
    
    func getReminderLists() -> [[String: String]]? {
        let lists: [EKCalendar] = eventStore.calendars(for: .reminder)
        return lists.map{ [
            "id": $0.calendarIdentifier,
            "title": $0.title
        ] }
    }
    
    func getReminders(_ id: String, _ result: @escaping FlutterResult) {
        let calendar = [eventStore.calendar(withIdentifier: id) ?? EKCalendar()]
        let predicate: NSPredicate? = eventStore.predicateForReminders(in: calendar)
        
        guard let predicate = predicate else { result([]); return }
        
        eventStore.fetchReminders(matching: predicate) { (_ reminders: [EKReminder]?) -> Void in
            guard let reminders = reminders else { result([]); return}

            let map: [[String: String]] = reminders.map {[
                "list": id,
                "id": $0.calendarItemIdentifier,
                "title": $0.title ?? "Private",
                "dueDate": $0.dueDateComponents?.description ?? "",
                "priority": $0.priority.description,
                "isCompleted": $0.isCompleted.description,
                "notes": $0.notes ?? "",
                "url": $0.url ?? ""
            ]} as! [[String : String]]
            result(map)
        }
    }
    
    func addReminder(_ rem: [String: Any?]) -> [String: String] {
        guard rem["list"] != nil,
              let calendarID: String = rem["list"] as? String,
              let list: EKCalendar = eventStore.calendar(withIdentifier: calendarID) else { return ["error": "Invalid list"] }
        
        let reminder: EKReminder = EKReminder(eventStore: eventStore)
        
        reminder.calendar = list
        reminder.title = rem["title"] as? String
        reminder.priority = rem["priority"] as? Int ?? 0
        reminder.isCompleted = rem["isCompleted"] as? Bool ?? false
        reminder.notes = rem["notes"] as? String
        if let date: [String: Int?] = rem["dueDate"] as? [String: Int?] {
            reminder.dueDateComponents = DateComponents(year: date["year"]!!, month: date["month"]!!, day: date["day"]!!, hour: date["hour"] ?? nil, minute: date["minute"] ?? nil, second: date["second"] ?? nil)
        } else {
            reminder.dueDateComponents = nil
        }
        
        do {
            try eventStore.save(reminder, commit: true)
            print(reminder)
        } catch let error {
            return ["error": error.localizedDescription]
        }
        
        return ["success": reminder.calendarItemIdentifier]
    }
    
    func deleteReminder(_ id: String?) {
        guard
              let reminderId = id,
              let oiginal: EKReminder = eventStore.calendarItem(withIdentifier: reminderId) as? EKReminder else { return }
        
        do {
            try eventStore.remove(oiginal, commit: true)
        } catch {
            print("Error deleting event \(oiginal)")
            print(error.localizedDescription)
        }
    }
}
