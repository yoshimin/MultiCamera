//
//  ViewController.swift
//  MultiCamera
//
//  Created by Shingai Yoshimi on 2019/11/21.
//

import UIKit
import MetalKit
import AVFoundation

class ViewController: UIViewController {
    private let outputQueue = DispatchQueue(label: "outputQueue")
    private let session = AVCaptureMultiCamSession()
    private let backCameraVideoDataOutput = AVCaptureVideoDataOutput()
    private let frontCameraVideoDataOutput = AVCaptureVideoDataOutput()
    private var currentFrontBuffer: CVPixelBuffer?

    private var metalView: MetalView? {
        return view as? MetalView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard AVCaptureMultiCamSession.isMultiCamSupported else {
          assertionFailure("not supported")
          return
        }

        configure()
        session.startRunning()
    }
}

private extension ViewController {
    func configure() {
        session.beginConfiguration()
        configureBackCamera()
        configureFrontCamera()
        session.commitConfiguration()
        session.startRunning()
    }

    func configureBackCamera() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device) else { return }
        if session.canAddInput(input) {
            session.addInputWithNoConnections(input)
        }

        backCameraVideoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        backCameraVideoDataOutput.setSampleBufferDelegate(self, queue: outputQueue)
        if session.canAddOutput(backCameraVideoDataOutput) {
            session.addOutputWithNoConnections(backCameraVideoDataOutput)
        }

        let port = input.ports(for: .video, sourceDeviceType: device.deviceType, sourceDevicePosition: device.position)
        let connection = AVCaptureConnection(inputPorts: port, output: backCameraVideoDataOutput)
        connection.videoOrientation = .portrait

        if session.canAddConnection(connection) {
            session.addConnection(connection)
        }
    }

    func configureFrontCamera() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
            let input = try? AVCaptureDeviceInput(device: device) else { return }
        if session.canAddInput(input) {
            session.addInputWithNoConnections(input)
        }

        frontCameraVideoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        frontCameraVideoDataOutput.setSampleBufferDelegate(self, queue: outputQueue)
        if session.canAddOutput(frontCameraVideoDataOutput) {
            session.addOutputWithNoConnections(frontCameraVideoDataOutput)
        }

        let port = input.ports(for: .video, sourceDeviceType: device.deviceType, sourceDevicePosition: device.position)
        let connection = AVCaptureConnection(inputPorts: port, output: frontCameraVideoDataOutput)
        connection.videoOrientation = .portrait

        if session.canAddConnection(connection) {
            session.addConnection(connection)
        }
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let output = output as? AVCaptureVideoDataOutput,
            let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        if output == backCameraVideoDataOutput {
            guard let currentFrontBuffer = currentFrontBuffer else { return }
            DispatchQueue.main.async {
                self.metalView?.setPixelBuffer(main: pixelBuffer, sub: currentFrontBuffer)
            }
        }
        else if output == frontCameraVideoDataOutput {
            currentFrontBuffer = pixelBuffer
        }
    }
}
