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
	var nearSighted = false
	var lightSensitive = false
	var noDetail = false
	var fullyColorblind = false
	var cataract = false
	var glaucoma = false
	var retinalDetachment = false
	var macularDegeneration = false
	var diabeticRetinopathy = false
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
	
	private var session: AVCaptureSession!
	
	private let sessionQueue = DispatchQueue(label: "session queue") // Communicate with the session and other session objects on this queue.
	
	var videoDevice: AVCaptureDevice!
	var videoDeviceInput: AVCaptureDeviceInput!
	var photoOutput: AVCapturePhotoOutput!
	var dataOutput: AVCaptureVideoDataOutput!
	
	@IBOutlet var cameraView: CameraView!
	public var imageOverlay: UIImageView?
	public var colorOverlay: UIView?
	let ciContext = CIContext()
	
	@IBOutlet var filterPickerCollectionView: UICollectionView!
	@IBOutlet var selectionLabel: UILabel!
	@IBOutlet var loadingView: UIActivityIndicatorView!
	
	override public var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}
	
	@IBOutlet public var capture: UIButton!
	@IBAction public func captureButton(_ sender: Any) {
		if !state.startedOnce {
			return
		}
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

		filterPickerCollectionView.delegate = self
		filterPickerCollectionView.dataSource = self
		
		selectionLabel.layer.opacity = 0
		
		imageOverlay = UIImageView()
		imageOverlay?.contentMode = .scaleAspectFill
		imageOverlay?.frame = view.frame
		imageOverlay?.alpha = 0
		cameraView.addSubview(imageOverlay!)
		colorOverlay = UIView(frame: view.frame)
		colorOverlay?.alpha = 0
		cameraView.addSubview(colorOverlay!)
		
		capture.setImage(UIImage(named: "Capture"), for: .normal)
	}

	override public func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		switch AVCaptureDevice.authorizationStatus(for: .video) {
		case .authorized: // The user has previously granted access to the camera.
			self.session = AVCaptureSession()
			self.setupSession()
		case .notDetermined: // The user has not yet been asked for camera access.
			AVCaptureDevice.requestAccess(for: .video) { granted in
				if granted {
					self.session = AVCaptureSession()
					self.setupSession()
				} else {
					DispatchQueue.main.async {
						let alert = UIAlertController(title: "Camera Access Required", message: "To experience the various camera filters in this playground, camera access is required.", preferredStyle: .alert)
						alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
							alert.dismiss(animated: true, completion: nil)
						}))
						self.present(alert, animated: true)
					}
				}
			}
		default:
			DispatchQueue.main.async {
				let alert = UIAlertController(title: "Camera Access Required", message: "To experience the various camera filters in this playground, camera access is required.", preferredStyle: .alert)
				alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
					alert.dismiss(animated: true, completion: nil)
				}))
				self.present(alert, animated: true)
			}
		}
	}
	
	override public func viewWillDisappear(_ animated: Bool) {
		self.session.stopRunning()
		
		super.viewWillDisappear(animated)
	}

	func setupSession() {
		videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .unspecified)
		
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
				
				session.startRunning()
				
				self.cameraView.cameraLayer.session = self.session
				self.orientVideo()
				self.state.startedOnce = true
				
			}
		}
		
	}
	
	public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		// filters
		if state.fullyColorblind || state.cataract || state.noDetail {
			sessionQueue.async {
				if self.state.noDetail {
					// Not actually using a Core Image filter, but we need the data output
					let metadata = CFDictionaryCreateMutableCopy(nil, 0, CMCopyDictionaryOfAttachments(allocator: nil, target: sampleBuffer, attachmentMode: CMAttachmentMode(kCMAttachmentMode_ShouldPropagate))) as NSMutableDictionary
					let exif = metadata.value(forKey: "{Exif}") as? NSMutableDictionary
					let light = ( pow(exif!["FNumber"] as! Double, 2)) / (exif!["ExposureTime"] as! Double * ((exif!["ISOSpeedRatings"] as! NSArray)[0] as! Double))
					let lightColor = UIColor(white: CGFloat(light), alpha: 1)
					DispatchQueue.main.async {
						self.colorOverlay?.backgroundColor = lightColor
					}
					return
				}
				
				let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
				let ciImage = CIImage(cvImageBuffer: imageBuffer!)
				
				var filteredImage: CIImage = ciImage
				if self.state.fullyColorblind {
					let filter = CIFilter(name: "CIColorMonochrome") // monochrome color
					filter?.setValue(filteredImage, forKey: "inputImage")
					filter?.setValue(CIColor(color: .gray), forKey: "inputColor")
					filteredImage = (filter?.outputImage)!
				}
				if self.state.cataract {
					let filter = CIFilter(name: "CIDiscBlur") // blurry
					filter?.setValue(filteredImage, forKey: "inputImage")
					filter?.setValue(20.0, forKey: "inputRadius")
					filteredImage = (filter?.outputImage)!
				}
				
				var transformedImage = filteredImage
				var uiImage: UIImage
				UIDevice.current.beginGeneratingDeviceOrientationNotifications()
				switch self.interfaceOrientation { // Using because UIDevice.current.orientation returns unknown in playgrounds
				case .portrait:
					transformedImage = filteredImage.transformed(by: CGAffineTransform(rotationAngle: CGFloat((3 * Double.pi)/2)))
				case .landscapeLeft:
					transformedImage = filteredImage.transformed(by: CGAffineTransform(rotationAngle: CGFloat(Double.pi)))
				case .portraitUpsideDown:
					transformedImage = filteredImage.transformed(by: CGAffineTransform(rotationAngle: CGFloat(Double.pi/2)))
				default:
					transformedImage = filteredImage
				}
				UIDevice.current.endGeneratingDeviceOrientationNotifications()

				let cgImage = self.ciContext.createCGImage(transformedImage, from: transformedImage.extent)
				uiImage = UIImage(cgImage: cgImage!)
				
				DispatchQueue.main.async {
					self.imageOverlay!.image = uiImage
				}
			}
		}
	}
	
	// detecting taps of the collection view
	@objc public func tapRecognizer(_ sender: UITapGestureRecognizer?) {
		if !state.startedOnce {
			return
		}
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
			if state.nearSighted {
				CameraFilters.distanceFilter(videoDevice, near: true, enabled: false)
				state.nearSighted = false
			} else {
				CameraFilters.distanceFilter(videoDevice, near: true, enabled: true)
				state.nearSighted = true
			}
		case "Light Sensitive":
			if state.noDetail {
				colorOverlay!.alpha = 0
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
			if state.fullyColorblind {
				imageOverlay!.alpha = 0
				state.fullyColorblind = false
			}
			if state.cataract {
				imageOverlay!.alpha = 0
				state.cataract = false
			}
			if state.lightSensitive {
				CameraFilters.lightFilter(videoDevice, over: true, enabled: false)
				state.lightSensitive = false
				colorOverlay!.alpha = 1
				state.noDetail = true
			} else if state.noDetail {
				colorOverlay!.alpha = 0
				state.noDetail = false
			} else {
				colorOverlay!.alpha = 1
				state.noDetail = true
			}
		case "Fully Colorblind":
			if state.noDetail {
				colorOverlay!.alpha = 0
				state.noDetail = false
			}
			if state.fullyColorblind {
				state.fullyColorblind = false
				if state.cataract == false {
					imageOverlay!.alpha = 0
				}
			} else {
				imageOverlay!.alpha = 1
				state.fullyColorblind = true
			}
		case "Cataract":
			if state.noDetail {
				colorOverlay!.alpha = 0
				state.noDetail = false
			}
			if state.cataract {
				state.cataract = false
				if state.fullyColorblind == false {
					imageOverlay!.alpha = 0
				}
			} else {
				imageOverlay!.alpha = 1
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
		case "Severe Glaucoma":
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
		case "Macular Degeneration":
			if state.macularDegeneration {
				CameraFilters.imageOverlayFilter(cameraView, image: UIImage(named: "MacularDegeneration")!, tag: 26, enabled: false)
				state.macularDegeneration = false
			} else {
				CameraFilters.imageOverlayFilter(cameraView, image: UIImage(named: "MacularDegeneration")!, tag: 26, enabled: true)
				state.macularDegeneration = true
			}
		case "Diabetic Retinopathy":
			if state.diabeticRetinopathy {
				CameraFilters.imageOverlayFilter(cameraView, image: UIImage(named: "DiabeticRetinopathy")!, tag: 27, enabled: false)
				state.diabeticRetinopathy = false
			} else {
				CameraFilters.imageOverlayFilter(cameraView, image: UIImage(named: "DiabeticRetinopathy")!, tag: 27, enabled: true)
				state.diabeticRetinopathy = true
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
		return 12
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
				cell.imageView.image = UIImage(named: "DistanceCV")
			} else {
			  	cell.imageView.image = UIImage(named: "DistanceCVDisabled")
			}
		case 1:
			cell.name = "Light Sensitive"
			cell.tapRecognizer.name = "Light Sensitive"
			if state.lightSensitive {
				cell.imageView.image = UIImage(named: "Light")
			} else {
				cell.imageView.image = UIImage(named: "LightDisabled")
			}
		case 2:
			cell.name = "No Detail"
			cell.tapRecognizer.name = "No Detail"
			if state.noDetail {
				cell.imageView.image = UIImage(named: "NoDetailCV")
			} else {
				cell.imageView.image = UIImage(named: "NoDetailCVDisabled")
			}
	  	case 3:
			cell.name = "Fully Colorblind"
			cell.tapRecognizer.name = "Fully Colorblind"
			if state.fullyColorblind {
				cell.imageView.image = UIImage(named: "Colorblind")
			} else {
				cell.imageView.image = UIImage(named: "ColorblindDisabled")
			}
		case 4:
			cell.name = "Cataract"
			cell.tapRecognizer.name = "Cataract"
			if state.cataract {
				cell.imageView.image = UIImage(named: "Cataracts")
			} else {
				cell.imageView.image = UIImage(named: "CataractsDisabled")
			}
		case 5:
			cell.name = "No Peripheral Vision"
			cell.tapRecognizer.name = "No Peripheral Vision"
			if state.noPeripheral {
				cell.imageView.image = UIImage(named: "NoPeripheralCV")
			} else {
				cell.imageView.image = UIImage(named: "NoPeripheralCVDisabled")
			}
		case 6:
			cell.name = "No Central Vision"
			cell.tapRecognizer.name = "No Central Vision"
			if state.noCentral {
				cell.imageView.image = UIImage(named: "NoCentralCV")
			} else {
				cell.imageView.image = UIImage(named: "NoCentralCVDisabled")
			}
		case 7:
			cell.name = "Severe Glaucoma"
			cell.tapRecognizer.name = "Severe Glaucoma"
			if state.glaucoma {
				cell.imageView.image = UIImage(named: "GlaucomaCV")
			} else {
				cell.imageView.image = UIImage(named: "GlaucomaCVDisabled")
			}
		case 8:
			cell.name = "Retinal Detachment"
			cell.tapRecognizer.name = "Retinal Detachment"
			if state.retinalDetachment {
				cell.imageView.image = UIImage(named: "RetinalDetachmentCV")
			} else {
				cell.imageView.image = UIImage(named: "RetinalDetachmentCVDisabled")
			}
		case 9:
			cell.name = "Macular Degeneration"
			cell.tapRecognizer.name = "Macular Degeneration"
			if state.macularDegeneration {
				cell.imageView.image = UIImage(named: "MacularDegenerationCV")
			} else {
				cell.imageView.image = UIImage(named: "MacularDegenerationCVDisabled")
			}
		case 10:
			cell.name = "Diabetic Retinopathy"
			cell.tapRecognizer.name = "Diabetic Retinopathy"
			if state.diabeticRetinopathy {
				cell.imageView.image = UIImage(named: "DiabeticRetinopathyCV")
			} else {
				cell.imageView.image = UIImage(named: "DiabeticRetinopathyCVDisabled")
			}
		case 11:
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
			vc?.lightColor = self.colorOverlay?.backgroundColor
			self.present(vc!, animated: false, completion: nil)
		}
	}
	
	
}
