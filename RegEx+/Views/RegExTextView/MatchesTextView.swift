//
//  MatchesTextView.swift
//  RegEx+
//
//  Created by Lex on 2020/5/2.
//  Copyright © 2020 Lex.sh. All rights reserved.
//

import UIKit
import SwiftUI


fileprivate struct UITextViewWrapper: UIViewRepresentable {
    typealias UIViewType = UITextView

    @Binding var text: String
    @Binding var calculatedHeight: CGFloat
    var matches: [NSTextCheckingResult]
    var onDone: (() -> Void)?

    func makeUIView(context: UIViewRepresentableContext<UITextViewWrapper>) -> UITextView {
        
        let tv = UITextView()
        tv.delegate = context.coordinator

        tv.isEditable = true
        tv.font = UIFont.preferredFont(forTextStyle: .body)
        tv.isSelectable = true
        tv.isUserInteractionEnabled = true
        tv.isScrollEnabled = false
        tv.backgroundColor = UIColor.clear
        
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        if nil != onDone {
            tv.returnKeyType = .done
        }

        tv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: UIViewRepresentableContext<UITextViewWrapper>) {
        if !text.isEmpty {
            let att = NSMutableAttributedString(string: text)
            att.setAttributes([
                .font: UIFont.preferredFont(forTextStyle: .body),
                .foregroundColor: UIColor.label
            ], range: NSRange(location: 0, length: uiView.text.count))
            
            matches.forEach { result in
                for index in 0..<result.numberOfRanges {
                    let range = result.range(at: index)
                    if range.location + range.length > uiView.attributedText.length {
                        return
                    }
                    att.setAttributes([
                        .font: UIFont.preferredFont(forTextStyle: .body),
                        .foregroundColor: UIColor.red
                    ], range: range)
                }
            }
            
            uiView.attributedText = att
        }
        
        UITextViewWrapper.recalculateHeight(view: uiView, result: $calculatedHeight)
    }

    fileprivate static func recalculateHeight(view: UIView, result: Binding<CGFloat>) {
        let newSize = view.sizeThatFits(CGSize(width: view.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
        if result.wrappedValue != newSize.height {
            DispatchQueue.main.async {
                result.wrappedValue = newSize.height // !! must be called asynchronously
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text, height: $calculatedHeight, onDone: onDone)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var text: Binding<String>
        var calculatedHeight: Binding<CGFloat>
        var onDone: (() -> Void)?

        init(text: Binding<String>, height: Binding<CGFloat>, onDone: (() -> Void)? = nil) {
            self.text = text
            self.calculatedHeight = height
            self.onDone = onDone
        }

        func textViewDidChange(_ uiView: UITextView) {
            text.wrappedValue = uiView.text
            UITextViewWrapper.recalculateHeight(view: uiView, result: calculatedHeight)
        }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if let onDone = self.onDone, text == "\n" {
                textView.resignFirstResponder()
                onDone()
                return false
            }
            return true
        }
    }

}

struct MatchesTextView: View {

    private var placeholder: String
    private var onCommit: (() -> Void)?

    @Binding private var text: String
    private var internalText: Binding<String> {
        Binding<String>(get: { self.text } ) {
            self.text = $0
            self.showingPlaceholder = $0.isEmpty
        }
    }
    
    @Binding private var matches: [NSTextCheckingResult]
    @State private var dynamicHeight: CGFloat = 100
    @State private var showingPlaceholder = false

    init (_ placeholder: String = "", text: Binding<String>, matches: Binding<[NSTextCheckingResult]>, onCommit: (() -> Void)? = nil) {
        self.placeholder = placeholder
        self.onCommit = onCommit
        self._matches = matches
        self._text = text
        self._showingPlaceholder = State<Bool>(initialValue: self.text.isEmpty)
    }

    var body: some View {
        UITextViewWrapper(text: internalText,
                          calculatedHeight: $dynamicHeight,
                          matches: matches,
                          onDone: onCommit)
            .frame(minHeight: dynamicHeight, maxHeight: dynamicHeight)
            .background(placeholderView, alignment: .topLeading)
    }

    var placeholderView: some View {
        Group {
            if showingPlaceholder {
                VStack {
                    Text(placeholder)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

}

#if DEBUG
struct MatchesTextView_Previews: PreviewProvider {
    static var test = "^(\\d+)\\.(\\d{2}) (\\d+)\\.(\\d{2}) (\\d+)\\.(\\d{2}) (\\d+)\\.(\\d{2})"
    static var testBinding = Binding<String>(get: { test }, set: { test = $0 } )
    static var matches = [NSTextCheckingResult]()
    static var matchesBinding = Binding<[NSTextCheckingResult]>(get: { matches }, set: { matches = $0 })

    static var previews: some View {
        VStack(alignment: .leading) {
            Text("Description:")
            MatchesTextView("Enter some text here",
                          text: testBinding,
                          matches: matchesBinding)
            {
                print("Final text: \(test)")
            }
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.black))
            Spacer()
        }
        .padding()
    }
}
#endif
