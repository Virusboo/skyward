//
//  LookRoutePopupView.swift
//  ModuleMap
//
//  Created by zhaobo on 2026/1/12.
//

import UIKit
import SnapKit
import TXKit
import SWKit
import SWTheme

class LookRoutePopupView: UIView, SWPopupContentView {
    
    // MARK: - UI Components
    
    /// 标题标签
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .pingFangFontBold(ofSize: 18)
        label.textColor = ThemeManager.current.titleColor
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 关闭按钮
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(MapModule.image(named: "map_close"), for: .normal)
        button.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let descLabel: UILabel = {
        let label = UILabel()
        label.font = .pingFangFontRegular(ofSize: 12)
        label.textColor = ThemeManager.current.textColor
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    
    private let deleteButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = ThemeManager.current.mediumGrayBGColor
        button.setImage(MapModule.image(named: "map_user_delete"), for: .normal)
        button.setTitle("删除", for: .normal)
        button.setTitleColor(ThemeManager.current.titleColor, for: .normal)
        button.titleLabel?.font = .pingFangFontMedium(ofSize: 16)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -8)
        button.layer.cornerRadius = CornerRadius.medium.rawValue
        button.layer.masksToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    
    // MARK: - Properties
    
    var closeHandler: (() -> Void)?
    var deleteHandler: (() -> Void)?
    
    // MARK: - Initialization
    init(routeName: String?, desc: String?) {
        super.init(frame: CGRectZero)
        setupUI(desc: desc)
        setupConstraints()
        
        deleteButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
        titleLabel.text = routeName
        descLabel.text = desc
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI(desc: String?) {
        backgroundColor = .white
        
        addSubview(titleLabel)
        addSubview(closeButton)
        
        if let desc = desc, !desc.isEmpty {
            addSubview(descLabel)
        }
        
        addSubview(deleteButton)
    }
    
    private func setupConstraints() {

        titleLabel.snp.makeConstraints {
            $0.height.equalTo(swAdaptedValue(25))
            $0.top.left.equalToSuperview().inset(Layout.hMargin)
        }
        
        closeButton.snp.makeConstraints {
            $0.right.equalToSuperview().inset(swAdaptedValue(9))
            $0.centerY.equalTo(titleLabel)
            $0.width.height.equalTo(swAdaptedValue(30))
        }
        
        if descLabel.superview == nil {
            deleteButton.snp.makeConstraints { make in
                make.height.equalTo(swAdaptedValue(48))
                make.top.equalTo(swAdaptedValue(45))
                make.bottom.equalToSuperview().inset(ScreenUtil.safeAreaBottom + 12)
                make.left.right.equalToSuperview().inset(Layout.hMargin)
            }
        } else {
            descLabel.snp.makeConstraints { make in
                make.height.greaterThanOrEqualTo(swAdaptedValue(20))
                make.top.equalTo(swAdaptedValue(45))
                make.left.right.equalToSuperview().inset(Layout.hMargin)
            }
            
            deleteButton.snp.makeConstraints { make in
                make.height.equalTo(swAdaptedValue(48))
                make.top.equalTo(descLabel.snp.bottom).offset(28)
                make.bottom.equalToSuperview().inset(ScreenUtil.safeAreaBottom + 12)
                make.left.right.equalToSuperview().inset(Layout.hMargin)
            }
        }
        
        
    }
    
    // MARK: - Actions
    @objc private func closeButtonTapped() {
        self.closeHandler?()
    }
    
    @objc private func confirmButtonTapped() {
        self.deleteHandler?()
    }
}
