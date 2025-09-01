//
//  CapturedViewController.swift
//  WWDC19App
//
//  Created by Zoe Knox on 3/16/19.
//  Copyright © 2019 Zoe Knox. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class CapturedViewController: UIViewController {

	var photo: AVCapturePhoto!
	@IBOutlet var imageView: UIImageView!
	
	@IBOutlet var savedLabel: UILabel!
	
	@IBOutlet var save: UIButton!
	@IBAction func saveButton(_ sender: Any) {
		PHPhotoLibrary.requestAuthorization { status in
			switch status {
			case .authorized:
				PHPhotoLibrary.shared().performChanges({
					// Add the captured photo's file data as the main resource for the Photos asset.
					let creationRequest = PHAssetCreationRequest.forAsset()
					creationRequest.addResource(with: .photo, data: self.photo.fileDataRepresentation()!, options: nil)
				}, completionHandler: { success, error in
					if success {
						DispatchQueue.main.async {
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
						dump(error)
					}
				})
			default:
				let alert = UIAlertController(title: "Unable to Save Photo", message: "Check the app settings to verify Photo Library access", preferredStyle: .alert)
				self.present(alert, animated: true, completion: nil)
			}
		}
	}
	
	@IBOutlet var back: UIButton!
	@IBAction func backButton(_ sender: Any) {
		self.dismiss(animated: false, completion: nil)
	}
	
	override func viewDidLoad() {
        super.viewDidLoad()

		savedLabel.text = ""
		savedLabel.alpha = 0
		
		imageView.contentMode = .scaleAspectFill
		imageView.image = UIImage(data: photo.fileDataRepresentation()!)
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
