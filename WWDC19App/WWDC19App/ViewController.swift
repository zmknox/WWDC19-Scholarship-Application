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

	private let session = AVCaptureSession()
	
	private let sessionQueue = DispatchQueue(label: "session queue") // Communicate with the session and other session objects on this queue.
	
	var videoDevice: AVCaptureDevice!
	var videoDeviceInput: AVCaptureDeviceInput!
	var photoOutput: AVCaptureOutput!
	
	@IBOutlet var cameraView: CameraView!
	
	@IBOutlet var filterPickerCollectionView: UICollectionView!
	
	override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		filterPickerCollectionView.delegate = self
		filterPickerCollectionView.dataSource = self
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
		//CameraFilters.distanceFilter(videoDevice)
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
		session.beginConfiguration()
		switch sender?.name {
		case "Far-Sighted":
			CameraFilters.distanceFilter(videoDevice, far: true, enabled: true)
		case "Near-Sighted":
			CameraFilters.distanceFilter(videoDevice, far: false, enabled: true)
		case "Light Sensitive":
			CameraFilters.lightFilter(videoDevice, over: true, enabled: true)
		case "No Detail":
			CameraFilters.lightFilter(videoDevice, over: false, enabled: true)
		case "Fully Colorblind":
			CameraFilters.colorFilter(videoDevice, full: true, enabled: true)
		default:
			session.commitConfiguration()
			return
		}
		session.commitConfiguration()
	}
}

