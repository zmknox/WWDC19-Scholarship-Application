//
//  CameraFilters.swift
//  WWDC19App
//
//  Copyright © 2019 Zoe Knox. All rights reserved.
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
					device.setFocusModeLocked(lensPosition: 0.22) { CMTime in
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
		// Using exposure
		
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
