//
//  MQTTManager2.swift
//  SWNetwork
//
//  Created by 赵波 on 2025/11/19.
//

import Foundation
import CocoaMQTT

protocol MQTTManagerDelegate: AnyObject {
    func mqttDidConnect(_ manager: MQTTManager)
    func mqttDidDisconnect(_ manager: MQTTManager, with error: Error?)
    func mqtt(_ manager: MQTTManager, didReceive message: CocoaMQTTMessage, on topic: String)
    func mqtt(_ manager: MQTTManager, didPublishMessageWith messageId: UInt16)
}

class MQTTManager: NSObject {
    
    // MARK: - Properties
    
    private var client: CocoaMQTT!
    private let host: String
    private let port: UInt16
    private let clientId: String
    private let username: String?
    private let password: String?
    private let cleanSession: Bool
    
    weak var delegate: MQTTManagerDelegate?
    
    // MARK: - Initialization
    
    init(host: String,
         port: UInt16 = 1883,
         clientId: String = UUID().uuidString,
         username: String? = nil,
         password: String? = nil,
         cleanSession: Bool = true) {
        self.host = host
        self.port = port
        self.clientId = clientId
        self.username = username
        self.password = password
        self.cleanSession = cleanSession
        super.init()
        
        setupMQTTClient()
    }
    
    private func setupMQTTClient() {
        client = CocoaMQTT(clientID: clientId, host: host, port: port)
        client.delegate = self
        client.username = username
        client.password = password
        client.cleanSession = cleanSession
        client.keepAlive = 60
        client.willMessage = nil // 可选：设置遗嘱消息
    }
    
    // MARK: - Public API
    
    func connect() {
        client.connect()
    }
    
    func disconnect() {
        client.disconnect()
    }
    
    func subscribe(_ topic: String, qos: CocoaMQTTQOS = .qos1) {
        client.subscribe(topic, qos: qos)
    }
    
    func unsubscribe(_ topic: String) {
        client.unsubscribe(topic)
    }
    
    func publish(_ topic: String, payload: String, qos: CocoaMQTTQOS = .qos1, retained: Bool = false) {
        let data = payload.data(using: .utf8)!
        let message = CocoaMQTTMessage(topic: topic, string: payload)
        message.qos = qos
        message.retained = retained
        client.publish(message)
    }
    
    func isConnected() -> Bool {
        return client.status == .connected
    }
}

// MARK: - CocoaMQTTDelegate

extension MQTTManager: CocoaMQTTDelegate {
    
    func mqtt(_ mqtt: CocoaMQTT, didConnect ack: Bool) {
        if ack {
            delegate?.mqttDidConnect(self)
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        // 可根据 ack 做更细粒度处理
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        delegate?.mqtt(self, didPublishMessageWith: id)
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        // 可选：确认 QoS1 消息已送达
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        guard let topic = message.topic else { return }
        delegate?.mqtt(self, didReceive: message, on: topic)
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topic: String) {
        // 可选：订阅成功回调
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
        // 可选：取消订阅回调
    }
    
    func mqttDidPing(_ mqtt: CocoaMQTT) {}
    
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {}
    
    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        delegate?.mqttDidDisconnect(self, with: err)
    }
}


class MyViewController: UIViewController {
    private var mqttManager: MQTTManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mqttManager = MQTTManager(
            host: "broker.hivemq.com",
            port: 1883,
            clientId: "MyAppClient",
            username: nil,
            password: nil
        )
        mqttManager.delegate = self
        
        mqttManager.connect()
        mqttManager.subscribe("test/topic")
    }
    
    @IBAction func sendMessageButtonTapped(_ sender: Any) {
        mqttManager.publish("test/topic", payload: "Hello from Swift!")
    }
}

extension MyViewController: MQTTManagerDelegate {
    func mqttDidConnect(_ manager: MQTTManager) {
        print("✅ MQTT connected")
    }
    
    func mqttDidDisconnect(_ manager: MQTTManager, with error: Error?) {
        print("❌ MQTT disconnected: \(error?.localizedDescription ?? "unknown")")
    }
    
    func mqtt(_ manager: MQTTManager, didReceive message: CocoaMQTTMessage, on topic: String) {
        if let payload = String(data: message.payload, encoding: .utf8) {
            print("📥 Received on \(topic): \(payload)")
        }
    }
    
    func mqtt(_ manager: MQTTManager, didPublishMessageWith messageId: UInt16) {
        print("📤 Message published with ID: \(messageId)")
    }
}
