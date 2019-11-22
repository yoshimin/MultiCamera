//
//  Mixer.swift
//  MultiCamera
//
//  Created by Shingai Yoshimi on 2019/11/21.
//

import Foundation
import CoreVideo
import MetalKit

class Mixer {
    private let semaphore = DispatchSemaphore(value: 3)
    private let device: MTLDevice
    private var commandQueue: MTLCommandQueue?
    private var pipelineState: MTLComputePipelineState?
    

    init(device: MTLDevice) {
        self.device = device

        guard let defaultLibrary = device.makeDefaultLibrary(),
            let function = defaultLibrary.makeFunction(name: "mix") else { return }
        pipelineState = try? device.makeComputePipelineState(function: function)
        commandQueue = device.makeCommandQueue()
    }

    func draw(main: MTLTexture, sub: MTLTexture, drawable: CAMetalDrawable) {
        guard let pipelineState = pipelineState else { return }

        semaphore.wait()

        let commandBuffer = commandQueue?.makeCommandBuffer()

        let encoder = commandBuffer?.makeComputeCommandEncoder()
        encoder?.setComputePipelineState(pipelineState)
        encoder?.setTexture(main, index: 0)
        encoder?.setTexture(sub, index: 1)
        encoder?.setTexture(drawable.texture, index: 2)

        let w = pipelineState.threadExecutionWidth
        let h = pipelineState.maxTotalThreadsPerThreadgroup / w
        let groupsize = MTLSizeMake(w, h, 1)
        let numgroups = MTLSize(width: (main.width + groupsize.width - 1) / groupsize.width,
                                height: (main.height + groupsize.height - 1) / groupsize.height,
                                depth: 1)

        encoder?.dispatchThreadgroups(numgroups, threadsPerThreadgroup: groupsize)
        encoder?.endEncoding()

        commandBuffer?.addCompletedHandler { _ in
            self.semaphore.signal()
        }

        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
}
