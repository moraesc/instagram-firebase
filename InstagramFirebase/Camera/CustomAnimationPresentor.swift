//
//  CustomAnimationPresentor.swift
//  InstagramFirebase
//
//  Created by Camilla Moraes on 1/30/18.
//  Copyright © 2018 Camilla Moraes. All rights reserved.
//

import UIKit

//create custom presenter
class CustomAnimationPresentor: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        //my custom transition animation code
        
        let containerView = transitionContext.containerView
        
        guard let fromView = transitionContext.view(forKey: .from) else { return } //home screen
        guard let toView = transitionContext.view(forKey: .to) else { return } //gets us the view for the view we're transitioning to
        
        containerView.addSubview(toView)
        
        let startingFrame = CGRect(x: -toView.frame.width, y: 0, width: toView.frame.width, height: toView.frame.height)
        toView.frame = startingFrame
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            //animation
            
            toView.frame = CGRect(x: 0, y: 0, width: toView.frame.width, height: toView.frame.height)
            
            fromView.frame = CGRect(x: fromView.frame.width, y: 0, width: fromView.frame.width, height: fromView.frame.height)
            
        }) { (_) in
            transitionContext.completeTransition(true)
        }
        
    }
}
