//
//  PersonalModule.swift
//  Pods
//
//  Created by TXTS on 2025/11/19.
//


import Foundation
import TXKit
import TXRouterKit
import SWKit

public class MapModule: ModuleType {
    
    public static var name: String = "ModuleMap"
    
    public init() {
        DBManager.shared.createTable(table: DBTableName.track.rawValue, of: TrackRecord.self)
        DBManager.shared.createTable(table: DBTableName.route.rawValue, of: RouteRecord.self)
        DBManager.shared.createTable(table: DBTableName.routePoint.rawValue, of: RoutePoint.self)
    }
    
    /// 当前模块的路由
    public var routeSettings: [any RoutableType.Type] {
        return [MapRouter.self]
    }
}
