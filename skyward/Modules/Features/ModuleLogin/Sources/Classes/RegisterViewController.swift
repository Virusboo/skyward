//
//  RegisterViewController.swift
//  TXTS
//
//  Created by yifan kang on 2025/11/12.
//

import UIKit
import SnapKit

class RegisterViewController: BaseViewController {
    
    private var usernameField = DefaultInputField()
    private var phoneField = PhoneInputField()
    private var verificationCodeField = DefaultInputField()
    private var passwordField = PasswordInputField()
    private var rePasswordField = PasswordInputField()
    private lazy var nameTitleView = creatTitleView(titleName: "昵称")
    private lazy var phoneTitleView = creatTitleView(titleName: "手机号")
    private lazy var verficationCodeTitleView = creatTitleView(titleName: "验证码")
    private lazy var passwordTitleView = creatTitleView(titleName: "密码")
    private lazy var rePasswordTitleView = creatTitleView(titleName: "密码")
    // 新增元素
    private let passwordTipLabel = UILabel()
    private let rePasswordTipLabel = UILabel()
    
    private let userAgreementView = UserAgreementView()
    
    private lazy var registerButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("注册", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.init(hex: "#FFE0B9")
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.isEnabled = false
        button.addTarget(self, action: #selector(registerButtonTapped), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupConstraints()
    }
    
    private func setupUI() {
        titleLabel.text = "注册"
        
        usernameField.placeholder = "请输入昵称"
        phoneField.placeholder = "请输入手机号"
        verificationCodeField.placeholder = "请输入验证码"
        passwordField.placeholder = "请输入密码"
        rePasswordField.placeholder = "请再次输入密码"
        
        passwordTipLabel.text = "需包含英文大小写和数字，长度6~20位"
        passwordTipLabel.textColor = UIColor.init(hex: "#84888C")
        passwordTipLabel.font = UIFont.systemFont(ofSize: 12)
        
        rePasswordTipLabel.text = "前后密码保持一致"
        rePasswordTipLabel.textColor = UIColor.init(hex: "#84888C")
        rePasswordTipLabel.font = UIFont.systemFont(ofSize: 12)
        
        view.addSubview(nameTitleView)
        view.addSubview(usernameField)
        view.addSubview(phoneTitleView)
        view.addSubview(phoneField)
        view.addSubview(verficationCodeTitleView)
        view.addSubview(verificationCodeField)
        view.addSubview(passwordTitleView)
        view.addSubview(passwordField)
        view.addSubview(passwordTipLabel)
        view.addSubview(rePasswordTitleView)
        view.addSubview(rePasswordField)
        view.addSubview(rePasswordTipLabel)
        view.addSubview(userAgreementView)
        view.addSubview(registerButton)
        
    }
    
    private func setupConstraints() {
        nameTitleView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(120)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(20)
        }
        usernameField.snp.makeConstraints { make in
            make.top.equalTo(nameTitleView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
        }
        
        phoneTitleView.snp.makeConstraints { make in
            make.top.equalTo(usernameField.snp.bottom).offset(25)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(20)
        }
        phoneField.snp.makeConstraints { make in
            make.top.equalTo(phoneTitleView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
        }
        
        verficationCodeTitleView.snp.makeConstraints { make in
            make.top.equalTo(phoneField.snp.bottom).offset(25)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(20)
        }
        verificationCodeField.snp.makeConstraints { make in
            make.top.equalTo(verficationCodeTitleView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
        }
        
        passwordTitleView.snp.makeConstraints { make in
            make.top.equalTo(verificationCodeField.snp.bottom).offset(25)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(20)
        }
        passwordField.snp.makeConstraints { make in
            make.top.equalTo(passwordTitleView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
        }
        passwordTipLabel.snp.makeConstraints { make in
            make.top.equalTo(passwordField.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(20)
        }
        
        rePasswordTitleView.snp.makeConstraints { make in
            make.top.equalTo(passwordTipLabel.snp.bottom).offset(25)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(20)
        }
        rePasswordField.snp.makeConstraints { make in
            make.top.equalTo(rePasswordTitleView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
        }
        rePasswordTipLabel.snp.makeConstraints { make in
            make.top.equalTo(rePasswordField.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(20)
        }
        
        userAgreementView.snp.makeConstraints { make in
            make.top.equalTo(rePasswordTipLabel.snp.bottom).offset(30)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(40)
        }
        
        registerButton.snp.makeConstraints { make in
            make.top.equalTo(userAgreementView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(48)
        }
    }
    
    private func creatTitleView(titleName: String) -> UIView {
        let view = UIView()
        let iv = UIImageView()
        let img = LoginModule.image(named: "remind")
        iv.image = img
        view.addSubview(iv)
        
        let label = UILabel()
        label.text = titleName
        label.textColor = defaultBlackColor
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        view.addSubview(label)
        
        iv.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview()
            make.width.height.equalTo(6)
        }
        
        label.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(iv.snp.trailing).offset(5)
        }
        
        return view
    }
    
    @objc private func registerButtonTapped() {
        guard userAgreementView.isSelected else {
            // 弹出确认协议页面
            print("没有勾选隐私协议")
            return
        }
        
        // 执行登录逻辑
        
    }
    
}
