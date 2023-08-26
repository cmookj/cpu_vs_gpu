//
//  main.swift
//  AddCompute
//
//  Created by Changmook Chun on 6/30/21.
//

import MetalKit

// =============================================================================
// MARK: View & Sweep Metrics
// =============================================================================
public struct ViewMetric {
    let width: Int
    let height: Int
}

// Size of a sweep
public struct SweepMetric {
    let countSweeps: Int
    let countViews: Int
}


// =============================================================================
//                                                         Program Begins Here
// =============================================================================
var stopWatch = StopWatch()

#if false
let count: Int = 800
let width: Int = 1280
let height: Int = 960

var images = [Float].init(repeating: 0.0, count: width * height * count)
let head = withUnsafeMutablePointer(to: &images[0]) {
    $0.withMemoryRebound(to: Float.self, capacity: width * height * count) { $0 }
}

stopWatch.tic()
randomImages(head, width: width, height: height, count: count, inParallelWith: countThreads)
let elapsedTimeParalle = stopWatch.toc()
print("Parallel creation of \(count) images (\(width) x \(height)): \(elapsedTimeParalle) seconds")

stopWatch.tic()
randomImages(head, width: width, height: height, count: count)
let elapsedTimeSerial = stopWatch.toc()
print("Serial creation of \(count) images (\(width) x \(height)): \(elapsedTimeSerial) seconds")

#endif

let countThreads: Int = 8

let width: Int = 2064
let height: Int = 128
let count: Int = 1875

let viewMetric = ViewMetric(width: width, height: height)
let sweepMetric = SweepMetric(countSweeps: 2, countViews: count)
var average: MetalComputeBuffer2D<Float>
var metalView: MetalComputeBuffer2D<Float>

do {
    average = try MetalComputeBuffer2D<Float>(width: width, height: height)
    metalView = try MetalComputeBuffer2D<Float>(width: width, height: height)
}
catch {
    print("Failed to create device memory")
    exit(EXIT_FAILURE)
}

var darkViews: [UInt16] = loadRawData(from: "/Users/me/Desktop/dark/dark_0_0000",
                                      countViews: sweepMetric.countViews,
                                      width: viewMetric.width,
                                      height: viewMetric.height,
                                      offset: 0,
                                      count: count)

let elapsedTime = stopWatch.measure {
    for i in 0..<count {
        let head = withUnsafeMutablePointer(to: &darkViews[i*width*height]) {
            $0.withMemoryRebound(to: UInt16.self, capacity: width * height) { $0 }
        }
        inject(head, toMetalComputeBuffer2D: metalView, withWidth: width, andHeight: height)
        metalView.syncToGpu()
        
        accumulateMetalComputeBeffer2D(metalView, to: average)
        
        print("\(i)")
    }
    
    multiplyMetalComputeBeffer2D(Float(count), to: average)
}

print("Binary file loading, conversion (uint16 to float), and averaging: \(elapsedTime) sec")


/*
 let darkUp1 = RawFileLoader<UInt16>(filePath: "/Users/me/Desktop/dark/dark_0_0000",
 countViews: sweepMetric.countViews,
 viewSize: viewMetric,
 offset: 100,
 count: 10)
 
 let darkUp2 = RawFileLoader<UInt16>(filePath: "/Users/me/Desktop/dark/dark_0_0001",
 countViews: sweepMetric.countViews,
 viewSize: viewMetric,
 offset: 100,
 count: 20)
 */

#if false

stopWatch.tic()
averageInComputeWay(images: darkUp1.grid, width: width, height: height, count: count)
let elapsedTimeInComputeWay = stopWatch.toc()
print("Averaging \(count) images (\(width) x \(height)) in compute way: \(elapsedTimeInComputeWay) seconds")

stopWatch.tic()
averageInBasicForLoopWay(images: darkUp1.grid, width: width, height: height, count: count)
let elapsedTimeInBasicForLoopWay = stopWatch.toc()
print("Averaging \(count) images (\(width) x \(height)) in basic for-loop way: \(elapsedTimeInBasicForLoopWay) seconds")

stopWatch.tic()
averageInSimdForLoopWay(images: darkUp1.grid, width: width, height: height, count: count)
let elapsedTimeInSimdForLoopWay = stopWatch.toc()
print("Averaging \(count) images (\(width) x \(height)) in SIMD for-loop way: \(elapsedTimeInSimdForLoopWay) seconds")

stopWatch.tic()
let head = withUnsafeMutablePointer(to: &darkUp1.grid[0]) {
    $0.withMemoryRebound(to: Float.self, capacity: width * height * count) { $0 }
}
averageInSimdForLoopWay(images: head, width: width, height: height, count: count, inParallelWith: countThreads)
let elapsedTimeInMultiThreadedSimdForLoopWay = stopWatch.toc()
print("Averaging \(count) images (\(width) x \(height)) in multi-threaded SIMD for-loop way: \(elapsedTimeInMultiThreadedSimdForLoopWay) seconds")

#endif
