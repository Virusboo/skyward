//
//  NetworkPlugin.swift
//  Alamofire
//
//  Created by 赵波 on 2025/11/16.
//

import Foundation
import Moya

// MARK: - 网络日志插件
public class NetworkLoggerPlugin: PluginType {
    
    public enum LogLevel: String, CaseIterable {
        case none = "NONE"
        case info = "INFO"
        case debug = "DEBUG"
        case verbose = "VERBOSE"
    }
    
    private let logLevel: LogLevel
    private let dateFormatter: DateFormatter
    
    public init(logLevel: LogLevel = .info) {
        self.logLevel = logLevel
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "HH:mm:ss.SSS"
    }
    
    public func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        guard logLevel != .none else { return request }
        
        let timestamp = dateFormatter.string(from: Date())
        print("\n🌐 [\(timestamp)] 🚀 Network Plugin - Request")
        print("📍 Target: \(target.path)")
        print("🔍 Method: \(target.method.rawValue)")
        print("🌐 URL: \(request.url?.absoluteString ?? "N/A")")
        
        if logLevel == .verbose || logLevel == .debug {
            if let headers = request.allHTTPHeaderFields {
                print("📋 Headers: \(headers)")
            }
            
            if let body = request.httpBody,
               let bodyString = String(data: body, encoding: .utf8) {
                print("📦 Body: \(bodyString)")
            }
        }
        
        return request
    }
    
    public func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
        guard logLevel != .none else { return }
        
        let timestamp = dateFormatter.string(from: Date())
        
        switch result {
        case .success(let response):
            print("\n🌐 [\(timestamp)] ✅ Network Plugin - Response")
            print("📍 Target: \(target.path)")
            print("📊 Status Code: \(response.statusCode)")
            
            if logLevel == .verbose || logLevel == .debug {
                if let responseString = String(data: response.data, encoding: .utf8) {
                    print("📦 Response Body: \(responseString)")
                }
            }
            
        case .failure(let error):
            print("\n🌐 [\(timestamp)] ❌ Network Plugin - Error")
            print("📍 Target: \(target.path)")
            print("❌ Error: \(error)")
        }
    }
}

// MARK: - 网络缓存插件
public class NetworkCachePlugin: PluginType {
    
    private let cache: URLCache
    private let cachePolicy: CachePolicy
    
    public enum CachePolicy {
        case never
        case memoryOnly
        case diskAndMemory
        case custom(URLRequest.CachePolicy)
    }
    
    public init(cachePolicy: CachePolicy = .memoryOnly, cache: URLCache? = nil) {
        self.cachePolicy = cachePolicy
        self.cache = cache ?? URLCache.shared
    }
//    
//    public func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
//        var modifiedRequest = request
//        
//        switch cachePolicy {
//        case .never:
//            modifiedRequest.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
//        case .memoryOnly:
//            modifiedRequest.cachePolicy = .returnCacheDataElseLoad
//        case .diskAndMemory:
//            modifiedRequest.cachePolicy = .returnCacheDataElseLoad
//        case .custom(let policy):
//            modifiedRequest.cachePolicy = policy
//        }
//        
//        return modifiedRequest
//    }
//    
//    public func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
//        // 缓存成功的响应
//        if case .success(let response) = result,
//           response.statusCode >= 200 && response.statusCode < 300 {
//            
//            if let url = response.request?.url,
//               let urlResponse = HTTPURLResponse(
//                url: url,
//                statusCode: response.statusCode,
//                httpVersion: "HTTP/1.1",
//                headerFields: response.response?.allHeaderFields as? [String: String]
//               ) {
//                
//                let cachedResponse = CachedURLResponse(
//                    response: urlResponse,
//                    data: response.data
//                )
//                cache.storeCachedResponse(cachedResponse, for: response.request!)
//            }
//        }
//    }
    
    public func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        if let cacheData = NetworkCacherCacher.shared.urlCache!.cachedResponse(for: request) {
            return applyCacheResponse(request, cachedResponse: cacheData)
        }
        return request
    }
    
    
    public func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
        switch result {
        case .success(let response):
            if let httpResponse = response.response {
                let cacheResponse = CachedURLResponse(response: httpResponse, data: response.data)
                NetworkCacherCacher.shared.urlCache!.storeCachedResponse(cacheResponse, for: response.request!)
            }
        case .failure(_):
            break
        }
    }
    
    public func applyCacheResponse(
        _ request: URLRequest,
        cachedResponse: CachedURLResponse
    ) -> URLRequest {
        var newRequest = request
        // 只在非GET请求中添加缓存数据到请求体
        if request.httpMethod != "GET" {
            newRequest.httpBody = cachedResponse.data
        }
        return newRequest
    }
    
}

// MARK: - 网络重试插件
public class NetworkRetryPlugin: PluginType {
    
    private let maxRetryCount: Int
    private let retryDelay: TimeInterval
    private var retryCount: [String: Int] = [:]
    
    public init(maxRetryCount: Int = 3, retryDelay: TimeInterval = 1.0) {
        self.maxRetryCount = maxRetryCount
        self.retryDelay = retryDelay
    }
    
