//
//  HomeViewModel.swift
//  ModuleHome
//
//  Created by zhaobo on 2025/11/16.
//

import Foundation
import Combine
import Moya
import SWNetwork

public class HomeViewModel: ObservableObject {
    
    @Published var allNotices: [HomeNoticeItem] = []
    @Published var sosNotices: [HomeNoticeItem] = []
    @Published public var isLoading: Bool = false
    @Published public var error: String?
    
    
    // MARK: - Initialization
    public init() {
        setupBindings()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // 可以在这里设置数据绑定
    }
    
    // MARK: - Public Methods
    /// 刷新数据
    public func refreshData() {
        isLoading = true
        error = nil
        /**
         * 由于导入了 Moya 模块，编译器将 Task 解释为 Moya.Task ，而不是Swift标准库中的并发 Task 类型。这就是为什么会出现"'Task' cannot be constructed because it has no accessible initializers"错误的原因。所以需要改为_Concurrency.Task
         */
        _Concurrency.Task {
            await requestNoticeList()
        }
    }
    
    public func requestNewMessage() async {
        do {
            // 使用 async/await 方式获取用户信息
            let message = try await NetworkProvider<HomeAPI>().request(.newMessage).map(HomeNewMessageModel.self)
        } catch {
            print("❌ 获取最新消息失败: \(error)")
        }
    }
    
    /// 加载最新数据
    public func requestNoticeList() async {
        // 使用Task启动异步操作
        do {
            // 并发请求两个接口
            async let noticesResponse = NetworkProvider<HomeAPI>().request(.noticesList)
            async let newMessageResponse = NetworkProvider<HomeAPI>().request(.newMessage)
            
            // 等待两个请求都完成
            let (noticesData, newMessageData) = try await (noticesResponse, newMessageResponse)
            
            // 回到主线程更新UI
            await MainActor.run {
                self.isLoading = false
                
                do {
                    // 解析通知列表数据
                    let notices = try noticesData.map(HomeNoticeModel.self)
                    var allNotices = notices.allNotices
                    // 处理新消息，与通知列表解耦
                    do {
                        let newMessage = try newMessageData.map(HomeNewMessageModel.self)
                        // 只有当message不为空时才创建通知
                        if let messageContent = newMessage.message, !messageContent.isEmpty {
                            let notice = HomeNoticeItem(noticeId: String(newMessage.sendId),
                                                        noticeType: .service,
                                                        noticeContent: messageContent,
                                                        reportId: nil,
                                                        noticeTime: newMessage.sendTime)
                            allNotices.insert(notice, at: 0)
                        }
                    } catch {
                        print("新消息解析失败: \(error)")
                        // 新消息解析失败不影响通知列表的显示
                    }
                    self.allNotices = allNotices
                    
                } catch {
                    print("通知列表解析失败: \(error)")
                    self.error = "通知列表解析失败: \(error.localizedDescription)"
                }
            }
        } catch {
            // 回到主线程处理错误
            await MainActor.run {
                self.isLoading = false
                self.error = "网络请求失败: \(error.localizedDescription)"
            }
        }
    }
}
