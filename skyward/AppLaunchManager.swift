//
//  AppLaunchManager.swift
//  skyward
//
//  Created by TXTS on 2026/1/13.
//

import Foundation
import ModulePersonal
import SWNetwork
import SWKit
import ModuleMap

// MARK: - 应用启动管理器
class AppLaunchManager {
    static let shared = AppLaunchManager()
    
    // MARK: - 私有属性
    private let firmwareManager = FirmwareManager.shared
    private let firmwareUpdater = DeviceFirmwareUpdater.shared
    private let poiSyncManager = POISyncManager.shared
    
    private let mapViewModel = MapViewModel()
    
    // MARK: - 启动任务
    func performLaunchTasks() {
        print("应用启动，执行固件管理任务")
        
        // 1. 检查硬件型号是否设置
        let hardwareModel = firmwareManager.getHardwareModel()
        print("当前硬件型号: \(hardwareModel)")
        
        // 2. 检查当前存储版本
        let storedVersion = firmwareManager.getCurrentStoredVersion()
        print("当前存储版本: \(storedVersion)")
        
        // 3. 检查是否有已下载的固件
        if firmwareManager.isFirmwareDownloaded() {
            let firmwareInfo = firmwareManager.getDownloadedFirmware()
            print("已有下载的固件: \(firmwareInfo?.versionName ?? "未知")")
        } else {
            print("没有已下载的固件")
        }
        
        // 4. 检查POI未同步数据
        checkUnsyncedPOIData()
        
        // 5. 静默检查更新（如果有网络）
        silentCheckForUpdates()
    }
    
    // MARK: - 静默检查更新
    private func silentCheckForUpdates() {
        print("开始静默检查更新...")
        
        // 检查网络连接
        if !NetworkMonitor.shared.isConnected {
            print("网络不可用，跳过静默检查")
            return
        }
        
        let hardwareModel = firmwareManager.getHardwareModel()
        
        firmwareUpdater.checkAndDownloadFirmware(hardwareModel: hardwareModel) { success, message in
            if success {
                print("静默检查更新成功: \(message ?? "")")
            } else {
                print("静默检查更新失败: \(message ?? "")")
                if let firmwareInfo = self.firmwareManager.getDownloadedFirmware() {
                    print(firmwareInfo.versionName)
                    print(firmwareInfo.filePath)
                }
            }
        }
    }
    
    // MARK: - 检查未同步POI数据
    private func checkUnsyncedPOIData() {
        print("🔍 检查未同步的用户POI数据...")
        
        let hasUnsynced = poiSyncManager.checkUnsyncedStatus()
        let unsyncedCount = poiSyncManager.getUnsyncedCount()
        
        if hasUnsynced {
            print("⚠️ 发现 \(unsyncedCount) 条未同步的POI数据")
            
            // 可以在这里决定是否自动同步
            // 如果网络可用，可以自动同步
            if NetworkMonitor.shared.isConnected {
                print("📤 网络可用，开始自动同步POI数据...")
                syncUnsyncedPOIData()
            }
            
            // 发送通知让UI显示同步提示
            NotificationCenter.default.post(
                name: .init("HasUnsyncedPOIData"),
                object: nil,
                userInfo: ["count": unsyncedCount]
            )
        } else {
            print("✅ 所有POI数据已同步")
        }
    }
    
    /// 同步未同步的POI数据
    private func syncUnsyncedPOIData() {
        // 获取需要同步的数据
        let toSave = poiSyncManager.getDataNeedingSync() ?? []
        let toDelete = poiSyncManager.getDataNeedingDeleteSync() ?? []
        
        guard !toSave.isEmpty || !toDelete.isEmpty else {
            print("📊 没有需要同步的POI数据")
            return
        }
        
        print("📤 开始同步POI数据 - 新增/更新: \(toSave.count)条, 删除: \(toDelete.count)条")
        
        
    }
    
    // MARK: - 手动检查更新
    func manualCheckForUpdates(completion: @escaping (Bool, String?) -> Void) {
        print("手动检查更新")
        
        if !NetworkMonitor.shared.isConnected {
            completion(false, "网络连接不可用")
            return
        }
        
        let hardwareModel = firmwareManager.getHardwareModel()
        
        firmwareUpdater.checkAndDownloadFirmware(hardwareModel: hardwareModel, completion: completion)
    }
    
    private func savePOI(poiData: UserPOILocalData) {
        
        let poiModel = UserPOIModel(poiId: poiData.poiId ?? "",
                                    name: poiData.name ?? "",
                                    description: poiData.description ?? "",
                                    lon: poiData.lon ?? 00,
                                    lat: poiData.lat ?? 00,
                                    category: poiData.category ?? 1,
                                    imgUrlList: nil,
                                    state: poiData.isDelected ?? false ? 1 : 0,
                                    userId: Int(UserManager.shared.userId) ?? 0,
                                    address: poiData.address ?? nil,
                                    altitude: "\(poiData.altitude ?? 0))")
        mapViewModel.saveUserPoi(poiModel)
            .sink { completion in
                switch completion {
                case .finished:
                    print("操作完成")
                case .failure(let error):
                    print("发生错误: \(error.localizedDescription)")
                }
            } receiveValue: { data in
                print("保存结果: \(data)")
            }
            .store(in: &mapViewModel.cancellables)
    }
}


// MARK: - 扩展通知名称
extension Notification.Name {
    static let hasUnsyncedPOIData = Notification.Name("HasUnsyncedPOIData")
    static let syncUnsyncedPOIData = Notification.Name("SyncUnsyncedPOIData")
    static let networkStatusChanged = Notification.Name("NetworkStatusChanged")
}
