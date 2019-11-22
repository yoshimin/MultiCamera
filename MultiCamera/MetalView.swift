//
//  MetalView.swift
//  MultiCamera
//
//  Created by Shingai Yoshimi on 2019/11/21.
//

import UIKit
import MetalKit

class MetalView: MTKView {
    private var mixer: Mixer?
    private var mainTexture: MTLTexture?
    private var subTexture: MTLTexture?
    private var textureCache: CVMetalTextureCache?

    required init(coder: NSCoder) {
        super.init(coder: coder)
        device = MTLCreateSystemDefaultDevice()
        if let device = device {
            mixer = Mixer(device: device)
            CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &textureCache)
        }

        framebufferOnly = false
        autoResizeDrawable = false
    }

    func setPixelBuffer(main: CVPixelBuffer, sub: CVPixelBuffer) {
        mainTexture = createMetalTexture(from: main)
        subTexture = createMetalTexture(from: sub)
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let main = mainTexture, let sub = subTexture, let currentDrawable = currentDrawable else { return }
        mixer?.draw(main: main, sub: sub, drawable: currentDrawable)
    }
}

private extension MetalView {
    func createMetalTexture(from buffer: CVPixelBuffer) -> MTLTexture? {
        guard let textureCache = textureCache else { return nil }

        var cvMetalTexture: CVMetalTexture?
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                  textureCache,
                                                  buffer,
                                                  nil,
                                                  colorPixelFormat,
                                                  CVPixelBufferGetWidth(buffer),
                                                  CVPixelBufferGetHeight(buffer),
                                                  0,
                                                  &cvMetalTexture)

        guard let texture = cvMetalTexture else { return nil }

        return CVMetalTextureGetTexture(texture)
    }
}