    public func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        let key = target.path
        retryCount[key] = 0
        return request
    }
    
    public func process(_ result: Result<Response, MoyaError>, target: TargetType) -> Result<Response, MoyaError> {
        let key = target.path
        
        switch result {
        case .success(_):
            // 成功的响应，重置重试计数
            retryCount[key] = nil
            return result
            
        case .failure(let error):
            let currentRetryCount = retryCount[key] ?? 0
            
            if currentRetryCount < maxRetryCount && shouldRetry(error: error) {
                retryCount[key] = currentRetryCount + 1
                
                print("🔄 重试请求: \(target.path) (第\(currentRetryCount + 1)次)")
                
                // 延迟重试
                Thread.sleep(forTimeInterval: retryDelay * Double(currentRetryCount + 1))
                
                // 返回一个特殊的重试错误
                return .failure(MoyaError.underlying(NSError(
                    domain: "NetworkRetry",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Retry needed"]
                ), nil))
            }
            
            // 达到最大重试次数或不应该重试
            retryCount[key] = nil
            return result
        }
    }
    
    private func shouldRetry(error: MoyaError) -> Bool {
        switch error {
        case .underlying(let nsError as NSError, _):
            // 网络错误、超时等可重试
            return nsError.domain == NSURLErrorDomain &&
                   (nsError.code == NSURLErrorNotConnectedToInternet ||
                    nsError.code == NSURLErrorTimedOut ||
                    nsError.code == NSURLErrorCannotConnectToHost ||
                    nsError.code == NSURLErrorNetworkConnectionLost)
        case .statusCode(let response):
            // 5xx 服务器错误可重试
            return response.statusCode >= 500 && response.statusCode < 600
        default:
            return false
        }
    }
}

// MARK: - 网络认证插件
public class NetworkAuthPlugin: PluginType {
    
    private let tokenProvider: () -> String?
    private let tokenUpdater: (String) -> Void
    
    public init(
        tokenProvider: @escaping () -> String?,
        tokenUpdater: @escaping (String) -> Void
    ) {
        self.tokenProvider = tokenProvider
        self.tokenUpdater = tokenUpdater
    }
    
    public func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        var modifiedRequest = request
        
        // 添加认证token
        if let token = tokenProvider() {
            modifiedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return modifiedRequest
    }
    
    public func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
        // 检查是否需要刷新token
        if case .success(let response) = result, response.statusCode == 401 {
            print("🔒 Token过期，需要刷新")
            // TODO: 实现token刷新逻辑
        }
    }
}

// MARK: - 网络监控插件
public class NetworkMonitorPlugin: PluginType {
    
    public struct NetworkMetrics {
        let target: TargetType
        let startTime: Date
        let endTime: Date
        let statusCode: Int?
        let error: Error?
        let requestSize: Int?
        let responseSize: Int?
        
        var duration: TimeInterval {
            return endTime.timeIntervalSince(startTime)
        }
        
        var isSuccess: Bool {
            return error == nil && (statusCode ?? 0) >= 200 && (statusCode ?? 0) < 300
        }
    }
    
    private var requestStartTimes: [String: Date] = [:]
    private let metricsHandler: (NetworkMetrics) -> Void
    
    public init(metricsHandler: @escaping (NetworkMetrics) -> Void) {
        self.metricsHandler = metricsHandler
    }
    
    public func willSend(_ request: RequestType, target: TargetType) {
        requestStartTimes[target.path] = Date()
    }
    
    public func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
        guard let startTime = requestStartTimes[target.path] else { return }
        
        let endTime = Date()
        requestStartTimes[target.path] = nil
        
        let metrics: NetworkMetrics
        
        switch result {
        case .success(let response):
            metrics = NetworkMetrics(
                target: target,
                startTime: startTime,
                endTime: endTime,
                statusCode: response.statusCode,
                error: nil,
                requestSize: response.request?.httpBody?.count,
                responseSize: response.data.count
            )
            
        case .failure(let error):
            metrics = NetworkMetrics(
                target: target,
                startTime: startTime,
                endTime: endTime,
                statusCode: nil,
                error: error,
                requestSize: nil,
                responseSize: nil
            )
        }
        
        metricsHandler(metrics)
        
        // 打印监控信息
        if metrics.isSuccess {
            print("📊 网络请求成功: \(target.path) (\(String(format: "%.3f", metrics.duration))s)")
        } else {
            print("📊 网络请求失败: \(target.path) (\(String(format: "%.3f", metrics.duration))s) - \(metrics.error?.localizedDescription ?? "Unknown error")")
        }
    }
}


// MARK: - 默认插件配置
public struct NetworkDefaultPlugins {
    
    /// 创建默认的Moya插件（推荐）
    public static func createDefaultMoyaPlugins(
        logLevel: NetworkLoggerPlugin.LogLevel = .info,
        cachePolicy: NetworkCachePlugin.CachePolicy = .memoryOnly,
        maxRetryCount: Int = 3,
        tokenProvider: @escaping () -> String? = { nil },
        tokenUpdater: @escaping (String) -> Void = { _ in },
        metricsHandler: @escaping (NetworkMonitorPlugin.NetworkMetrics) -> Void = { _ in }
    ) -> [PluginType] {
        var plugins: [PluginType] = []
        
        // 添加日志插件（适配为Moya PluginType）
        let loggerAdapter = NetworkLoggerPlugin(logLevel: logLevel)
        plugins.append(loggerAdapter)
        
        // 添加缓存插件（适配为Moya PluginType）
        let cacheAdapter = NetworkCachePlugin(cachePolicy: cachePolicy)
        plugins.append(cacheAdapter)
        
        // 添加认证插件（适配为Moya PluginType）
        let authAdapter = NetworkAuthPlugin(tokenProvider: tokenProvider, tokenUpdater: tokenUpdater)
        plugins.append(authAdapter)
        
        return plugins
    }
}
