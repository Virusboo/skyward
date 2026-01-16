//
//  RouteManager.swift
//  ModuleMap
//
//  Created by zhaobo on 2025/12/18.
//

import Foundation
import CoreLocation
import SWKit
import WCDBSwift


struct RoutePoint: TableCodable {
    let routeId: UInt64?
    let longitude: Double?
    let latitude: Double?
    var altitude: Double?
    var timestamp: UInt64?
    
    enum CodingKeys: String, CodingTableKey {
        typealias Root = RoutePoint
        
        case routeId
        case longitude
        case latitude
        case altitude
        case timestamp
        
        static let objectRelationalMapping = TableBinding(CodingKeys.self)
    }
}


class RouteManager {
    private let dataManager = TrackDataManager()
    
    func startRecord() {
        dataManager.startRecord()
    }
    
    func stopRecord() {
        dataManager.stopRecord()
    }
    
    func writePoint(_ point: CLLocationCoordinate2D) {
        let point = RecordPoint(latitude: point.latitude, longitude: point.longitude)
        dataManager.writePointToTxtFile(point)
    }
    
    func getAllRoutes() -> [RouteRecord]? {
        return dataManager.getRouteRecords(type: .route)
    }

    func getPointsInRoute(routeId: Int64) -> [CLLocationCoordinate2D]? {
        return dataManager.readCoordinatesFromGPXFile(from: routeId)
        
    }
    
    func saveRoute(name: String, desc: String?) {
        guard let sessionRecordId = dataManager.sessionRecordId else {
            return
        }

        let record = RouteRecord(id: sessionRecordId, routeName: name, description: desc)
        dataManager.saveRouteToService(record) { [weak self] success, errorMsg in
            UIWindow.topWindow?.sw_hideLoading()
            if success {
                UIWindow.topWindow?.sw_showSuccessToast("保存成功")
            } else {
                if let msg = errorMsg {
                    UIWindow.topWindow?.sw_showWarningToast(msg)
                }
            }
            self?.stopRecord()
        }
    }
    
    func deleteRoute(_ routeId: Int64, completion: ((Bool) -> Void)?) {
        dataManager.deleteRouteFromService(routeId: routeId) { success, errorMsg in
            completion?(success)
            
            if success == false, let msg = errorMsg {
                UIWindow.topWindow?.sw_showWarningToast(msg)
            }
        }
    }
}
