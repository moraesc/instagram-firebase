//
//  SharePhotoController.swift
//  InstagramFirebase
//
//  Created by Camilla Moraes on 1/17/18.
//  Copyright © 2018 Camilla Moraes. All rights reserved.
//

import UIKit
import Firebase

class SharePhotoController: UIViewController {
    
    //holds on to selected image
    var selectedImage: UIImage? //optional because it is nil at the beginning of the initializer of SharePhotoController
    {
        didSet {
            self.imageView.image = selectedImage
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.rgb(red: 240, green: 240, blue: 240)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Share", style: .plain, target: self, action: #selector(handleShare))
        
        setupImageAndTextViews()
        
    }
    
    fileprivate func setupImageAndTextViews() {
        let containerView = UIView()
        containerView.backgroundColor = .white
        
        view.addSubview(containerView)
        containerView.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 100)
        
        containerView.addSubview(imageView)
        imageView.anchor(top: containerView.topAnchor, left: containerView.leftAnchor, bottom: containerView.bottomAnchor, right: nil, paddingTop: 8, paddingLeft: 8, paddingBottom: 8, paddingRight: 0, width: 84, height: 0)
        
        containerView.addSubview(textView)
        textView.anchor(top: containerView.topAnchor, left: imageView.rightAnchor, bottom: containerView.bottomAnchor, right: containerView.rightAnchor, paddingTop: 0, paddingLeft: 4, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
    }
    
    let imageView: UIImageView = {
        let iv = UIImageView()
        iv.backgroundColor = .red
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    let textView: UITextView = {
        let tv = UITextView()
        tv.font = UIFont.systemFont(ofSize: 14)
        return tv
    }()
    
    @objc func handleShare() {
        //doesn't disable button if no caption
        guard let caption = textView.text, caption.characters.count > 0 else { return }
        
        guard let image = selectedImage else { return }
        
        guard let uploadData = UIImageJPEGRepresentation(image, 0.5) else { return }
        
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        //get access to storage in firebase
        let filename = NSUUID().uuidString //random string of letters + numbers
        Storage.storage().reference().child("posts").child(filename).putData(uploadData, metadata: nil) { (metadata, err) in
            
            if let err = err {
                self.navigationItem.rightBarButtonItem?.isEnabled = true
                print("Failed to upload post image:", err)
            }
            
            //gets image url
            guard let imageUrl = metadata?.downloadURL()?.absoluteString else { return }
            
            print("Successfully uploaded post image:", imageUrl)
            
            //save image url to database
            self.saveToDatabaseWithImageUrl(imageUrl: imageUrl)
            
        }
    }
    
    static let updateFeedNotifcationName = NSNotification.Name(rawValue: "UpdateFeed")

    func saveToDatabaseWithImageUrl(imageUrl: String) {
        //save information into firebase database area
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let caption = textView.text else { return }
        guard let postImage = selectedImage else { return } //small image next to caption
        
        let userPostRef = Database.database().reference().child("posts").child(uid)
        
        //generate a new child location - useful when children of firebase database location represent a list of items
        let ref = userPostRef.childByAutoId()
        
        //cast as String: Any because lots of different types in the array
        let values = ["imageUrl": imageUrl, "caption": caption, "imageWidth": postImage.size.width, "imageHeight": postImage.size.height, "creationDate": Date().timeIntervalSince1970] as [String : Any]
        
        ref.updateChildValues(values) { (err, ref) in
            if let err = err {
                self.navigationItem.rightBarButtonItem?.isEnabled = true
                print("Failed to save post to DB", err)
            }
            
            print("Successfully saved post to DB")
            self.dismiss(animated: true, completion: nil)
            
            NotificationCenter.default.post(name: SharePhotoController.updateFeedNotifcationName, object: nil)
        }
        

    }
    
    //hide status bar
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    
}
