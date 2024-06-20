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
}
