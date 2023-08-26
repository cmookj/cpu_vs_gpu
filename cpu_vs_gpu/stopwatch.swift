//
//  stopwatch.swift
//  AddCompute
//
//  Created by Changmook Chun on 11/28/21.
//

import Foundation

class StopWatch {
    init() {
        startTime = CFAbsoluteTimeGetCurrent()
        elapsedTime = 0
    }
    
    func tic() {
        startTime = CFAbsoluteTimeGetCurrent()
    }
    
    func toc() -> String {
        elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
        return String(format: "%0.5f", elapsedTime)
    }
    
    func measure(objFunc: () -> ()) -> CFAbsoluteTime {
        tic()
        objFunc()
        _ = toc()
        return elapsedTime
    }
    
    var startTime: CFAbsoluteTime
    var elapsedTime: CFAbsoluteTime
}
