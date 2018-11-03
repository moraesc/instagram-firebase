//
//  FirebaseUtils.swift
//  InstagramFirebase
//
//  Created by Camilla Moraes on 1/19/18.
//  Copyright © 2018 Camilla Moraes. All rights reserved.
//

import Foundation
import Firebase

extension Database {
    static func fetchUserWithUID(uid: String, completion: @escaping (User) -> ()) {
        print("Fetching user with uid:", uid)
        
        Database.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            
            //turn snapshot.value into a user
            guard let userDictionary = snapshot.value as? [String: Any] else { return }
            
            let user = User(uid: uid, dictionary: userDictionary)
            
            print(user.username)
            
            completion(user)
            
            //self.fetchPostsWithUser(user: user)
            
        }) { (err) in
            print("Failed to fetch user for posts:", err)
        }
        
    }
}
