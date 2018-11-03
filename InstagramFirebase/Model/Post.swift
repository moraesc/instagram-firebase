//
//  Post.swift
//  InstagramFirebase
//
//  Created by Camilla Moraes on 1/18/18.
//  Copyright © 2018 Camilla Moraes. All rights reserved.
//

import UIKit

struct Post {
    
    var id: String? //optional so you don't have to initialize value below
    let user: User
    let imageUrl: String
    let caption: String
    let creationDate: Date
    
    var hasLiked: Bool = false
    
    init(user: User, dictionary: [String: Any]) {
        self.imageUrl = dictionary["imageUrl"] as? String ?? ""
        self.user = user
        self.caption = dictionary["caption"] as? String ?? ""
        
        let secondsFrom1970 = dictionary["creationDate"] as? Double ?? 0
        self.creationDate = Date(timeIntervalSince1970: secondsFrom1970)
    }
}
