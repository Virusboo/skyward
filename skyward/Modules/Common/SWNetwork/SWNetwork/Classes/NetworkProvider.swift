//
//  NetworkProvider.swift
//  SWNetworkKit
//
//  Created by 赵波 on 2025/11/16.
//

/// 二次封装的网络提供者

import Foundation
import Moya
import Combine


public class NetworkProvider<T: TargetType> {
    
    private let provider: MoyaProvider<T>
    private let config: NetworkConfigProtocol
    
    public init(
        config: NetworkConfigProtocol = NetworkConfigurationManager.shared.getConfig(),
        plugins: [PluginType] = NetworkDefaultPlugins.createDefaultMoyaPlugins(),
        stubClosure: @escaping (T) -> StubBehavior = MoyaProvider.neverStub,
        callbackQueue: DispatchQueue? = nil
    ) {
        self.config = config
        
        // 创建自定义endpoint closure
        let endpointClosure = { (target: T) -> Endpoint in
            let defaultEndpoint = MoyaProvider.defaultEndpointMapping(for: target)
            
            // 添加公共headers
            var headers = target.headers ?? [:]
            config.commonHeaders.forEach { headers[$0.key] = $0.value }
            
            // 处理参数：只有当任务类型支持参数时才添加公共参数
            var finalTask = target.task
            if case .requestParameters(var parameters, let encoding) = target.task {
                // 添加公共参数
                config.commonParameters.forEach { parameters[$0.key] = $0.value }
                finalTask = .requestParameters(parameters: parameters, encoding: encoding)
            } else if case .requestPlain = target.task {
                // 对于Plain请求，如果有公共参数，转换为参数请求
                if !config.commonParameters.isEmpty {
                    finalTask = .requestParameters(parameters: config.commonParameters, encoding: URLEncoding.default)
                }
            }
            
            return defaultEndpoint
                .adding(newHTTPHeaderFields: headers)
                .replacing(task: finalTask)
        }
        
        // 创建自定义request closure
        let requestClosure = { (endpoint: Endpoint, closure: @escaping (Result<URLRequest, MoyaError>) -> Void) in
            do {
                var request = try endpoint.urlRequest()
                request.timeoutInterval = config.timeoutInterval
                closure(.success(request))
            } catch {
                closure(.failure(MoyaError.underlying(error, nil)))
            }
        }
        
        self.provider = MoyaProvider<T>(
            endpointClosure: endpointClosure,
            requestClosure: requestClosure,
            stubClosure: stubClosure,
            callbackQueue: callbackQueue,
            plugins: plugins,
            trackInflights: false
        )
    }
    
    /// 发送请求（使用async/await）
    @available(iOS 13.0, *)
    public func request(_ target: T) async throws -> Response {
        return try await withCheckedThrowingContinuation { continuation in
            provider.request(target) { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// 发送请求（使用Combine）
    @available(iOS 13.0, *)
    public func request(_ target: T) -> AnyPublisher<Response, MoyaError> {
        return Future<Response, MoyaError> { promise in
            self.provider.request(target) { result in
                switch result {
                case .success(let response):
                    promise(.success(response))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// 发送请求（传统回调方式）
    public func request(_ target: T,
                       callbackQueue: DispatchQueue? = .main,
                       progress: ProgressBlock? = nil,
                       completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(target, callbackQueue: callbackQueue, progress: progress, completion: completion)
    }
}

