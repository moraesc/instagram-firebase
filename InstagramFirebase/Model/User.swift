//
//  User.swift
//  InstagramFirebase
//
//  Created by Camilla Moraes on 1/19/18.
//  Copyright © 2018 Camilla Moraes. All rights reserved.
//

import Foundation

//model object
struct User {
    let uid: String
    let username: String
    let profileImageUrl: String
    
    //constructor that helps us set up username and profileImageUrl
    init(uid: String, dictionary: [String: Any]) {
        self.uid = uid //will make it a lot easier to search for users in the future
        self.username = dictionary["username"] as? String ?? ""
        self.profileImageUrl = dictionary["profileImageUrl"] as? String ?? ""
    }
}
