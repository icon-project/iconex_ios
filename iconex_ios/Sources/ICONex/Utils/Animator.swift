//
//  Animator.swift
//  ios-iCONex
//
//  Copyright © 2018 theloop, Inc. All rights reserved.
//

import Foundation
import UIKit

struct Transition {
    class FlipPopTransition: NSObject, UIViewControllerAnimatedTransitioning {
        private let originFrame: CGRect
        
        init(originFrame: CGRect) {
            self.originFrame = originFrame
        }
        
        func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
            return 0.5
        }
        
        func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
            guard let fromVC = transitionContext.viewController(forKey: .from),
                let toVC = transitionContext.viewController(forKey: .to),
                let snapShot = toVC.view.snapshotView(afterScreenUpdates: true) else { return }
            
            let containerView = transitionContext.containerView
            let finalFrame = transitionContext.finalFrame(for: toVC)
            
            snapShot.frame = originFrame
            
            containerView.addSubview(toVC.view)
            containerView.addSubview(snapShot)
            toVC.view.isHidden = true
            
            AnimationHelper.perspectiveTransformForContainerView(containerView)
            snapShot.layer.transform = AnimationHelper.yRotation(.pi / 2)
            
            let duration = transitionDuration(using: transitionContext)
            
            UIView.animateKeyframes(withDuration: duration, delay: 0, options: .calculationModeCubic, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1/3, animations: {
                    fromVC.view.layer.transform = AnimationHelper.yRotation(-.pi / 2)
                })
                
                UIView.addKeyframe(withRelativeStartTime: 1/3, relativeDuration: 1/3, animations: {
                    snapShot.layer.transform = AnimationHelper.yRotation(0.0)
                })
                
                UIView.addKeyframe(withRelativeStartTime: 2/3, relativeDuration: 1/3, animations: {
                    snapShot.frame = finalFrame
                    snapShot.layer.cornerRadius = 0
                })
            }) { (_) in
                toVC.view.isHidden = false
                snapShot.removeFromSuperview()
                fromVC.view.layer.transform = CATransform3DIdentity
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        }
        
        
    }
}

struct AnimationHelper {
    static func yRotation(_ angle: Double) -> CATransform3D {
        return CATransform3DMakeRotation(CGFloat(angle), 0.0, 1.0, 0.0)
    }
    
    static func perspectiveTransformForContainerView(_ containerView: UIView) {
        var transform = CATransform3DIdentity
        transform.m34 = -0.002
        containerView.layer.sublayerTransform = transform
    }
}
