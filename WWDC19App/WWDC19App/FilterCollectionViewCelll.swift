//
//  FilterCollectionViewCelll.swift
//  WWDC19App
//
//  Created by Zach Knox on 3/15/19.
//  Copyright © 2019 Zachary Knox. All rights reserved.
//

import UIKit

class FilterCollectionViewCelll: UICollectionViewCell {

	@IBOutlet var imageView: UIImageView!
	var name: String!
	
	internal let tapRecognizer = UITapGestureRecognizer()
	
	override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
		
		tapRecognizer.cancelsTouchesInView = true
    }
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		imageView.alpha = 0.7
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		imageView.alpha = 1
	}
	
	override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		imageView.alpha = 1
	}

}
