//
//  MQTTUsageExample.swift
//  SWNetwork
//
//  Created by AI Assistant on 2025/11/19.
//

import Foundation
import CocoaMQTT

/// MQTTManager 使用示例和最佳实践
public class MQTTUsageExample {
    
    // MARK: - 基本使用示例
    
    /// 示例1: 基本连接和消息处理
    func basicUsageExample() {
        // 创建配置
        let configuration = MQTTConfiguration(
            host: "broker.hivemq.com",
            port: 1883,
            clientID: "iOS_Client_Demo",
            username: nil,
            password: nil,
            keepAlive: 60,
            cleanSession: true,
            autoReconnect: true
        )
        
        // 创建MQTT管理器
        let mqttManager = MQTTManager(configuration: configuration)
        
        // 设置代理
        mqttManager.delegate = self
        
        // 连接
        mqttManager.connect()
        
        // 订阅主题
        mqttManager.subscribe(to: "test/topic", qos: .qos1)
        
        // 发布消息
        mqttManager.publish(message: "Hello MQTT", to: "test/topic", qos: .qos1)
    }
    
    /// 示例2: 使用单例模式
    func singletonUsageExample() {
        // 配置共享实例
        MQTTManager.configureSharedInstance(host: "broker.hivemq.com", port: 1883)
        
        // 获取共享实例
        let mqttManager = MQTTManager.shared
        
        // 设置代理
        mqttManager.delegate = self
        
        // 连接
        mqttManager.connect()
    }
    
    /// 示例3: 聊天应用中的使用
    func chatApplicationExample() {
        let userId = "user123"
        let chatRoomId = "room456"
        
        // 创建聊天相关的主题
        let messageTopic = "chat/\(chatRoomId)/messages"
        let presenceTopic = "chat/\(chatRoomId)/presence"
        let typingTopic = "chat/\(chatRoomId)/typing"
        
        // 配置MQTT
        let configuration = MQTTConfiguration(
            host: "your-mqtt-server.com",
            port: 1883,
            clientID: "chat_\(userId)",
            cleanSession: false, // 保持会话
            autoReconnect: true
        )
        
        let mqttManager = MQTTManager(configuration: configuration)
        mqttManager.delegate = self
        
        // 连接成功后订阅相关主题
        mqttManager.connect()
    }
    
    /// 示例4: IoT设备控制
    func iotControlExample() {
        let deviceId = "device001"
        
        // 创建设备相关的主题
        let commandTopic = "devices/\(deviceId)/command"
        let statusTopic = "devices/\(deviceId)/status"
        let telemetryTopic = "devices/\(deviceId)/telemetry"
        
        let configuration = MQTTConfiguration(
            host: "iot.eclipse.org",
            port: 1883,
            clientID: "ios_controller_\(deviceId)",
            keepAlive: 30, // IoT设备通常需要更短的心跳
            autoReconnect: true
        )
        
        let mqttManager = MQTTManager(configuration: configuration)
        mqttManager.delegate = self
        
        // 订阅设备状态
        mqttManager.subscribe(to: statusTopic)
        mqttManager.subscribe(to: telemetryTopic)
        
        // 连接
        mqttManager.connect()
        
        // 发送控制命令
        let command = "{\"action\":\"turn_on\",\"timestamp\":\(Date().timeIntervalSince1970)}"
        mqttManager.publish(message: command, to: commandTopic, qos: .qos1)
    }
    
    // MARK: - 高级功能示例
    
    /// 示例5: 通配符订阅
    func wildcardSubscriptionExample() {
        let mqttManager = MQTTManager.shared
        
        // 订阅所有设备的状态（使用通配符）
        mqttManager.subscribeWithWildcard(to: "devices/+/status")
        
        // 订阅所有传感器数据
        mqttManager.subscribeWithWildcard(to: "sensors/#")
        
        // 检查主题匹配
        let matches = MQTTManager.matchTopic("devices/device123/status", to: "devices/+/status")
        print("主题匹配结果: \(matches)")
    }
    
