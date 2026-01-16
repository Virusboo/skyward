//
//  TrackDataManager.swift
//  ModuleMap
//
//  Created by zhaobo on 2025/12/15.
//

import Foundation
import CoreLocation
import TXKit
import SWKit
import SWNetwork
import WCDBSwift

public enum RouteType: Int {
    case route
    case track
}

enum UploadStatus: Int, Codable, ColumnCodable {
    case notUploaded  // 未上传
    case uploaded     // 已上传
    case uploading    // 上传中
    
    public static var columnType: WCDBSwift.ColumnType {
        return .integer32
    }
    
    public init?(with value: WCDBSwift.Value) {
        self.init(rawValue: Int(value.int32Value))
    }
    
    public func archivedValue() -> WCDBSwift.Value {
        return FundamentalValue.init(Int32(self.rawValue))
    }
}

struct TrackRecord: TableCodable {
    var id: UInt64 = UInt64(Date().timeIntervalSince1970)
    var name: String = DateFormatter.fullPretty.string(from: Date())
    var localFileUrl: String?
    var uploadStatus: UploadStatus = .notUploaded
    var isLook: Bool = false
    
    enum CodingKeys: String, CodingTableKey {
        typealias Root = TrackRecord
        
        case id
        case name
        case localFileUrl
        case uploadStatus
        case isLook
        
        static let objectRelationalMapping = TableBinding(CodingKeys.self) {
            BindColumnConstraint(id, isPrimary: true)
        }
    }
    
    func fileFullURL() -> URL? {
        guard let fileUrl = localFileUrl, let fileURL = SandBox.docmentsURL?.appendingPathComponent(fileUrl) else {
            return nil
        }
        return fileURL
    }
}

// MARK: - 轨迹数据管理器
class TrackDataManager {
    // 常量定义
    private let fileExtension = "txt"
    private let gpxExtension = "gpx"
    // 本次记录的相关属性
    private(set) var sessionRecordId: Int64?
    private var sessionTxtFileURL: URL?
    
    private lazy var uploadManager: UploadManager = {
        let mgr = UploadManager()
        return mgr
    }()
    
    private lazy var mapService: MapService = {
        let mapService = MapService()
        return mapService
    }()
    
    // 创建并获取本次记录的目录路径
//    private func createSessionDirectory(dirName: String) -> URL? {
//        guard let trackDirectory = getDirectoryPath() else { return nil }
//        
//        let fileManager = FileManager.default
//        let sessionDirectory = trackDirectory.appendingPathComponent(dirName)
//        
//        do {
//            try fileManager.createDirectory(at: sessionDirectory, withIntermediateDirectories: true, attributes: nil)
//            print("创建会话目录成功：\(sessionDirectory.path)")
//            return sessionDirectory
//        } catch {
//            print("创建会话目录失败：\(error.localizedDescription)")
//            return nil
//        }
//    }
    
    // 创建新的带时间戳的.txt文件
//    private func createNewFile() -> URL? {
//        let fileName = "record.\(fileExtension)"
//        let fileURL = tempOutputURL().appendingPathComponent(fileName)
//        let fileManager = FileManager.default
//        if !fileManager.fileExists(atPath: fileURL.path) {
//            do {
//                // 创建空文件
//                try "".write(to: fileURL, atomically: true, encoding: .utf8)
//                print("创建新文件成功：\(fileURL.path)")
//                return fileURL
//            } catch {
//                print("创建新文件失败：\(error.localizedDescription)")
//                return nil
//            }
//        } else {
//            print("文件已存在：\(fileURL.path)")
//            return fileURL
//        }
//    }
    
    // MARK: - 增删改查
    
//    @discardableResult
//    func createNewRecord(type: RouteType) -> RouteRecord? {
//        var record = RouteRecord()
//        record.type = type.rawValue
//        record.tempTxtFileURL = txtFileURL()
//        return record
//    }
    func startRecord() {
        sessionRecordId = Int64(Date().timeIntervalSince1970)
        sessionTxtFileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension(fileExtension)
    }
    
    func stopRecord() {
        sessionRecordId = nil
        sessionTxtFileURL = nil
    }
    
