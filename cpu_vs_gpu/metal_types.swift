//
//  metal_types.swift
//  AddCompute
//
//  Created by Changmook Chun on 11/28/21.
//

import Foundation
import MetalKit

// =============================================================================
// MARK: METAL Data Structures
// =============================================================================
public enum MetalComputeError : Error {
    case memoryAllocationFailure
}

public enum BufferStorageMode {
    case managed
    case shared
    case pivate
}

public class ComputeContext {
    let device: MTLDevice
    let library: MTLLibrary
    let commandQueue: MTLCommandQueue
    
    public init() {
        // The GPU we want to use
        device = MTLCreateSystemDefaultDevice()!
        
        // A fifo queue for sending commands to the gpu
        commandQueue = device.makeCommandQueue()!
        
        // A library for getting our metal functions
        library = device.makeDefaultLibrary()!
    }
}

public class MetalComputeBuffer2D<ComputeType: Numeric> {
    let context: ComputeContext
    
    let width: Int
    let height: Int
    let storageMode: BufferStorageMode
    
    var buffer: MTLBuffer?
    var contents: UnsafeMutableRawPointer? {
        get {
            if buffer == nil {
                return nil
            }
            else {
                return buffer!.contents()
            }
        }
    }
    
    public init(width w: Int, height h: Int, withStorageMode mode: BufferStorageMode = .shared) throws {
        context = ComputeContext()
        
        width = w
        height = h
        storageMode = mode
        
        do {
            try createBuffer()
        }
        catch {
            print(error)
            throw error
        }
    }
    
    fileprivate func createBuffer() throws {
        var modeOptions: MTLResourceOptions
        switch (storageMode) {
        case .shared:
            modeOptions = .storageModeShared
            // The resource is stored in system memory and is accessible to both
            // the CPU and the GPU.
            // When either the CPU or GPU changes the contents of the resource,
            // you are responsible for synchronizing access to the buffer from
            // the other participant.
            // If you use the CPU to change the contents of the resource, you
            // must complete those changes before you commit a command buffer
            // that accesses that resource.
            // If you use encode commands in a command buffer that change the
            // contents of the resource, your code running on the CPU must not
            // read the contents of the resource until the command buffer completes
            // execution (that is, the status property of the MTLCommandBuffer
            // object is MTLCommandBufferStatus.completed).
            //
            // Default storage mode for MTLBuffer objects.
            // iOS, tvOS: default storage mode for MTLTexture objects.
            // macOS: shared storage mode is not available for MTLTexture objects.
            
        case .managed:
            modeOptions = .storageModeManaged
            // The CPU and GPU may maintain separate copies of the resource, and
            // any changes must be explicitly synchronized.
            // You explicitly decide when to synchronize changes between the CPU and GPU.
            // If you use the CPU to change the contents of a resource, you must
            // se one or more of the methods provided by the MTLBuffer or MTLTexture
            // protocols to copy the changes to the GPU.
            // If you use the GPU to change the contents of a resource, you must
            // encode a blit pass to copy the changes to the CPU.
            //
            // macOS: default storage mode for MTLTexture objects.
            // iOS, tvOS: managed storage mode is not available.
            
        case .pivate:
            modeOptions = .storageModePrivate
            // The resource can be accessed only by the GPU.
            // (Resource coherency between the CPU and GPU is not necessary)
        }
        
        guard let buff = context.device.makeBuffer(length: MemoryLayout<ComputeType>.size * width * height,
                                                   options: modeOptions)
        else {
            throw MetalComputeError.memoryAllocationFailure
        }
        
        buffer = buff
    }
    
    public func syncToGpu() {
        if storageMode == .managed {
            // Explicit synchronization necessary
            buffer?.didModifyRange(0..<MemoryLayout<ComputeType>.size * width * height)
        }
    }
}
