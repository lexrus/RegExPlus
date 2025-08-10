//
//  ShortcutKeys.swift
//  RegEx+
//
//  Created by Lex on 8/10/25.
//  Copyright © 2025 Lex.sh. All rights reserved.
//

import SwiftUI
import UIKit

enum ShortcutKey: String, CaseIterable {
    case leftArrow = "←"
    case rightArrow = "→"
    case asterisk = "*"
    case question = "?"
    case openBracket = "["
    case closeBracket = "]"
    case openParen = "("
    case closeParen = ")"
    case backslash = "\\"
    case dollar = "$"
    case caret = "^"
    case dot = "."
    case plus = "+"
    case minus = "-"
    case pipe = "|"
    case openBrace = "{"
    case closeBrace = "}"

    var displayText: String {
        return self.rawValue
    }

    var accessibilityLabel: String {
        switch self {
        case .asterisk: return "Asterisk"
        case .question: return "Question mark"
        case .openBracket: return "Open bracket"
        case .closeBracket: return "Close bracket"
        case .openParen: return "Open parenthesis"
        case .closeParen: return "Close parenthesis"
        case .backslash: return "Backslash"
        case .dollar: return "Dollar sign"
        case .caret: return "Caret"
        case .dot: return "Dot"
        case .plus: return "Plus"
        case .minus: return "Minus"
        case .pipe: return "Pipe"
        case .openBrace: return "Open brace"
        case .closeBrace: return "Close brace"
        case .leftArrow: return "Left arrow"
        case .rightArrow: return "Right arrow"
        }
    }

    var isCharKey: Bool {
        switch self {
        case .leftArrow, .rightArrow: false
        default: true
        }
    }
}

private let keyWidth: CGFloat = 35
private let keyHeight: CGFloat = 40
private let keyHorizontalMargin: CGFloat = 6
private let keyVerticalSpacing: CGFloat = 8

struct ShortcutKeysView: View {
    let onKeyTapped: (ShortcutKey) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color(UIColor.separator))
                .frame(height: 0.5)

            HStack(alignment: .center, spacing: keyHorizontalMargin) {
                HStack(alignment: .center, spacing: keyHorizontalMargin) {
                    ForEach(ShortcutKey.allCases.filter { !$0.isCharKey }, id: \.rawValue) { key in
                        Button(action: {
                            onKeyTapped(key)
                        }) {
                            Text(key.displayText)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .frame(width: keyWidth, height: keyHeight)
                                .background(Color(UIColor.secondarySystemFill))
                                .cornerRadius(8)
                        }
                        .accessibilityLabel(key.accessibilityLabel)
                        .accessibilityHint(key.accessibilityLabel)
                    }
                }

                Rectangle()
                    .fill(Color(UIColor.separator))
                    .frame(width: 1, height: keyHeight)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .center, spacing: keyHorizontalMargin) {
                        ForEach(ShortcutKey.allCases.filter(\.isCharKey), id: \.rawValue) { key in
                            Button(action: {
                                onKeyTapped(key)
                            }) {
                                Text(key.displayText)
                                    .font(.title2)
                                    .foregroundColor(.primary)
                                    .frame(width: keyWidth, height: keyHeight)
                                    .background(Color(UIColor.secondarySystemFill))
                                    .cornerRadius(8)
                            }
                            .accessibilityLabel(key.accessibilityLabel)
                            .accessibilityHint("Insert \(key.accessibilityLabel.lowercased()) into text")
                        }
                    }
                }
            }
            .padding(.horizontal, keyHorizontalMargin)
            .padding(.vertical, keyVerticalSpacing)
            .frame(maxHeight: .greatestFiniteMagnitude)
        }
        .frame(maxHeight: .greatestFiniteMagnitude)
        .background(Color(UIColor.systemBackground))
    }
}

class ShortcutKeysAccessoryView: UIView {
    weak var textView: UITextView?
    weak var coordinator: UITextViewWrapper.Coordinator?
    
    private var hostingController: UIHostingController<ShortcutKeysView>?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        let shortcutKeysView = ShortcutKeysView { [weak self] key in
            self?.handleKeyTapped(key)
        }
        
        let hostingController = UIHostingController(rootView: shortcutKeysView)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(hostingController.view)
        self.hostingController = hostingController

        translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightAnchor.constraint(equalToConstant: keyHeight + keyVerticalSpacing * 2)
        ])
    }

    private func handleKeyTapped(_ key: ShortcutKey) {
        guard let textView = textView else { return }

        let selectedRange = textView.selectedRange
        
        // Handle cursor movement keys
        if key == .leftArrow {
            let newPosition = max(0, selectedRange.location - 1)
            textView.selectedRange = NSRange(location: newPosition, length: 0)
            return
        } else if key == .rightArrow {
            let textLength = textView.text?.count ?? 0
            let newPosition = min(textLength, selectedRange.location + 1)
            textView.selectedRange = NSRange(location: newPosition, length: 0)
            return
        }
        
        // Handle text insertion keys
        let currentText = textView.text ?? ""
        let newText = (currentText as NSString).replacingCharacters(in: selectedRange, with: key.rawValue)

        textView.text = newText

        let newCursorPosition = selectedRange.location + key.rawValue.count
        textView.selectedRange = NSRange(location: newCursorPosition, length: 0)

        // Update the binding through coordinator
        if let coordinator = coordinator {
            coordinator.text.wrappedValue = newText
        }

        // Trigger syntax highlighting if available
        if let textStorage = textView.textStorage.delegate as? RegExSyntaxHighlighter {
            textStorage.textStorage = textView.textStorage
            textStorage.highlightRegularExpression()
        }

        // Notify delegate of text change to trigger height recalculation
        if let delegate = textView.delegate {
            delegate.textViewDidChange?(textView)
        }
    }
}
