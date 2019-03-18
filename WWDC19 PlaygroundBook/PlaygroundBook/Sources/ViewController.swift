//
//  ViewController.swift
//  WWDC19App
//
//  Created by Zach Knox on 3/14/19.
//  Copyright © 2019 Zachary Knox. All rights reserved.
//

import UIKit
import AVFoundation
import PlaygroundSupport

@objc(Book_Sources_ViewController)
public class ViewController: UIViewController, PlaygroundLiveViewMessageHandler, PlaygroundLiveViewSafeAreaContainer {

	public func receive(_ message: PlaygroundValue) { // For Playgrounds
		return
	}
	
	public struct FilterState {
		var startedOnce = false
		var farSighted = false
		var nearSighted = false
		var lightSensitive = false
		var noDetail = false
		var fullyColorblind = false
		var cataract = false
		var glaucoma = false
		var retinalDetachment = false
	}

	private var state = FilterState()
	
	private let session = AVCaptureSession()
	
	private let sessionQueue = DispatchQueue(label: "session queue") // Communicate with the session and other session objects on this queue.
	
	var videoDevice: AVCaptureDevice!
	var videoDeviceInput: AVCaptureDeviceInput!
	var photoOutput: AVCapturePhotoOutput!
	
	@IBOutlet var cameraView: CameraView!
	
	@IBOutlet var filterPickerCollectionView: UICollectionView!
	@IBOutlet var selectionLabel: UILabel!
	
