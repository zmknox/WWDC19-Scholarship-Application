//
//  ViewController.swift
//  WWDC19App
//
//  Copyright © 2019 Zachary Knox. All rights reserved.
//

import UIKit
import AVFoundation
import PlaygroundSupport

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
	var noPeripheral = false
	var noCentral = false
	var blind = false
}

@objc(Book_Sources_ViewController)
public class ViewController: UIViewController, PlaygroundLiveViewMessageHandler, PlaygroundLiveViewSafeAreaContainer, AVCaptureVideoDataOutputSampleBufferDelegate {

	public func receive(_ message: PlaygroundValue) { // For Playgrounds
		return
	}

	private var state = FilterState()
	
	private let session = AVCaptureSession()
	
	private let sessionQueue = DispatchQueue(label: "session queue") // Communicate with the session and other session objects on this queue.
	
	var videoDevice: AVCaptureDevice!
	var videoDeviceInput: AVCaptureDeviceInput!
	var photoOutput: AVCapturePhotoOutput!
	var dataOutput: AVCaptureVideoDataOutput!
	
	@IBOutlet var cameraView: CameraView!
	public var imageOverlay: UIImageView?
	let ciContext = CIContext()
	
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
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.001) {
			self.orientVideo()
		}
	}
	
	func orientVideo() {
		if let cameraLayerConnection = self.cameraView.cameraLayer.connection {
			let interfaceOrientation = self.interfaceOrientation // Using this as it is seemingly the ONLY way to get orientation in a playground — I really wish UIDevice.current.orientation worked in a playground
			var deviceOrientation: UIDeviceOrientation
			switch interfaceOrientation {
			case .portrait:
				deviceOrientation = .portrait
			case .portraitUpsideDown:
				deviceOrientation = .portraitUpsideDown
			case .landscapeLeft:
				deviceOrientation = .landscapeRight
			case .landscapeRight:
				deviceOrientation = .landscapeLeft
			default:
				deviceOrientation = .unknown
			}
			guard let newVideoOrientation = AVCaptureVideoOrientation(deviceOrientation: deviceOrientation),
				deviceOrientation.isPortrait || deviceOrientation.isLandscape else {
					return
			}
			
			cameraLayerConnection.videoOrientation = newVideoOrientation
		}
	}
	
	override public func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
	}
	
	override public func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		for v in cameraView.subviews {
			if v === imageOverlay {
				imageOverlay!.removeFromSuperview()
				imageOverlay!.frame = cameraView.frame
				cameraView.addSubview(imageOverlay!)
			}
			else if v is UIImageView {
				let image = (v as! UIImageView).image
				let tag = v.tag
				v.removeFromSuperview()
				let newView = UIImageView(image: image)
				newView.frame = cameraView.frame
				newView.contentMode = .scaleAspectFill
				newView.tag = tag
				cameraView.addSubview(newView)
			} else {
				v.removeFromSuperview()
				v.frame = CGRect(origin: v.frame.origin, size: CGSize(width: v.frame.size.height, height: v.frame.size.width))
				cameraView.addSubview(v)
			}
		}
	}
	
	override public func viewDidLoad() {
		super.viewDidLoad()
		
		liveViewSafeAreaGuide.bottomAnchor.constraint(equalTo: filterPickerCollectionView.bottomAnchor).isActive = true
		//filterPickerCollectionView.bottomAnchor.constraint(equalTo: liveViewSafeAreaGuide.bottomAnchor).isActive = true
		filterPickerCollectionView.delegate = self
		filterPickerCollectionView.dataSource = self
		
		selectionLabel.layer.opacity = 0
		
		imageOverlay = UIImageView()
		imageOverlay?.contentMode = .scaleAspectFill
		imageOverlay?.frame = view.frame
		imageOverlay?.alpha = 0
		cameraView.addSubview(imageOverlay!)
		
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
				dataOutput = AVCaptureVideoDataOutput()
				dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "dataOutput"))
				session.addOutput(dataOutput)
				session.commitConfiguration()
				
				self.session.startRunning()
				state.startedOnce = true
				
				// filter
				
				DispatchQueue.main.async {
					self.cameraView.cameraLayer.session = self.session
					self.orientVideo()
				}
				
			}
		}
		
	}
	
	public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		// filters
		if state.fullyColorblind {
			sessionQueue.async {
				let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
				let ciImage = CIImage(cvImageBuffer: imageBuffer!)
				
				let filter = CIFilter(name: "CIColorMonochrome")
				filter?.setValue(ciImage, forKey: "inputImage")
				let filteredImage = filter?.outputImage
				var transformedImage = filteredImage
				var uiImage: UIImage
				
				UIDevice.current.beginGeneratingDeviceOrientationNotifications()
				switch self.interfaceOrientation { // Using because UIDevice.current.orientation returns unknown in playgrounds
				case .portrait:
					transformedImage = filteredImage?.transformed(by: CGAffineTransform(rotationAngle: CGFloat((3 * Double.pi)/2)))
				case .landscapeLeft:
					transformedImage = filteredImage?.transformed(by: CGAffineTransform(rotationAngle: CGFloat(Double.pi)))
				case .portraitUpsideDown:
					transformedImage = filteredImage?.transformed(by: CGAffineTransform(rotationAngle: CGFloat(Double.pi/2)))
				default:
					transformedImage = filteredImage
				}
				UIDevice.current.endGeneratingDeviceOrientationNotifications()

				let cgImage = self.ciContext.createCGImage(transformedImage!, from: transformedImage!.extent)
				uiImage = UIImage(cgImage: cgImage!)
				
				DispatchQueue.main.async {
					self.imageOverlay!.image = uiImage
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
				CameraFilters.lightOnlyFilter(videoDevice, view: cameraView, enabled: true)
				state.noDetail = true
			} else if state.noDetail {
				CameraFilters.lightOnlyFilter(videoDevice, view: cameraView, enabled: false)
				state.noDetail = false
			} else {
				CameraFilters.lightOnlyFilter(videoDevice, view: cameraView, enabled: true)
				state.noDetail = true
			}
		case "Fully Colorblind":
			if state.fullyColorblind {
				imageOverlay!.alpha = 0
				state.fullyColorblind = false
			} else {
				imageOverlay!.alpha = 1
				state.fullyColorblind = true
			}
		case "Cataract":
			if state.cataract {
				CameraFilters.blurFilter(videoDevice, view: cameraView, darken: true, enabled: false)
				state.cataract = false
			} else {
				CameraFilters.blurFilter(videoDevice, view: cameraView, darken: true, enabled: true)
				state.cataract = true
			}
		case "No Peripheral Vision":
			if state.noPeripheral {
				CameraFilters.imageOverlayFilter(cameraView, image: UIImage(named: "NoPeripheral")!, tag: 21, enabled: false)
				state.noPeripheral = false
			} else {
				CameraFilters.imageOverlayFilter(cameraView, image: UIImage(named: "NoPeripheral")!, tag: 21, enabled: true)
				state.noPeripheral = true
			}
		case "No Central Vision":
			if state.noCentral {
				CameraFilters.imageOverlayFilter(cameraView, image: UIImage(named: "NoCentral")!, tag: 22, enabled: false)
				state.noCentral = false
			} else {
				CameraFilters.imageOverlayFilter(cameraView, image: UIImage(named: "NoCentral")!, tag: 22, enabled: true)
				state.noCentral = true
			}
		case "Glaucoma":
			if state.glaucoma {
				CameraFilters.imageOverlayFilter(cameraView, image: UIImage(named: "GlaucomaVisionLoss")!, tag: 23, enabled: false)
				state.glaucoma = false
			} else {
				CameraFilters.imageOverlayFilter(cameraView, image: UIImage(named: "GlaucomaVisionLoss")!, tag: 23, enabled: true)
				state.glaucoma = true
			}
		case "Retinal Detachment":
			if state.retinalDetachment {
				CameraFilters.imageOverlayFilter(cameraView, image: UIImage(named: "RetinalDetachment")!, tag: 24, enabled: false)
				state.retinalDetachment = false
			} else {
				CameraFilters.imageOverlayFilter(cameraView, image: UIImage(named: "RetinalDetachment")!, tag: 24, enabled: true)
				state.retinalDetachment = true
			}
		case "Blind":
			if state.blind {
				CameraFilters.imageOverlayFilter(cameraView, image: UIImage(named: "Blind")!, tag: 25, enabled: false)
				state.blind = false
			} else {
				CameraFilters.imageOverlayFilter(cameraView, image: UIImage(named: "Blind")!, tag: 25, enabled: true)
				state.blind = true
			}
		default:
			session.commitConfiguration()
			return
		}
		session.commitConfiguration()
		filterPickerCollectionView.reloadData()
	}
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {
	// MARK: Collection View
	public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return 11 // TODO
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
			if state.nearSighted {
				cell.imageView.image = UIImage(named: "Distance")
			} else {
				cell.imageView.image = UIImage(named: "DistanceDisabled")
			}
		case 1:
			cell.name = "Far-Sighted"
			cell.tapRecognizer.name = "Far-Sighted"
			if state.farSighted {
				cell.imageView.image = UIImage(named: "Distance")
			} else {
				cell.imageView.image = UIImage(named: "DistanceDisabled")
			}
		case 2:
			cell.name = "Light Sensitive"
			cell.tapRecognizer.name = "Light Sensitive"
			if state.lightSensitive {
				cell.imageView.image = UIImage(named: "Light")
			} else {
				cell.imageView.image = UIImage(named: "LightDisabled")
			}
		case 3:
			cell.name = "No Detail"
			cell.tapRecognizer.name = "No Detail"
			if state.noDetail {
				cell.imageView.image = UIImage(named: "Light")
			} else {
				cell.imageView.image = UIImage(named: "LightDisabled")
			}		case 4:
			cell.name = "Fully Colorblind"
			cell.tapRecognizer.name = "Fully Colorblind"
			if state.fullyColorblind {
				cell.imageView.image = UIImage(named: "Colorblind")
			} else {
				cell.imageView.image = UIImage(named: "ColorblindDisabled")
			}
		case 5:
			cell.name = "Cataract"
			cell.tapRecognizer.name = "Cataract"
			if state.cataract {
				cell.imageView.image = UIImage(named: "Cataracts")
			} else {
				cell.imageView.image = UIImage(named: "CataractsDisabled")
			}
		case 6:
			cell.name = "No Peripheral Vision"
			cell.tapRecognizer.name = "No Peripheral Vision"
			if state.noPeripheral {
				cell.imageView.image = UIImage(named: "NoPeripheralCV")
			} else {
				cell.imageView.image = UIImage(named: "NoPeripheralCVDisabled")
			}
		case 7:
			cell.name = "No Central Vision"
			cell.tapRecognizer.name = "No Central Vision"
			if state.noCentral {
				cell.imageView.image = UIImage(named: "NoCentralCV")
			} else {
				cell.imageView.image = UIImage(named: "NoCentralCVDisabled")
			}
		case 8:
			cell.name = "Glaucoma"
			cell.tapRecognizer.name = "Glaucoma"
			if state.glaucoma {
				cell.imageView.image = UIImage(named: "GlaucomaCV")
			} else {
				cell.imageView.image = UIImage(named: "GlaucomaCVDisabled")
			}
		case 9:
			cell.name = "Retinal Detachment"
			cell.tapRecognizer.name = "Retinal Detachment"
			if state.retinalDetachment {
				cell.imageView.image = UIImage(named: "RetinalDetachmentCV")
			} else {
				cell.imageView.image = UIImage(named: "RetinalDetachmentCVDisabled")
			}
		case 10:
			cell.name = "Blind"
			cell.tapRecognizer.name = "Blind"
			if state.blind {
				cell.imageView.image = UIImage(named: "BlindCV")
			} else {
				cell.imageView.image = UIImage(named: "BlindCVDisabled")
			}
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
			vc?.state = self.state
			self.present(vc!, animated: false, completion: nil)
		}
	}
	
	
}
