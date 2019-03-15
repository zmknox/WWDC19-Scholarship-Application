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
	
	

}
