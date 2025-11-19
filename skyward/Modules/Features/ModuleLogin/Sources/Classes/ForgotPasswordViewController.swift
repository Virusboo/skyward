//
//  ForgotPasswordViewController.swift
//  TXTS
//
//  Created by yifan kang on 2025/11/12.
//

import UIKit
import SnapKit

class ForgotPasswordViewController: BaseViewController {
    
    private let phoneField = PhoneInputField()
    private let verifyCodeField = DefaultInputField()
    private let newPasswordField = PasswordInputField()
    private let confirmPasswordField = PasswordInputField()
    
    // 新增元素
    private let passwordTipLabel = UILabel()
    
    private lazy var confirmButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("确认", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.init(hex: "#FFE0B9")
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.isEnabled = false
        button.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        titleLabel.text = "忘记密码"
        
        // 配置输入框
        phoneField.configure(placeholder: "请输入手机号")
        verifyCodeField.configure(placeholder: "请输入验证码")
        newPasswordField.configure(placeholder: "请输入新密码")
        confirmPasswordField.configure(placeholder: "请再次输入新密码")
        
        passwordTipLabel.text = "需包含英文大小写和数字，长度6~20位"
        passwordTipLabel.textColor = UIColor.init(hex: "#84888C")
        passwordTipLabel.font = UIFont.systemFont(ofSize: 12)
        
        phoneField.onVerifyCodeTapped = { [weak self] in
            self?.sendVerifyCode()
        }
        
        view.addSubview(phoneField)
        view.addSubview(verifyCodeField)
        view.addSubview(newPasswordField)
        view.addSubview(passwordTipLabel)
        view.addSubview(confirmPasswordField)
        view.addSubview(confirmButton)
        
        phoneField.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(120)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
        }
        
        verifyCodeField.snp.makeConstraints { make in
            make.top.equalTo(phoneField.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
        }
        
        newPasswordField.snp.makeConstraints { make in
            make.top.equalTo(verifyCodeField.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
        }
        
        passwordTipLabel.snp.makeConstraints { make in
            make.top.equalTo(newPasswordField.snp.bottom).offset(5)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(20)
        }
        
        confirmPasswordField.snp.makeConstraints { make in
            make.top.equalTo(passwordTipLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
        }
        
        confirmButton.snp.makeConstraints { make in
            make.top.equalTo(confirmPasswordField.snp.bottom).offset(30)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(48)
        }
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func submitTapped() {
        // 重置密码逻辑
    }
    
    private func sendVerifyCode() {
        // 发送验证码逻辑
    }
}
