//
//  ShowNotification.swift
//  CoEpi
//
//  Created by Stewart, Allen on 4/18/20.
//  Copyright © 2020 org.coepi. All rights reserved.
//

import Foundation
import UserNotifications
import UIKit
import RxSwift

//ask for notification permissions, called form RootWireFrame.swift at line 28
func notificationPermissions(){
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
        if error == nil {
        }
    }
}

class ShowNotifications{
    
    private let disposeBag = DisposeBag()
    init(CoEpiRepo: CoEpiRepo){
        let reports: Observable<[ReceivedCenReport]>
        reports = CoEpiRepo.reports
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))

        reports.subscribe().disposed(by: disposeBag)
    }
    

    func alertBadge(count:Int){
        // Show number of new alerts.
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            if error == nil {
                DispatchQueue.main.async {
                    UIApplication.shared.applicationIconBadgeNumber = count
                }
            }
        }
    }

    func newAlertNotification(){
         //show notification that new reports found
        let content = UNMutableNotificationContent()
        content.title = "New Contact Alerts"
        content.body = "New contact alerts have been detected. Tap for details."
        content.sound = UNNotificationSound.default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false))
        UNUserNotificationCenter.current().add(request)
    }
    
    
    
    
    
}




