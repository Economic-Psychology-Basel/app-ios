import RxSwift
import os.log

protocol HomeViewModelDelegate {
    func debugTapped()
    func checkInTapped()
    func seeAlertsTapped()
}

class HomeViewModel {
    var delegate: HomeViewModelDelegate?
    
    let title = "CoEpi"

    private let disposeBag = DisposeBag()

    init(startPermissions: StartPermissions) {
        startPermissions.granted.subscribe(onNext: { granted in
            os_log("Start permissions granted: %@", log: servicesLog, type: .debug, "\(granted)")
        }).disposed(by: disposeBag)

        startPermissions.request()
    }

    func debugTapped() {
        delegate?.debugTapped()
    }
    
    func quizTapped() {
        delegate?.checkInTapped()
    }
    
    func seeAlertsTapped() {
        delegate?.seeAlertsTapped()
    }
}
