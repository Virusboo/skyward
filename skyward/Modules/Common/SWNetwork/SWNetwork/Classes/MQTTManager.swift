//
//  MQTTManager.swift
//  SWNetwork
//
//  Created by 赵波 on 2025/11/19.
//

/**
 *该MQTT客户端封装具有以下核心功能：
 *连接管理‌：提供完整的连接状态监控、连接/断开控制，以及连接失败的错误处理机制
 *自动重连‌：实现基于指数退避算法的智能重连策略，避免频繁重连对服务器造成压力
 *消息处理‌：支持消息发布、订阅管理，并自动恢复重连后的订阅状态
 *配置灵活‌：支持自定义KeepAlive时间、会话保持、认证信息等参数配置
 *状态维护‌：维护连接状态、已订阅主题列表，确保业务连续性
 */

import Foundation
import CocoaMQTT

// MQTT连接状态枚举
public enum MQTTConnectionState {
    case connecting
    case connected
    case disconnected
    case reconnecting
}

// MQTT消息接收协议
public protocol MQTTManagerDelegate: AnyObject {
    func mqttManager(_ manager: MQTTManager, didChangeState state: MQTTConnectionState)
    func mqttManager(_ manager: MQTTManager, didReceiveMessage message: String, fromTopic topic: String)
    func mqttManager(_ manager: MQTTManager, didPublishMessage message: String, toTopic topic: String)
    func mqttManager(_ manager: MQTTManager, connectionDidFailWithError error: Error?)
}

// MQTT配置结构体
public struct MQTTConfiguration {
    let host: String
    let port: UInt16
    let clientID: String
    let username: String?
    let password: String?
    let keepAlive: UInt16
    let cleanSession: Bool
    let autoReconnect: Bool
    let reconnectInterval: TimeInterval
    let maxReconnectInterval: TimeInterval
    
    public init(host: String, port: UInt16 = 1883, clientID: String? = nil, username: String? = nil, password: String? = nil, keepAlive: UInt16 = 60, cleanSession: Bool = false, autoReconnect: Bool = true, reconnectInterval: TimeInterval = 1.0, maxReconnectInterval: TimeInterval = 60.0) {
        self.host = host
        self.port = port
        self.clientID = clientID ?? "iOS_Client_\(UUID().uuidString)"
        self.username = username
        self.password = password
        self.keepAlive = keepAlive
        self.cleanSession = cleanSession
        self.autoReconnect = autoReconnect
        self.reconnectInterval = reconnectInterval
        self.maxReconnectInterval = maxReconnectInterval
    }
}

// 主要的MQTT管理类
public final class MQTTManager: CocoaMQTTDelegate {
    
    // MARK: - 属性
    
    private var mqtt: CocoaMQTT?
    private var configuration: MQTTConfiguration
    private var reconnectTimer: Timer?
    private var currentReconnectInterval: TimeInterval = 0
    private var subscribedTopics: Set<String> = []
    
    public weak var delegate: MQTTManagerDelegate?
    public private(set) var connectionState: MQTTConnectionState = .disconnected {
        didSet {
            delegate?.mqttManager(self, didChangeState: connectionState)
        }
    }
    
    // MARK: - 初始化
    
    public init(configuration: MQTTConfiguration) {
        self.configuration = configuration
        setupMQTTClient()
    }
    
    deinit {
        disconnect()
        reconnectTimer?.invalidate()
    }
    
    // MARK: - 配置设置
    
    private func setupMQTTClient() {
        mqtt = CocoaMQTT(clientID: configuration.clientID, host: configuration.host, port: configuration.port)
        mqtt?.username = configuration.username
        mqtt?.password = configuration.password
        mqtt?.keepAlive = configuration.keepAlive
        mqtt?.cleanSession = configuration.cleanSession
        mqtt?.delegate = self
        mqtt?.autoReconnect = false // 使用自定义重连逻辑
    }
    
    // MARK: - 连接管理
    
    /// 连接到MQTT代理
    public func connect() {
        guard let mqtt = mqtt else { return }
        
        connectionState = .connecting
        do {
            try mqtt.connect()
        } catch {
            handleConnectionError(error)
        }
    }
    
