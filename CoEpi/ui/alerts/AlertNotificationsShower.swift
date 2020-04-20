import Foundation
import UserNotifications
import UIKit
import RxSwift
import os.log

class AlertNotificationsShower {
    
    private let disposeBag = DisposeBag()

    // TODO background task / fetch - model flow differently
    // TODO clear badge
    // TODO open alerts screen when click on notification

    init(alertsRepo: AlertRepo) {
        alertsRepo.alerts
            .distinctUntilChanged()
            .pairwise()
            .filter { previous, current in current.count > previous.count }
            .map { previous, current in current }
            .subscribe(onNext: { [weak self] alerts in
                self?.handleNewAlerts(alerts)
            }).disposed(by: disposeBag)
    }

    private func handleNewAlerts(_ alerts: [Alert]) {
        updateAppBadge(number: alerts.count)
        showNewAlertsNotification()
    }

    private func updateAppBadge(number: Int) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            if error == nil {
                DispatchQueue.main.async {
                    os_log("Updating app badge: %@", log: servicesLog, type: .debug, "\(number)")
                    UIApplication.shared.applicationIconBadgeNumber = number
                }
            }
        }
    }

    private func showNewAlertsNotification() {
        os_log("Showing alerts notification", log: servicesLog, type: .debug)

        let content = UNMutableNotificationContent()
        content.title = "New Contact Alerts"
        content.body = "New contact alerts have been detected. Tap for details."
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content,
                                            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false))
        UNUserNotificationCenter.current().add(request)
    }
}
