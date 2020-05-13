//
//  RegExSyntaxHighlighter.swift
//  RegEx+
//
//  Created by Lex on 2020/5/2.
//  Copyright © 2020 Lex.sh. All rights reserved.
//

import UIKit
import SwiftUI


fileprivate extension NSTextStorage {

    func highlight(text: String, color: UIColor = .red) {
        string.ranges(of: text, options: .regularExpression).forEach { [weak self] range in
            guard let self = self else {
                return
            }
            
            let r = self.string.nsRange(from: range)
            self.removeAttribute(.foregroundColor, range: r)
            self.addAttributes([
                .foregroundColor: color
            ], range: r)
        }
    }

}

class RegExSyntaxHighlighter: NSObject, NSTextStorageDelegate {
    
    weak var textStorage: NSTextStorage?
    
    func highlightRegularExpression() {
        guard let ts = textStorage else {
            return
        }
        
        let r = NSRange(location: 0, length: ts.length)
        ts.removeAttribute(.foregroundColor, range: r)
        ts.addAttribute(.foregroundColor, value: UIColor.label, range: r)
        
        [
            #"[\?\*\.\+]"# :                 UIColor.systemGreen,
            #"(?:\{)[\d\w,]+(?:\})"# :       UIColor.systemPurple,
            #"[\^\[\$\]]"# :                 UIColor.systemTeal,
            #"\\[$$\w\.\u0023]"# :           UIColor.systemOrange,
            #"\s\u0023\s?[^\r\n]+[\r\n]*"# : UIColor.systemGray,
            #"[\(\)]"# :                     UIColor.systemPink,
        ].forEach(ts.highlight)
    }

    func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorage.EditActions, range editedRange: NSRange, changeInLength delta: Int) {
        
        self.textStorage = textStorage
        highlightRegularExpression()
    }

}