    // 写入记录的点到文件
    @discardableResult
    func writePointToTxtFile(_ point: RecordPoint) -> Bool {
        guard let txtFileURL = sessionTxtFileURL else { return false }
        let pointString = point.toString() + "\n"
        
        do {
            let fileHandle = try FileHandle(forWritingTo: txtFileURL)
            fileHandle.seekToEndOfFile()
            fileHandle.write(pointString.data(using: .utf8)!)
            fileHandle.closeFile()
            return true
        } catch {
            print("写入文件失败：\(error.localizedDescription)")
            return false
        }
    }
    
    // 批量写入记录点到文件
    @discardableResult
    func writeRecordPoints(_ points: [RecordPoint]) -> Bool {
        guard let txtFileURL = sessionTxtFileURL else { return false }
        let pointsString = points.map { $0.toString() }.joined(separator: "\n") + "\n"
        
        do {
            let fileHandle = try FileHandle(forWritingTo: txtFileURL)
            fileHandle.seekToEndOfFile()
            fileHandle.write(pointsString.data(using: .utf8)!)
            fileHandle.closeFile()
            return true
        } catch {
            print("批量写入文件失败：\(error.localizedDescription)")
            return false
        }
    }
    
    // 按行读取文件中的轨迹点
    private func readPointsFromTxtFile() -> [RecordPoint] {
        guard let fileURL = sessionTxtFileURL else {
            return []
        }
        var points: [RecordPoint] = []
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)
            
