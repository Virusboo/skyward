//
//  RouteModel.swift
//  ModuleMap
//
//  Created by zhaobo on 2026/1/15.
//

import SWKit
import WCDBSwift

// 路线/轨迹记录
struct RouteRecord: TableCodable {
    var id: Int64 = Int64(Date().timeIntervalSince1970)
    var routeName: String?
    var startName: String?
    var startLongitude: Double?
    var startLatitude: Double?
    var endName: String?
    var endLongitude: Double?
    var endLatitude: Double?
    var distance: Double?
    var travelTime: Int?
    var description: String?
    var fileUrl: String?
    var type: Int?
    
    enum CodingKeys: String, CodingTableKey {
        typealias Root = RouteRecord
        
        case id
        case routeName
        case startName
        case startLongitude
        case startLatitude
        case endName
        case endLongitude
        case endLatitude
        case distance
        case travelTime
        case description
        case fileUrl
        case type
        
        static let objectRelationalMapping = TableBinding(CodingKeys.self) {
            BindColumnConstraint(id, isPrimary: true)
        }
    }
}

// 路线/轨迹记录点
struct RecordPoint {
    var latitude: Double
    var longitude: Double
    var altitude: Double
    var timestamp: Date
    
    // 初始化方法
    init(latitude: Double, longitude: Double, altitude: Double = 0, timestamp: Date = Date()) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.timestamp = timestamp
    }
    
    // 从字符串解析轨迹点
    init?(from line: String) {
        let components = line.components(separatedBy: ",")
        guard components.count == 4 else { return nil }
        
        guard let lat = Double(components[0]),
              let lon = Double(components[1]),
              let alt = Double(components[2]),
              let timeInterval = Double(components[3]) else { return nil }
        
        self.latitude = lat
        self.longitude = lon
        self.altitude = alt
        self.timestamp = Date(timeIntervalSince1970: timeInterval)
    }
    
    // 转换为字符串格式（用于写入文件）
    func toString() -> String {
        let timeInterval = timestamp.timeIntervalSince1970
        return "\(latitude),\(longitude),\(altitude),\(timeInterval)"
    }
}
