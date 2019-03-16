//
//  CapturedViewController.swift
//  WWDC19App
//
//  Created by Zach Knox on 3/16/19.
//  Copyright © 2019 Zachary Knox. All rights reserved.
//

import UIKit
import AVFoundation

class CapturedViewController: UIViewController {

	var photo: AVCapturePhoto!
	@IBOutlet var imageView: UIImageView!
	
	@IBOutlet var save: UIButton!
	@IBAction func saveButton(_ sender: Any) {
		
	}
	
	@IBOutlet var back: UIButton!
	@IBAction func backButton(_ sender: Any) {
		
	}
	
	override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
