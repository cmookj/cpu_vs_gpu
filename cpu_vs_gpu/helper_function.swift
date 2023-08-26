//
//  helper_function.swift
//  AddCompute
//
//  Created by Changmook Chun on 11/28/21.
//

import Foundation
import MetalKit
import simd

//                                                    Averaging in compute way
// -----------------------------------------------------------------------------
func averageInComputeWay(images: [Float],
                         width w: Int,
                         height h: Int,
                         count: Int) {
    // The GPU we want to use
    let device = MTLCreateSystemDefaultDevice()
    
    // A fifo queue for sending commands to the gpu
    let commandQueue = device?.makeCommandQueue()
    
    // A library for getting our metal functions
    let gpuFunctionLibrary = device?.makeDefaultLibrary()
    
    // Grab our gpu function
    let averageGPUFunction = gpuFunctionLibrary?.makeFunction(name: "average_compute_function")
    
    var averageComputePipelineState: MTLComputePipelineState!
    do {
        averageComputePipelineState = try device?.makeComputePipelineState(function: averageGPUFunction!)
    }
    catch {
        print(error)
    }
    
    print()
    print("Compute Way")
    
    // Create the buffers to be sent to the gpu from our arrays
    let imageBuff = device?.makeBuffer(bytes: images,
                                       length: MemoryLayout<Float>.size * count * w * h,
                                       options:.storageModeShared)
    
    let resultBuff = device?.makeBuffer(length: MemoryLayout<Float>.size * w * h,
                                        options:.storageModeShared)
    
    var mutableCount = count
    let countBuff = device?.makeBuffer(bytes: &mutableCount,
                                       length: MemoryLayout<UInt>.size,
                                       options:.storageModeShared)
    
    var mutableSize = w * h
    let sizeBuff = device?.makeBuffer(bytes: &mutableSize,
                                      length: MemoryLayout<UInt>.size,
                                      options:.storageModeShared)
    
    // Create a buffer to be sent to the command queue
    let commandBuffer = commandQueue?.makeCommandBuffer()
    
    // Create an encoder to set values on the compute function
    let commandEncoder = commandBuffer?.makeComputeCommandEncoder()
    commandEncoder?.setComputePipelineState(averageComputePipelineState)
    
    // Set the parameters of our gpu function
    commandEncoder?.setBuffer(imageBuff, offset : 0, index : 0)
    commandEncoder?.setBuffer(resultBuff, offset : 0, index : 1)
    commandEncoder?.setBuffer(countBuff, offset : 0, index : 2)
    commandEncoder?.setBuffer(sizeBuff, offset : 0, index : 3)
    
    // Figure out how many threads we need to use for our operation
    let threadsPerGrid = MTLSize(width: w, height: 1, depth: 1)
    let maxThreadsPerThreadgroup = averageComputePipelineState.maxTotalThreadsPerThreadgroup
    let threadsPerThreadgroup = MTLSize(width: maxThreadsPerThreadgroup, height: 1, depth: 1)
    commandEncoder?.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
    
    // Tell the encoder that it is done encodig.  Now we can send this
    // off to the gpu.
    commandEncoder?.endEncoding()
    
    // Push this command to the command queue for processing
    commandBuffer?.commit()
    
    // Wait until the gpu function completes before working with any of
    // the data
    commandBuffer?.waitUntilCompleted()
    
    // Get the pointer to the beginning of our data
    var resultBufferPointer = resultBuff?.contents().bindMemory(to: Float.self,
                                                                capacity: MemoryLayout<Float>.size * count)
    
    // Print out all of our new added together array information
    for _ in 0..<10 {
        print("\(Float(resultBufferPointer!.pointee) as Any)")
        resultBufferPointer = resultBufferPointer?.advanced(by : 1)
    }
}

