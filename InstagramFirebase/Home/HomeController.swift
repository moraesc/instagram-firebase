//
//  HomeController.swift
//  InstagramFirebase
//
//  Created by Camilla Moraes on 1/19/18.
//  Copyright © 2018 Camilla Moraes. All rights reserved.
//

import UIKit
import Firebase

class HomeController: UICollectionViewController, UICollectionViewDelegateFlowLayout, HomePostCellDelegate {
    
    let cellId = "cellId"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(handleUpdateFeed), name: SharePhotoController.updateFeedNotifcationName, object: nil)
        
        collectionView?.backgroundColor = .white
        
        collectionView?.register(HomePostCell.self, forCellWithReuseIdentifier: cellId)
        
        let refreshControl = UIRefreshControl()
        
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        
        collectionView?.refreshControl = refreshControl
        
        setupNavigationItems()
        
        fetchAllPosts()
        
        fetchFollowingUserIds()
    }
    
    @objc func handleUpdateFeed() {
        handleRefresh()
    }
    
    @objc func handleRefresh() {
        fetchAllPosts()
        posts.removeAll() //when you unfollow someone this removes their images from your feed
    }
    
    fileprivate func fetchAllPosts() {
        fetchPosts()
        fetchFollowingUserIds()
    }
    
    //adds all images posted by users you're following to home screen
    fileprivate func fetchFollowingUserIds() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Database.database().reference().child("following").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let userIdsDictionary = snapshot.value as? [String: Any] else { return }
            
            //iterating through all of the user id's that we're following
            userIdsDictionary.forEach({ (key, value) in
                //this gets us all of the users, given the user ids
                Database.fetchUserWithUID(uid: key, completion: { (user) in
                    self.fetchPostsWithUser(user: user)
                })
            })
            
        }) { (err) in
            print("failed to fetch following users ids:", err)
        }
    }
    
    var posts = [Post]()
    //use this function to fetch user's posts to display on the home page
    //don't use .childAdded - this will have the controller fetch a new post each time, will cause weird animation behavior that user can't control
    fileprivate func fetchPosts() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Database.fetchUserWithUID(uid: uid) { (user) in
            self.fetchPostsWithUser(user: user)
        }
    }
    
    //ios9
    //let refreshControl = UIRefreshControl()
    
    //fetch posts for the right user, rather than constantly fetching the post for the current user
    fileprivate func fetchPostsWithUser(user: User) {
        
        //fetching the posts for the current user
         let ref = Database.database().reference().child("posts").child(user.uid)
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            
            self.collectionView?.refreshControl?.endRefreshing()
            
            //cast snapshot to dictionary
            guard let dictionaries = snapshot.value as? [String: Any] else { return }
            
            //forEach iterates through dictionary giving us the key and value at the same time
            dictionaries.forEach({ (key, value) in
                
                guard let dictionary = value as? [String: Any] else { return }
                
                //constructs posts and appends them to array
                //struct needs to be a variable in order for you to change the property of the struct - so use var instead of let
                var post = Post(user: user, dictionary: dictionary)
                post.id = key
                
                guard let uid = Auth.auth().currentUser?.uid else { return }
                
                Database.database().reference().child("likes").child(key).child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
                    
                    //whenever value is 1, set hasLiked value to true
                    
                    //when a post has been liked
                    if let value = snapshot.value as? Int, value == 1 {
                        post.hasLiked = true
                        self.posts.append(post)
                        self.posts.sort(by: { (p1, p2) -> Bool in
                            return p1.creationDate.compare(p2.creationDate) == .orderedDescending
                        })
                        self.collectionView?.reloadData()
                    } else {
                        post.hasLiked = false
                    }
                    
                }, withCancel: { (err) in
                    print("failed to fetch like info for post:", err)
                })
                
                
            })
            
        }) { (err) in
            print("Failed to fetch posts:", err)
        }
    }
    
    func setupNavigationItems() {
        navigationItem.titleView = UIImageView(image: #imageLiteral(resourceName: "logo2"))
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "camera3").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleCamera))
    }
    
    @objc func handleCamera() {
        print("showing camera")
        
        let cameraController = CameraController()
        
        present(cameraController, animated: true, completion: nil)
    }
    
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! HomePostCell
        
        cell.post = posts[indexPath.item]
        
        cell.delegate = self
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = view.frame.width
        
        var height: CGFloat = 40 + 8 + 8 //username and userprofileimageview
        height += view.frame.width
        height += 50 //accounts for bottom row of buttons
        height += 60
        
        return CGSize(width: width, height: height)
    }
    
    //firing up an action from a cell and bubbling it up into the controller
    func didTapComment(post: Post) {
        let commentsController = CommentsController(collectionViewLayout: UICollectionViewFlowLayout())
        commentsController.post = post
        navigationController?.pushViewController(commentsController, animated: true)
    }
    
    func didLike(for cell: HomePostCell) {
        print("handling like inside controller")
        
        guard let indexPath = collectionView?.indexPath(for: cell) else { return } //returns index path for specified cell
        
        var post = self.posts[indexPath.item]
        
        guard let postId = post.id else { return }
        
        //current users uid
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        //if you've liked post, value is 1 and once you unlike it it becomes 0
        let values = [uid: post.hasLiked == true ? 0 : 1]
        Database.database().reference().child("likes").child(postId).updateChildValues(values) { (err, ref) in
            if let err = err {
                print("failed to like post:", err)
                return
            }
            print("successfully liked post")
            
            //change has liked from false to true
            post.hasLiked = !post.hasLiked
            
            //whenever you get the post object ouside of the array you actually get a different reference for the post, the following line remodifies the post so it's the object that you are updating
            self.posts[indexPath.item] = post
            
            self.collectionView?.reloadItems(at: [indexPath]) //only update the cell that we are liking
        }
    }
    
    
}
