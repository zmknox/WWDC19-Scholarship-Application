//
//  CameraView.swift
//  WWDC19App
//
//  Copyright © 2019 Zachary Knox. All rights reserved.
//

import UIKit
import AVFoundation

@objc(Book_Sources_CameraView)
public class CameraView: UIView {

	public var cameraLayer: AVCaptureVideoPreviewLayer {
		guard let layer = layer as? AVCaptureVideoPreviewLayer else {
			fatalError("Expected `AVCaptureVideoPreviewLayer`")
		}
		layer.videoGravity = .resizeAspectFill
		return layer
	}
	
	public var session: AVCaptureSession? {
		get {
			return cameraLayer.session
		}
		set {
			cameraLayer.session = newValue
		}
	}
	
	// MARK: UIView
	
	override public class var layerClass: AnyClass {
		return AVCaptureVideoPreviewLayer.self
	}

}