//                                 Averaging in compute way with multiple GPUs
// -----------------------------------------------------------------------------
func averageInMultipleComputeWay(images: [Float],
                                 width w: Int,
                                 height h: Int,
                                 count: Int) {
    // Get all the GPUs
    let devices = MTLCopyAllDevices()
    print ("The number of devices is \(devices.count)")
    
    // Preparation
    for i in 0..<devices.count {
        
        // The GPU we want to use
        let device = devices[i]
        
        // A fifo queue for sending commands to the gpu
        let commandQueue = device.makeCommandQueue()
        
        // A library for getting our metal functions
        let gpuFunctionLibrary = device.makeDefaultLibrary()
        
        // Grab our gpu function
        let averageGPUFunction = gpuFunctionLibrary?.makeFunction(name: "average_compute_function")
        
        var averageComputePipelineState: MTLComputePipelineState!
        do {
            averageComputePipelineState = try device.makeComputePipelineState(function: averageGPUFunction!)
        }
        catch {
            print(error)
        }
        
        print()
        print("Compute Way")
        
        // Create the buffers to be sent to the gpu from our arrays
        let imageBuff = device.makeBuffer(bytes: images,
                                          length: MemoryLayout<Float>.size * count * w * h,
                                          options:.storageModeShared)
        
        let resultBuff = device.makeBuffer(length: MemoryLayout<Float>.size * w * h,
                                           options:.storageModeShared)
        
        var mutableCount = count
        let countBuff = device.makeBuffer(bytes: &mutableCount,
                                          length: MemoryLayout<UInt>.size,
                                          options:.storageModeShared)
        
        var mutableSize = w * h
        let sizeBuff = device.makeBuffer(bytes: &mutableSize,
                                         length: MemoryLayout<UInt>.size,
                                         options:.storageModeShared)
        
        // Create a buffer to be sent to the command queue
        let commandBuffer = commandQueue?.makeCommandBuffer()
        
        // Create an encoder to set values on the compute function
        let commandEncoder = commandBuffer?.makeComputeCommandEncoder()
        commandEncoder?.setComputePipelineState(averageComputePipelineState)
        
        // Set the parameters of our gpu function
        commandEncoder?.setBuffer(imageBuff, offset : 0, index : 0)
        commandEncoder?.setBuffer(resultBuff, offset : 0, index : 1)
        commandEncoder?.setBuffer(countBuff, offset : 0, index : 2)
        commandEncoder?.setBuffer(sizeBuff, offset : 0, index : 3)
        
        // Figure out how many threads we need to use for our operation
        let threadsPerGrid = MTLSize(width: w, height: 1, depth: 1)
        let maxThreadsPerThreadgroup = averageComputePipelineState.maxTotalThreadsPerThreadgroup
        let threadsPerThreadgroup = MTLSize(width: maxThreadsPerThreadgroup, height: 1, depth: 1)
        commandEncoder?.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        
        // Tell the encoder that it is done encodig.  Now we can send this
        // off to the gpu.
        commandEncoder?.endEncoding()
        
        // Push this command to the command queue for processing
        commandBuffer?.commit()
        
        // Wait until the gpu function completes before working with any of
        // the data
        commandBuffer?.waitUntilCompleted()
        
        // Get the pointer to the beginning of our data
        var resultBufferPointer = resultBuff?.contents().bindMemory(to: Float.self,
                                                                    capacity: MemoryLayout<Float>.size * count)
        
        // Print out all of our new added together array information
        for _ in 0..<10 {
            print("\(Float(resultBufferPointer!.pointee) as Any)")
            resultBufferPointer = resultBufferPointer?.advanced(by : 1)
        }
    }
}


//                                                            Averaging in CPU
// -----------------------------------------------------------------------------
func averageInBasicForLoopWay(images: [Float],
                              width w: Int,
                              height h: Int,
                              count: Int) {
    print("Basic For Loop Way")
    
    let resolution = w * h
    var result = [Float].init(repeating: 0.0, count: w * h)
    
    // Process the average
    for i in 0..<count {
        for j in 0..<resolution {
            result[j] += images[i * resolution + j]
        }
    }
    
    for i in 0..<resolution {
        result[i] /= Float(count)
    }
    
    // Print out the results
    for i in 0..<10 {
        print("\(result[i])")
    }
}

