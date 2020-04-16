import Dip
import RxCocoa
import RxSwift
import UserNotifications
import UIKit

class AlertsViewModel {
    private let alertRepo: AlertRepo

    private(set) var title: Driver<String>
    private(set) var alerts: Driver<[Alert]>
    
    init(container: DependencyContainer) {
        self.alertRepo = try! container.resolve()

        title = alertRepo.alerts
            .map { AlertsViewModel.formatTitleLabel(count: $0.count) }
            .startWith(AlertsViewModel.formatTitleLabel(count: 0))
            .asDriver(onErrorJustReturn: "Alerts")

        alerts = alertRepo.alerts.asDriver(onErrorJustReturn: [])
    }

    private static func formatTitleLabel(count: Int) -> String {
        let title: String = "\(count) new contact alert"
        
        // Show number of new alerts. This is functional, but has an issue. It only updates when the alert view is loaded. This is likely the wrong place for this, but it demonstrates the functionality. A space for this is called out in CoepiRepo.swift
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            if error == nil {
                DispatchQueue.main.async {
                    UIApplication.shared.applicationIconBadgeNumber = count
                }
            }
        }
        
        if count < 2 {
            return title
        }
        return title + "s"
    }

    public func acknowledge(alert: Alert) {
        alertRepo.removeAlert(alert: alert)
    }
}
