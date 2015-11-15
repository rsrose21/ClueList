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
    // Indicates that the edit process has begun for the given cell
    func cellDidBeginEditing(editingCell: ToDoCellTableViewCell)
    // Indicates that the edit process has committed for the given cell
    func cellDidEndEditing(editingCell: ToDoCellTableViewCell)
}

class ToDoCellTableViewCell: UITableViewCell, UITextFieldDelegate, UIButtonDelegate {

    //Defining fonts of size and type
    let titleFont:UIFont = UIFont(name: Constants.UIFonts.HEADLINE_FONT, size: Constants.UIFonts.HEADLINE_FONT_SIZE)!
    let bodyFont:UIFont = UIFont(name: Constants.UIFonts.BODY_FONT, size: Constants.UIFonts.BASE_FONT_SIZE)!
    
    var originalCenter = CGPoint()
    var hintOnDragRelease = false, revealOnDragRelease = false
    
    // The object that acts as delegate for this cell.
    var delegate: TableViewCellDelegate?
    // The item that this cell renders.
    var toDoItem: ToDoItem? {
        didSet {
            let item = toDoItem!
            // reset the cell label contents
            titleLabel.text = nil
            bodyLabel.text = nil
            editLabel.text = nil
            if item.text == Constants.Messages.PLACEHOLDER_TEXT {
                editLabelOnly = true
            } else {
                editLabelOnly = false
                //if we have some factoids then randomly select one to display as the To Do label
                titleLabel.text = item.getRandomFactoid()
                if titleLabel.text == nil {
                    //no factoids returned for this task, show the original task instead
                    titleLabel.text = item.text
                }
                if item.deadline != nil {
                    bodyLabel.text = "Due " + timeAgoSinceDate(item.deadline!, numericDates: false)
                }
                toggleCompleted(item.completed)
            }
            
            setNeedsLayout()
        }
    }
    
    //labels that serve as contextual clues for our swipe left/right gestures
    var tickLabel: UILabel!, clueLabel: UILabel!
    
    let kUICuesMargin: CGFloat = 10.0, kUICuesWidth: CGFloat = 50.0
    
    var didSetupConstraints = false
    
    var titleLabel: UILabel = UILabel.newAutoLayoutView()
    var bodyLabel: UILabel = UILabel.newAutoLayoutView()
    var editLabel: UITextField = UITextField()
    var checkbox: DOCheckbox!
    
    var editLabelOnly: Bool = false
    
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
    
    // utility method for creating the contextual cues
    func createCueLabel() -> UILabel {
        let label = UILabel(frame: CGRect.null)
        label.textColor = UIColor.whiteColor()
        label.font = UIFont.boldSystemFontOfSize(32.0)
        label.backgroundColor = UIColor.clearColor()
        return label
    }
    
    func setupViews()
    {
        backgroundColor = UIColor.clearColor()
        //prevent highlight from selecting cell when clicking to drag
        selectionStyle = .None
        
        editLabel.delegate = self
        editLabel.contentVerticalAlignment = .Center
        editLabel.placeholder = Constants.Messages.PLACEHOLDER_TEXT
        if Constants.Data.DEBUG_LAYERS {
            editLabel.layer.borderColor = UIColor.blackColor().CGColor
            editLabel.layer.borderWidth = 1.0;
        }
        contentView.addSubview(editLabel)
        
        titleLabel.lineBreakMode = .ByTruncatingTail
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .Left
        if Constants.Data.DEBUG_LAYERS {
            titleLabel.textColor = UIColor.blackColor()
            titleLabel.backgroundColor = UIColor(hexString: "#eeeeeeff")
        }
        contentView.addSubview(titleLabel)
        
        bodyLabel.lineBreakMode = .ByTruncatingTail
        bodyLabel.numberOfLines = 1
        bodyLabel.textAlignment = .Left
        if Constants.Data.DEBUG_LAYERS {
            bodyLabel.textColor = UIColor.darkGrayColor()
            bodyLabel.backgroundColor = UIColor(hexString: "#ccccccff")
        }
        contentView.addSubview(bodyLabel)
        
        checkbox = layoutCheckbox(UIColor(red: 231/255, green: 76/255, blue: 60/255, alpha: 1.0))
        contentView.addSubview(checkbox)
        
        // add a pan recognizer for handling cell dragging
        let recognizer = UIPanGestureRecognizer(target: self, action: "handlePan:")
        recognizer.delegate = self
        addGestureRecognizer(recognizer)
        
        // tick and cross labels for context cues
        tickLabel = createCueLabel()
        tickLabel.text = "\u{2713}"
        tickLabel.textAlignment = .Right
        addSubview(tickLabel)
        clueLabel = createCueLabel()
        clueLabel.text = "?"
        clueLabel.textAlignment = .Left
        addSubview(clueLabel)

        updateFonts()
    }
    
