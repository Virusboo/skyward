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
import WCDBSwift

public class MapModule: ModuleType {
    
    public static var name: String = "ModuleMap"
    
    public init() {
        // 监听登录成功通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLoginSuccess),
            name: .loginSuccess,
            object: nil
        )
    }
    
    public func moduleSetup() {
        if UserManager.shared.isLogin {
            // 移除老表
            DBManager.shared.dropTable(table: DBTableName.track.rawValue)
            DBManager.shared.dropTable(table: DBTableName.route.rawValue)
            DBManager.shared.dropTable(table: DBTableName.routePoint.rawValue)
            // 创建新表
            DBManager.shared.createTable(table: DBTableName.route.rawValue, of: Route.self)
            DBManager.shared.createTable(table: DBTableName.miniDevice.rawValue, of: MiniDeviceData.self)
            DBManager.shared.createTable(table: DBTableName.userPOI.rawValue, of: UserPOILocalData.self)
            DBManager.shared.createTable(table: DBTableName.userPublicPOI.rawValue, of: PublicPOIData.self)
            
            // 静默上传本地的路线
            RouteDataManager.silentSaveLocalRoutesToServer(completion: nil)
        }
    }
    
    /// 当前模块的路由
    public var routeSettings: [any RoutableType.Type] {
        return [MapRouter.self, RouteListRouter.self, RoutesCountRouter.self, TracksCountRouter.self, POIListRouter.self, POICollectListRouter.self]
    }
    
    /// 处理登录成功
    @objc private func handleLoginSuccess() {
        moduleSetup()
    }
}
