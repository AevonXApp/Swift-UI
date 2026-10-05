//
//  Data+Hex.swift
//  AevonXCore
//
//  Extension for converting Data to/from hexadecimal strings
//

import Foundation

public extension Data {
    /// Initialize Data from a hexadecimal string
    /// - Parameter hexString: A string containing hexadecimal characters (0-9, a-f, A-F)
    /// - Returns: Data if the string is valid hex, nil otherwise
    init?(hexString: String) {
        let hex = hexString.lowercased()
        
        // Validate length is even
        guard hex.count % 2 == 0 else { return nil }
        
        var data = Data(capacity: hex.count / 2)
        var index = hex.startIndex
        
        while index < hex.endIndex {
            let nextIndex = hex.index(index, offsetBy: 2)
            let byteString = hex[index..<nextIndex]
            
            guard let byte = UInt8(byteString, radix: 16) else {
                return nil
            }
            
            data.append(byte)
            index = nextIndex
        }
        
        self = data
    }
    
    /// Convert Data to a hexadecimal string
    var hexString: String {
        return self.map { String(format: "%02x", $0) }.joined()
    }
}
