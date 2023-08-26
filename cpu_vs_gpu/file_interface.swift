//
//  file_interface.swift
//  AddCompute
//
//  Created by Changmook Chun on 11/28/21.
//

import Foundation

// =============================================================================
// MARK: Raw File Loader
// =============================================================================
public func loadRawData<RawType: Numeric> (from fPath: String,
                                           countViews cv: Int,
                                           width w: Int,
                                           height h: Int,
                                           offset os: Int,
                                           count ct: Int) -> [RawType] {
    let width = w
    let height = h

    var grid = Array<RawType>(repeating:0, count: ct*width*height)
    
    loadViews(fromFile: fPath, to: &grid, withOffset: os, countViews: ct)
    
    // print("Raw binary file loaded successfully")
    
    return grid
}

public func loadRawData<RawType: Numeric> (from fPath: String,
                                           countViews cv: Int,
                                           width w: Int,
                                           height h: Int,
                                           viewSize vs: ViewMetric) -> [RawType] {
    let width = w
    let height = h

    var grid = Array<RawType>(repeating: 0, count: cv*width*height)
    
    loadViews(fromFile: fPath, to: &grid, withOffset: 0, countViews: cv)
    
    return grid
}

fileprivate func loadViews<RawType: Numeric>(fromFile filePath: String,
                                             to grid: inout [RawType],
                                             withOffset offset: Int,
                                             countViews count: Int) {
    guard let data = NSData(contentsOfFile: filePath)
    else {
        print("Could not open the file \(filePath)")
        return
    }
    
    let viewSize = width * height
    let dataRange = NSRange(location: offset * viewSize * MemoryLayout<RawType>.size,
                            length: count * viewSize * MemoryLayout<RawType>.size)
    data.getBytes(&grid, range: dataRange)
}
