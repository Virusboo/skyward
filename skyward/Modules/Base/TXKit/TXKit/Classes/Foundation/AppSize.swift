//
//  AppSize.swift
//  SAKit
//
//  Created by hushijun on 2024/4/3.
//

import UIKit

// 屏幕宽度
public func screenWidth() -> CGFloat {
    return UIScreen.main.bounds.width
}

// 屏幕高度
public func screenHeight() -> CGFloat {
    return UIScreen.main.bounds.height
}

// 相比375屏幕的比例
public func zRatio() -> CGFloat {
    return UIScreen.main.bounds.width / 375.0
}

// 将传入的参数乘以375屏幕比例
public func zRatio(_ x:CGFloat) -> CGFloat {
    return x * (UIScreen.main.bounds.width / 375.0)
}

// tabbar的高度：待完善
public let tabBarHeight: CGFloat = 50

// 顶部安全距离
public func topMargin() -> CGFloat {
    // 增加刘海屏【普通和灵动岛设备】的通用适配逻辑，兼容iOS 13+的SceneDelegate
    if let windowScene = UIApplication.shared.connectedScenes
        .filter({ $0.activationState == .foregroundActive })
        .first as? UIWindowScene,
       let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
        return window.safeAreaInsets.top
    }
    return 0
}

// 底部安全距离
public func bottomMargin() -> CGFloat {
    if let windowScene = UIApplication.shared.connectedScenes
        .filter({ $0.activationState == .foregroundActive })
        .first as? UIWindowScene,
       let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
        return window.safeAreaInsets.bottom
    }
    return 0
}
