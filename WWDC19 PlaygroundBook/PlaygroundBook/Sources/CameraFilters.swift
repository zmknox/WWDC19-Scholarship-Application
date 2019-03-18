//
//  CameraFilters.swift
//  WWDC19App
//
//  Created by Zach Knox on 3/14/19.
//  Copyright © 2019 Zachary Knox. All rights reserved.
//

import UIKit
import AVFoundation

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
			}
			
		} catch {
			print("ERROR IN FILTER")
		}
		
	}
	
	public static func colorFilter(_ device: AVCaptureDevice, full: Bool = true, enabled: Bool = true) -> AVCaptureDevice {
		// Using Core Image filters
		
		return device
	}
	
	public static func lightFilter(_ device: AVCaptureDevice, over: Bool = true, enabled: Bool = true) {
		// Using exposure (and maybe light level detection with a blur)
		
		do {
			try device.lockForConfiguration()
			
			if enabled {
				if over {
					device.setExposureModeCustom(duration: device.activeFormat.maxExposureDuration, iso: device.activeFormat.maxISO, completionHandler: { (CMTime) in
						device.unlockForConfiguration()
					})
				} else {
					// act like blind w/ blur and light level detection
					device.setExposureModeCustom(duration: device.activeFormat.minExposureDuration, iso: AVCaptureDevice.currentISO, completionHandler: { (CMTime) in
						device.unlockForConfiguration()
					})
				}
			} else {
				device.exposureMode = .autoExpose
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
			visualEffectView.frame = view.bounds
			view.addSubview(visualEffectView)
		} else {
			for v in view.subviews {
				if (v as? UIVisualEffectView)?.effect is UIBlurEffect {
					v.removeFromSuperview()
				}
			}
		}
	}
	
	public static func imageOverlayFilter(_ view: UIView, image: UIImage, tag: Int, enabled: Bool = true) {
		if enabled {
			let imageView = UIImageView(image: image)
			imageView.frame = view.bounds
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
