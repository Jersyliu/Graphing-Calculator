//
//  StatisticsViewController.swift
//  Graphing calculator
//
//  Created by Ruslan Serebryakov on 7/23/15.
//  Copyright (c) 2015 Ruslan Serebryakov. All rights reserved.
//

import UIKit

class StatisticsViewController: UIViewController {

    @IBOutlet weak var textView: UITextView! {
        didSet {
            textView.text = statistics
        }
    }
    
    var statistics: String? {
        didSet {
            textView?.text = statistics
        }
    }
    
    override var preferredContentSize: CGSize {
        get {
            if textView != nil && presentingViewController != nil {
                return textView.sizeThatFits(presentingViewController!.view.bounds.size)
            } else {
                return super.preferredContentSize
            }
        }
        set { super.preferredContentSize = newValue }
    }

}
