//
//  RoutePlanManager.swift
//  ModuleMap
//
//  Created by zhaobo on 2026/3/10.
//

import Foundation
import CoreLocation
import SWNetwork
import SWKit

/// 路线规划管理器
public class RoutePlanManager {

    private static let mapService = MapService()

    // MARK: - Public Methods

    /// 请求路线规划
    /// - Parameters:
    ///   - request: 路线规划请求
    ///   - completion: 完成回调，返回 Result<[PlannedRoute], Error>
    static func planRoute(_ request: RoutePlanRequest, completion: @escaping (Result<[PlannedRoute], Error>) -> Void) {
        mapService.planRoute(request) { result in
            switch result {
            case .success(let response):
                do {
                    let bizResponse = try JSONDecoder().decode(RoutePlanResponse.self, from: response.data)
                    if let routes = bizResponse.routes, !routes.isEmpty {
                        Logger.debug("路线规划成功，返回 \(routes.count) 条路线")
                        completion(.success(routes))
                    } else {
                        let error = NSError(domain: "RoutePlanManager", code: -4, userInfo: [NSLocalizedDescriptionKey: "未找到路线"])
                        completion(.failure(error))
                    }
                } catch {
                    Logger.debug("路线规划解析失败：\(error.localizedDescription)")
                    // 打印原始响应用于调试
                    if let jsonString = String(data: response.data, encoding: .utf8) {
                        Logger.debug("路线规划原始响应：\(jsonString)")
                    }
                    completion(.failure(error))
                }
            case .failure(let error):
                Logger.debug("路线规划网络错误：\(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

    /// 请求路线规划
    /// - Parameters:
    ///   - coordinates: 坐标点数组（起点、途经点、终点）
    ///   - mode: 出行模式
    ///   - completion: 完成回调，返回 Result<[PlannedRoute], Error>
    static func planRoute(coordinates: [CLLocationCoordinate2D],
                          mode: RoutePlanRequest.TravelMode = .driving,
                          completion: @escaping (Result<[PlannedRoute], Error>) -> Void) {
        // overview=true 返回完整的 geometry（包含所有坐标点）
        let request = RoutePlanRequest(coordinates: coordinates, mode: mode, overview: true, alternatives: true, steps: true)
        planRoute(request, completion: completion)
    }
}