    /// 示例6: 消息模型使用
    func messageModelExample() {
        // 创建消息模型
        let message = MQTTMessage(
            topic: "chat/general",
            payload: "Hello, World!",
            qos: .qos1,
            retained: false
        )
        
        // 使用消息模型发布
        let mqttManager = MQTTManager.shared
        mqttManager.publish(message: message.payload, to: message.topic, qos: message.qos)
    }
    
    /// 示例7: 错误处理
    func errorHandlingExample() {
        let mqttManager = MQTTManager.shared
        mqttManager.delegate = self
        
        // 检查连接状态
        if mqttManager.isConnected {
            // 执行MQTT操作
            mqttManager.publish(message: "Test", to: "test/topic")
        } else {
            print("MQTT未连接，请先连接")
            // 处理错误情况
        }
    }
    
    /// 示例8: 批量操作
    func batchOperationsExample() {
        let mqttManager = MQTTManager.shared
        
        // 批量订阅
        let topics = ["topic1", "topic2", "topic3"]
        mqttManager.subscribe(to: topics)
        
        // 批量取消订阅
        mqttManager.unsubscribe(from: topics)
        
        // 获取所有已订阅的主题
        let subscribedTopics = mqttManager.getAllSubscribedTopics()
        print("已订阅的主题: \(subscribedTopics)")
    }
}

// MARK: - MQTTManagerDelegate 实现示例

extension MQTTUsageExample: MQTTManagerDelegate {
    
    public func mqttManager(_ manager: MQTTManager, didChangeState state: MQTTConnectionState) {
        switch state {
        case .connecting:
            print("MQTT正在连接...")
        case .connected:
            print("MQTT已连接")
            // 连接成功后可以执行订阅等操作
        case .disconnected:
            print("MQTT已断开")
        case .reconnecting:
            print("MQTT正在重连...")
        }
    }
    
    public func mqttManager(_ manager: MQTTManager, didReceiveMessage message: String, fromTopic topic: String) {
        print("收到消息 - 主题: \(topic), 内容: \(message)")
        
        // 根据主题处理不同的消息
        if topic.contains("chat") {
            handleChatMessage(message, topic: topic)
        } else if topic.contains("devices") {
            handleDeviceMessage(message, topic: topic)
        }
    }
    
    public func mqttManager(_ manager: MQTTManager, didPublishMessage message: String, toTopic topic: String) {
        print("消息发布成功 - 主题: \(topic), 内容: \(message)")
    }
    
    public func mqttManager(_ manager: MQTTManager, connectionDidFailWithError error: Error?) {
        print("MQTT连接失败: \(error?.localizedDescription ?? "未知错误")")
        // 处理连接失败，可以显示错误提示给用户
    }
    
    // 处理聊天消息
    private func handleChatMessage(_ message: String, topic: String) {
        // 解析消息并更新UI
        print("处理聊天消息: \(message)")
    }
    
    // 处理设备消息
    private func handleDeviceMessage(_ message: String, topic: String) {
        // 解析设备数据并更新状态
        print("处理设备消息: \(message)")
    }
}

// MARK: - 最佳实践建议

/*
 MQTTManager 使用最佳实践：
 
 1. 连接管理：
    - 在应用启动时连接，在应用进入后台时考虑断开连接
    - 使用自动重连功能处理网络不稳定情况
    - 监听连接状态变化并给用户适当的反馈
 
 2. 主题设计：
    - 使用清晰的主题层级结构，如：app/functionality/specific
    - 避免使用过多的通配符订阅，可能影响性能
    - 为不同功能模块设计独立的主题空间
 
 3. 消息处理：
    - 在主线程中更新UI，MQTT回调可能在后台线程
    - 实现消息去重机制，避免重复处理相同消息
    - 对重要消息使用QoS 1或QoS 2保证送达
 
 4. 性能优化：
    - 合理设置keep-alive间隔，平衡电量消耗和连接稳定性
    - 批量处理消息，避免频繁的小消息
    - 及时清理不再需要的订阅
 
 5. 错误处理：
    - 实现完善的错误处理机制
    - 给用户清晰的错误提示
    - 记录错误日志便于调试
 
 6. 安全性：
    - 使用TLS/SSL加密连接
    - 实现身份验证机制
    - 对敏感数据进行加密
 */



