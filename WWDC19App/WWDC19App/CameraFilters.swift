//
//  CameraFilters.swift
//  WWDC19App
//
//  Created by Zoe Knox on 3/14/19.
//  Copyright © 2019 Zoe Knox. All rights reserved.
//

import AVFoundation

class CameraFilters {
	static func distanceFilter(_ device: AVCaptureDevice, far: Bool = true, enabled: Bool = true) {
		// using focus and blur
		do {
			try device.lockForConfiguration()
			
			if enabled {
				if far {
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
	
	static func colorFilter(_ device: AVCaptureDevice, full: Bool = true, enabled: Bool = true) -> AVCaptureDevice {
		// Using Core Image filters
		
		return device
	}
	
	static func lightFilter(_ device: AVCaptureDevice, over: Bool = true, enabled: Bool = true) {
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
}
