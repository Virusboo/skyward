//
//  HomeViewController.swift
//  skyward
//
//  Created by 赵波 on 2025/11/12.
//

import TXKit
import TXRouterKit
import SWKit
import SWTheme
import SnapKit

public class HomeViewController: BaseViewController, MapViewDelegate {
    private var selectedIndexPath: IndexPath?
    
    private let messageTabsData = ["全部", "SOS报警", "报平安", "天气", "服务消息"]
    
    private var viewModel = HomeViewModel()
    
    
    // MARK: - Override
    override public var hasNavBar: Bool {
        return false
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ThemeManager.current.backgroundColor
        
        messageCollectionView.dataSource = self
        messageCollectionView.delegate = self
        messageCollectionView.register(HomeMessageTabCell.self, forCellWithReuseIdentifier: "MessageTabCell")
        
        // 设置 mapView 代理
        mapView.delegate = self
        mapView.setWeatherIcon(HomeModule.image(named: "home_map_weather_icon"))
        mapView.setWeatherText("中雨20℃")
        
        // 初始选中第一个 cell
        DispatchQueue.main.async {
            let firstIndexPath = IndexPath(item: 0, section: 0)
            self.selectedIndexPath = firstIndexPath
            self.messageCollectionView.selectItem(at: firstIndexPath, animated: false, scrollPosition: [])
            if let cell = self.messageCollectionView.cellForItem(at: firstIndexPath) as? HomeMessageTabCell {
                cell.setSelected(true)
            }
        }
        
        setupActions()
    }

    override public func viewDidAppearForTheFirstTime(_ animated: Bool) {
        
    }
    
    override public func setupViews() {
        super.setupViews()
        
        view.addSubview(switchDeviceButton)
        view.addSubview(mapView)
        view.addSubview(centerTitleLabel)
        view.addSubview(clearButton)
        view.addSubview(messageCollectionView)
        view.addSubview(tableView)
        view.addSubview(reportSafetyButton)
        view.addSubview(sosButton)
    }
    
    public override func setupConstraints() {
        super.setupConstraints()
        
        switchDeviceButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(HomeViewController.statusBarHeight)
            make.leading.equalToSuperview().inset(Layout.hMargin)
            make.height.equalTo(44)
            make.width.equalTo(167.5)
        }
        
        mapView.snp.makeConstraints { make in
            make.top.equalTo(switchDeviceButton.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(180)
        }
        
        centerTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(mapView.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(16)
        }
        
        clearButton.snp.makeConstraints { make in
            make.centerY.equalTo(centerTitleLabel)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        messageCollectionView.snp.makeConstraints { make in
            make.top.equalTo(centerTitleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(24)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(messageCollectionView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(reportSafetyButton.snp.top).offset(-12)
        }
        
        reportSafetyButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().dividedBy(2).offset(-6)
            make.bottom.equalToSuperview().offset(-12)
            make.height.equalTo(54)
        }
        
        sosButton.snp.makeConstraints { make in
            make.leading.equalTo(self.view.snp.centerX).offset(6)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-12)
            make.height.equalTo(54)
        }
    }
    
    private func setupActions() {
        switchDeviceButton.addTarget(self, action: #selector(addDeviceTapped), for: .touchUpInside)
        reportSafetyButton.addTarget(self, action: #selector(reportSafetyTapped), for: .touchUpInside)
        clearButton.addTarget(self, action: #selector(clearMessagesTapped), for: .touchUpInside)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressSOSTapped))
        sosButton.addGestureRecognizer(longPress)
        
        // 设置tableView的代理和数据源
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    public override func bindViewModel() {
        super.bindViewModel()
    
        bindPublisher(viewModel.$allNotices.eraseToAnyPublisher()) { [weak self] _ in
            self?.tableView.reloadData()
        }
    }
    
    // MARK: - Actions
    @objc private func addDeviceTapped() {
        print("添加设备点击")
    }
    
    @objc private func reportSafetyTapped() {
        print("报平安点击")
    }
    
    @objc private func longPressSOSTapped(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            print("开始长按 SOS 报警")
        } else if gesture.state == .ended {
            print("结束长按 SOS 报警")
        }
    }
    
    @objc private func clearMessagesTapped() {
        print("清除消息")
    }
    
    // MARK: - UI Components
    private let switchDeviceButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("暂未添加设备", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        button.setTitleColor(.systemGray, for: .normal)
        button.backgroundColor = ThemeManager.current.lightGrayBGColor
        button.layer.cornerRadius = CornerRadius.medium.rawValue
        button.setImage(HomeModule.image(named: "home_arrow_right_icon"), for: .normal)
        button.semanticContentAttribute = .forceRightToLeft  // 强制图片在右边，文字在左边
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -Layout.hInset)  // 图片距离右边12点
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: Layout.hInset, bottom: 0, right: Layout.hInset)
        return button
    }()
    
    private let mapView = HomeMapView()
    
    private let centerTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "服务中心消息"
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = ThemeManager.current.titleColor
        return label
    }()
    
    private let clearButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(HomeModule.image(named: "home_clean_icon"), for: .normal)
        button.setTitle("清除", for: .normal)
        button.setTitleColor(ThemeManager.current.textColor, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        return button
    }()
    
    private let reportSafetyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("报平安", for: .normal)
        button.titleLabel?.font = ThemeManager.bold16Font
        button.backgroundColor = ThemeManager.current.successColor
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = CornerRadius.medium.rawValue
        return button
    }()
    
