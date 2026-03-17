//
//  PolylineDecoder.swift
//  ModuleMap
//
//  Created by Claude on 2026/3/9.
//

import Foundation
import CoreLocation

/// Google Polyline 编码/解码器
public class PolylineDecoder {

    // MARK: - 解码

    /// 解码 Google Polyline 格式的字符串为坐标数组
    /// - Parameter encodedString: Polyline 编码的字符串
    /// - Returns: 坐标点数组
    public static func decode(_ encodedString: String) -> [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []
        var index = 0

        var lat = 0.0
        var lon = 0.0

        while index < encodedString.count {
            // 解码纬度
            var result = 0
            var shift = 0
            var byte: Int

            repeat {
                let characterIndex = encodedString.index(encodedString.startIndex, offsetBy: index)
                let character = encodedString[characterIndex]

                // 将字符转换为 0-63 的值
                byte = Int(character.asciiValue ?? 63) - 63
                index += 1

                result |= (byte & 0x1F) << shift
                shift += 5
            } while byte >= 0x20

            // 判断是否为负数
            if (result & 1) != 0 {
                result = ~(result >> 1)
            } else {
                result = result >> 1
            }

            lat += Double(result) * 1e-5

            // 解码经度
            result = 0
            shift = 0

            repeat {
                let characterIndex = encodedString.index(encodedString.startIndex, offsetBy: index)
                let character = encodedString[characterIndex]

                byte = Int(character.asciiValue ?? 63) - 63
                index += 1

                result |= (byte & 0x1F) << shift
                shift += 5
            } while byte >= 0x20

            if (result & 1) != 0 {
                result = ~(result >> 1)
            } else {
                result = result >> 1
            }

            lon += Double(result) * 1e-5

            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            coordinates.append(coordinate)
        }

        return coordinates
    }

    // MARK: - 编码

    /// 将坐标数组编码为 Google Polyline 格式的字符串
    /// - Parameters:
    ///   - coordinates: 坐标点数组
    ///   - precision: 精度（默认 5，即 1e-5）
    /// - Returns: Polyline 编码的字符串
    public static func encode(_ coordinates: [CLLocationCoordinate2D], precision: Int = 5) -> String {
        var encoded = ""
        var lastLat = 0
        var lastLon = 0

        let factor = pow(10.0, Double(precision))

        for coordinate in coordinates {
            // 处理纬度
            var lat = Int(round(coordinate.latitude * factor))
            lat -= lastLat
            lastLat = Int(round(coordinate.latitude * factor))

            lat = (lat < 0) ? ~(lat << 1) : (lat << 1)
            encoded += encodeNumber(lat)

            // 处理经度
            var lon = Int(round(coordinate.longitude * factor))
            lon -= lastLon
            lastLon = Int(round(coordinate.longitude * factor))

            lon = (lon < 0) ? ~(lon << 1) : (lon << 1)
            encoded += encodeNumber(lon)
        }

        return encoded
    }

    /// 编码数字
    private static func encodeNumber(_ num: Int) -> String {
        var num = num
        var encoded = ""

        while num >= 0x20 {
            let value = (0x20 | (num & 0x1F)) + 63
            encoded.append(Character(UnicodeScalar(UInt8(value))))
            num >>= 5
        }

        // 最后一部分
        let value = num + 63
        encoded.append(Character(UnicodeScalar(UInt8(value))))

        return encoded
    }
}
