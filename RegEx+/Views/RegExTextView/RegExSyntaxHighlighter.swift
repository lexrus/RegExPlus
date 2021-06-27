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

    func highlight(range: Range<String.Index>, color: UIColor) {
        let nsRange = NSRange(range, in: string)
        removeAttribute(.foregroundColor, range: nsRange)
        addAttributes([
            .foregroundColor: color
        ], range: nsRange)
    }

}

class RegExSyntaxHighlighter: NSObject, NSTextStorageDelegate {
    
    weak var textStorage: NSTextStorage?

    private var contentHash: Int = 0
    
    func highlightRegularExpression() {
        guard let ts = textStorage else {
            return
        }

        let regColorMap: [String: UIColor] = [
            #"[\?\*\.\+]"# :                 UIColor.systemGreen,
            #"(?:\{)[\d\w,]+(?:\})"# :       UIColor.systemPurple,
            #"[\^\[\$\]]"# :                 UIColor.systemTeal,
            #"\\[$$\w\.\u0023]"# :           UIColor.systemOrange,
            #"\s\u0023\s?[^\r\n]+[\r\n]*"# : UIColor.systemGray,
            #"[\(\)]"# :                     UIColor.systemPink,
        ]
        
        let r = NSRange(location: 0, length: ts.length)
        ts.removeAttribute(.foregroundColor, range: r)
        ts.addAttribute(.foregroundColor, value: UIColor.label, range: r)

        var colorMap = [Range<String.Index>: UIColor]()

        regColorMap.forEach { regMap in
            ts.string
                .ranges(of: regMap.key, options: .regularExpression)
                .forEach { range in
                    colorMap[range] = regMap.value
                }
        }

        colorMap.forEach(ts.highlight)
    }

    func textStorage(
        _ textStorage: NSTextStorage,
        didProcessEditing editedMask: NSTextStorage.EditActions,
        range editedRange: NSRange,
        changeInLength delta: Int
    ) {
        self.textStorage = textStorage

        let hash = textStorage.string.hash
        if hash != contentHash {
            highlightRegularExpression()
            contentHash = hash
        }
    }

}
