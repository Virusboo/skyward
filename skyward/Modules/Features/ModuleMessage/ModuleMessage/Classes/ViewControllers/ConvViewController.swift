//
//  ConvViewController.swift
//  ModuleMessage
//
//  Created by zhaobo on 2025/11/19.
//

import TXKit
import SnapKit
import SWTheme

class ConvViewController: BaseViewController {
    var tableView: UITableView!
    
    private var messages: [Message] = []
    
    private let inputContainerView = UIView()
    private let messageInputTextView = UITextView()
    private let sendButton = UIButton(type: .system)
    
    // 当前用户
    private let currentUser = User(id: "current_user", name: "赵波", avatarUrl: "avatar_sos", isCurrentUser: true)
    
    // 对方用户
    private let otherUser = User(id: "other_user", name: "李芳敏", avatarUrl: "avatar_service", isCurrentUser: false)
    
    // MARK: - Override
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = otherUser.name
        view.backgroundColor = ThemeManager.current.backgroundColor
        setupTableView()
        loadSampleData()
    }
    
    private func setupTableView() {
        // 初始化 tableView
        tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        
        tableView.register(cellType: MessageCell.self)
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.keyboardDismissMode = .onDrag // 滑动隐藏键盘
        view.addSubview(tableView)
        
        // 设置输入容器
        inputContainerView.backgroundColor = UIColor.systemGray6
        inputContainerView.layer.cornerRadius = 16
        inputContainerView.clipsToBounds = true
        view.addSubview(inputContainerView)
        
        // 设置输入框
        messageInputTextView.font = UIFont.systemFont(ofSize: 16)
        messageInputTextView.text = "请输入消息..."
        messageInputTextView.textColor = UIColor.placeholderText
        messageInputTextView.layer.cornerRadius = 12
        messageInputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        messageInputTextView.isScrollEnabled = false
        messageInputTextView.delegate = self
        inputContainerView.addSubview(messageInputTextView)
        
        // 设置发送按钮
        sendButton.setTitle("发送", for: .normal)
        sendButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.backgroundColor = UIColor.systemBlue
        sendButton.layer.cornerRadius = 12
        sendButton.isEnabled = false // 初始禁用
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        inputContainerView.addSubview(sendButton)
        
        // 布局
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(inputContainerView.snp.top).offset(-8)
        }
        
        inputContainerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-8)
            make.height.equalTo(50)
        }
        
        messageInputTextView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(4)
            make.leading.equalToSuperview().offset(8)
            make.trailing.equalTo(sendButton.snp.leading).offset(-8)
        }
        
        sendButton.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(6)
            make.trailing.equalToSuperview().offset(-8)
            make.width.equalTo(60)
        }
    }
    
    private func loadSampleData() {        
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        let keyboardHeight = keyboardFrame.height
        tableView.contentInset.bottom = keyboardHeight + 64 // 64 = inputContainer高度 + 间距
        tableView.scrollIndicatorInsets.bottom = keyboardHeight + 64
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        tableView.contentInset.bottom = 0
        tableView.scrollIndicatorInsets.bottom = 0
    }
    
    @objc private func sendButtonTapped() {
            let content = messageInputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !content.isEmpty, content != "请输入消息..." else { return }
            
            // 创建新消息
            let newMessage = Message(id: "6", content: content, sender: currentUser, timestamp: Date())
        
            messages.append(newMessage)
            tableView.reloadData()
            tableView.scrollToRow(at: IndexPath(row: messages.count - 1, section: 0), at: .bottom, animated: true)
            
            // 清空输入框
            messageInputTextView.text = ""
            messageInputTextView.textColor = UIColor.placeholderText
            sendButton.isEnabled = false
            sendButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.5)
        }
    
}

extension ConvViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath, cellType: MessageCell.self)
        cell.configure(with: messages[indexPath.row])
        return cell
    }
}

extension ConvViewController: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "请输入消息..." {
            textView.text = ""
            textView.textColor = .label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "请输入消息..."
            textView.textColor = UIColor.placeholderText
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        let hasContent = !(textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        sendButton.isEnabled = hasContent
        sendButton.backgroundColor = hasContent ? UIColor.systemBlue : UIColor.systemBlue.withAlphaComponent(0.5)
        
        // 自动调整高度（可选，本例固定高度）
        // 如果需要动态高度，可监听 contentSize 并更新约束
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            // 回车即发送
            sendButtonTapped()
            return false
        }
        return true
    }
}