    private let sosButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("长按SOS报警", for: .normal)
        button.titleLabel?.font = ThemeManager.bold16Font
        button.backgroundColor = ThemeManager.current.errorColor
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = CornerRadius.medium.rawValue
        return button
    }()
    
    // 添加 UICollectionView 定义
    private let messageCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 12
        layout.estimatedItemSize = CGSize(width: 55, height: 24)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        return collectionView
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(HomeMessageCell.self, forCellReuseIdentifier: "HomeMessageCell")
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        return tableView
    }()
    
    
    // MARK: - Helpers
    private func createTabButton(title: String, isSelected: Bool = false) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        button.setTitleColor(isSelected ? .white : .systemGray, for: .normal)
        button.backgroundColor = isSelected ? .black : UIColor(white: 0.95, alpha: 1)
        button.layer.cornerRadius = 14
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
    
    
    static var statusBarHeight: CGFloat {
        if #available(iOS 13.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let statusBarManager = windowScene.statusBarManager {
                return statusBarManager.statusBarFrame.height
            }
        } else {
            return UIApplication.shared.statusBarFrame.height
        }
        return 0
    }
    
    // MARK: - MapViewDelegate
    func mapViewDidTapLocationButton(_ mapView: HomeMapView) {
        print("点击了定位按钮")
        // 在这里添加定位按钮的处理逻辑
    }
    
    func mapViewDidTapZoomButton(_ mapView: HomeMapView) {
        print("点击了缩放按钮")
        // 在这里添加缩放按钮的处理逻辑
    }
    
    func mapViewDidTapLayerButton(_ mapView: HomeMapView) {
        print("点击了图层按钮")
        // 在这里添加图层按钮的处理逻辑
    }
}

// 用于存储消息数据的示例结构
enum MessageType {
    case sos
    case safety
    case weather
    case service
    
    var icon: String? {
        switch self {
        case .sos:
            return "chat_sos_icon"
        case .safety:
            return "chat_safety_icon"
        case .weather:
            return "chat_weather_icon"
        case .service:
            return "chat_service_icon"
        }
    }
    
    var title: String? {
        switch self {
        case .sos:
            return "SOS报警"
        case .safety:
            return "报平安"
        case .weather:
            return "天气预警"
        case .service:
            return "服务消息"
        }
    }
    
}

struct HomeMessage {
    let type: MessageType
    let content: String
    let time: String
}

extension HomeViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDelegate, UITableViewDataSource {
    // MARK: - UICollectionView DataSource & Delegate Methods
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messageTabsData.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MessageTabCell", for: indexPath) as! HomeMessageTabCell
        cell.configure(with: messageTabsData[indexPath.item])
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 如果点击的是已经选中
        if let previousIndexPath = selectedIndexPath, previousIndexPath == indexPath {
            return
        }
    
        // 取消之前选中的cell
        if let previousIndexPath = selectedIndexPath {
            let previousCell = collectionView.cellForItem(at: previousIndexPath) as? HomeMessageTabCell
            previousCell?.setSelected(false)
        }
        
        // 更新当前选中的索引
        selectedIndexPath = indexPath
        
        // 设置当前选中的cell
        let cell = collectionView.cellForItem(at: indexPath) as? HomeMessageTabCell
        cell?.setSelected(true)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let label = UILabel()
        label.text = messageTabsData[indexPath.item]
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.sizeToFit()
        return CGSize(width: label.frame.width + 2*Layout.hInset, height: 24) 
    }
    
    // MARK: - UITableView DataSource & Delegate Methods
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // 这里可以根据当前选中的标签返回对应的消息数量
        return 5 // 示例数据
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HomeMessageCell", for: indexPath) as! HomeMessageCell
        
        // 示例：创建消息数据
        let messageTypes: [MessageType] = [.service, .weather, .sos, .service, .weather]
        let messages = [
            HomeMessage(type: messageTypes[indexPath.row],
                        content: "您的设备已连接到服务器",
                        time: "10:30"),
            HomeMessage(type: messageTypes[indexPath.row],
                        content: "今日有大雨，请注意出行安全", 
                        time: "昨天"),
            HomeMessage(type: messageTypes[indexPath.row],
                        content: "您的家人触发了SOS报警",
                        time: "2024-01-15"),
            HomeMessage(type: messageTypes[indexPath.row],
                        content: "有新的设备固件版本可用", 
                        time: "2024-01-14"),
            HomeMessage(type: messageTypes[indexPath.row],
                        content: "您的设备电量低于20%", 
                        time: "2024-01-13")
        ]
        
        // 配置cell
        let message = messages[indexPath.row]
        cell.configure(with: message)
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 36 // 示例高度，可根据实际需求调整
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // 处理消息点击事件
        print("点击了第\(indexPath.row)条消息")
    }
}

