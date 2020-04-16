import Foundation
import RxSwift
import os.log
import UserNotifications

// NOTE: This is interace for possible Rust shared library
// Reports storage unclear, most likely shared lib forwards api call result, we cache in Realm
// For now the caching happens _in_ CoEpiRepo

protocol CoEpiRepo {
    // Infection reports fetched periodically from the API
    var reports: Observable<[ReceivedCenReport]> { get }

    // Store CEN from other device
    func storeObservedCen(cen: CEN)

    // Send symptoms report
    func sendReport(report: CenReport) -> Completable
}

class CoEpiRepoImpl: CoEpiRepo {
    private let cenRepo: CENRepo
    private let api: CoEpiApi
    private let cenMatcher: CenMatcher
    private let cenKeyDao: CENKeyDao

    let reports: Observable<[ReceivedCenReport]>

    // last time (unix timestamp) the CENKeys were requested
    // TODO has to be updated. In Android it's currently also not updated.
    private static var lastCENKeysCheck: Int64 = 0

    private let disposeBag = DisposeBag()

    init(cenRepo: CENRepo, api: CoEpiApi, keysFetcher: CenKeysFetcher, cenMatcher: CenMatcher, cenKeyDao: CENKeyDao) {
        self.cenRepo = cenRepo
        self.api = api
        self.cenMatcher = cenMatcher
        self.cenKeyDao = cenKeyDao

        // Benchmarking
        var matchingStartTime: CFAbsoluteTime?

        reports = keysFetcher.keys
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .do(onNext: { keys in
                 matchingStartTime = CFAbsoluteTimeGetCurrent()
                os_log("Fetched keys from API (%d)", log: servicesLog, type: .debug, keys.count)
            })

//            // Uncomment this to benchmark a few keys quickly...
//            .map({ keys in
//                keys[0...2]
//            })

            // Filter matching keys
//            .map { keys -> [CENKey] in keys.compactMap { key in
//                if (cenMatcher.hasMatches(key: key, maxTimestamp: CoEpiRepoImpl.lastCENKeysCheck)) {
//                    return key
//                } else {
//                    return nil
//                }
//            }}
            
            .map{keys -> [CENKey] in cenMatcher.matchLocalFirst(keys: keys, maxTimestamp: .now()) }
            
            .do(onNext: { matchedKeys in
                if let matchingStartTime = matchingStartTime {
                    let time = CFAbsoluteTimeGetCurrent() - matchingStartTime
                    os_log("Took %.2f to match keys", log: servicesLog, type: .debug, time)
                }
                if !matchedKeys.isEmpty {
                    os_log("Matches found for [%{public}d] keys: %{public}@", log: servicesLog, type: .debug, matchedKeys.count ,"\(matchedKeys)")

                    //Show notification that matches were found (background)
                        //Needs to open alert view
                    let content = UNMutableNotificationContent()
                    content.title = "New Contact Alerts"
                    content.body = "New contact alerts have been detected. Tap for details."
                    content.sound = UNNotificationSound.default
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                    UNUserNotificationCenter.current().add(request)
                    
                    //Show notification that matches were found (foreground) TODO
                    
                    //Show badge number TODO

                } else {
                    os_log("No matches found for keys", log: servicesLog, type: .debug)
                }
            })
            
            // Retrieve reports for matching keys
            .flatMap { matchedKeys -> Observable<[ReceivedCenReport]> in
                let requests: [Observable<[ReceivedCenReport]>] = matchedKeys.map {
                    api.getCenReports(cenKey: $0)
                        .map({ apiCenReports in
                            apiCenReports.map { ReceivedCenReport(report: $0.toCenReport()) }
                        })
                        .asObservable()
                }
                return .merge(requests)
            }
            
            .observeOn(MainScheduler.instance) // TODO switch to main only in view models
            .share()

        reports.subscribe().disposed(by: disposeBag)
    }

    func storeObservedCen(cen: CEN) {
        if !(cenRepo.insert(cen: cen)) {
            os_log("Observed CEN already in DB: %@", log: servicesLog, type: .debug, "\(cen)")
        }
    }

    // TODO clarify with Rust lib, does it store the keys or we pass them
    func sendReport(report: CenReport) -> Completable {
        switch cenKeyDao.generateAndStoreCENKey() {  // TODO last n keys?
        case .success(let key):
            // TODO clarify id
            return api.postCenReport(myCenReport: MyCenReport(id: "123", report: report, keys: [key.cenKey]))
        case .failure(let error):
            switch error {
            case .couldNotComputeKey: return .error(RepoError.couldNotComputeKey)
            case .database: return .error(RepoError.database)
            }
        }
    }
}
