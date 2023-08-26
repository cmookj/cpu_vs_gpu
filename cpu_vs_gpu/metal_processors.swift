//
//  metal_processors.swift
//  AddCompute
//
//  Created by Changmook Chun on 11/28/21.
//

import Foundation
import MetalKit

// =============================================================================
// MARK: METAL Data Processors
// =============================================================================
public func convertToMetalComputeBeffer2D<RawType: Numeric, ComputeType: Numeric>(_ data: inout [RawType],
                                                                                  width w: Int,
                                                                                  height h: Int
    ) -> MetalComputeBuffer2D<ComputeType>? {
    
    let output: MetalComputeBuffer2D<ComputeType>?
    do {
        output = try MetalComputeBuffer2D<ComputeType>(width: w, height: h)
    }
    catch {
        return nil
    }
        
//    let head = withUnsafePointer(to: &data[0]) {
//        $0.withMemoryRebound(to: RawType.self, capacity: w*h) { $0 }
//    }
    
    // Grab our gpu function
    let gpuFunction = output!.context.library.makeFunction(name: "uint16_to_float")
        
    var gpuPipelineState: MTLComputePipelineState!
    do {
        gpuPipelineState = try output!.context.device.makeComputePipelineState(function: gpuFunction!)
    }
    catch {
        print(error)
        return nil
    }
                
    // Create the buffers to be sent to the gpu from our arrays
    let inputBuff = output!.context.device.makeBuffer(bytes: data,
                                       length: MemoryLayout<RawType>.size * width * height,
                                       options:.storageModeShared)
    
    var mutableSize = width * height
    let sizeBuff = output!.context.device.makeBuffer(bytes: &mutableSize,
                                      length: MemoryLayout<UInt>.size,
                                      options:.storageModeShared)
    
    // Create a buffer to be sent to the command queue
    let commandBuffer = output!.context.commandQueue.makeCommandBuffer()
    
    // Create an encoder to set values on the compute function
    let commandEncoder = commandBuffer?.makeComputeCommandEncoder()
    commandEncoder?.setComputePipelineState(gpuPipelineState)
    
    // Set the parameters of our gpu function
    commandEncoder?.setBuffer(inputBuff, offset : 0, index : 0)
    commandEncoder?.setBuffer(output!.buffer, offset : 0, index : 1)
    commandEncoder?.setBuffer(sizeBuff, offset : 0, index : 2)
    
    // Figure out how many threads we need to use for our operation
    let threadsPerGrid = MTLSize(width: width, height: 1, depth: 1)
    let maxThreadsPerThreadgroup = gpuPipelineState.maxTotalThreadsPerThreadgroup
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
    
    return output
        
        #if false
        // Get the pointer to the beginning of our data
        var resultBufferPointer = buffer?.contents().bindMemory(to: ComputeType.self,
                                                                    capacity: MemoryLayout<ComputeType>.size * width * height)
        
        // Copy the converted values to the main memory
        for i in 0..<width * height {
            grid[i] = resultBufferPointer!.pointee as ComputeType
            resultBufferPointer = resultBufferPointer?.advanced(by : 1)
        }
        #endif
}

public func inject<RawType: Numeric, ComputeType: Numeric>(_ data: UnsafePointer<RawType>,
                                                           toMetalComputeBuffer2D metalBuffer: MetalComputeBuffer2D<ComputeType>,
                                                           withWidth w: Int,
                                                           andHeight h: Int) {
    // Grab our gpu function
    let gpuFunction = metalBuffer.context.library.makeFunction(name: "uint16_to_float")
        
    var gpuPipelineState: MTLComputePipelineState!
    do {
        gpuPipelineState = try metalBuffer.context.device.makeComputePipelineState(function: gpuFunction!)
    }
    catch {
        print(error)
    }
                
    // Create the buffers to be sent to the gpu from our arrays
    let inputBuff = metalBuffer.context.device.makeBuffer(bytes: data,
                                       length: MemoryLayout<RawType>.size * width * height,
                                       options:.storageModeShared)
    
    var mutableSize = width * height
    let sizeBuff = metalBuffer.context.device.makeBuffer(bytes: &mutableSize,
                                      length: MemoryLayout<UInt>.size,
                                      options:.storageModeShared)
    
    // Create a buffer to be sent to the command queue
    let commandBuffer = metalBuffer.context.commandQueue.makeCommandBuffer()
    
    // Create an encoder to set values on the compute function
    let commandEncoder = commandBuffer?.makeComputeCommandEncoder()
    commandEncoder?.setComputePipelineState(gpuPipelineState)
    
    // Set the parameters of our gpu function
    commandEncoder?.setBuffer(inputBuff, offset : 0, index : 0)
    commandEncoder?.setBuffer(metalBuffer.buffer, offset : 0, index : 1)
    commandEncoder?.setBuffer(sizeBuff, offset : 0, index : 2)
    
    // Figure out how many threads we need to use for our operation
    let threadsPerGrid = MTLSize(width: width, height: 1, depth: 1)
    let maxThreadsPerThreadgroup = gpuPipelineState.maxTotalThreadsPerThreadgroup
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
}

