//
//  FlickrConstants.swift
//  Virtual Tourist
//
//  Created by Adhemar Soria Galvarro on 28/3/16.
//  Copyright © 2016 Adhemar Soria Galvarro. All rights reserved.
//

import Foundation

extension FlickrClient {

    struct Constants {
        static let APIKey   = "359e19d4880ad4f3718dbdcdff954c31"
        static let BASE_URL = "https://api.flickr.com/services/rest/"
        static let Format = "json"
        static let NoJsonCallBack = "1"
        static let SearchWidth = 1.0
        static let SearchLenght = 1.0
    }
    
    // MARK: - Methods
    struct Methods {
        static let Search = "flickr.photos.search"
    }
    
    // MARK: - URL Keys
    struct URLKeys {
        static let APIKey = "api_key"
        static let BoundingBox = "bbox"
        static let Format = "format"
        static let Extras = "extras"
        static let Latitude = "lat"
        static let Longitude = "lon"
        static let Method = "method"
        static let NoJSONCallback = "nojsoncallback"
        static let Page = "page"
        static let PerPage = "per_page"
    }
    
    // MARK: - URL Values
    struct URLValues {
        static let JSONFormat = "json"
        static let URLMediumPhoto = "url_m"
    }
    
    // MARK: - JSON Response Keys
    struct JSONResponseKeys {
        static let Status = "stat"
        static let Code = "code"
        static let Message = "message"
        static let Pages = "pages"
        static let Photos = "photos"
        static let Photo = "photo"
    }
    
    // MARK: - JSON Response Values
    
    struct JSONResponseValues {
        
        static let Fail = "fail"
        static let Ok = "ok"
    }
    
}
