//
//  ImageScrollView.swift
//  Virtual Tourist
//
//  Created by Adhemar Soria Galvarro on 8/4/16.
//  Copyright © 2016 Adhemar Soria Galvarro. All rights reserved.
//

import UIKit

class ImageScrollView: UIViewController {
    
    
    @IBOutlet weak var myImageView: UIImageView!
    
    var selectedImage: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(selectedImage)
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // ToDo: I should probably list the title of the image
        let imageUrl = NSURL(string:self.selectedImage)
        let imageData = NSData(contentsOfURL: imageUrl!)
        if (imageData != nil)
        {
            self.myImageView.image  = UIImage(data: imageData!)
        }
        
    }
    
    
    
}
