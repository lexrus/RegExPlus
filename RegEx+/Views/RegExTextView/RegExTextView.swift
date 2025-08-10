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
struct UITextViewWrapper: UIViewRepresentable {
    typealias UIViewType = UITextView

    @Binding var text: String
    @Binding var calculatedHeight: CGFloat
    var onDone: (() -> Void)?
    @Binding var coordinator: Coordinator?
    var showShortcutBar: Bool
    
    private let syntaxHighlighter = RegExSyntaxHighlighter()

    func makeUIView(context: UIViewRepresentableContext<UITextViewWrapper>) -> UITextView {
        let tv = UITextView()
        tv.delegate = context.coordinator
        tv.textStorage.delegate = syntaxHighlighter

        let font = UIFont.preferredFont(forTextStyle: .body)

        tv.isEditable = true
        tv.font = font.withSize(font.pointSize + 2)
        tv.isSelectable = true
        tv.autocorrectionType = .no
        tv.spellCheckingType = .no
        tv.keyboardType = .emailAddress
        tv.isUserInteractionEnabled = true
        tv.isScrollEnabled = false
        tv.backgroundColor = UIColor.clear
        
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        if nil != onDone {
            tv.returnKeyType = .done
        }

        context.coordinator.textView = tv
        coordinator = context.coordinator

#if !targetEnvironment(macCatalyst)
        // Set up input accessory view for shortcut bar on iOS
        if showShortcutBar {
            let accessoryView = ShortcutKeysAccessoryView()
            accessoryView.textView = tv
            accessoryView.coordinator = context.coordinator
            tv.inputAccessoryView = accessoryView
        }
#endif

        return tv
    }

    func updateUIView(_ uiView: UITextView, context: UIViewRepresentableContext<UITextViewWrapper>) {
        guard uiView.text != text else {
            return
        }

        uiView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        uiView.textContainer.lineBreakMode = .byCharWrapping
        uiView.text = text
        
        syntaxHighlighter.textStorage = uiView.textStorage
        syntaxHighlighter.highlightRegularExpression()
        
        // Calculate height synchronously since we're already on the main thread
        UITextViewWrapper.recalculateHeight(view: uiView, result: $calculatedHeight)
    }

    fileprivate static func recalculateHeight(view: UIView, result: Binding<CGFloat>) {
        let newSize = view.sizeThatFits(CGSize(width: view.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
        if result.wrappedValue != newSize.height {
            result.wrappedValue = newSize.height
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text, height: $calculatedHeight, onDone: onDone)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var text: Binding<String>
        var calculatedHeight: Binding<CGFloat>
        var onDone: (() -> Void)?
        weak var textView: UITextView?

        init(text: Binding<String>, height: Binding<CGFloat>, onDone: (() -> Void)? = nil) {
            self.text = text
            self.calculatedHeight = height
            self.onDone = onDone
            super.init()
        }

        func textViewDidChange(_ uiView: UITextView) {
            // Only update if text actually changed
            if text.wrappedValue != uiView.text {
                text.wrappedValue = uiView.text
                UITextViewWrapper.recalculateHeight(view: uiView, result: calculatedHeight)
            }
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

struct RegExTextView: View, Equatable {

    private var placeholder: String
    private var onCommit: (() -> Void)?
    private var showShortcutBar: Bool

    @Binding private var text: String
    private var internalText: Binding<String> {
        Binding<String>(get: { self.text }) {
            self.text = $0
            self.showingPlaceholder = $0.isEmpty
        }
    }
    
    @State private var dynamicHeight: CGFloat = 20
    @State private var showingPlaceholder = false
    @State private var coordinator: UITextViewWrapper.Coordinator?

    init (_ placeholder: String = "", text: Binding<String>, onCommit: (() -> Void)? = nil, showShortcutBar: Bool = false) {
        self.placeholder = placeholder
        self.onCommit = onCommit
        self._text = text
        self.showShortcutBar = showShortcutBar
        self._showingPlaceholder = State<Bool>(initialValue: text.wrappedValue.isEmpty)
    }

    var body: some View {
        UITextViewWrapper(
            text: internalText,
            calculatedHeight: $dynamicHeight,
            onDone: onCommit,
            coordinator: $coordinator,
            showShortcutBar: showShortcutBar
        )
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

    static func == (lhs: RegExTextView, rhs: RegExTextView) -> Bool {
        lhs.text == rhs.text
    }

}

#if DEBUG
struct RegExTextView_Previews: PreviewProvider {
    static var test = #"^(\d+)\.(\d{2}) (\d+)\.(\d{2}) (\d+)\.(\d{2}) (\d+)\.(\d{2})"#
    static var testBinding = Binding<String>(get: { test }, set: { test = $0 })

    static var previews: some View {
        Group {
            VStack(alignment: .leading) {
                RegExTextView("Enter some text here", text: testBinding, onCommit: {
                    print("Final text: \(test)")
                }, showShortcutBar: true)
                .overlay(
                    RoundedRectangle(cornerRadius: 4).stroke(Color.black)
                )
            }
            VStack(alignment: .leading) {
                RegExTextView("Enter some text here", text: testBinding, onCommit: {
                    print("Final text: \(test)")
                }, showShortcutBar: false)
                .overlay(
                    RoundedRectangle(cornerRadius: 4).stroke(Color.black)
                )
            }
        }
    }
}
#endif