	override public var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}
	
	@IBOutlet public var capture: UIButton!
	@IBAction public func captureButton(_ sender: Any) {
		let cameraLayerOrientation = cameraView.cameraLayer.connection?.videoOrientation

		sessionQueue.async {
			if let photoOutputConnection = self.photoOutput.connection(with: .video) {
				photoOutputConnection.videoOrientation = cameraLayerOrientation!
			}
			
			var settings = AVCapturePhotoSettings()
			if self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
				settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
			}
			
			settings.isHighResolutionPhotoEnabled = true
			
			// TODO: Capture Photo with photoOutput, making settings and a delegate for it
			self.photoOutput.capturePhoto(with: settings, delegate: self)
		}
		
	}
	
	override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		
		if let cameraLayerConnection = cameraView.cameraLayer.connection {
			let deviceOrientation = UIDevice.current.orientation
			guard let newVideoOrientation = AVCaptureVideoOrientation(deviceOrientation: deviceOrientation),
				deviceOrientation.isPortrait || deviceOrientation.isLandscape else {
					return
			}
			
			cameraLayerConnection.videoOrientation = newVideoOrientation
		}
	}
	
	override public func viewDidLoad() {
		super.viewDidLoad()
		
		filterPickerCollectionView.delegate = self
		filterPickerCollectionView.dataSource = self
		
		selectionLabel.layer.opacity = 0
		
		capture.setImage(UIImage(named: "Capture"), for: .normal) // TODO: FIX FOR PLAYGROUND
	}

	override public func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		sessionQueue.async {
			switch AVCaptureDevice.authorizationStatus(for: .video) {
			case .authorized: // The user has previously granted access to the camera.
				if self.state.startedOnce {
					self.session.startRunning()
				} else {
					self.setupSession()
				}
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
	
	override public func viewWillDisappear(_ animated: Bool) {
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
				photoOutput.isHighResolutionCaptureEnabled = true
				guard session.canAddOutput(photoOutput) else { return }
				session.sessionPreset = .photo
				session.addOutput(photoOutput)
				session.commitConfiguration()
				
				self.session.startRunning()
				state.startedOnce = true
				
				// filter
				
				DispatchQueue.main.async {
					self.cameraView.cameraLayer.session = self.session
				}
				
			}
		}
		
	}
	
	@objc public func tapRecognizer(_ sender: UITapGestureRecognizer?) {
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
		case "Near-Sighted":
			if state.farSighted {
				CameraFilters.distanceFilter(videoDevice, near: false, enabled: false)
				state.farSighted = false
				CameraFilters.distanceFilter(videoDevice, near: true, enabled: true)
				state.nearSighted = true
			} else if state.nearSighted {
				CameraFilters.distanceFilter(videoDevice, near: true, enabled: false)
				state.nearSighted = false
			} else {
				CameraFilters.distanceFilter(videoDevice, near: true, enabled: true)
				state.nearSighted = true
			}
		case "Far-Sighted":
			if state.nearSighted {
				CameraFilters.distanceFilter(videoDevice, near: true, enabled: false)
				state.nearSighted = false
				CameraFilters.distanceFilter(videoDevice, near: false, enabled: true)
				state.farSighted = true
			} else if state.farSighted {
				CameraFilters.distanceFilter(videoDevice, near: false, enabled: false)
				state.farSighted = false
			} else {
				CameraFilters.distanceFilter(videoDevice, near: false, enabled: true)
				state.farSighted = true
			}
			CameraFilters.distanceFilter(videoDevice, near: false, enabled: true)
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
		case "Cataract":
			if state.cataract {
				CameraFilters.blurFilter(videoDevice, view: cameraView, darken: true, enabled: false)
				state.cataract = false
			} else {
				CameraFilters.blurFilter(videoDevice, view: cameraView, darken: true, enabled: true)
				state.cataract = true
			}
		case "Glaucoma":
			if state.glaucoma {
				CameraFilters.imageOverlayFilter(cameraView, image: UIImage(named: "GlaucomaVisionLoss")!, tag: 21, enabled: false)
				state.glaucoma = false
			} else {
				CameraFilters.imageOverlayFilter(cameraView, image: UIImage(named: "GlaucomaVisionLoss")!, tag: 21, enabled: true)
				state.glaucoma = true
			}
		case "Retinal Detachment":
			if state.retinalDetachment {
				CameraFilters.imageOverlayFilter(cameraView, image: UIImage(named: "RetinalDetachment")!, tag: 22, enabled: false)
				state.retinalDetachment = false
			} else {
				CameraFilters.imageOverlayFilter(cameraView, image: UIImage(named: "RetinalDetachment")!, tag: 22, enabled: true)
				state.retinalDetachment = true
			}
		default:
			session.commitConfiguration()
			return
		}
		session.commitConfiguration()
	}
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {
	// MARK: Collection View
	public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return 8 // TODO
	}
	
	public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FilterCell", for: indexPath) as! FilterCollectionViewCelll
		//Get tap of the cell
		cell.tapRecognizer.addTarget(self, action: #selector(ViewController.tapRecognizer(_:)))
		cell.gestureRecognizers = []
		cell.gestureRecognizers?.append(cell.tapRecognizer)
		switch indexPath.row {
		case 0:
			cell.name = "Near-Sighted"
			cell.tapRecognizer.name = "Near-Sighted"
			cell.imageView.image = UIImage(named: "Distance") // TODO: FIX FOR PLAYGROUND
		case 1:
			cell.name = "Far-Sighted"
			cell.tapRecognizer.name = "Far-Sighted"
			cell.imageView.image = UIImage(named: "Distance") // TODO: FIX FOR PLAYGROUND
		case 2:
			cell.name = "Light Sensitive"
			cell.tapRecognizer.name = "Light Sensitive"
			cell.imageView.image = UIImage(named: "Light") // TODO: FIX FOR PLAYGROUND
		case 3:
			cell.name = "No Detail"
			cell.tapRecognizer.name = "No Detail"
			cell.imageView.image = UIImage(named: "Light") // TODO: FIX FOR PLAYGROUND
		case 4:
			cell.name = "Fully Colorblind"
			cell.tapRecognizer.name = "Fully Colorblind"
			cell.imageView.image = UIImage(named: "Colorblind") // TODO: FIX FOR PLAYGROUND
		case 5:
			cell.name = "Cataract"
			cell.tapRecognizer.name = "Cataract"
			cell.imageView.image = UIImage(named: "Light") // TODO: FIX FOR PLAYGROUND
		case 6:
			cell.name = "Glaucoma"
			cell.tapRecognizer.name = "Glaucoma"
			cell.imageView.image = UIImage(named: "Light") // TODO: FIX FOR PLAYGROUND
		case 7:
			cell.name = "Retinal Detachment"
			cell.tapRecognizer.name = "Retinal Detachment"
			cell.imageView.image = UIImage(named: "Light") // TODO: FIX FOR PLAYGROUND
		default:
			cell.name = "Default"
			cell.tapRecognizer.name = "Default"
		}
		
		cell.imageView.contentMode = .center
		
		return cell
	}
}

extension AVCaptureVideoOrientation {
	init?(deviceOrientation: UIDeviceOrientation) {
		switch deviceOrientation {
		case .portrait: self = .portrait
		case .portraitUpsideDown: self = .portraitUpsideDown
		case .landscapeLeft: self = .landscapeRight
		case .landscapeRight: self = .landscapeLeft
		default: return nil
		}
	}
}

extension ViewController: AVCapturePhotoCaptureDelegate {
	public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
		DispatchQueue.main.async {
			let vc = self.storyboard?.instantiateViewController(withIdentifier: "captured") as? CapturedViewController
			vc?.photo = photo
			self.present(vc!, animated: false, completion: nil)
		}
	}
	
	
}
