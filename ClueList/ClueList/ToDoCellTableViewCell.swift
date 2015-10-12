//
//  ToDoCellTableViewCell.swift
//  ClueList
//
//  Created by Ryan Rose on 10/12/15.
//  Copyright © 2015 GE. All rights reserved.
//  This is a TableViewCell with AutoLayout where the cell row height dynamically changes to fit the cell contents
//  http://stackoverflow.com/questions/18746929/using-auto-layout-in-uitableview-for-dynamic-cell-layouts-variable-row-heights
//

import UIKit
import PureLayout

// A protocol that the TableViewCell uses to inform its delegate of state change
protocol TableViewCellDelegate {
    // indicates that the given item has been deleted
    func toDoItemRevealed(todoItem: ToDoItem)
}

class ToDoCellTableViewCell: UITableViewCell {

    // The CGFloat type annotation is necessary for these constants because they are passed as arguments to bridged Objective-C methods,
    // and without making the type explicit these will be inferred to be type Double which is not compatible.
    let kLabelHorizontalInsets: CGFloat = 15.0
    let kLabelVerticalInsets: CGFloat = 10.0
    
    var originalCenter = CGPoint()
    var revealOnDragRelease = false
    
    // The object that acts as delegate for this cell.
    var delegate: TableViewCellDelegate?
    // The item that this cell renders.
    var toDoItem: ToDoItem?
    
    var didSetupConstraints = false
    
    var titleLabel: UILabel = UILabel.newAutoLayoutView()
    var bodyLabel: UILabel = UILabel.newAutoLayoutView()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String!)
    {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        
        setupViews()
    }
    
    func setupViews()
    {
        titleLabel.lineBreakMode = .ByTruncatingTail
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .Left
        titleLabel.textColor = UIColor.blackColor()
        
        bodyLabel.lineBreakMode = .ByTruncatingTail
        bodyLabel.numberOfLines = 1
        bodyLabel.textAlignment = .Left
        bodyLabel.textColor = UIColor.darkGrayColor()
        
        updateFonts()
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(bodyLabel)
        
        // add a pan recognizer for handling cell dragging
        let recognizer = UIPanGestureRecognizer(target: self, action: "handlePan:")
        recognizer.delegate = self
        addGestureRecognizer(recognizer)
    }
    
    override func updateConstraints()
    {
        if !didSetupConstraints {
            // Note: if the constraints you add below require a larger cell size than the current size (which is likely to be the default size {320, 44}), you'll get an exception.
            // As a fix, you can temporarily increase the size of the cell's contentView so that this does not occur using code similar to the line below.
            //      See here for further discussion: https://github.com/Alex311/TableCellWithAutoLayout/commit/bde387b27e33605eeac3465475d2f2ff9775f163#commitcomment-4633188
            // contentView.bounds = CGRect(x: 0.0, y: 0.0, width: 99999.0, height: 99999.0)
            
            // Prevent the two UILabels from being compressed below their intrinsic content height
            NSLayoutConstraint.autoSetPriority(UILayoutPriorityRequired) {
                self.titleLabel.autoSetContentCompressionResistancePriorityForAxis(.Vertical)
                self.bodyLabel.autoSetContentCompressionResistancePriorityForAxis(.Vertical)
            }
            
            titleLabel.autoPinEdgeToSuperviewEdge(.Top, withInset: kLabelVerticalInsets)
            titleLabel.autoPinEdgeToSuperviewEdge(.Leading, withInset: kLabelHorizontalInsets)
            titleLabel.autoPinEdgeToSuperviewEdge(.Trailing, withInset: kLabelHorizontalInsets)
            
            // This constraint is an inequality so that if the cell is slightly taller than actually required, extra space will go here
            bodyLabel.autoPinEdge(.Top, toEdge: .Bottom, ofView: titleLabel, withOffset: 10.0, relation: .GreaterThanOrEqual)
            
            bodyLabel.autoPinEdgeToSuperviewEdge(.Leading, withInset: kLabelHorizontalInsets)
            bodyLabel.autoPinEdgeToSuperviewEdge(.Trailing, withInset: kLabelHorizontalInsets)
            bodyLabel.autoPinEdgeToSuperviewEdge(.Bottom, withInset: kLabelVerticalInsets)
            
            didSetupConstraints = true
        }
        
        super.updateConstraints()
    }
    
    func updateFonts()
    {
        titleLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        bodyLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption2)
    }
    
    //MARK: - horizontal pan gesture methods
    
    //http://www.raywenderlich.com/77974/making-a-gesture-driven-to-do-list-app-like-clear-in-swift-part-1
    func handlePan(recognizer: UIPanGestureRecognizer) {
        // 1
        if recognizer.state == .Began {
            // when the gesture begins, record the current center location
            originalCenter = center
        }
        // 2
        if recognizer.state == .Changed {
            let translation = recognizer.translationInView(self)
            center = CGPointMake(originalCenter.x + translation.x, originalCenter.y)
            // has the user dragged the item far enough to initiate a delete/complete?
            revealOnDragRelease = frame.origin.x < -frame.size.width / 2.0
        }
        // 3
        if recognizer.state == .Ended {
            // the frame this cell had before user dragged it
            let originalFrame = CGRect(x: 0, y: frame.origin.y,
                width: bounds.size.width, height: bounds.size.height)
            if !revealOnDragRelease {
                // if the item is not being revealed, snap back to the original location
                UIView.animateWithDuration(0.2, animations: {self.frame = originalFrame})
            }
            if revealOnDragRelease {
                if delegate != nil && toDoItem != nil {
                    // notify the delegate that this item should be revealed
                    delegate!.toDoItemRevealed(toDoItem!)
                }
            }
        }
    }
    
    //only allow horizontal pans
    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let translation = panGestureRecognizer.translationInView(superview!)
            if fabs(translation.x) > fabs(translation.y) {
                return true
            }
            return false
        }
        return false
    }

}
