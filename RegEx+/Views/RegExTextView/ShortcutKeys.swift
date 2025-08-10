//
//  ShortcutKeys.swift
//  RegEx+
//
//  Created by Lex on 8/10/25.
//  Copyright © 2025 Lex.sh. All rights reserved.
//

import UIKit

extension UIFont {
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        let descriptor = fontDescriptor.addingAttributes([
            .traits: [UIFontDescriptor.TraitKey.weight: weight]
        ])
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}

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

class ShortcutKeysUIKitView: UIView {
    private let onKeyTapped: (ShortcutKey) -> Void
    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    
    init(onKeyTapped: @escaping (ShortcutKey) -> Void) {
        self.onKeyTapped = onKeyTapped
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = .systemBackground
        
        let separatorTop = UIView()
        separatorTop.backgroundColor = .separator
        separatorTop.translatesAutoresizingMaskIntoConstraints = false
        
        let mainStackView = UIStackView()
        mainStackView.axis = .horizontal
        mainStackView.alignment = .center
        mainStackView.spacing = keyHorizontalMargin
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let arrowKeysStackView = UIStackView()
        arrowKeysStackView.axis = .horizontal
        arrowKeysStackView.spacing = keyHorizontalMargin
        arrowKeysStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let arrowKeys = ShortcutKey.allCases.filter { !$0.isCharKey }
        for key in arrowKeys {
            let button = createKeyButton(for: key, isBold: true)
            arrowKeysStackView.addArrangedSubview(button)
        }
        
        let separatorVertical = UIView()
        separatorVertical.backgroundColor = .separator
        separatorVertical.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceVertical = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        contentStackView.axis = .horizontal
        contentStackView.spacing = keyHorizontalMargin
        contentStackView.translatesAutoresizingMaskIntoConstraints = false

        let charKeys = ShortcutKey.allCases.filter(\.isCharKey)
        for key in charKeys {
            let button = createKeyButton(for: key, isBold: false)
            contentStackView.addArrangedSubview(button)
        }
        
        scrollView.addSubview(contentStackView)
        
        mainStackView.addArrangedSubview(arrowKeysStackView)
        mainStackView.addArrangedSubview(separatorVertical)
        mainStackView.addArrangedSubview(scrollView)
        
        addSubview(separatorTop)
        addSubview(mainStackView)
        
        NSLayoutConstraint.activate([
            separatorTop.topAnchor.constraint(equalTo: topAnchor),
            separatorTop.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorTop.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorTop.heightAnchor.constraint(equalToConstant: 0.5),
            
            mainStackView.topAnchor.constraint(equalTo: separatorTop.bottomAnchor, constant: keyVerticalSpacing),
            mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: keyHorizontalMargin),
            mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -keyHorizontalMargin),
            mainStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -keyVerticalSpacing),
            
            separatorVertical.widthAnchor.constraint(equalToConstant: 1),
            separatorVertical.heightAnchor.constraint(equalToConstant: keyHeight),
            
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
    }
    
    private func createKeyButton(for key: ShortcutKey, isBold: Bool) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(key.displayText, for: .normal)
        button.titleLabel?.font = isBold ? UIFont.preferredFont(forTextStyle: .title2).withWeight(.bold) : UIFont.preferredFont(forTextStyle: .title2)
        button.setTitleColor(.label, for: .normal)
        button.backgroundColor = .secondarySystemFill
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.accessibilityLabel = key.accessibilityLabel
        if key.isCharKey {
            button.accessibilityHint = "Insert \(key.accessibilityLabel.lowercased()) into text"
        } else {
            button.accessibilityHint = key.accessibilityLabel
        }
        
        button.addTarget(self, action: #selector(keyTapped(_:)), for: .touchUpInside)
        button.tag = ShortcutKey.allCases.firstIndex(of: key) ?? 0
        
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: keyWidth),
            button.heightAnchor.constraint(equalToConstant: keyHeight)
        ])
        
        return button
    }
    
    @objc private func keyTapped(_ sender: UIButton) {
        let key = ShortcutKey.allCases[sender.tag]
        onKeyTapped(key)
    }
}

class ShortcutKeysAccessoryView: UIView {
    weak var textView: UITextView?
    weak var coordinator: UITextViewWrapper.Coordinator?
    
    private var shortcutKeysView: ShortcutKeysUIKitView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        let shortcutKeysView = ShortcutKeysUIKitView { [weak self] key in
            self?.handleKeyTapped(key)
        }
        
        shortcutKeysView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(shortcutKeysView)
        self.shortcutKeysView = shortcutKeysView

        translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            shortcutKeysView.topAnchor.constraint(equalTo: topAnchor),
            shortcutKeysView.leadingAnchor.constraint(equalTo: leadingAnchor),
            shortcutKeysView.trailingAnchor.constraint(equalTo: trailingAnchor),
            shortcutKeysView.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightAnchor.constraint(equalToConstant: keyHeight + keyVerticalSpacing * 2 + 1)
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
