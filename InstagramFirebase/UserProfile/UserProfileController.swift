//
//  UserProfileController.swift
//  InstagramFirebase
//
//  Created by Camilla Moraes on 1/11/18.
//  Copyright © 2018 Camilla Moraes. All rights reserved.
//

import UIKit
import Firebase

class UserProfileController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UserProfileHeaderDelegate {
    
    let cellId = "cellId"
    let homePostCellId = "homePostCellId"
    var userId: String?
    var isGridView = true
    
    func didChangeToGridView() {
        isGridView = true
        collectionView?.reloadData()
    }
    
    func didChangeToListView() {
        isGridView = false
        collectionView?.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.backgroundColor = .white

        //firebase persists your username/user id every time you create a user or sign in
        //navigationItem.title = Auth.auth().currentUser?.uid
        
        fetchUser()
        
        //register collection view with a header
        collectionView?.register(UserProfileHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "headerId")
        
        //register collection view with the cell
        collectionView?.register(UserProfilePhotoCell.self, forCellWithReuseIdentifier: cellId)
        collectionView?.register(HomePostCell.self, forCellWithReuseIdentifier: homePostCellId)
        
        setupLogOutButton()
    }
    
    var isFinishedPaging = false
    var posts = [Post]()
    
    fileprivate func paginatePosts() {
        print("Start paging for more posts")
        
        guard let uid = self.user?.uid else { return }
        let ref = Database.database().reference().child("posts").child(uid)
        
        //var query = ref.queryOrderedByKey()
        
        var query = ref.queryOrdered(byChild: "creationDate")
        
        //don't really get this if statement
        if posts.count > 0 {
            //let value = posts.last?.id
            let value = posts.last?.creationDate.timeIntervalSince1970 //last object inside of posts array
            query = query.queryEnding(atValue: value)
        }
        
        //.value lets you observe the entire node
        //use toLast to search from the end of the list
        query.queryLimited(toLast: 4).observeSingleEvent(of: .value, with: { (snapshot) in

            guard var allObjects = snapshot.children.allObjects as? [DataSnapshot] else { return } //all objects inside snapshot
            
            allObjects.reverse()
            
            if allObjects.count < 4 {
                self.isFinishedPaging = true
            }
            
            //gets rid of repitition
            if self.posts.count > 0 {
                allObjects.removeFirst()
            }
            
            guard let user = self.user else { return }
            
            allObjects.forEach({ (snapshot) in
                
                guard let dictionary = snapshot.value as? [String: Any] else { return }
                var post = Post(user: user, dictionary: dictionary)
                
                post.id = snapshot.key
                
                self.posts.append(post)
                
            })
            
            self.posts.forEach({ (post) in
                print(post.id ?? "")
            })
            
            self.collectionView?.reloadData()
            
        }) { (err) in
            print("failed to paginate for posts:", err)
        }
    }
    
    fileprivate func fetchOrderedPosts() {
        guard let uid = self.user?.uid else { return }

        let ref = Database.database().reference().child("posts").child(uid)
        
        //order by creation data
        ref.queryOrdered(byChild: "creationDate").observe(.childAdded, with: { (snapshot) in

            guard let dictionary = snapshot.value as? [String: Any] else { return }
            
            guard let user = self.user else { return }
            
            let post = Post(user: user, dictionary: dictionary)
            
            //fix ordered - newest images are in first cell of collection view grid
            self.posts.insert(post, at: 0)
            
            self.collectionView?.reloadData()
            
        }) { (err) in
            print("Failed to fetch ordered posts:", err)
        }
        
    }
    
    //use this function to fetch user's posts to display on the home page
    //don't use .childAdded - this will have the controller fetch a new post each time, will cause weird animation behavior that user can't control
//    fileprivate func fetchPosts() {
//        guard let uid = Auth.auth().currentUser?.uid else { return }
//            
//        let ref = Database.database().reference().child("posts").child(uid)
//        
//        ref.observeSingleEvent(of: .value, with: { (snapshot) in
//            //cast snapshot to dictionary
//            guard let dictionaries = snapshot.value as? [String: Any] else { return }
//            
//            //forEach iterates through dictionary giving us the key and value at the same time
//            dictionaries.forEach({ (key, value) in
//                
//                guard let dictionary = value as? [String: Any] else { return }
//                
//                //constructs posts and appends them to array
//                let post = Post(dictionary: dictionary)
//                self.posts.append(post)
//                
//            })
//            
//            self.collectionView?.reloadData()
//            
//        }) { (err) in
//            print("Failed to fetch posts:", err)
//        }
//    }

    
    fileprivate func setupLogOutButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "gear"), style: .plain, target: self, action: #selector(handleLogOut))
    }
    
    @objc func handleLogOut() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        //when you click the log out button
        alertController.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { (_) in
            
            //log out user from app
            do {
                try Auth.auth().signOut()
                
                //present log in controller when you sign out
                let loginController = LoginController()
                let navController = UINavigationController(rootViewController: loginController)
                self.present(navController, animated: true, completion: nil)
                
            } catch let signOutErr {
                print("Failed to sign out", signOutErr)
            }
            
        }))
        
        //when you click cancel button
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        //how to fire off paginate call
        if indexPath.item == self.posts.count - 1  && !isFinishedPaging{
            print("paginating for posts")
            paginatePosts()
        }
        
        if isGridView {
            //if we use the following line we have to register the cell to be dequeued from the collection view using this cell id
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! UserProfilePhotoCell
            cell.post = posts[indexPath.item]
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: homePostCellId, for: indexPath) as! HomePostCell
            cell.post = posts[indexPath.item]
            return cell
        }

    }
    
    //fix vertical spacing
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    //fix line spacing on horizontal line between cells
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    //set size of collection view cells
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if isGridView {
            let width = (view.frame.width - 2) / 3
            return CGSize(width: width, height: width)
        } else {
            var height: CGFloat = 40 + 8 + 8
            height += view.frame.width
            height += 50
            height += 60
            return CGSize(width: view.frame.width, height: height)
        }
    
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "headerId", for: indexPath) as! UserProfileHeader //cast this way bc we know exactly what the resulting dequeud item 
        
        header.user = self.user
        header.delegate = self
        
        //not correct
        //header.addSubview(UIImageView())
                
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 200)
    }
    
    //not accessible outside of this class
    var user: User? //optional because User? is nil when app begins
    fileprivate func fetchUser() {

        let uid = userId ?? Auth.auth().currentUser?.uid ?? ""
        
        // guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Database.fetchUserWithUID(uid: uid) { (user) in
            self.user = user
            
            self.navigationItem.title = self.user?.username
            
            self.collectionView?.reloadData()
            
            self.paginatePosts()
        }
    }
}