import UIKit

// 示例：在ViewController中使用MQTTManager
class ViewController: UIViewController {
    
    private var mqttManager: MQTTManager!
    private var statusLabel: UILabel!
    private var messageTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupMQTT()
    }
    
    private func setupUI() {
        // 创建状态标签
        statusLabel = UILabel()
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.textAlignment = .center
        statusLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        view.addSubview(statusLabel)
        
        // 创建消息显示文本框
        messageTextView = UITextView()
        messageTextView.translatesAutoresizingMaskIntoConstraints = false
        messageTextView.isEditable = false
        messageTextView.font = UIFont.systemFont(ofSize: 14)
        view.addSubview(messageTextView)
        
        // 设置约束
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            statusLabel.heightAnchor.constraint(equalToConstant: 30),
            
            messageTextView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20),
            messageTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            messageTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            messageTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupMQTT() {
        // 创建配置
        let configuration = MQTTConfiguration(
            host: "broker.emqx.io",
            port: 1883,
            clientID: "iOS_Example_App",
            username: nil,
            password: nil,
            keepAlive: 60,
            cleanSession: false,
            autoReconnect: true,
            reconnectInterval: 1.0,
            maxReconnectInterval: 60.0
        )
        
        // 初始化MQTT管理器
        mqttManager = MQTTManager(configuration: configuration)
        mqttManager.delegate = self
        
        // 连接MQTT代理
        mqttManager.connect()
        
        // 订阅示例主题
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.mqttManager.subscribe(to: "ios/demo/messages", qos: .qos1)
        }
    }
    
    func publishMessageTapped(_ sender: UIButton) {
        let message = "Hello from iOS at \(Date())"
        mqttManager.publish(message: message, to: "ios/demo/publish")
    }
    
   func reconnectTapped(_ sender: UIButton) {
        mqttManager.reconnect()
    }
}

// MARK: - MQTTManagerDelegate实现
extension ViewController: MQTTManagerDelegate {
    
    func mqttManager(_ manager: MQTTManager, didChangeState state: MQTTConnectionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                self.statusLabel.text = "状态：已连接"
                self.statusLabel.textColor = .systemGreen
            case .connecting:
                self.statusLabel.text = "状态：连接中..."
                self.statusLabel.textColor = .systemOrange
            case .disconnected:
                self.statusLabel.text = "状态：已断开"
                self.statusLabel.textColor = .systemRed
            case .reconnecting:
                self.statusLabel.text = "状态：重连中..."
                self.statusLabel.textColor = .systemYellow
            }
        }
    }
    
    func mqttManager(_ manager: MQTTManager, didReceiveMessage message: String, fromTopic topic: String) {
        DispatchQueue.main.async {
            let currentText = self.messageTextView.text ?? ""
            let newMessage = "[\(Date())] 主题: \(topic)\n消息: \(message)\n\n"
            self.messageTextView.text = newMessage + currentText
        }
    }
    
    func mqttManager(_ manager: MQTTManager, didPublishMessage message: String, toTopic topic: String) {
            print("消息发布成功到主题: \(topic)")
        }
    
    func mqttManager(_ manager: MQTTManager, connectionDidFailWithError error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                let alert = UIAlertController(
                    title: "连接失败",
                    message: error.localizedDescription,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "确定", style: .default))
                self.present(alert, animated: true)
            }
        }
    }
}
