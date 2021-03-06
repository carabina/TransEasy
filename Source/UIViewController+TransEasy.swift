//
//  UIViewController+TransEasy.swift
//  TransEasy
//
//  Created by Mohammad Porooshani on 7/21/16.
//  Copyright © 2016 Porooshani. All rights reserved.
//
// The MIT License (MIT)
//
// Copyright (c) 2016 Mohammad Poroushani
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import UIKit

/// Holds a reference to the memory for associated delegate object.
var PresentAssociatedHandler: UInt8 = 0

/**
 *  A simple struct to encapsulate present transition's settings.
 *  This struct is used only if you use the UIViewController's extension related to TransEasy.
 */
public struct TransEasyPresentOptions {
  /// The duration of the animation.
  public var duration: NSTimeInterval = 0.4
  /// The view present will start from.
  public let sourceView: UIView
  /// The blur effect to use as background. (If set as nil, won't add blur effect)
  public let blurStyle: UIBlurEffectStyle?

  public init(duration: NSTimeInterval, sourceView: UIView, blurStyle: UIBlurEffectStyle? = nil) {
    self.duration = duration
    self.sourceView = sourceView
    self.blurStyle = blurStyle
  }
}

/**
 *  A simple struct to encapsulate dismiss transition's settings.
 *  This struct is used only if you use the UIViewController's extension related to TransEasy.
 */
public struct TransEasyDismissOptions {
  /// The duration of the animation.
  public var duration: NSTimeInterval = 0.4
  /// The view dismiss transition animation will end on.
  public let destinationView: UIView
  
  public init(duration: NSTimeInterval, destinationView: UIView) {
    self.duration = duration
    self.destinationView = destinationView
  }
  
}

public extension UIViewController {
  
  /// The reference to the animator object. The `transitioningDelegate` of the `UIViewController` is of weak type therefore ot will be lost after setup.
  internal var easyTransDelegate: EasyPresentHelper? {
    get {
      return objc_getAssociatedObject(self, &PresentAssociatedHandler) as? EasyPresentHelper
    }
    
    set {
      objc_setAssociatedObject(self, &PresentAssociatedHandler, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      
    }
  }
  
  /**
   Allows the view controller to have an easy transition from a view controller to another view controller, moving a view in between.
   
   - parameter targetViewController: The destination of the transition. If you are using a segue, this is the actual `destinationViewController` of the segue.
   - parameter presentOptions:       The options for present animation.
   - parameter dismissOptions:       The options for dimiss animation.
   
   - discussion `targetViewController` should implement `TransEasyDestinationViewControllerProtocol`, because in `prepareForSegue` views are not yet initialized and you wouldn't have access to view's references.
   
   */
  func setupEasyTransition(on targetViewController: UIViewController, presentOptions: TransEasyPresentOptions?, dismissOptions: TransEasyDismissOptions?) {
    
    let transDel = EasyPresentHelper(presentOptions: presentOptions, dismissOptions: dismissOptions)
    easyTransDelegate = transDel
    targetViewController.transitioningDelegate = easyTransDelegate
    
  }
  
}

/// A class that will act as animation controller for the view controllers.
class EasyPresentHelper: NSObject, UIViewControllerTransitioningDelegate {
  
  /// A lazy instance of `EasyPresentAnimationController` that will hold on to present animations.
  lazy var presentAnimator = EasyPresentAnimationController()
  /// A lazy instance of `EasyDismissAnimationController` that will hold on to dimiss animations.
  lazy var dismissAnimator = EasyDismissAnimationController()
  
  /// The present options.
  let presentOptions: TransEasyPresentOptions?
  /// The dismiss options.
  let dismissOptions: TransEasyDismissOptions?
  
  init(presentOptions: TransEasyPresentOptions?, dismissOptions: TransEasyDismissOptions?) {
    self.presentOptions = presentOptions
    self.dismissOptions = dismissOptions
  }

  func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    
    /// If setup is not complete, this method will return nil allowing UIKit to use the default transition.
    guard let pOptions = presentOptions,
    let pDestPro = presented as? TransEasyDestinationViewControllerProtocol
      else {
      return nil
    }

    // Setup animator's settings.
    presentAnimator.blurEffectStyle = pOptions.blurStyle
    presentAnimator.duration = pOptions.duration
    presentAnimator.originalView = pOptions.sourceView
    presentAnimator.destinationView = pDestPro.transEasyDestinationView()
    
    return presentAnimator
  }
  
  func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    
    /// If setup is not complete, this method will return nil allowing UIKit to use the default transition.
    guard let dOption = dismissOptions,
    let sDestPro = dismissed as? TransEasyDestinationViewControllerProtocol
    else {
      return nil
    }
    
    // Setup animator's settings.
    dismissAnimator.duration = dOption.duration
    dismissAnimator.originalView = sDestPro.transEasyDestinationView()
    dismissAnimator.destinationView = dOption.destinationView
    
    return dismissAnimator
    
  }
  
  
}

/**
 *  A simple protocol that will be used instead of a property, to let the destination view be selected lazily.
 */
public protocol TransEasyDestinationViewControllerProtocol {
  
  /**
   The View that transition will finish on. Please note that this method can be used for dismiss options as well.
   
   - returns: A UIView that will be used at final view (or initial view for dimiss) transition.
   */
  func transEasyDestinationView() -> UIView
  
}