    let kLabelLeftMargin: CGFloat = 15.0
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layoutFrames()
    }

    func layoutFrames() {

        // ensure the background occupies the full bounds
        contentView.frame = bounds
        //set up default dimensions
        let padding: CGFloat = 5
        let buttonWidth: CGFloat = 40
        var marginLeft: CGFloat = 0.0
        var width = frame.width
        var height = frame.height
        
        if editLabelOnly == false {
            editLabel.hidden = true

            //position our contextual clue labels off screen
            tickLabel.frame = CGRect(x: -kUICuesWidth - kUICuesMargin, y: 0,
                width: kUICuesWidth, height: bounds.size.height)
            clueLabel.frame = CGRect(x: bounds.size.width + kUICuesMargin, y: 0,
                width: kUICuesWidth, height: bounds.size.height)
            
            if !checkbox.hidden {
                marginLeft = CGRectGetMaxX(checkbox.frame) + 10
                //give some room for the accessory button
                width = (frame.width - marginLeft) - buttonWidth
            } else {
                //give some room for the move button
                width = (frame.width - marginLeft) - (buttonWidth * 2)
            }

            height = frame.height - 35.0
            
            checkbox.frame = CGRectMake(padding, (frame.height - 25)/2, 25, 25)
            titleLabel.frame = CGRectMake(marginLeft, 0, width, height)
            bodyLabel.frame = CGRectMake(marginLeft, CGRectGetMaxY(titleLabel.frame), width, 35.0)
        } else {
            //show textfield and hide checkbox and accessory button when editing
            editLabel.hidden = false
            checkbox.hidden = true
            titleLabel.hidden = false
            bodyLabel.hidden = false
            accessoryType = .None
        }
        if Constants.Data.DEBUG_LAYERS {
            editLabel.backgroundColor = UIColor(hexString: "#eeeeeeff")
        }
        editLabel.frame = CGRectMake(marginLeft, 0, width, Constants.UIFonts.HEADLINE_FONT_SIZE)
    }
    
    func layoutCheckbox(color: UIColor?) -> DOCheckbox {
        let style: DOCheckboxStyle = .FilledRoundedSquare
        let size: CGFloat = 25.0
        let frame: CGFloat = 25.0
        let checkBoxPosition = (size - frame) / 2
        
        let checkbox = DOCheckbox(frame: CGRectMake(25.0, 25.0, size, size), checkboxFrame: CGRectMake(checkBoxPosition, checkBoxPosition, frame, frame))
        checkbox.setPresetStyle(style, baseColor: color)
        
        return checkbox
    }
    
    override func updateConstraints()
    {
        if !didSetupConstraints {
            // Note: if the constraints you add below require a larger cell size than the current size (which is likely to be the default size {320, 44}), you'll get an exception.
            // As a fix, you can temporarily increase the size of the cell's contentView so that this does not occur using code similar to the line below.
            //      See here for further discussion: https://github.com/Alex311/TableCellWithAutoLayout/commit/bde387b27e33605eeac3465475d2f2ff9775f163#commitcomment-4633188
            //contentView.bounds = CGRect(x: 0.0, y: 0.0, width: 99999.0, height: 99999.0)
            
            if !editLabelOnly {
                // Prevent the two UILabels from being compressed below their intrinsic content height
                NSLayoutConstraint.autoSetPriority(UILayoutPriorityRequired) {
                    self.titleLabel.autoSetContentCompressionResistancePriorityForAxis(.Vertical)
                    self.bodyLabel.autoSetContentCompressionResistancePriorityForAxis(.Vertical)
                }
                titleLabel.autoPinEdgeToSuperviewEdge(.Top, withInset: Constants.UIDimensions.TABLE_CELL_PADDING_TOP)
                titleLabel.autoPinEdgeToSuperviewEdge(.Leading, withInset: Constants.UIDimensions.TABLE_CELL_PADDING_LEFT)
                titleLabel.autoPinEdgeToSuperviewEdge(.Trailing, withInset: Constants.UIDimensions.TABLE_CELL_PADDING_RIGHT)
                
                // This constraint is an inequality so that if the cell is slightly taller than actually required, extra space will go here
                bodyLabel.autoPinEdge(.Top, toEdge: .Bottom, ofView: titleLabel, withOffset: 0.0, relation: .GreaterThanOrEqual)
                
                bodyLabel.autoPinEdgeToSuperviewEdge(.Leading, withInset: Constants.UIDimensions.TABLE_CELL_PADDING_LEFT)
                bodyLabel.autoPinEdgeToSuperviewEdge(.Trailing, withInset: Constants.UIDimensions.TABLE_CELL_PADDING_RIGHT)
                bodyLabel.autoPinEdgeToSuperviewEdge(.Bottom, withInset: Constants.UIDimensions.TABLE_CELL_PADDING_BOTTOM)
            }
            
            //we overlay the editLabel on top of the titleLabel so we set the constraints for both to be the same
            editLabel.autoPinEdgeToSuperviewEdge(.Top, withInset: Constants.UIDimensions.TABLE_CELL_PADDING_TOP)
            editLabel.autoPinEdgeToSuperviewEdge(.Leading, withInset: Constants.UIDimensions.TABLE_CELL_PADDING_LEFT)
            editLabel.autoPinEdgeToSuperviewEdge(.Trailing, withInset: Constants.UIDimensions.TABLE_CELL_PADDING_RIGHT)
            editLabel.autoPinEdgeToSuperviewEdge(.Bottom, withInset: Constants.UIDimensions.TABLE_CELL_PADDING_BOTTOM)
            
            didSetupConstraints = true
        }
        
        super.updateConstraints()
    }
    
    func updateFonts()
    {
        if !editLabelOnly {
            titleLabel.font = titleFont
            bodyLabel.font = bodyFont
        }
        editLabel.font = titleFont
        
    }
    
    func resetConstraints() {
        //didSetupConstraints = false
        updateFonts()
        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
    }
    
    //highlight text in a UILabel: http://stackoverflow.com/questions/3586871/bold-non-bold-text-in-a-single-uilabel
    func highlightText(haystack: NSString, needle: NSString) -> NSMutableAttributedString {
        //Making dictionaries of fonts that will be passed as an attribute
        let textDict:NSDictionary = NSDictionary(object: titleFont, forKey: NSFontAttributeName)
        
        let attributedString = NSMutableAttributedString(string: haystack as String, attributes: textDict as? [String : AnyObject])
        //the clue could be multiple words, so we break them up here for separate highlighting
        let parts = needle.componentsSeparatedByString(" ")
        //loop through each word and highlight them in subject
        for word in parts {
            do {
                try attributedString.highlightStrings(word as String, fontName: Constants.UIFonts.HIGHLIGHT_FONT, fontSize: Constants.UIFonts.HEADLINE_FONT_SIZE)
            } catch {
                print(error)
            }
        }
        return attributedString
    }
    
    func strikeThrough(str: String, style: Int) -> NSAttributedString {
        //http://stackoverflow.com/questions/13133014/uilabel-with-text-struck-through
        let attributeString = NSAttributedString(string: str, attributes: [NSStrikethroughStyleAttributeName: style, NSStrikethroughColorAttributeName: UIColor.redColor()])
        
        return attributeString
    }
    
    //helper to indicate a table view cell item is completed/not completed
    func toggleCompleted(completed: Bool) {
        if completed {
            // fade completed cell
            contentView.alpha = 0.6
            titleLabel.attributedText = strikeThrough(titleLabel.text!, style: NSUnderlineStyle.StyleSingle.rawValue)
            editLabel.attributedText = strikeThrough(editLabel.text!, style: NSUnderlineStyle.StyleSingle.rawValue)
            // hide due date for completed items
            bodyLabel.hidden = true
        } else {
            // make cell opaque
            contentView.alpha = 1.0
            titleLabel.attributedText = strikeThrough(titleLabel.text!, style: NSUnderlineStyle.StyleNone.rawValue)
            editLabel.attributedText = strikeThrough(editLabel.text!, style: NSUnderlineStyle.StyleNone.rawValue)
            bodyLabel.hidden = false
        }
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
            // has the user dragged the item far enough to initiate a hint/reveal?
            hintOnDragRelease = frame.origin.x < -frame.size.width / 2.0
            revealOnDragRelease = frame.origin.x > frame.size.width / 2.0
            // fade the contextual clues
            let cueAlpha = fabs(frame.origin.x) / (frame.size.width / 2.0)
            tickLabel.alpha = cueAlpha
            clueLabel.alpha = cueAlpha
            // indicate when the user has pulled the item far enough to invoke the given action
            tickLabel.textColor = revealOnDragRelease ? UIColor.greenColor() : UIColor.whiteColor()
            clueLabel.textColor = hintOnDragRelease ? UIColor.redColor() : UIColor.whiteColor()
        }
        // 3
        if recognizer.state == .Ended {
            let originalFrame = CGRect(x: 0, y: frame.origin.y,
                width: bounds.size.width, height: bounds.size.height)
            if hintOnDragRelease {
                //highlight the "clue" in the factoid for the user
                titleLabel.attributedText = highlightText((titleLabel.text)!, needle: (toDoItem?.clue)!)
                // Make sure the constraints have been added to this cell, since it may have just been created from scratch
                resetConstraints()
                layoutFrames()
            } else if revealOnDragRelease {
                //reveal the original description
                editLabel.text = toDoItem?.text
                titleLabel.hidden = true
                editLabel.hidden = false
            }
            UIView.animateWithDuration(0.2, animations: {self.frame = originalFrame})
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
    
    // MARK: - UITextFieldDelegate methods
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        // close the keyboard on Enter
        textField.resignFirstResponder()
        return false
    }
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        // disable editing of completed to-do items
        if toDoItem != nil {
            return !toDoItem!.completed
        }
        return false
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if toDoItem != nil {
            toDoItem!.text = textField.text!
        }
        if delegate != nil {
            delegate!.cellDidEndEditing(self)
        }
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        if delegate != nil {
            delegate!.cellDidBeginEditing(self)
        }
    }
    
    // MARK: - UIButtonDelegate methods
    
    func toDoItemCompleted(toDoItem: ToDoItem) {
        //update cell to mark/unmark item completed status
        toggleCompleted(!toDoItem.completed)
    }

}
