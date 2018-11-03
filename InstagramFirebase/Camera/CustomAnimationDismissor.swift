//
//  CustomAnimationDismissor.swift
//  InstagramFirebase
//
//  Created by Camilla Moraes on 1/30/18.
//  Copyright © 2018 Camilla Moraes. All rights reserved.
//

import UIKit

class CustomAnimationDismissor: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        //my custom transition animation code
        
        let containerView = transitionContext.containerView
        
        //from view - camera controller view
        guard let fromView = transitionContext.view(forKey: .from) else { return }
        guard let toView = transitionContext.view(forKey: .to) else { return }
        
        containerView.addSubview(toView)
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            
            fromView.frame = CGRect(x: -fromView.frame.width, y: 0, width: fromView.frame.width, height: fromView.frame.height)
            
            toView.frame = CGRect(x: 0, y: 0, width: toView.frame.width, height: toView.frame.height)
            
        }) { (_) in
            transitionContext.completeTransition(true) //must call this method after animation is completed to notify the system that the transition is done
        }
    }
}
