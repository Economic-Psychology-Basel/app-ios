import UIKit
import os.log

protocol NotificationShower {
    func showNotification(data: NotificationData)
}

class NotificationShowerImpl: NotificationShower {

    func showNotification(data: NotificationData) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            if error == nil {
                os_log("Showing alerts notification", log: servicesLog, type: .debug)

                let content = UNMutableNotificationContent()
                content.title = data.title
                content.body = data.body 
                content.sound = .default
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false))
                UNUserNotificationCenter.current().add(request)
            }
        }
    }
}

struct NotificationData {
    let title: String
    let body: String
}
