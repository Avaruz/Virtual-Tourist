//
//  FlickrCell.swift
//  Virtual Tourist
//
//  Created by Adhemar Soria Galvarro on 28/3/16.
//  Copyright © 2016 Adhemar Soria Galvarro. All rights reserved.
//

import UIKit

class FlickrCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func prepareForReuse() {
        
        super.prepareForReuse()
        
        if imageView.image == nil {
            activityIndicator.hidden = false
            imageView.image = UIImage(named: "no-image")
            activityIndicator.startAnimating()
        }
    }

}