//                                                     Averaging in CPU (SIMD)
// -----------------------------------------------------------------------------
func averageInSimdForLoopWay(images: [Float],
                             width w: Int,
                             height h: Int,
                             count: Int) {
    print("For Loop Way (with SIMD)")
    
    let resolution = w * h
    var result = [Float].init(repeating: 0.0, count: resolution)
    
    let vecSize = 8
    let jobSize = resolution / vecSize
    
    var simd_result = [simd_float8].init(repeating: simd_float8(repeating: 0.0), count: jobSize)
    
    // Process the average
    for i in 0..<count {
        for j in 0..<jobSize {
            let grid = simd_float8(images[resolution * i + j * vecSize + 0],
                                   images[resolution * i + j * vecSize + 1],
                                   images[resolution * i + j * vecSize + 2],
                                   images[resolution * i + j * vecSize + 3],
                                   images[resolution * i + j * vecSize + 4],
                                   images[resolution * i + j * vecSize + 5],
                                   images[resolution * i + j * vecSize + 6],
                                   images[resolution * i + j * vecSize + 7])
            simd_result[j] += grid
        }
    }
    
    for j in 0..<jobSize {
        simd_result[j] /= Float(count)
        result[j * vecSize + 0] = simd_result[j][0]
        result[j * vecSize + 1] = simd_result[j][1]
        result[j * vecSize + 2] = simd_result[j][2]
        result[j * vecSize + 3] = simd_result[j][3]
        result[j * vecSize + 4] = simd_result[j][4]
        result[j * vecSize + 5] = simd_result[j][5]
        result[j * vecSize + 6] = simd_result[j][6]
        result[j * vecSize + 7] = simd_result[j][7]
    }
    
    // Print out the results
    for i in 0..<10 {
        print("\(result[i])")
    }
}

func averageSubImage(_ image: UnsafeMutablePointer<Float>,
                     from b: Int,
                     to e: Int,
                     toResult result: UnsafeMutablePointer<Float>) {
    let vecSize = 8
    let jobSize = (e - b) / vecSize
    let resolution = width * height
    
    var simd_result = [simd_float8].init(repeating: simd_float8(repeating: 0.0), count: jobSize)
    
    // Process the average
    for i in 0..<count {
        for j in 0..<jobSize {
            let grid = simd_float8(image[resolution * i + b + j * vecSize + 0],
                                   image[resolution * i + b + j * vecSize + 1],
                                   image[resolution * i + b + j * vecSize + 2],
                                   image[resolution * i + b + j * vecSize + 3],
                                   image[resolution * i + b + j * vecSize + 4],
                                   image[resolution * i + b + j * vecSize + 5],
                                   image[resolution * i + b + j * vecSize + 6],
                                   image[resolution * i + b + j * vecSize + 7])
            simd_result[j] += grid
        }
    }
    
    for j in 0..<jobSize {
        simd_result[j] /= Float(count)
        result[j * vecSize + 0] = simd_result[j][0]
        result[j * vecSize + 1] = simd_result[j][1]
        result[j * vecSize + 2] = simd_result[j][2]
        result[j * vecSize + 3] = simd_result[j][3]
        result[j * vecSize + 4] = simd_result[j][4]
        result[j * vecSize + 5] = simd_result[j][5]
        result[j * vecSize + 6] = simd_result[j][6]
        result[j * vecSize + 7] = simd_result[j][7]
    }
}

func averageInSimdForLoopWay(images imageHead: UnsafeMutablePointer<Float>,
                             width w: Int,
                             height h: Int,
                             count c: Int,
                             inParallelWith countThreads: Int) {
    print("Multi-Threaded For Loop Way (with SIMD)")
    
    let resolution = w * h
    var result = [Float].init(repeating: 0.0, count: resolution)
    
    let head = withUnsafeMutablePointer(to: &result[0]) {
        $0.withMemoryRebound(to: Float.self, capacity: w * h * c) { $0 }
    }
    
    let countRowsInSubImage = h / countThreads
    
    let groupAveragingImages = DispatchGroup()
    for index in 0..<countThreads {
        DispatchQueue.global().async(group: groupAveragingImages) {
            averageSubImage(imageHead,
                            from: w * countRowsInSubImage * index,
                            to: w * countRowsInSubImage * (index + 1),
                            toResult: head + w * countRowsInSubImage * index)
        }
    }
    groupAveragingImages.wait()
    
    // Print out the results
    for i in 0..<10 {
        print("\(result[i])")
    }
}