public func accumulateMetalComputeBeffer2D<ComputeType: Numeric>(_ input: MetalComputeBuffer2D<ComputeType>,
                                                                 to output: MetalComputeBuffer2D<ComputeType>) {
    
    // Grab our gpu function
    let averageGPUFunction = output.context.library.makeFunction(name: "accumulate_compute_function")
    
    var averageComputePipelineState: MTLComputePipelineState!
    do {
        averageComputePipelineState = try output.context.device.makeComputePipelineState(function: averageGPUFunction!)
    }
    catch {
        print(error)
    }
            
    var mutableSize = output.width * output.height
    let sizeBuff = output.context.device.makeBuffer(bytes: &mutableSize,
                                      length: MemoryLayout<UInt>.size,
                                      options:.storageModeShared)
    
    // Create a buffer to be sent to the command queue
    let commandBuffer = output.context.commandQueue.makeCommandBuffer()
    
    // Create an encoder to set values on the compute function
    let commandEncoder = commandBuffer?.makeComputeCommandEncoder()
    commandEncoder?.setComputePipelineState(averageComputePipelineState)
    
    // Set the parameters of our gpu function
    commandEncoder?.setBuffer(input.buffer, offset : 0, index : 0)
    commandEncoder?.setBuffer(output.buffer, offset : 0, index : 1)
    commandEncoder?.setBuffer(sizeBuff, offset : 0, index : 2)
    
    // Figure out how many threads we need to use for our operation
    let threadsPerGrid = MTLSize(width: output.width, height: 1, depth: 1)
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
    // var resultBufferPointer = resultBuff?.contents().bindMemory(to: Float.self,
    //                                                            capacity: MemoryLayout<Float>.size * count)
}

public func multiplyMetalComputeBeffer2D<ComputeType: Numeric>(_ f: ComputeType,
                                                                 to output: MetalComputeBuffer2D<ComputeType>) {
    
    // Grab our gpu function
    let kernelFunction = output.context.library.makeFunction(name: "multiply_compute_function")
    
    var computePipelineState: MTLComputePipelineState!
    do {
        computePipelineState = try output.context.device.makeComputePipelineState(function: kernelFunction!)
    }
    catch {
        print(error)
    }
            
    var mutableSize = output.width * output.height
    let sizeBuff = output.context.device.makeBuffer(bytes: &mutableSize,
                                      length: MemoryLayout<UInt>.size,
                                      options:.storageModeShared)
    
    var factor = f
    let factorBuff = output.context.device.makeBuffer(bytes: &factor,
                                                      length: MemoryLayout<ComputeType>.size,
                                                      options:.storageModeShared)
    
    // Create a buffer to be sent to the command queue
    let commandBuffer = output.context.commandQueue.makeCommandBuffer()
    
    // Create an encoder to set values on the compute function
    let commandEncoder = commandBuffer?.makeComputeCommandEncoder()
    commandEncoder?.setComputePipelineState(computePipelineState)
    
    // Set the parameters of our gpu function
    commandEncoder?.setBuffer(output.buffer, offset : 0, index : 0)
    commandEncoder?.setBuffer(factorBuff, offset : 0, index : 1)
    commandEncoder?.setBuffer(sizeBuff, offset : 0, index : 2)
    
    // Figure out how many threads we need to use for our operation
    let threadsPerGrid = MTLSize(width: output.width, height: 1, depth: 1)
    let maxThreadsPerThreadgroup = computePipelineState.maxTotalThreadsPerThreadgroup
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
    // var resultBufferPointer = resultBuff?.contents().bindMemory(to: Float.self,
    //                                                            capacity: MemoryLayout<Float>.size * count)
}
