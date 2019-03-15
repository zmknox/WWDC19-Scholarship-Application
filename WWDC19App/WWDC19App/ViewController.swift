//
//  ViewController.swift
//  WWDC19App
//
//  Created by Zach Knox on 3/14/19.
//  Copyright © 2019 Zachary Knox. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

	struct FilterState {
		var farSighted = false
		var nearSighted = false
		var lightSensitive = false
		var noDetail = false
		var fullyColorblind = false
	}

	private var state = FilterState()
	
	private let session = AVCaptureSession()
	
	private let sessionQueue = DispatchQueue(label: "session queue") // Communicate with the session and other session objects on this queue.
	
	var videoDevice: AVCaptureDevice!
	var videoDeviceInput: AVCaptureDeviceInput!
	var photoOutput: AVCaptureOutput!
	
	@IBOutlet var cameraView: CameraView!
	
	@IBOutlet var filterPickerCollectionView: UICollectionView!
	@IBOutlet var selectionLabel: UILabel!
	
	override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		filterPickerCollectionView.delegate = self
		filterPickerCollectionView.dataSource = self
		
		selectionLabel.layer.opacity = 0
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
		
		// Max frame rate
		var format: AVCaptureDevice.Format?
		var range: AVFrameRateRange?
		for f in videoDevice.formats {
			for r in f.videoSupportedFrameRateRanges {
				if range == nil || r.maxFrameRate > range!.maxFrameRate {
					format = f
					range = r
				}
			}
		}
		if format != nil {
			do {
				try videoDevice.lockForConfiguration()
				videoDevice.activeFormat = format!
				videoDevice.activeVideoMinFrameDuration = (range?.minFrameDuration)!
				videoDevice.activeVideoMaxFrameDuration = (range?.minFrameDuration)!
				videoDevice.unlockForConfiguration()
			} catch {
				return
			}
		}
		
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
	
	// MARK: Collection View
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return 6 // TODO
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FilterCell", for: indexPath) as! FilterCollectionViewCelll
		//Get tap of the cell
		cell.tapRecognizer.addTarget(self, action: #selector(ViewController.tapRecognizer(_:)))
		cell.gestureRecognizers = []
		cell.gestureRecognizers?.append(cell.tapRecognizer)
		switch indexPath.row { // TODO: Add image assignment here
		case 0:
			cell.name = "Far-Sighted"
			cell.tapRecognizer.name = "Far-Sighted"
		case 1:
			cell.name = "Near-Sighted"
			cell.tapRecognizer.name = "Near-Sighted"
		case 2:
			cell.name = "Light Sensitive"
			cell.tapRecognizer.name = "Light Sensitive"
		case 3:
			cell.name = "No Detail"
			cell.tapRecognizer.name = "No Detail"
		case 4:
			cell.name = "Fully Colorblind"
			cell.tapRecognizer.name = "Fully Colorblind"
		default:
			cell.name = "Default"
			cell.tapRecognizer.name = "Default"
		}
		
		cell.imageView.image = UIImage(named: "Light") // TODO: FIX FOR PLAYGROUND
		cell.imageView.contentMode = .center
		
		return cell
	}
	
	@objc func tapRecognizer(_ sender: UITapGestureRecognizer?) {
		selectionLabel.text = sender?.name?.uppercased()
		UIView.animate(withDuration: 0.2, animations: {
			self.selectionLabel.alpha = 1
		})
		DispatchQueue.main.asyncAfter(deadline: .now() + 1.3, execute: {
			UIView.animate(withDuration: 0.2, animations: {
				self.selectionLabel.alpha = 0
			})
		})
		session.beginConfiguration()
		switch sender?.name {
		case "Far-Sighted":
			if state.nearSighted {
				CameraFilters.distanceFilter(videoDevice, far: false, enabled: false)
				state.nearSighted = false
				CameraFilters.distanceFilter(videoDevice, far: true, enabled: true)
				state.farSighted = true
			} else if state.farSighted {
				CameraFilters.distanceFilter(videoDevice, far: true, enabled: false)
				state.farSighted = false
			} else {
				CameraFilters.distanceFilter(videoDevice, far: true, enabled: true)
				state.farSighted = true
			}
		case "Near-Sighted":
			if state.farSighted {
				CameraFilters.distanceFilter(videoDevice, far: true, enabled: false)
				state.farSighted = false
				CameraFilters.distanceFilter(videoDevice, far: false, enabled: true)
				state.nearSighted = true
			} else if state.nearSighted {
				CameraFilters.distanceFilter(videoDevice, far: false, enabled: false)
				state.nearSighted = false
			} else {
				CameraFilters.distanceFilter(videoDevice, far: false, enabled: true)
				state.nearSighted = true
			}
			CameraFilters.distanceFilter(videoDevice, far: false, enabled: true)
		case "Light Sensitive":
			if state.noDetail {
				CameraFilters.lightFilter(videoDevice, over: false, enabled: false)
				state.noDetail = false
				CameraFilters.lightFilter(videoDevice, over: true, enabled: true)
				state.lightSensitive = true
			} else if state.lightSensitive {
				CameraFilters.lightFilter(videoDevice, over: true, enabled: false)
				state.lightSensitive = false
			} else {
				CameraFilters.lightFilter(videoDevice, over: true, enabled: true)
				state.lightSensitive = true
			}
		case "No Detail":
			if state.lightSensitive {
				CameraFilters.lightFilter(videoDevice, over: true, enabled: false)
				state.lightSensitive = false
				CameraFilters.lightFilter(videoDevice, over: false, enabled: true)
				state.noDetail = true
			} else if state.noDetail {
				CameraFilters.lightFilter(videoDevice, over: false, enabled: false)
				state.noDetail = false
			} else {
				CameraFilters.lightFilter(videoDevice, over: false, enabled: true)
				state.noDetail = true
			}
		case "Fully Colorblind":
			_ = CameraFilters.colorFilter(videoDevice, full: true, enabled: true)
		default:
			session.commitConfiguration()
			return
		}
		session.commitConfiguration()
	}
}