    /// 断开MQTT连接
    public func disconnect() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        mqtt?.disconnect()
        connectionState = .disconnected
    }
    
    /// 重新连接
    public func reconnect() {
        guard configuration.autoReconnect else { return }
        disconnect()
        setupMQTTClient()
        connect()
    }
    
    // MARK: - 消息发布
    
    /// 发布消息到指定主题
    /// - Parameters:
    ///   - message: 消息内容
    ///   - topic: 主题名称
    ///   - qos: 服务质量级别
    /// - Returns: 是否发布成功
    @discardableResult
    public func publish(message: String, to topic: String, qos: CocoaMQTTQoS = .qos1) -> Bool {
        guard let mqtt = mqtt, connectionState == .connected else {
            return false
        }
        
        mqtt.publish(topic, withString: message, qos: qos)
        delegate?.mqttManager(self, didPublishMessage: message, toTopic: topic)
        return true
    }
    
    // MARK: - 主题订阅
    
    /// 订阅主题
    /// - Parameters:
    ///   - topic: 主题名称
    ///   - qos: 服务质量级别
    public func subscribe(to topic: String, qos: CocoaMQTTQoS = .qos1) {
        guard let mqtt = mqtt, connectionState == .connected else { return }
        
        mqtt.subscribe(topic, qos: qos)
        subscribedTopics.insert(topic)
    }
    
    /// 取消订阅主题
    /// - Parameter topic: 主题名称
    public func unsubscribe(from topic: String) {
        guard let mqtt = mqtt, connectionState == .connected else { return }
        
        mqtt.unsubscribe(topic)
        subscribedTopics.remove(topic)
    }
    
    /// 重新订阅之前的所有主题（用于重连后恢复订阅）
    private func resubscribeToTopics() {
        guard let mqtt = mqtt, connectionState == .connected else { return }
        
        for topic in subscribedTopics {
            mqtt.subscribe(topic)
        }
    }
    
    // MARK: - 自动重连逻辑
    
    private func scheduleReconnect() {
        guard configuration.autoReconnect else { return }
        
        reconnectTimer?.invalidate()
        
        // 使用指数退避算法计算重连间隔
        currentReconnectInterval = min(
            currentReconnectInterval * 2,
            configuration.maxReconnectInterval
        )
        
        if currentReconnectInterval == 0 {
            currentReconnectInterval = configuration.reconnectInterval
        }
        
        reconnectTimer = Timer.scheduledTimer(
            timeInterval: currentReconnectInterval,
            target: self,
            selector: #selector(performReconnect),
            userInfo: nil,
            repeats: false
        )
    }
    
    @objc private func performReconnect() {
        reconnect()
    }
    
    private func handleConnectionError(_ error: Error) {
        delegate?.mqttManager(self, connectionDidFailWithError: error)
        connectionState = .disconnected
        
        if configuration.autoReconnect {
            scheduleReconnect()
        }
    }
    
    // MARK: - CocoaMQTTDelegate
    
    public func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        switch ack {
        case .accept:
            connectionState = .connected
            currentReconnectInterval = 0 // 重置重连间隔
            resubscribeToTopics() // 恢复订阅
        default:
            handleConnectionError(NSError(domain: "MQTT", code: Int(ack.rawValue), userInfo: [NSLocalizedDescriptionKey: "连接被拒绝"])
        }
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didStateChangeTo state: CocoaMQTTConnState) {
        switch state {
        case .connected:
            connectionState = .connected
        case .connecting:
            connectionState = .connecting
        case .disconnected:
            connectionState = .disconnected
        }
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        let payload = String(data: message.payload, encoding: .utf8) ?? ""
        delegate?.mqttManager(self, didReceiveMessage: payload, fromTopic: message.topic)
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        let payload = String(data: message.payload, encoding: .utf8) ?? ""
        delegate?.mqttManager(self, didPublishMessage: payload, toTopic: message.topic)
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topic: String) {
        print("成功订阅主题: \(topic)")
    }
    
    public func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
        print("成功取消订阅主题: \(topic)")
    }
    
    public func mqttDidPing(_ mqtt: CocoaMQTT) {
        print("发送心跳ping")
    }
    
    public func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        print("收到心跳pong")
    }
    
    public func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        if let error = err {
            handleConnectionError(error)
        } else {
            connectionState = .disconnected
        }
    }
}


// MARK: - 便捷方法扩展
extension MQTTManager {
    
    /// 便捷初始化方法
    /// - Parameters:
    ///   - host: 服务器地址
    ///   - port: 端口号
    ///   - clientID: 客户端ID
    public convenience init(host: String, port: UInt16 = 1883, clientID: String? = nil) {
        let configuration = MQTTConfiguration(
            host: host,
            port: port,
            clientID: clientID
        )
        self.init(configuration: configuration)
    }
    
    /// 检查是否已连接到指定主题
    /// - Parameter topic: 主题名称
    /// - Returns: 是否已订阅
    public func isSubscribed(to topic: String) -> Bool {
        return subscribedTopics.contains(topic)
    }
    
    /// 获取当前已订阅的所有主题
    /// - Returns: 主题名称数组
    public func getAllSubscribedTopics() -> [String] {
        return Array(subscribedTopics)
    }
    
