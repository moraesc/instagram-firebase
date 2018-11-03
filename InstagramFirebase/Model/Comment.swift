//
//  Comment.swift
//  InstagramFirebase
//
//  Created by Camilla Moraes on 1/31/18.
//  Copyright © 2018 Camilla Moraes. All rights reserved.
//

import Foundation

struct Comment {
    
    //var user: User? - doesn't need to be optional becasue a comment will always belong to a user
    let user: User
    
    let text: String
    let uid: String
    
    init(user: User, dictionary: [String: Any]) {
        self.user = user
        self.text = dictionary["text"] as? String ?? ""
        self.uid = dictionary["uid"] as? String ?? ""
    }
}
