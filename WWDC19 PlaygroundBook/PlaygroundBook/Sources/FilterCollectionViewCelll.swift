//
//  FilterCollectionViewCelll.swift
//  WWDC19App
//
//  Copyright © 2019 Zachary Knox. All rights reserved.
//

import UIKit

@objc(Book_Sources_FilterCollectionViewCelll)
public class FilterCollectionViewCelll: UICollectionViewCell {

	@IBOutlet public var imageView: UIImageView!
	public var name: String!
	
	public let tapRecognizer = UITapGestureRecognizer()
	
	override public func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
		
		tapRecognizer.cancelsTouchesInView = true
    }
	
	override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		imageView.alpha = 0.7
	}
	
	override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		imageView.alpha = 1
	}
	
	override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		imageView.alpha = 1
	}

}
