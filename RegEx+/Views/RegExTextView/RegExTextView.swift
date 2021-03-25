//
//  RegExSyntaxView.swift
//  RegEx+
//
//  Created by Lex on 2020/4/23.
//  Copyright © 2020 Lex.sh. All rights reserved.
//

import SwiftUI
import Combine
import UIKit


// Credit to: Asperi https://stackoverflow.com/users/12299030/asperi
// https://stackoverflow.com/a/58639072/1209135
private struct UITextViewWrapper: UIViewRepresentable {
    typealias UIViewType = UITextView

    @Binding var text: String
    @Binding var calculatedHeight: CGFloat
    var onDone: (() -> Void)?
    
    private let syntaxHighlighter = RegExSyntaxHighlighter()

    func makeUIView(context: UIViewRepresentableContext<UITextViewWrapper>) -> UITextView {
        let tv = UITextView()
        tv.delegate = context.coordinator
        tv.textStorage.delegate = syntaxHighlighter

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
        if uiView.text != self.text {
            uiView.text = self.text
        }
        
        syntaxHighlighter.textStorage = uiView.textStorage
        syntaxHighlighter.highlightRegularExpression()
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

struct RegExTextView: View {

    private var placeholder: String
    private var onCommit: (() -> Void)?

    @Binding private var text: String
    private var internalText: Binding<String> {
        Binding<String>(get: { self.text }) {
            self.text = $0
            self.showingPlaceholder = $0.isEmpty
        }
    }
    
    @State private var dynamicHeight: CGFloat = 22
    @State private var showingPlaceholder = false

    init (_ placeholder: String = "", text: Binding<String>, onCommit: (() -> Void)? = nil) {
        self.placeholder = placeholder
        self.onCommit = onCommit
        self._text = text
        self._showingPlaceholder = State<Bool>(initialValue: self.text.isEmpty)
    }

    var body: some View {
        UITextViewWrapper(text: internalText,
                          calculatedHeight: $dynamicHeight,
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
struct RegExTextView_Previews: PreviewProvider {
    static var test = "^(\\d+)\\.(\\d{2}) (\\d+)\\.(\\d{2}) (\\d+)\\.(\\d{2}) (\\d+)\\.(\\d{2})"
    static var testBinding = Binding<String>(get: { test }, set: { test = $0 })

    static var previews: some View {
        Group {
            VStack(alignment: .leading) {
                RegExTextView("Enter some text here", text: testBinding) {
                    print("Final text: \(test)")
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 4).stroke(Color.black)
                )
            }
            VStack(alignment: .leading) {
                RegExTextView("Enter some text here", text: testBinding) {
                    print("Final text: \(test)")
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 4).stroke(Color.black)
                )
            }
        }
    }
}
#endif
