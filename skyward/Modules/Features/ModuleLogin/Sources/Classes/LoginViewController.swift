//
//  LoginViewController.swift
//  TXTS
//
//  Created by yifan kang on 2025/11/11.
//

import UIKit
import SnapKit

public class LoginViewController: UIViewController {
    
    private lazy var navigationView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        
        let closeButton = UIButton()
        if #available(iOS 13.0, *) {
            closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        } 
        closeButton.tintColor = .black
        closeButton.addTarget(self, action: #selector(backPresonalView), for: .touchUpInside)
        view.addSubview(closeButton)
        
        let registerButton = UIButton()
        registerButton.setTitle("注册", for: .normal)
        registerButton.setTitleColor(defaultOrangeColor, for: .normal)
        registerButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        registerButton.addTarget(self, action: #selector(registerClick), for: .touchUpInside)
        view.addSubview(registerButton)
        
        closeButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
            make.width.height.equalTo(30)
        }
        
        registerButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(30)
        }
        
        return view
    }()
    
    private let welcomeText: UILabel = {
        let label = UILabel()
        label.text = "欢迎使用天行探索"
        label.textColor = defaultBlackColor
        label.font = UIFont.systemFont(ofSize: 28, weight: .semibold)
        return label
    }()
    
    private let loginMethodView = LoginMethodView()
    private let contentView = UIView()
    // MARK: - Properties
    /// 密码登录
    private var usernameField: DefaultInputField?
    private var passwordField: PasswordInputField?
    /// 验证码登录
    private var phoneField: PhoneInputField?
    private var verificationCodeField: DefaultInputField?
    
    // 当前显示的登录表单
    private var currentLoginView: UIView?
    
    private let userAgreementView = UserAgreementView()
    
    private lazy var loginButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("立即登录", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.init(hex: "#FFE0B9")
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.isEnabled = false
        button.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        return button
    }()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        setUI()
        setupConstraints()
        configureLoginMethods()
    }
    
    private func setUI() {
        view.addSubview(navigationView)
        view.addSubview(welcomeText)
        view.addSubview(loginMethodView)
        view.addSubview(contentView)
        view.addSubview(userAgreementView)
        view.addSubview(loginButton)
        
        loginMethodView.delegate = self
        userAgreementView.delegate = self
    }
    
    private func setupConstraints() {
        
        navigationView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(44)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(50)
        }
        
        welcomeText.snp.makeConstraints { make in
            make.top.equalTo(navigationView.snp.bottom).offset(22)
            make.leading.equalToSuperview().offset(16)
        }
        
        loginMethodView.snp.makeConstraints { make in
            make.top.equalTo(welcomeText.snp.bottom).offset(30)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(40)
        }
        
        contentView.snp.makeConstraints { make in
            make.top.equalTo(loginMethodView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(200)
        }
        
        userAgreementView.snp.makeConstraints { make in
            make.top.equalTo(contentView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(40)
        }
        
        loginButton.snp.makeConstraints { make in
            make.top.equalTo(userAgreementView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(48)
        }
        
    }
    
    private func configureLoginMethods() {
        // 配置登录方式
        let methods = ["密码登录", "验证码登录"]
        loginMethodView.configure(with: methods, defaultSelectedIndex: 0)
        
        // 默认显示密码登录
        showCurrentViewWitchType(with: "password")
    }
    
    // MARK: - 登录表单切换
    private func showCurrentViewWitchType(with type:String) {
        currentLoginView?.removeFromSuperview()
        
        let passwordView = type == "password" ? createPasswordLoginView() : createVerificationCodeLoginView()
        contentView.addSubview(passwordView)
        passwordView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            passwordView.topAnchor.constraint(equalTo: contentView.topAnchor),
            passwordView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            passwordView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            passwordView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        currentLoginView = passwordView
    }
    
    @objc private func backPresonalView() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc private func registerClick() {
        let registerVC = RegisterViewController()
        self.navigationController?.pushViewController(registerVC, animated: true)
    }
    
    @objc private func forgotPasswordTapped() {
        let forgotPasswordVC = ForgotPasswordViewController()
        self.navigationController?.pushViewController(forgotPasswordVC, animated: true)
    }
    
    @objc private func loginButtonTapped() {
        guard userAgreementView.isSelected else {
            // 弹出确认协议页面
            print("没有勾选隐私协议")
            return
        }
        
        // 执行登录逻辑
        
    }
}

// MARK: - 视图创建
extension LoginViewController {
    // MARK: - 密码登录视图创建方法
    private func createPasswordLoginView() -> UIView {
        let view = UIView()
        
        // 用户名/手机号输入框
        let usernameField = DefaultInputField()
        usernameField.configure(placeholder: "请输入手机号")
        usernameField.textField.keyboardType = .numberPad
        usernameField.delegate = self
        self.usernameField = usernameField
        
        // 密码输入框 - 现在包含忘记密码按钮
        let passwordField = PasswordInputField()
        passwordField.configure(
            placeholder: "请输入密码",
            showForgotPassword: true // 在密码登录时显示忘记密码
        )
        passwordField.onForgotPasswordTapped = { [weak self] in
            self?.forgotPasswordTapped()
        }
        passwordField.delegate = self
        self.passwordField = passwordField
        
        // 主垂直栈
        let stackView = UIStackView(arrangedSubviews: [usernameField, passwordField])
        stackView.axis = .vertical
        stackView.spacing = 20
        
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
        
        return view
    }
    
    // MARK: - 验证码登录视图创建方法
    private func createVerificationCodeLoginView() -> UIView {
        let view = UIView()
        
        // 手机号输入框
        let phoneField = PhoneInputField()
        phoneField.configure(placeholder: "请输入手机号")
        self.phoneField = phoneField
        
        // 密码输入框 - 现在包含忘记密码按钮
        let verificationCodeField = DefaultInputField()
        verificationCodeField.configure(
            placeholder: "请输入验证码"
        )
        self.verificationCodeField = verificationCodeField
        
        // 主垂直栈
        let stackView = UIStackView(arrangedSubviews: [phoneField, verificationCodeField])
        stackView.axis = .vertical
        stackView.spacing = 20
        
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
        
        return view
    }
    
    // MARK: - 更新登录按钮状态
    private func updateLoginButtonState() {
        let isEnabled: Bool
        
        if loginMethodView.selectedIndex == 0 {
            // 密码登录模式
            let username = usernameField?.text ?? ""
            let password = passwordField?.text ?? ""
            isEnabled = !username.isEmpty && !password.isEmpty
        } else {
            // 验证码登录模式
            let phone = phoneField?.text ?? ""
            let code = verificationCodeField?.text ?? ""
            isEnabled = !phone.isEmpty && !code.isEmpty
        }
        print("改变登录按钮背景颜色")
        loginButton.isEnabled = isEnabled
        loginButton.backgroundColor = isEnabled ? defaultOrangeColor : UIColor(hex: "#FFE0B9")
    }
}

extension LoginViewController: LoginMethodViewDelegate {
    
    func loginMethodView(_ view: LoginMethodView, didSelectMethod method: String, at index: Int) {
        print("选择了登录方式: \(method), 索引: \(index)")
        // 根据选择的登录方式切换内容
        switch method {
        case "密码登录":
            showCurrentViewWitchType(with: "password")
        case "验证码登录":
            showCurrentViewWitchType(with: "verificationCode")
            print("验证码登录")
        case "扫码登录":
            print("扫码登录")
        default:
            break
        }
    }
    
}

extension LoginViewController: InputFieldDelegate {
    func inputFieldDidBeginEditing(_ inputField: BaseInputField) {
        
    }
    
    func inputFieldDidEndEditing(_ inputField: BaseInputField) {
        
    }
    
    func inputFieldTextDidChange(_ inputField: BaseInputField, text: String) {
        // 输入内容变化时更新登录按钮状态
        updateLoginButtonState()
    }
    
    
}

extension LoginViewController: UserAgreementViewDelegate {
    
    func userAgreementViewDidTapCheckbox(_ view: UserAgreementView, isSelected: Bool) {
        
    }
    
    func userAgreementViewDidTapAgreement(_ view: UserAgreementView, type: AgreementType) {
        switch type {
        case .privacy:
            let webVC = WebViewController(
                        urlString: "https://www.google.com",
                        title: "隐私协议"
                    )
            self.navigationController?.pushViewController(webVC, animated: true)
        case .service:
            let webVC = WebViewController(
                        urlString: "https://www.baidu.com",
                        title: "用户服务协议"
                    )
            self.navigationController?.pushViewController(webVC, animated: true)
        }
    }
    
    
}
