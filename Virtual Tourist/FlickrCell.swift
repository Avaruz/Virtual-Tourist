//
//  FlickrCell.swift
//  Virtual Tourist
//
//  Created by Adhemar Soria Galvarro on 28/3/16.
//  Copyright © 2016 Adhemar Soria Galvarro. All rights reserved.
//

import UIKit

class FlickrCell: UICollectionViewCell {

    @IBOutlet weak var photoView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var deleteButton: UIButton!
    
    override func prepareForReuse() {
        
        super.prepareForReuse()
        
        if photoView.image == nil {
            activityIndicator.hidden = false
            photoView.image = UIImage(named: "noimage")
            activityIndicator.startAnimating()
        }
    }

}
