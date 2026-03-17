//
//  RoutePlanModel.swift
//  ModuleMap
//
//  Created by zhaobo on 2026/3/9.
//

import Foundation
import CoreLocation

// MARK: - 路径规划响应

struct RoutePlanResponse: Codable {
    let code: String?
    let routes: [PlannedRoute]?
    let waypoints: [Waypoint]?
}

// MARK: - 规划的路线

struct PlannedRoute: Codable {
    let legs: [RouteLeg]?          // 路段数组
    let weight_name: String?       // 权重名称
    let weight: Double?            // 权重值
    let duration: Double?          // 总时间（秒）
    let distance: Double?          // 总距离（米）
    let geometry: String?          // Polyline 编码的坐标字符串（overview=false 时为 nil）

    private enum CodingKeys: String, CodingKey {
        case legs, weight_name, weight, duration, distance, geometry
    }

    /// 解码 geometry 为坐标数组
    func decodedGeometry() -> [CLLocationCoordinate2D] {
        guard let geometry = geometry else {
            return []
        }
        return PolylineDecoder.decode(geometry)
    }
}

// MARK: - 路段

struct RouteLeg: Codable {
    let steps: [RouteStep]?        // 转向步骤
    let weight: Double?            // 权重值
    let summary: String?           // 路段摘要
    let duration: Double?          // 时间（秒）
    let distance: Double?          // 距离（米）
}

// MARK: - 转向步骤

struct RouteStep: Codable {
    let intersections: [Intersection]?  // 交叉口信息数组
    let driving_side: String?           // 靠哪侧行驶：right/left
    let geometry: String?              // 该步骤的 Polyline 编码
    let maneuver: Maneuver?            // 转向动作
    let weight: Double?                // 权重值
    let duration: Double?              // 时间（秒）
    let distance: Double?              // 距离（米）
    let name: String?                 // 道路名称
    let mode: String?                 // 交通模式

    private enum CodingKeys: String, CodingKey {
        case intersections, driving_side, geometry, maneuver, weight, duration, distance, name, mode
    }

    /// 解码 geometry 为坐标数组
    func decodedGeometry() -> [CLLocationCoordinate2D] {
        if let geometry = geometry {
            return PolylineDecoder.decode(geometry)
        }
        return []
    }
}

// MARK: - 转向动作

struct Maneuver: Codable {
    let type: String?                // 动作类型：turn, merge, depart, arrive, new name, etc.
    let modifier: String?            // 修饰符：left, right, slight, sharp, straight, uturn, etc.
    let bearing_after: Int?          // 转向后的方向角（0-359）
    let bearing_before: Int?         // 转向前的方向角（0-359）
    let location: [Double]?          // 转向点坐标 [longitude, latitude]

    private enum CodingKeys: String, CodingKey {
        case type, modifier, bearing_after, bearing_before, location
    }

    /// 转换为 CLLocationCoordinate2D
    var coordinate: CLLocationCoordinate2D? {
        guard let location = location, location.count >= 2 else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: location[1], longitude: location[0])
    }

    /// 生成本地化的转向指令
    func localizedInstruction() -> String {
        switch type {
        case "depart":
            return "出发"
        case "arrive":
            return "到达目的地"
        case "turn":
            if let modifier = modifier {
                switch modifier {
                case "slight left":
                    return "向左转"
                case "left":
                    return "向左转"
                case "sharp left":
                    return "向左急转"
                case "slight right":
                    return "向右转"
                case "right":
                    return "向右转"
                case "sharp right":
                    return "向右急转"
                case "uturn":
                    return "掉头"
                case "straight":
                    return "直行"
                default:
                    return "\(modifier)"
                }
            }
            return "转弯"
        case "new name":
            if let modifier = modifier {
                switch modifier {
                case "straight":
                    return "继续直行"
                case "slight left":
                    return "稍微向左"
                case "slight right":
                    return "稍微向右"
                default:
                    return "继续"
                }
            }
            return "继续"
        case "merge":
            return "并线"
        case "on ramp":
            return "进入匝道"
        case "off ramp":
            return "驶出匝道"
        case "fork":
            if let modifier = modifier {
                switch modifier {
                case "slight left":
                    return "在岔路口向左"
                case "left":
                    return "在岔路口向左"
                case "slight right":
                    return "在岔路口向右"
                case "right":
                    return "在岔路口向右"
                default:
                    return "在岔路口"
                }
            }
            return "在岔路口"
        case "end of road":
            return "道路尽头"
        case "continue":
            return "继续直行"
        case "roundabout":
            return "进入环岛"
        case "rotary":
            return "进入转盘"
        case "roundabout turn":
            return "环岛出口"
        case "notification":
            return "注意"
        default:
            return type ?? ""
        }
    }
}

