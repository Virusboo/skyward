//
//  ViewController.swift
//  TXTS
//
//  Created by yifan kang on 2025/11/11.
//

import UIKit
import SnapKit
import SafariServices
import TXKit

open class LaunchViewController: UIViewController {

    private lazy var txLogoImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "tx_logo")
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private lazy var txBgImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "tx_bg_1")
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    private let agreementView = PresonalInfoProtectionView()
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.navigationController?.navigationBar.isHidden = true
        view.backgroundColor = UIColor.init(hex: "#FECC33")
        
        setUI()
        setupConstraints()
    }
    
    private func setUI() {
        
        agreementView.onUserAgreementTapped = { [weak self] in
            self?.showUserAgreement()
        }
        
        agreementView.onPrivacyPolicyTapped = { [weak self] in
            self?.showPrivacyPolicy()
        }
        
        agreementView.onDisAgreeButtonTapped = { [weak self] in
            self?.showAgreeAgainView()
        }
        
        agreementView.onAgreeButtonTapped = { [weak self] in
            self?.handleAgreeAction()
        }
        
        view.addSubview(txBgImageView)
        view.addSubview(txLogoImageView)
        view.addSubview(agreementView)
    }

    private func setupConstraints() {
        txBgImageView.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalToSuperview()
            make.height.equalTo(ScreenUtil.screenWidth/2)
        }
        
        txLogoImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(158)
            make.centerX.equalToSuperview()
            make.height.equalTo(218)
            make.width.equalTo(166)
        }
        
        agreementView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func showUserAgreement() {
        // 跳转到用户服务协议页面
        let webVC = WebViewController(
                    urlString: "https://www.baidu.com",
                    title: "用户服务协议"
                )
        self.navigationController?.pushViewController(webVC, animated: true)
    }
    
    private func showPrivacyPolicy() {
        // 跳转到隐私政策页面
        let webVC = WebViewController(
                    urlString: "https://www.google.com",
                    title: "隐私协议"
                )
        self.navigationController?.pushViewController(webVC, animated: true)
    }
    
    private func handleAgreeAction() {
        // 处理用户同意逻辑
        UserDefaults.standard.set(true, forKey: "hasAgreedToTerms")
        print("用户已同意协议")
        
        let loginVC = LoginViewController()
        self.navigationController?.pushViewController(loginVC, animated: true)
    }
    
    private func showAgreeAgainView() {
        let agreeAgainView = AgreeAgainView()
        
        agreeAgainView.onUserAgreementTapped = { [weak self] in
            self?.showUserAgreement()
        }
        
        agreeAgainView.onPrivacyPolicyTapped = { [weak self] in
            self?.showPrivacyPolicy()
        }
        
        agreeAgainView.onAgreeButtonTapped = { [weak self] in
            self?.handleAgreeAction()
        }
        
        agreeAgainView.show()
    }
}

