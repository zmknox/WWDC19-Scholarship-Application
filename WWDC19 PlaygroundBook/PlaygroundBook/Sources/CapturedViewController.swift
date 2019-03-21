//
//  CapturedViewController.swift
//  WWDC19App
//
//  Created by Zach Knox on 3/16/19.
//  Copyright © 2019 Zachary Knox. All rights reserved.
//

import UIKit
import PlaygroundSupport
import AVFoundation
import Photos

@objc(Book_Sources_CapturedViewController)
public class CapturedViewController: UIViewController, PlaygroundLiveViewSafeAreaContainer {
	
	public var state: FilterState!
	public var photo: AVCapturePhoto!
	@IBOutlet var imageView: UIImageView!
	let ciContext = CIContext()
	
	@IBOutlet var savedLabel: UILabel!
	@IBOutlet var isSaving: UIActivityIndicatorView!
	
	@IBOutlet var buttonView: UIView!
	@IBOutlet var save: UIButton!
	@IBAction public func saveButton(_ sender: Any) {
		self.isSaving.startAnimating()
		let imageRenderer = UIGraphicsImageRenderer(bounds: imageView.bounds)
		let savingImage = imageRenderer.image(actions: { context in
			imageView.layer.render(in: context.cgContext)
		})
		PHPhotoLibrary.requestAuthorization { status in
			switch status {
			case .authorized:
				PHPhotoLibrary.shared().performChanges({
					// Add the captured photo's file data as the main resource for the Photos asset.
					let creationRequest = PHAssetCreationRequest.forAsset()
					creationRequest.addResource(with: .photo, data: savingImage.jpegData(compressionQuality: 100)!, options: nil)
					//creationRequest.addResource(with: .photo, data: self.photo.fileDataRepresentation()!, options: nil)
				}, completionHandler: { success, error in
					if success {
						DispatchQueue.main.async {
							self.isSaving.stopAnimating()
							self.savedLabel.text = "Saved to Photo Library!".uppercased()
							UIView.animate(withDuration: 0.2, animations: {
								self.savedLabel.alpha = 1
							})
							DispatchQueue.main.asyncAfter(deadline: .now() + 1.3, execute: {
								UIView.animate(withDuration: 0.2, animations: {
									self.savedLabel.alpha = 0
								})
							})
						}
					} else {
						DispatchQueue.main.async {
							self.isSaving.stopAnimating()
						}
						dump(error)
					}
				})
			default:
				self.isSaving.stopAnimating()
				let alert = UIAlertController(title: "Unable to Save Photo", message: "Check the app settings to verify Photo Library access", preferredStyle: .alert)
				self.present(alert, animated: true, completion: nil)
			}
		}
	}
	
	@IBOutlet var back: UIButton!
	@IBAction func backButton(_ sender: Any) {
		self.dismiss(animated: false, completion: nil)
	}
	
	override public func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		for v in imageView.subviews {
			if v is UIImageView {
				let image = (v as! UIImageView).image
				let tag = v.tag
				v.removeFromSuperview()
				let newView = UIImageView(image: image)
				newView.frame = imageView.frame
				newView.contentMode = .scaleAspectFill
				newView.tag = tag
				imageView.addSubview(newView)
			} else {
				v.removeFromSuperview()
				v.frame = CGRect(origin: v.frame.origin, size: CGSize(width: v.frame.size.height, height: v.frame.size.width))
				imageView.addSubview(v)
			}
		}
	}
	
	override public func viewDidLoad() {
        super.viewDidLoad()

		liveViewSafeAreaGuide.bottomAnchor.constraint(equalTo: buttonView.bottomAnchor).isActive = true
		
		savedLabel.text = ""
		savedLabel.alpha = 0
		
		imageView.contentMode = .scaleAspectFill
		imageView.image = UIImage(data: photo.fileDataRepresentation()!)
		
		back.layer.cornerRadius = 32
		save.layer.cornerRadius = 32
		save.titleEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 15)
		save.imageEdgeInsets = UIEdgeInsets(top: 0, left: -7, bottom: 0, right: 5)
		
		// Apply Filters to capture
		if state.fullyColorblind {
			let ciImage = CIImage(image: imageView.image!)
			
			let filter = CIFilter(name: "CIColorMonochrome")
			filter?.setValue(ciImage, forKey: "inputImage")
			let filteredImage = filter?.outputImage
			var transformedImage = filteredImage
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
			let cgImage = self.ciContext.createCGImage(transformedImage!, from: transformedImage!.extent)
			imageView.image = UIImage(cgImage: cgImage!)
		}
		if state.cataract {
			let blur = UIBlurEffect(style: .dark)
			let visualEffectView = UIVisualEffectView(effect: blur)
			visualEffectView.alpha = 0.37
			visualEffectView.frame = self.view.frame
			imageView.addSubview(visualEffectView)
		}
		if state.glaucoma {
			let image = UIImage(named: "GlaucomaVisionLoss")
			let subView = UIImageView(image: image)
			subView.contentMode = .scaleAspectFill
			subView.frame = self.view.frame
			imageView.addSubview(subView)
		}
		if state.retinalDetachment {
			let image = UIImage(named: "RetinalDetachment")
			let subView = UIImageView(image: image)
			subView.contentMode = .scaleAspectFill
			subView.frame = self.view.frame
			imageView.addSubview(subView)
		}
		if state.noCentral {
			let image = UIImage(named: "NoCentral")
			let subView = UIImageView(image: image)
			subView.contentMode = .scaleAspectFill
			subView.frame = self.view.frame
			imageView.addSubview(subView)
		}
		if state.noPeripheral {
			let image = UIImage(named: "NoPeripheral")
			let subView = UIImageView(image: image)
			subView.contentMode = .scaleAspectFill
			subView.frame = self.view.frame
			imageView.addSubview(subView)
		}
		if state.blind {
			let image = UIImage(named: "Blind")
			let subView = UIImageView(image: image)
			subView.contentMode = .scaleAspectFill
			subView.frame = self.view.frame
			imageView.addSubview(subView)
		}
        
    }

}