// MARK: - 交叉口

struct Intersection: Codable {
    let out: Int?                 // 离开交叉口时的 bearings 索引
    let entry: [Bool]?            // 是否可以从该角度进入交叉口
    let bearings: [Int]?          // 可能的行驶方向角度（0-359）
    let location: [Double]?       // 交叉口坐标 [longitude, latitude]
    let `in`: Int?                // 进入交叉口时的 bearings 索引（可选）

    /// 转换为 CLLocationCoordinate2D
    var coordinate: CLLocationCoordinate2D? {
        guard let location = location, location.count >= 2 else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: location[1], longitude: location[0])
    }
}

// MARK: - 途经点

struct Waypoint: Codable {
    let distance: Double?         // 该途经点偏离路线的距离（米）
    let location: [Double]?       // 坐标 [longitude, latitude]
    let name: String?             // 地点名称
    let hint: String?             // 内部使用的提示信息

    /// 转换为 CLLocationCoordinate2D
    var coordinate: CLLocationCoordinate2D? {
        guard let location = location, location.count >= 2 else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: location[1], longitude: location[0])
    }
}

// MARK: - 路径规划请求

struct RoutePlanRequest {
    enum TravelMode {
        case driving   // 驾车
        case cycling   // 骑行
        case walking   // 步行

        var path: String {
            switch self {
            case .driving: return "driving"
            case .cycling: return "cycling"
            case .walking: return "walking"
            }
        }
    }

    let coordinates: [CLLocationCoordinate2D]  // 坐标点（起点、途经点、终点）
    let mode: TravelMode                       // 出行模式
    var overview: Bool? = nil                  // 是否返回几何信息（nil=默认simplified, true=full, false=none）
    var alternatives: Bool = true              // 是否返回备选路线
    var steps: Bool = true                     // 是否返回详细步骤

    var params: [String: Any] {
        var dict: [String: Any] = [
            "alternatives": alternatives ? "true" : "false",
            "steps": steps ? "true" : "false"
        ]
        // 只有显式设置 overview 时才添加参数（nil 时使用 OSRM 默认的 simplified）
        if let overview = overview {
            dict["overview"] = overview ? "full" : "none"
        }
        return dict
    }

    /// 构建 URL
//    func buildURL(baseURL: String) -> URL? {
//        // 构建坐标字符串：经度,纬度;经度,纬度;...
//        let coordsString = coordinates
//            .map { "\($0.longitude),\($0.latitude)" }
//            .joined(separator: ";")
//
//        // 构建查询参数
//        var queryItems: [URLQueryItem] = []
//
//        // overview 参数（只有显式设置时才添加）
//        if let overview = overview {
//            queryItems.append(URLQueryItem(name: "overview", value: overview ? "true" : "false"))
//        }
//        // 不传 overview 时，OSRM 默认返回 simplified
//
//        queryItems.append(URLQueryItem(name: "alternatives", value: alternatives ? "true" : "false"))
//        queryItems.append(URLQueryItem(name: "steps", value: steps ? "true" : "false"))
//
//        // 构建 URL
//        var components = URLComponents(string: baseURL)
//        components?.path = "/route/v1/\(mode.path)/\(coordsString)"
//        components?.queryItems = queryItems
//
//        return components?.url
//    }
}
