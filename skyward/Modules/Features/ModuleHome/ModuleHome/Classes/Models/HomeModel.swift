//
//  HomeModel.swift
//  ModuleHome
//
//  Created by zhaobo on 2025/11/16.
//

import Foundation

/// 提醒类型
enum NoticeType: Int, Codable {
    case sos = 1         // SOS紧急求助
    case safety = 2      // 报平安
    case weather = 3     // 天气通知
    case service = 4     // 服务消息
    
    var title: String {
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
}
 
struct HomeNoticeItem: Codable {
    public let noticeId: String?
    public let noticeType: NoticeType
    public let noticeContent: String?
    public let reportId: String?
    public let noticeTime: String?
    
    public init(
        noticeId: String?,
        noticeType: NoticeType,
        noticeContent: String?,
        reportId: String?,
        noticeTime: String?
    ) {
        self.noticeId = noticeId
        self.noticeType = noticeType
        self.noticeContent = noticeContent
        self.reportId = reportId
        self.noticeTime = noticeTime
    }
}

struct HomeNewMessageModel: Codable {
    public let message: String?
    public let sendTime: String?
    public let sendId: Int
}

 struct HomeNoticeModel: Codable {
    public let totalCount: Int
    public let safeCount: Int
    public let sosCount: Int
    public let weatherCount: Int
    public let safeList: [HomeNoticeItem]
    public let sosList: [HomeNoticeItem]
    public let weatherList: [HomeNoticeItem]
     
//     enum CodingKeys: String, CodingKey {
//         case safeList
//         case sosList
//         case weatherList
//     }
    
    public init(
        totalCount: Int,
        safeCount: Int,
        sosCount: Int,
        weatherCount: Int,
        safeList: [HomeNoticeItem],
        sosList: [HomeNoticeItem],
        weatherList: [HomeNoticeItem]
    ) {
        self.totalCount = totalCount
        self.safeCount = safeCount
        self.sosCount = sosCount
        self.weatherCount = weatherCount
        self.safeList = safeList
        self.sosList = sosList
        self.weatherList = weatherList
    }
    
    // 获取所有通知列表
    public var allNotices: [HomeNoticeItem] {
        return sosList + safeList + weatherList
    }
    
    // 根据类型获取通知列表
    public func notices(ofType type: NoticeType) -> [HomeNoticeItem] {
        switch type {
        case .sos:
            return sosList
        case .safety:
            return safeList
        case .weather:
            return weatherList
        default:
            return []
        }
    }
}

// MARK: - Mock响应数据

// MARK: - 响应模型
struct HomeResponseModel: Codable {
    public let code: String
    public let data: HomeNoticeModel
    public let msg: String
    
    public init(code: String, data: HomeNoticeModel, msg: String) {
        self.code = code
        self.data = data
        self.msg = msg
    }
}

extension HomeResponseModel {
    static func mockResponse() -> HomeResponseModel {
        let sosItem = HomeNoticeItem(
            noticeId: nil,
            noticeType: .sos,
            noticeContent: "【SOS紧急求助】上报成功！\n已通知紧急联系人：张三。\n已通知保险公司：泰康人寿。\n救援人员正在赶往您所在的位置，请保持通讯畅通并注意安全。为了尽快为您提供帮助，请在简要描述您当前的情况：是否有受伤、地质灾害或其他紧急事件？",
            reportId: "1983371892287897600",
            noticeTime: "2025-10-29 11:14:51"
        )
        
        let weatherItem = HomeNoticeItem(
            noticeId: nil,
            noticeType: .weather,
            noticeContent: "您当前位置此时天气情况：阴，温度 4℃，体感温度 0℃。风向为 西风，风力等级 3 级，风速 13 km/h。相对湿度 74%，降水量 0.0 mm。大气压强 851 hPa，能见度 30 km。",
            reportId: "1978739390738890752",
            noticeTime: "2025-10-16 16:26:49"
        )
        
        let data = HomeNoticeModel(
            totalCount: 5,
            safeCount: 0,
            sosCount: 4,
            weatherCount: 1,
            safeList: [],
            sosList: [sosItem],
            weatherList: [weatherItem]
        )
        
        return HomeResponseModel(
            code: "00000",
            data: data,
            msg: "一切ok"
        )
    }
}