            for line in lines {
                if !line.isEmpty {
                    if let point = RecordPoint(from: line) {
                        points.append(point)
                    } else {
                        print("解析轨迹点失败：\(line)")
                    }
                }
            }
        } catch {
            print("读取文件失败：\(error.localizedDescription)")
        }
        
        return points
    }
    
    func readCoordinatesFromGPXFile(from routeId: Int64) -> [CLLocationCoordinate2D] {
        guard let fileURL = gpxFileURL(routeId) else {
            print("GPX文件路径为空")
            return []
        }
        
        var coordinates: [CLLocationCoordinate2D] = []
        
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            coordinates = parseGPXCoordinates(from: content)
            print("从GPX文件读取了 \(coordinates.count) 个坐标点")
        } catch {
            print("读取GPX文件失败：\(error.localizedDescription)")
        }
        
        return coordinates
    }
    // 保存路线/轨迹记录到本地
    func saveRouteToLocal(_ route: RouteRecord) {
        if DBManager.shared.insertToDb(objects: [route], intoTable: DBTableName.route.rawValue) {
            saveRouteGPXToLocal(route)
        }
    }
    
    // 删除路线/轨迹记录到本地
    @discardableResult
    func deleteRouteFromLocal(_ routeId: Int64) -> Bool {
        if DBManager.shared.deleteFromDb(fromTable: DBTableName.route.rawValue,
                                         where: RouteRecord.Properties.id == routeId) {
            return deleteRouteGPXFromLocal(routeId)
        }
        return false
    }
    
    // 修改当前记录名
    @discardableResult
    func renameRecord(_ record: RouteRecord) -> Bool {
        return DBManager.shared.updateToDb(table: DBTableName.route.rawValue,
                                           on: [RouteRecord.Properties.routeName],
                                           with: record,
                                           where: RouteRecord.Properties.id == record.id)
    }
    
    func getRouteRecords(type: RouteType) -> [RouteRecord] {
        guard let records = DBManager.shared.queryFromDb(fromTable: DBTableName.route.rawValue,
                                                         cls: RouteRecord.self,
                                                         where: RouteRecord.Properties.type == type.rawValue,
                                                         orderBy: [RouteRecord.Properties.id.order(.descending)]) else {
            return []
        }
        return records
    }
    
    //MARK: - GPX
    @discardableResult
    private func saveRouteGPXToLocal(_ route: RouteRecord) -> Bool {

        guard let outputURL = gpxFileURL(route.id) else {
            return false
        }
        
        let readPoints = readPointsFromTxtFile()
        
        if generateGPXFile(from: readPoints, outputURL: outputURL) {
            return true
        }
        return false
    }
    
    @discardableResult
    private func deleteRouteGPXFromLocal(_ routeId: Int64) -> Bool {

        guard let fileURL = gpxFileURL(routeId) else {
            print("删除失败：localFileUrl为空")
            return false
        }
        
        let fileManager = FileManager.default
        
        let filePath = fileURL.absoluteString

        guard fileManager.fileExists(atPath: filePath) else {
            print("删除record失败：目录不存在-\(filePath)")
            return false
        }
        
        do {
            try fileManager.removeItem(at: fileURL)
            print("删除record成功：\(filePath)")
            return true
        } catch {
            print("删除record失败：\(error.localizedDescription)")
            return false
        }
    }
    
    
    private func getRouteRecordGPXData(from record: RouteRecord) -> Data? {
        guard let outputURL = gpxFileURL(record.id) else {
            return nil
        }
        
        let readPoints = readPointsFromTxtFile()
        if generateGPXFile(from: readPoints, outputURL: outputURL) {
            return try? Data(contentsOf: outputURL)
        }
        return nil
    }
    
    /// 将轨迹点数据生成GPX文件
    /// - Parameters:
    ///   - points: 轨迹点数组
    ///   - outputURL: 输出文件路径
    ///   - name: 名称
    /// - Returns: 是否生成成功
    private func generateGPXFile(from points: [RecordPoint], outputURL: URL, name: String = "Generated Record") -> Bool {
        let gpxContent = generateGPXContent(from: points, name: name)
        
        do {
            try gpxContent.write(to: outputURL, atomically: true, encoding: .utf8)
            print("GPX文件生成成功：\(outputURL.path)")
            return true
        } catch {
            print("GPX文件生成失败：\(error.localizedDescription)")
            return false
        }
    }
    
    /// 生成GPX文件内容
    /// - Parameters:
    ///   - points: 轨迹点数组
    ///   - name: 名称
    /// - Returns: GPX格式的字符串内容
    private func generateGPXContent(from points: [RecordPoint], name: String) -> String {
        // 确保轨迹点按时间排序
        let sortedPoints = points.sorted { $0.timestamp < $1.timestamp }
        
        // 日期格式化器（用于生成GPX时间格式）
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        // 构建GPX文件内容
        var gpxContent = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        gpxContent += "<gpx version=\"1.1\" creator=\"天行探索\" xmlns=\"http://www.topografix.com/GPX/1/1\">\n"
        gpxContent += "  <trk>\n"
        gpxContent += "    <name>\(name)</name>\n"
        gpxContent += "    <trkseg>\n"
        
        // 添加所有轨迹点
        for point in sortedPoints {
            let timeString = dateFormatter.string(from: point.timestamp)
            gpxContent += "      <trkpt lat=\"\(point.latitude)\" lon=\"\(point.longitude)\">\n"
            gpxContent += "        <ele>\(point.altitude)</ele>\n"
            gpxContent += "        <time>\(timeString)</time>\n"
            gpxContent += "      </trkpt>\n"
        }
        
        // 闭合标签
        gpxContent += "    </trkseg>\n"
        gpxContent += "  </trk>\n"
        gpxContent += "</gpx>"
        
        return gpxContent
    }
    
    /// 解析GPX内容，提取坐标点
    /// - Parameter gpxContent: GPX格式的字符串内容
    /// - Returns: 坐标点数组
    private func parseGPXCoordinates(from gpxContent: String) -> [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []

        // 使用正则表达式匹配 <trkpt> 标签及其属性
        // 匹配格式：<trkpt lat="纬度" lon="经度">
        let pattern = "<trkpt\\s+lat=\"([+-]?\\d+\\.\\d+)\"\\s+lon=\"([+-]?\\d+\\.\\d+)\""

        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(gpxContent.startIndex..., in: gpxContent)
            let matches = regex.matches(in: gpxContent, options: [], range: range)

            for match in matches {
                // 提取纬度
                if let latRange = Range(match.range(at: 1), in: gpxContent),
                   let latString = Double(gpxContent[latRange]),
                   // 提取经度
                   let lonRange = Range(match.range(at: 2), in: gpxContent),
                   let lonString = Double(gpxContent[lonRange]) {
                    let coordinate = CLLocationCoordinate2D(latitude: latString, longitude: lonString)
                    coordinates.append(coordinate)
                }
            }
        } catch {
            print("正则表达式解析失败：\(error.localizedDescription)")
        }

        return coordinates
    }
    
    // MARK: - 目录路径
    
    private func gpxFileURL(_ routeId: Int64) -> URL? {

        guard let routeDirectory = getRouteDirectory() else {
            return nil
        }
        
        let fileName = String(routeId)
        guard !fileName.isEmpty else {
            return nil
        }
        
        let fileURL = routeDirectory.appendingPathComponent(fileName).appendingPathExtension(gpxExtension)
        return fileURL
    }
    
    private func getRouteDirectory() -> URL? {
        guard !UserManager.shared.userId.isEmpty else {
            return nil
        }
        
        guard let trackDirectory = SandBox.docmentsURL?.appendingPathComponent(UserManager.shared.userId).appendingPathComponent("route") else {
            return nil
        }
        
        // 创建主目录（如果不存在）
        do {
            try FileManager.default.createDirectory(at: trackDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("创建主目录失败：\(error.localizedDescription)")
            return nil
        }
        return trackDirectory
    }
    
}

