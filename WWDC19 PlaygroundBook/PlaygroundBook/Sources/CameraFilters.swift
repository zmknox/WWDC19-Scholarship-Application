//
//  CameraFilters.swift
//  WWDC19App
//
//  Copyright © 2019 Zachary Knox. All rights reserved.
//

import UIKit
import AVFoundation
import CoreImage

public class CameraFilters {
	public static func distanceFilter(_ device: AVCaptureDevice, near: Bool = true, enabled: Bool = true) {
		// using focus and blur
		do {
			try device.lockForConfiguration()
			
			if enabled {
				if near {
					// focus shift
					device.setFocusModeLocked(lensPosition: 0.15) { CMTime in
						device.unlockForConfiguration()
					}
				} else {
					// blur
				}
			} else { // disable
				device.focusMode = .continuousAutoFocus
				device.unlockForConfiguration()
			}
			
		} catch {
			print("ERROR IN FILTER")
		}
		
	}
	
	public static func lightFilter(_ device: AVCaptureDevice, over: Bool = true, enabled: Bool = true) {
		// Using exposure (and maybe light level detection with a blur)
		
		do {
			try device.lockForConfiguration()
			
			if enabled {
				if over {
					device.exposureMode = .custom
					device.setExposureModeCustom(duration: device.activeFormat.maxExposureDuration, iso: device.activeFormat.maxISO, completionHandler: { (CMTime) in
						device.unlockForConfiguration()
					})
				}
			} else {
				device.exposureMode = .continuousAutoExposure
				device.unlockForConfiguration()
			}
		} catch {
			print("ERROR IN FILTER")
		}
	}
	
	public static func lightOnlyFilter(_ device: AVCaptureDevice, view: UIView, enabled: Bool = true) {
		do {
			try device.lockForConfiguration()
			
			if enabled {
				// focus shift
				device.setFocusModeLocked(lensPosition: 0.001) { CMTime in
					device.unlockForConfiguration()
					
					// and blur
					let blur = UIBlurEffect(style: .regular)
					let visualEffectView = UIVisualEffectView(effect: blur)
					visualEffectView.frame = view.frame
					visualEffectView.tag = 90
					view.addSubview(visualEffectView)
					let blur2 = UIBlurEffect(style: .dark)
					let visualEffectView2 = UIVisualEffectView(effect: blur2)
					visualEffectView2.frame = view.frame
					visualEffectView2.tag = 92
					view.addSubview(visualEffectView2)
				}
			} else { // disable
				device.focusMode = .continuousAutoFocus
				device.unlockForConfiguration()
				for v in view.subviews {
					if v.tag == 90 || v.tag == 92 {
						v.removeFromSuperview()
					}
				}
			}
			
		} catch {
			print("ERROR IN FILTER")
		}
	}
	
	public static func blurFilter(_ device: AVCaptureDevice, view: UIView, darken: Bool = false, enabled: Bool = true) {
		if enabled {
			let blur = UIBlurEffect(style: darken ? .dark : .regular)
			let visualEffectView = UIVisualEffectView(effect: blur)
			visualEffectView.alpha = 0.37
			visualEffectView.frame = view.frame
			visualEffectView.tag = 91
			view.addSubview(visualEffectView)
		} else {
			for v in view.subviews {
				if v.tag == 91 {
					v.removeFromSuperview()
				}
			}
		}
	}
	
	public static func imageOverlayFilter(_ view: UIView, image: UIImage, tag: Int, enabled: Bool = true) {
		if enabled {
			let imageView = UIImageView(image: image)
			imageView.frame = view.frame
			imageView.contentMode = .scaleAspectFill
			imageView.tag = tag
			view.addSubview(imageView)
		} else {
			for v in view.subviews {
				if v.tag == tag {
					v.removeFromSuperview()
				}
			}
		}
		
	}
}
