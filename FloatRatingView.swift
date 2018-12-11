//
//  FloatRatingView.swift
//  Rating Demo
//
//  Created by Glen Yi on 2014-09-05.
//  Copyright (c) 2014 On The Pursuit. All rights reserved.
//

import UIKit

@objc public protocol FloatRatingViewDelegate {
    /// Returns the rating value when touch events end
    @objc optional func floatRatingView(_ ratingView: FloatRatingView, didUpdate rating: Double)

    /// Returns the rating value as the user pans
    @objc optional func floatRatingView(_ ratingView: FloatRatingView, isUpdating rating: Double)
}

/// A simple rating view that can set whole, half or floating point ratings.
@IBDesignable
@objcMembers
open class FloatRatingView: UIControl {
    
    // MARK: Properties
    
    open weak var delegate: FloatRatingViewDelegate?

    /// Array of empty image views
    private var emptyImageViews: [UIImageView] = []

    /// Array of full image views
    private var fullImageViews: [UIImageView] = []

    /// Sets the empty image (e.g. a star outline)
    @IBInspectable open var emptyImage: UIImage? {
        didSet {
            // Update empty image views
            for imageView in emptyImageViews {
                imageView.image = emptyImage
            }
            refresh()
        }
    }

    /// Sets the full image that is overlayed on top of the empty image.
    /// Should be same size and shape as the empty image.
    @IBInspectable open var fullImage: UIImage? {
        didSet {
            // Update full image views
            for imageView in fullImageViews {
                imageView.image = fullImage
            }
            refresh()
        }
    }

    /// Sets the empty and full image view content mode.
    open var imageContentMode: UIViewContentMode = UIViewContentMode.scaleAspectFit

    /// Minimum rating.
    @IBInspectable open var minRating: Int  = 0 {
        didSet {
            // Update current rating if needed
            if rating < Double(minRating) {
                rating = Double(minRating)
                refresh()
            }
        }
    }

    /// Max rating value.
    @IBInspectable open var maxRating: Int = 5 {
        didSet {
            if maxRating != oldValue {
                removeImageViews()
                initImageViews()
                
                // Relayout and refresh
                setNeedsLayout()
                refresh()
            }
        }
	}

    /// Set the current rating.
    @IBInspectable open var rating: Double = 0 {
        didSet {
            if rating != oldValue {
                refresh()
            }
        }
    }

    /// Sets whether or not the rating view can be changed by panning.
    @IBInspectable open var editable: Bool = true

    // MARK: Type

    @objc public enum FloatRatingViewType: Int {
        /// Integer rating
        case wholeRatings
        /// Double rating in increments of 0.5
        case halfRatings
        /// Double rating
        case floatRatings

        /// Returns true if rating can contain decimal places
        func supportsFractions() -> Bool {
            return self == .halfRatings || self == .floatRatings
        }
    }

    /// Float rating view type
    @IBInspectable open var type: FloatRatingViewType = .wholeRatings
    
    // MARK: Initializations
    
    required override public init(frame: CGRect) {
        super.init(frame: frame)
        
        initImageViews()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initImageViews()
    }
    
    // MARK: Helper methods

    private func initImageViews() {
        guard emptyImageViews.isEmpty && fullImageViews.isEmpty else {
            return
        }

        // Add new image views
        for _ in 0..<maxRating {
            let emptyImageView = UIImageView()
            emptyImageView.contentMode = imageContentMode
            emptyImageView.image = emptyImage
            emptyImageViews.append(emptyImageView)
            addSubview(emptyImageView)

            let fullImageView = UIImageView()
            fullImageView.contentMode = imageContentMode
            fullImageView.image = fullImage
            fullImageViews.append(fullImageView)
            addSubview(fullImageView)
        }
    }

    private func removeImageViews() {
        // Remove old image views
        for i in 0..<emptyImageViews.count {
            var imageView = emptyImageViews[i]
            imageView.removeFromSuperview()
            imageView = fullImageViews[i]
            imageView.removeFromSuperview()
        }
        emptyImageViews.removeAll(keepingCapacity: false)
        fullImageViews.removeAll(keepingCapacity: false)
    }

    // Refresh hides or shows full images
    private func refresh() {
        for i in 0..<fullImageViews.count {
            let imageView = fullImageViews[i]

            if rating >= Double(i+1) {
                imageView.layer.mask = nil
                imageView.isHidden = false
            } else if rating > Double(i) && rating < Double(i+1) {
                // Set mask layer for full image
                let maskLayer = CALayer()
                maskLayer.frame = CGRect(x: 0, y: 0, width: CGFloat(rating-Double(i))*imageView.frame.size.width, height: imageView.frame.size.height)
                maskLayer.backgroundColor = UIColor.black.cgColor
                imageView.layer.mask = maskLayer
                imageView.isHidden = false
            } else {
                imageView.layer.mask = nil;
                imageView.isHidden = true
            }
        }
    }

    // Calculates new rating based on touch location in view
    private func updateLocation(_ touch: UITouch) {
        guard editable else {
            return
        }

        let touchLocation = touch.location(in: self)
        var newRating: Double = 0
        for i in stride(from: (maxRating-1), through: 0, by: -1) {
            let imageView = emptyImageViews[i]
            guard touchLocation.x > imageView.frame.origin.x else {
                continue
            }

            // Find touch point in image view
            let newLocation = imageView.convert(touchLocation, from: self)

            // Find decimal value for float or half rating
            if imageView.point(inside: newLocation, with: nil) && (type.supportsFractions()) {
                let decimalNum = Double(newLocation.x / imageView.frame.size.width)
                newRating = Double(i) + decimalNum
                if type == .halfRatings {
                    newRating = Double(i) + (decimalNum > 0.75 ? 1 : (decimalNum > 0.25 ? 0.5 : 0))
                }
            } else {
                // Whole rating
                newRating = Double(i) + 1.0
            }
            break
        }

        // Check min rating
        rating = newRating < Double(minRating) ? Double(minRating) : newRating

        // Update delegate
        delegate?.floatRatingView?(self, isUpdating: rating)
    }


    // MARK: UIView
    
    open override var intrinsicContentSize: CGSize {
        guard let prototypeImageView = fullImageViews.first else {
            return super.intrinsicContentSize
        }
        
        let desiredWidth = prototypeImageView.intrinsicContentSize.width * CGFloat(maxRating)
        let desiredSize = CGSize(width: desiredWidth, height: prototypeImageView.intrinsicContentSize.height)
        
        return desiredSize
	}
    
    // Override to calculate ImageView frames
    override open func layoutSubviews() {
        super.layoutSubviews()

        let desiredImageWidth = frame.size.width / CGFloat(maxRating)
		
		var xOffset: CGFloat = 0
        for i in 0..<maxRating {
			xOffset = CGFloat(i) * desiredImageWidth
			let imageFrame = CGRect(x: xOffset, y: 0, width: desiredImageWidth, height: frame.size.height)
			
            var imageView = emptyImageViews[i]
            imageView.frame = imageFrame
            
            imageView = fullImageViews[i]
            imageView.frame = imageFrame
        }
        
        refresh()
    }


    // MARK: Touch events
	
	open override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
		updateLocation(touch)
		return true
	}

	open override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
		updateLocation(touch)
		return true
	}

	open override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
		super.endTracking(touch, with: event)
		delegate?.floatRatingView?(self, didUpdate: rating)
	}

	open override func cancelTracking(with event: UIEvent?) {
		super.cancelTracking(with: event)
		delegate?.floatRatingView?(self, didUpdate: rating)
	}
}