// MARK: - network
extension TrackDataManager {
    
    /// 保存路线到地图服务
    /// - Parameters:
    ///   - record: 路线记录
    ///   - fileUrl: 上传后的文件URL
    func saveRouteToService(_ record: RouteRecord, completion: ((Bool, String?) -> Void)?) {
        guard let type = record.type else {
            completion?(false, nil)
            return
        }
        
        uploadRouteToService(record) { [weak self] fileUrl in
            guard let fileUrl = fileUrl else {
                completion?(false, nil)
                return
            }
            let routeName = record.routeName ?? "未命名"
            
            self?.mapService.saveUserRoute(type: type, name: routeName, desc: record.description, fileUrl: fileUrl) { [weak self] result in
                switch result {
                case .success(let response):
                    do {
                        let bizResponse = try JSONDecoder().decode(NetworkResponse<RouteRecord>.self, from: response.data)
                        if let route = bizResponse.data {
                            self?.deleteRouteFromLocal(record.id)
                            self?.saveRouteToLocal(route)
                            completion?(true, nil)
                        } else {
                            completion?(false, response.description)
                        }
                    } catch {
                        completion?(false, error.localizedDescription)
                    }
                case .failure(let error):
                    completion?(false, error.localizedDescription)
                }
            }
        }
    }
    
    // 删除路线
    func deleteRouteFromService(routeId: Int64, completion: ((Bool, String?) -> Void)?) {
        
        mapService.deleteRoute(routeId) { [weak self] result in
            switch result {
            case .success(let response):
                do {
                    let bizResponse = try JSONDecoder().decode(NetworkResponse<Bool>.self, from: response.data)
                    if bizResponse.data == true {
                        self?.deleteRouteFromLocal(routeId)
                        completion?(true, nil)
                    } else {
                        completion?(false, response.description)
                    }
                } catch {
                    completion?(false, error.localizedDescription)
                }
            case .failure(let error):
                completion?(false, error.localizedDescription)
            }
        }
    }
    
    private func uploadRouteToService(_ record: RouteRecord, completion: ((String?) -> Void)?) {
        guard let fileData = getRouteRecordGPXData(from: record) else {
            return
        }
        let routeName = record.routeName ?? "未命名"
        
        uploadManager.uploadFile(fileData: fileData, fileName: routeName, mimeType: gpxExtension) { progress in
            debugPrint("上传进度： \(progress)")
        } completion: { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.isSuccess, let fileUrl = response.data?.fileUrl {
                        completion?(fileUrl)
                    } else {
                        completion?(nil)
                        UIWindow.topWindow?.sw_showWarningToast("上传失败: \(response.msg ?? "未知错误")")
                    }
                case .failure(let error):
                    completion?(nil)
                    UIWindow.topWindow?.sw_showWarningToast("上传错误: \(error.localizedDescription)")
                }
            }
        }
    }
}
