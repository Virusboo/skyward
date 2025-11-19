//
//  InputFieldDelegate.swift
//  TXTS
//
//  Created by yifan kang on 2025/11/11.
//


import UIKit

// MARK: - 输入框协议
protocol InputFieldDelegate: AnyObject {
    func inputFieldDidBeginEditing(_ inputField: BaseInputField)
    func inputFieldDidEndEditing(_ inputField: BaseInputField)
    func inputFieldTextDidChange(_ inputField: BaseInputField, text: String)
}

// MARK: - 输入验证规则
enum InputValidationRule {
    case none
    case phone
    case password
    case custom(regex: String)
    
    func validate(_ text: String) -> Bool {
        switch self {
        case .none:
            return true
        case .phone:
            let phoneRegex = "^1[0-9]{10}$"
            return NSPredicate(format: "SELF MATCHES %@", phoneRegex).evaluate(with: text)
        case .password:
            return text.count >= 6 && text.count <= 20
        case .custom(let regex):
            return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: text)
        }
    }
}

// MARK: - 基础输入框
class BaseInputField: UIView {
    
    // MARK: - UI Components
    let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#F2F3F4")
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.clear.cgColor
        return view
    }()
    
    let textField: UITextField = {
        let textField = UITextField()
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.textColor = .black
        textField.tintColor = .black
        return textField
    }()
    
    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor(hex: "#999999")
        label.isHidden = true
        return label
    }()
    
    var errorColor: UIColor = defaultOrangeColor
    var normalBorderColor: UIColor = .clear
    
    // MARK: - 新增错误状态相关
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .orange
        label.isHidden = true
        label.numberOfLines = 0
        return label
    }()
    
    // MARK: - 高度约束（改为可调整的）
    private var containerHeightConstraint: NSLayoutConstraint!
    private var totalHeightConstraint: NSLayoutConstraint!
    
    // MARK: - Properties
    weak var delegate: InputFieldDelegate?
    var validationRule: InputValidationRule = .none
    var placeholder: String = "" {
        didSet {
            placeholderLabel.text = placeholder
            textField.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [.foregroundColor: UIColor(hex: "#999999")]
            )
        }
    }
    
    var text: String {
        return textField.text ?? ""
    }
    
    // MARK: - 可配置的高度
    var containerHeight: CGFloat = 60 {
        didSet {
            containerHeightConstraint.constant = containerHeight
        }
    }
    
    var totalHeight: CGFloat = 80 {
        didSet {
            totalHeightConstraint.constant = totalHeight
        }
    }
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        containerHeightConstraint = containerView.heightAnchor.constraint(equalToConstant: containerHeight)
        totalHeightConstraint = heightAnchor.constraint(equalToConstant: totalHeight)
        
        setupUI()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupActions()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        addSubview(containerView)
        containerView.addSubview(textField)
        containerView.addSubview(placeholderLabel)
        addSubview(errorLabel)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        textField.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerHeightConstraint, // 增加高度
            
            textField.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            textField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            textField.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            
            placeholderLabel.leadingAnchor.constraint(equalTo: textField.leadingAnchor),
            placeholderLabel.centerYAnchor.constraint(equalTo: textField.centerYAnchor),
            
            errorLabel.topAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 4),
            errorLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            errorLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            errorLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            totalHeightConstraint
        ])
    }
    
    private func setupActions() {
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        textField.delegate = self
    }
    
    // 重写 hitTest 方法来处理触摸事件
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        
        // 如果点击的是输入框以外的区域，并且键盘是弹出的，则收起键盘
        if view != textField && textField.isFirstResponder {
            textField.resignFirstResponder()
        }
        
        return view
    }
    
    // MARK: - Public Methods
    func setValidationRule(_ rule: InputValidationRule) {
        self.validationRule = rule
    }
    
    func validate() -> Bool {
        return validationRule.validate(text)
    }
    
    // MARK: - Actions
    @objc func textFieldDidChange() {
        delegate?.inputFieldTextDidChange(self, text: text)
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        endEditing(true)
    }
    
    private func updatePlaceholderVisibility() {
        let shouldShowPlaceholder = text.isEmpty && !textField.isFirstResponder
        placeholderLabel.isHidden = !shouldShowPlaceholder
        textField.attributedPlaceholder = shouldShowPlaceholder ? 
            NSAttributedString(string: placeholder, attributes: [.foregroundColor: UIColor(hex: "#999999")]) : nil
    }
    
    // MARK: - 新增错误状态方法
    func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
        
        // 设置错误状态的边框颜色
        containerView.layer.borderColor = errorColor.cgColor
        containerView.layer.borderWidth = 1
    }
    
    func hideError() {
        errorLabel.isHidden = true
        errorLabel.text = nil
        
        // 恢复边框状态
        updateBorderColor()
    }
    
    func clearErrorWhenEditing() {
        // 当用户开始编辑时清除错误状态
        hideError()
    }
    
    private func updateBorderColor() {
        UIView.animate(withDuration: 0.2) {
            UIView.animate(withDuration: 0.2) {
                if self.textField.isFirstResponder {
                    self.containerView.layer.borderColor = UIColor.black.cgColor
                    self.containerView.layer.borderWidth = 1
                } else {
                    self.containerView.layer.borderColor = self.normalBorderColor.cgColor
                    self.containerView.layer.borderWidth = self.normalBorderColor == .clear ? 0 : 1
                }
            }
        }
    }
}

// MARK: - UITextFieldDelegate
extension BaseInputField: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        updateBorderColor()
        updatePlaceholderVisibility()
        clearErrorWhenEditing()
        delegate?.inputFieldDidBeginEditing(self)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateBorderColor()
        updatePlaceholderVisibility()
        delegate?.inputFieldDidEndEditing(self)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
