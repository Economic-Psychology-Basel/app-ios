import Foundation
import UserNotifications
import os.log
import UIKit

protocol AppBadgeUpdater {
    func updateAppBadge(number: Int)
}

class AppBadgeUpdaterImpl: AppBadgeUpdater {

    func updateAppBadge(number: Int) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            if error == nil {
                DispatchQueue.main.async {
                    os_log("Updating app badge: %@", log: servicesLog, type: .debug, "\(number)")
                    UIApplication.shared.applicationIconBadgeNumber = number
                }
            }
        }
    }
}