    /// 批量订阅主题
    /// - Parameters:
    ///   - topics: 主题名称数组
    ///   - qos: 服务质量级别
    public func subscribe(to topics: [String], qos: CocoaMQTTQoS = .qos1) {
        for topic in topics {
            subscribe(to: topic, qos: qos)
        }
    }
    
    /// 批量取消订阅主题
    /// - Parameter topics: 主题名称数组
    public func unsubscribe(from topics: [String]) {
        for topic in topics {
            unsubscribe(from: topic)
        }
    }
}

// MARK: - 连接状态检查
extension MQTTManager {
    
    /// 检查当前连接状态
    /// - Returns: 是否已连接
    public var isConnected: Bool {
        return connectionState == .connected
    }
    
    /// 检查是否正在连接中
    /// - Returns: 是否正在连接
    public var isConnecting: Bool {
        return connectionState == .connecting
    }
    
    /// 检查是否正在重连中
    /// - Returns: 是否正在重连
    public var isReconnecting: Bool {
        return connectionState == .reconnecting
    }
}

// MARK: - 配置管理
extension MQTTManager {
    
    /// 更新MQTT配置
    /// - Parameter newConfiguration: 新的配置
    public func updateConfiguration(_ newConfiguration: MQTTConfiguration) {
        let wasConnected = isConnected
        
        disconnect()
        configuration = newConfiguration
        setupMQTTClient()
        
        if wasConnected {
            connect()
        }
    }
    
    /// 获取当前配置的副本
    /// - Returns: 当前配置
    public func getCurrentConfiguration() -> MQTTConfiguration {
        return configuration
    }
}

////////////////////////////////////////////////////

// MARK: - 单例模式支持
extension MQTTManager {
    
    /// 全局共享的MQTT管理器实例
    public static let shared = MQTTManager(
        configuration: MQTTConfiguration(
            host: "localhost",
            port: 1883,
            clientID: "iOS_Shared_Client"
        )
    )
    
    /// 快速配置共享实例
    /// - Parameters:
    ///   - host: MQTT服务器地址
    ///   - port: 端口号
    ///   - clientID: 客户端ID
    public static func configureSharedInstance(host: String, port: UInt16 = 1883, clientID: String? = nil) {
        let configuration = MQTTConfiguration(
            host: host,
            port: port,
            clientID: clientID ?? "iOS_Shared_Client_\(UUID().uuidString)"
        )
        shared.updateConfiguration(configuration)
    }
}

// MARK: - 消息模型支持
public struct MQTTMessage {
    public let topic: String
    public let payload: String
    public let qos: CocoaMQTTQoS
    public let retained: Bool
    public let timestamp: Date
    
    public init(topic: String, payload: String, qos: CocoaMQTTQoS = .qos1, retained: Bool = false) {
        self.topic = topic
        self.payload = payload
        self.qos = qos
        self.retained = retained
        self.timestamp = Date()
    }
}

// MARK: - 主题通配符支持
extension MQTTManager {
    
    /// 使用通配符订阅主题
    /// - Parameters:
    ///   - topicPattern: 主题模式（可包含通配符 + 和 #）
    ///   - qos: 服务质量级别
    public func subscribeWithWildcard(to topicPattern: String, qos: CocoaMQTTQoS = .qos1) {
        subscribe(to: topicPattern, qos: qos)
    }
    
    /// 检查主题是否匹配给定的通配符模式
    /// - Parameters:
    ///   - topic: 实际主题
    ///   - pattern: 通配符模式
    /// - Returns: 是否匹配
    public static func matchTopic(_ topic: String, to pattern: String) -> Bool {
        // 简化的通配符匹配逻辑
        let topicParts = topic.split(separator: "/")
        let patternParts = pattern.split(separator: "/")
        
        guard topicParts.count == patternParts.count else { return false }
        
        for (topicPart, patternPart) in zip(topicParts, patternParts) {
            if patternPart == "+" {
                continue // 单层通配符，匹配任意值
            } else if patternPart == "#" {
                return true // 多层通配符，匹配剩余所有
            } else if topicPart != patternPart {
                return false
            }
        }
        
        return true
    }
}

// MARK: - 错误处理
public enum MQTTError: Error {
    case notConnected
    case connectionFailed
    case subscriptionFailed
    case publishFailed
    case invalidTopic
    case timeout
    
    public var localizedDescription: String {
        switch self {
        case .notConnected:
            return "MQTT未连接"
        case .connectionFailed:
            return "MQTT连接失败"
        case .subscriptionFailed:
            return "MQTT订阅失败"
        case .publishFailed:
            return "MQTT发布失败"
        case .invalidTopic:
            return "无效的主题名称"
        case .timeout:
            return "MQTT操作超时"
        }
    }
}
