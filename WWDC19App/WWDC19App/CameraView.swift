//
//  CameraView.swift
//  WWDC19App
//
//  Created by Zoe Knox on 3/14/19.
//  Copyright © 2019 Zoe Knox. All rights reserved.
//

import UIKit
import AVFoundation

class CameraView: UIView {

	var cameraLayer: AVCaptureVideoPreviewLayer {
		guard let layer = layer as? AVCaptureVideoPreviewLayer else {
			fatalError("Expected `AVCaptureVideoPreviewLayer`")
		}
		layer.videoGravity = .resizeAspectFill
		return layer
	}
	
	var session: AVCaptureSession? {
		get {
			return cameraLayer.session
		}
		set {
			cameraLayer.session = newValue
		}
	}
	
	// MARK: UIView
	
	override class var layerClass: AnyClass {
		return AVCaptureVideoPreviewLayer.self
	}

}
