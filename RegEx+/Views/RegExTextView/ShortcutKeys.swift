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
        }
    }
}

struct ShortcutKeysView: View {
    let onKeyTapped: (ShortcutKey) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color(UIColor.separator))
                .frame(height: 0.5)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .center, spacing: 8) {
                    ForEach(ShortcutKey.allCases, id: \.rawValue) { key in
                        Button(action: {
                            onKeyTapped(key)
                        }) {
                            Text(key.displayText)
                                .font(.title2)
                                .foregroundColor(.primary)
                                .frame(width: 35, height: 40)
                                .background(Color(UIColor.secondarySystemFill))
                                .cornerRadius(8)
                        }
                        .accessibilityLabel(key.accessibilityLabel)
                        .accessibilityHint("Insert \(key.accessibilityLabel.lowercased()) into text")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .frame(height: .greatestFiniteMagnitude)
        }
        .frame(maxHeight: 56)
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
            heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    private func handleKeyTapped(_ key: ShortcutKey) {
        guard let textView = textView else { return }

        let selectedRange = textView.selectedRange
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
