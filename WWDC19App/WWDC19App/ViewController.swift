//
//  ViewController.swift
//  WWDC19App
//
//  Created by Zach Knox on 3/14/19.
//  Copyright © 2019 Zachary Knox. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

	private let session = AVCaptureSession()
	
	private let sessionQueue = DispatchQueue(label: "session queue") // Communicate with the session and other session objects on this queue.
	
	var videoDevice: AVCaptureDevice!
	var videoDeviceInput: AVCaptureDeviceInput!
	var photoOutput: AVCaptureOutput!
	
	@IBOutlet var cameraView: CameraView!
	
	override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Do any additional setup after loading the view, typically from a nib.
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		sessionQueue.async {
			switch AVCaptureDevice.authorizationStatus(for: .video) {
			case .authorized: // The user has previously granted access to the camera.
				self.setupSession()
				
			case .notDetermined: // The user has not yet been asked for camera access.
				AVCaptureDevice.requestAccess(for: .video) { granted in
					if granted {
						self.setupSession()
					}
				}
				
			case .denied: // The user has previously denied access.
				return
			case .restricted: // The user can't grant access due to restrictions.
				return
			}
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		sessionQueue.async {
			self.session.stopRunning()
		}
		
		super.viewWillDisappear(animated)
	}

	func setupSession() {
		videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .unspecified)
		CameraFilters.distanceFilter(videoDevice)
		videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice!)
		if videoDeviceInput != nil {
			if session.canAddInput(videoDeviceInput) {
				session.addInput(videoDeviceInput)
				
				photoOutput = AVCapturePhotoOutput()
				guard session.canAddOutput(photoOutput) else { return }
				session.sessionPreset = .photo
				session.addOutput(photoOutput)
				session.commitConfiguration()
				
				self.session.startRunning()
				
				// filter
				
				DispatchQueue.main.async {
					self.cameraView.cameraLayer.session = self.session
				}
				
			}
		}
	}
}

