//
//  Conversation2ViewController.swift
//  ModuleMessage
//  Created by zhaobo on 2025/11/19.

import TXKit

class Conversation2ViewController: BaseViewController {
    // 消息列表
    private var messages: [Message] = []
    
    // 消息表格视图
    private var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .interactive
        return tableView
    }()
    
    // 输入栏
    private var inputContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    // 输入框
    private var messageInputField: UITextField = {
        let textField = UITextField()
        textField.backgroundColor = UIColor(red: 0.94, green: 0.94, blue: 0.94, alpha: 1.0)
        textField.layer.cornerRadius = 20
        textField.placeholder = "输入消息..."
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.returnKeyType = .send
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 0))
        textField.leftViewMode = .always
        return textField
    }()
    
    // 发送按钮
    private var sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("发送", for: .normal)
        button.setTitleColor(.orange, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        return button
    }()
    
    // 当前用户
    private let currentUser = User(id: "current_user", name: "赵波", avatarUrl: "avatar_sos", isCurrentUser: true)
    
    // 对方用户
    private let otherUser = User(id: "other_user", name: "李芳敏", avatarUrl: "avatar_service", isCurrentUser: false)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupData()
        setupActions()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
        title = "聊天消息"
        
        view.addSubview(tableView)
        view.addSubview(inputContainerView)
        inputContainerView.addSubview(messageInputField)
        inputContainerView.addSubview(sendButton)
        
        tableView.register(MessageCell.self, forCellReuseIdentifier: "MessageCell")
    }
    
    public override func setupConstraints() {
        super.setupConstraints()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputContainerView.topAnchor)
        ])
        
        inputContainerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            inputContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            inputContainerView.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        messageInputField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            messageInputField.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 15),
            messageInputField.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor),
            messageInputField.heightAnchor.constraint(equalToConstant: 40),
            messageInputField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -10)
        ])
        
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sendButton.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -15),
            sendButton.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    private func setupData() {
        // 初始化测试数据
        messages = [
            Message(id: "1", content: "你好，最近怎么样？", sender: otherUser, timestamp: Date().addingTimeInterval(-3600)),
            Message(id: "2", content: "挺不错的，你呢？", sender: currentUser, timestamp: Date().addingTimeInterval(-3590)),
            Message(id: "3", content: "我也挺好的，工作有点忙", sender: otherUser, timestamp: Date().addingTimeInterval(120)),
            Message(id: "4", content: "要注意休息啊", sender: currentUser, timestamp: Date().addingTimeInterval(180)),
            Message(id: "5", content: "谢谢关心，我会的。你最近在做什么项目？", sender: otherUser, timestamp: Date().addingTimeInterval(240))
        ]
        messages = [
            Message(id: "1", content: "[SOS紧急求助] 上报成功，已成功上报给紧急联系人188888888", sender: otherUser, timestamp: Date().addingTimeInterval(-3600)),
            Message(id: "2", content: "[安全上报] 上报成功，已成功上报给紧急联系人188888888", sender: currentUser, timestamp: Date().addingTimeInterval(-3590)),
            Message(id: "3", content: "我这边联系人去支援你我在阿拉善一个沙丘附近，车坏了不能行驶。需要水源、交通工具等紧急物资", sender: otherUser, timestamp: Date().addingTimeInterval(120)),
            Message(id: "4", content: "天气预警：阿拉善气象台2025年08月27日发布暴雨黄色预警，气温29℃，东北风6级，能见度5km，未来2小时内有短时强降水，山体", sender: currentUser, timestamp: Date().addingTimeInterval(180)),
            Message(id: "5", content: "谢谢关心，我会的。你最近在做什么项目？", sender: otherUser, timestamp: Date().addingTimeInterval(240))
        ]
    }
    
    private func setupActions() {
        tableView.delegate = self
        tableView.dataSource = self
        messageInputField.delegate = self
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
    }
    
    @objc private func sendButtonTapped() {
        sendMessage()
    }
    
    private func sendMessage() {
        guard let text = messageInputField.text, !text.isEmpty else { return }
        
        let newMessage = Message(id: UUID().uuidString, content: text, sender: currentUser, timestamp: Date())
        messages.append(newMessage)
        messageInputField.text = nil
        tableView.reloadData()
        scrollToBottom()
        
        // 模拟自动回复
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let replyMessage = Message(id: UUID().uuidString, content: "这是一条自动回复消息", sender: self.otherUser, timestamp: Date())
            self.messages.append(replyMessage)
            self.tableView.reloadData()
            self.scrollToBottom()
        }
    }
    
    private func scrollToBottom() {
        if messages.count > 0 {
            let indexPath = IndexPath(row: messages.count - 1, section: 0)
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension Conversation2ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as? MessageCell else {
            return UITableViewCell()
        }
        
        let message = messages[indexPath.row]
        cell.configure(with: message)
        
        return cell
    }
}

// MARK: - UITextFieldDelegate
extension Conversation2ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendMessage()
        return true
    }
}
