//
//  HomeAPI.swift
//  ModuleHome
//
//  Created by 赵波 on 2025/11/18.
//

import Foundation
import SWNetwork
import Moya

enum HomeAPI {
    case noticesList
    case clearNotice
    case newMessage
}

extension HomeAPI: NetworkAPI {
    
    var path: String {
        switch self {
        case .noticesList:
            return "/txts-user-center-app/api/v1/notice/list"
        case .clearNotice:
            return "/txts-user-center-app/api/v1/notice/clean"
        case .newMessage:
            return "/api/user/register"
        }
    }
    
    var method: Moya.Method {
        if self == .clearNotice {
            return .delete
        }
        return .get
    }
    
    var task: Moya.Task {
        return .requestPlain
    }
}
