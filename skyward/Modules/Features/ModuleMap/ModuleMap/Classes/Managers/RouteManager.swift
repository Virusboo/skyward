//
//  RouteManager.swift
//  ModuleMap
//
//  Created by zhaobo on 2025/12/18.
//

import Foundation
import CoreLocation

class RouteManager: NSObject {
    private let dataManager = RouteDataManager()
    
    
    // MARK: - Initializer
    override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidTermination),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func startRecord() {
        dataManager.startRecord()
    }
    
    func endRecord() {
        dataManager.endRecord()
    }
    
    // MARK: - 增删改查
    
    func writePoint(_ point: CLLocationCoordinate2D) {
        let point = RecordPoint(latitude: point.latitude, longitude: point.longitude)
        dataManager.writePointToTxtFile(point)
    }
    
    func getAllRoutes() -> [Route] {
        return dataManager.getRoutes(type: .route)
    }

    func getPointsInRoute(routeId: String) -> [CLLocationCoordinate2D]? {
        return dataManager.readCoordinatesFromGPXFile(from: routeId)
    }
    
    func saveRoute(name: String, desc: String?, completion: @escaping ()->Void) {
        guard let sessionRouteId = dataManager.sessionRouteId else {
            return
        }

        let route = Route(id: sessionRouteId, routeName: name, description: desc, type: 0)
        UIWindow.topWindow?.sw_showLoading()
        dataManager.saveRouteToService(route) { [weak self] rspRoute, errorMsg in
            UIWindow.topWindow?.sw_hideLoading()
            if let rspRoute = rspRoute {
                self?.dataManager.saveSessionRouteToLocal(rspRoute)
                UIWindow.topWindow?.sw_showSuccessToast("保存成功")
            } else {
                if let msg = errorMsg {
                    UIWindow.topWindow?.sw_showWarningToast(msg)
                }
            }
            completion()
        }
    }
    
    func deleteRoute(_ routeId: String, completion: ((Bool) -> Void)?) {
        dataManager.deleteRouteFromService(routeId: routeId) { success, errorMsg in
            completion?(success)
            
            if success == false, let msg = errorMsg {
                UIWindow.topWindow?.sw_showWarningToast(msg)
            }
        }
    }
    
    //MARK: - Notification
    
    @objc func appDidTermination() {
        // 如果正在记录，杀程序需要endRecord
        endRecord()
    }
}
