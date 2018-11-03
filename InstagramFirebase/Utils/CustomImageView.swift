//
//  CustomImageView.swift
//  InstagramFirebase
//
//  Created by Camilla Moraes on 1/19/18.
//  Copyright © 2018 Camilla Moraes. All rights reserved.
//
//  Class is repsonsible for loading image data

import UIKit

//cache images to efficiently load images into app
var imageCache = [String: UIImage]()

class CustomImageView: UIImageView {
    
    var lastURLUsedToLoadImage: String?
    
    func loadImage(urlString: String) {
        //check cache for image, if there is one, use it and avoid the URL Session task
        //if cachedImage is equal to something it will optionally bind cachedImage to imageCache
        if let cachedImage = imageCache[urlString] {
            self.image = cachedImage
            return //avoid unnecessary image fetching code
        }
        
        lastURLUsedToLoadImage = urlString
        
        self.image = nil //fixes flickering whenever you update images using loadImage()
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { (data, response, err) in
            if let err = err {
                print("Failed to fetch post image:", err)
                return
            }
            
            //if they're not equal we wont set the photoImage equal to the photoImageView
            //make sure last URL you used to post an image matches with whatever you finished off with in that session
            //eliminates repeats
            if url.absoluteString != self.lastURLUsedToLoadImage {
                return
            }
            
            guard let imageData = data else { return }
            let photoImage = UIImage(data: imageData)
            
            imageCache[url.absoluteString] = photoImage
            
            
            //update photo image view in main queue
            DispatchQueue.main.async {
                self.image = photoImage
            }
            }.resume()
    }
}
