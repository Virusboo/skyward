//
//  WebViewController.swift
//  TXTS
//
//  Created by yifan kang on 2025/11/11.
//


import UIKit
import WebKit

class WebViewController: UIViewController {
    
    // MARK: - Properties
    private let urlString: String
    private let pageTitle: String
    
    // MARK: - UI Components
    private lazy var webView: WKWebView = {
        let webView = WKWebView()
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }()
    
    private lazy var navigationBar: UINavigationBar = {
        let navBar = UINavigationBar()
        navBar.barTintColor = .white
        navBar.isTranslucent = false
        return navBar
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            indicator = UIActivityIndicatorView(style: .medium)
        } else {
            indicator = UIActivityIndicatorView(style: .gray)
        }
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Initialization
    init(urlString: String, title: String) {
        self.urlString = urlString
        self.pageTitle = title
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadWebPage()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .white
        
        // 设置导航栏
        setupNavigationBar()
        
        // 添加 WebView
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加加载指示器
        view.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // 导航栏约束
            navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navigationBar.heightAnchor.constraint(equalToConstant: 44),
            
            // WebView 约束
            webView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // 加载指示器约束
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupNavigationBar() {
        view.addSubview(navigationBar)
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        
        // 创建导航项
        let navItem = UINavigationItem(title: pageTitle)
        
        // 关闭按钮
        let closeButton = UIBarButtonItem(
            title: "返回",
            style: .plain,
            target: self,
            action: #selector(closeButtonTapped)
        )
        navItem.leftBarButtonItem = closeButton
        
        navigationBar.items = [navItem]
    }
    
    // MARK: - WebView Methods
    private func loadWebPage() {
        guard let url = URL(string: urlString) else {
            showErrorAlert(message: "无效的 URL")
            return
        }
        
        activityIndicator.startAnimating()
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    @objc private func refreshButtonTapped() {
        webView.reload()
    }
    
    @objc private func closeButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Error Handling
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "加载失败",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
}

// MARK: - WKNavigationDelegate
extension WebViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        activityIndicator.startAnimating()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
        showErrorAlert(message: error.localizedDescription)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
        showErrorAlert(message: "无法加载页面: \(error.localizedDescription)")
    }
}
