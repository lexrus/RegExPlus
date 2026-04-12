//
//  RegExSyntaxHighlighter.swift
//  RegEx+
//
//  Created by Lex on 2020/5/2.
//  Copyright © 2020 Lex.sh. All rights reserved.
//

import Foundation
import UIKit
import _RegexParser

enum RegExTextHighlightingMode: Equatable {
    case plainText
    case regularExpression(NSRegularExpression.Options)

    var signature: Int {
        switch self {
        case .plainText:
            return 0
        case .regularExpression(let options):
            return Int(truncatingIfNeeded: options.rawValue) ^ 0x51A9
        }
    }
}

fileprivate extension NSMutableAttributedString {

    func applyAttributes(_ attributes: [NSAttributedString.Key: Any], to range: Range<String.Index>) {
        let nsRange = NSRange(range, in: string)
        addAttributes(attributes, range: nsRange)
    }

}

final class RegExSyntaxHighlighter: NSObject, NSTextStorageDelegate {

    weak var textStorage: NSTextStorage?
    var highlightingMode: RegExTextHighlightingMode = .regularExpression([])

    private var lastHighlightSignature: Int?

    func highlightRegularExpression(force: Bool = false) {
        guard let textStorage else {
            return
        }

        let signature = highlightSignature(for: textStorage.string)
        if !force, signature == lastHighlightSignature {
            return
        }

        let string = textStorage.string
        let attributed = NSMutableAttributedString(attributedString: textStorage)
        let fullRange = NSRange(location: 0, length: attributed.length)

        attributed.removeAttribute(.foregroundColor, range: fullRange)
        attributed.removeAttribute(.underlineStyle, range: fullRange)
        attributed.removeAttribute(.underlineColor, range: fullRange)
        attributed.addAttribute(.foregroundColor, value: UIColor.label, range: fullRange)

        semanticTokens(for: string).sorted(by: tokenSort).forEach { token in
            attributed.applyAttributes(token.attributes, to: token.range)
        }

        textStorage.setAttributedString(attributed)
        lastHighlightSignature = signature
    }

    func textStorage(
        _ textStorage: NSTextStorage,
        didProcessEditing editedMask: NSTextStorage.EditActions,
        range editedRange: NSRange,
        changeInLength delta: Int
    ) {
        self.textStorage = textStorage
        highlightRegularExpression()
    }

}

private extension RegExSyntaxHighlighter {

    struct HighlightToken {
        let range: Range<String.Index>
        let attributes: [NSAttributedString.Key: Any]
        let priority: Int
    }

    struct TokenStyle {
        let color: UIColor
        let priority: Int
    }

    enum HighlightColor {
        static let quantifier = UIColor.systemGreen
        static let quantifierRange = UIColor.systemPurple
        static let structural = UIColor.systemPink
        static let characterClass = UIColor.systemTeal
        static let escape = UIColor.systemOrange
        static let comment = UIColor.systemGray
        static let directive = UIColor.systemPurple
        static let error = UIColor.systemRed
    }

    enum HighlightStyle {
        static let comment = TokenStyle(color: HighlightColor.comment, priority: 10)
        static let structural = TokenStyle(color: HighlightColor.structural, priority: 20)
        static let delimiter = TokenStyle(color: HighlightColor.structural, priority: 30)
        static let characterClass = TokenStyle(color: HighlightColor.characterClass, priority: 30)
        static let quantifier = TokenStyle(color: HighlightColor.quantifier, priority: 40)
        static let quantifierRange = TokenStyle(color: HighlightColor.quantifierRange, priority: 40)
        static let escape = TokenStyle(color: HighlightColor.escape, priority: 40)
        static let directive = TokenStyle(color: HighlightColor.directive, priority: 40)
    }

    func tokenSort(lhs: HighlightToken, rhs: HighlightToken) -> Bool {
        if lhs.priority != rhs.priority {
            return lhs.priority < rhs.priority
        }
        if lhs.range.lowerBound != rhs.range.lowerBound {
            return lhs.range.lowerBound < rhs.range.lowerBound
        }
        return lhs.range.upperBound < rhs.range.upperBound
    }

    func highlightSignature(for text: String) -> Int {
        var hasher = Hasher()
        hasher.combine(text)
        hasher.combine(highlightingMode.signature)
        return hasher.finalize()
    }

    func semanticTokens(for source: String) -> [HighlightToken] {
        guard !source.isEmpty else {
            return []
        }

        switch highlightingMode {
        case .plainText:
            return []
        case .regularExpression(let options):
            guard !options.contains(.ignoreMetacharacters) else {
                return []
            }

            let ast = parseWithRecovery(source, syntaxOptions(for: options))
            var tokens = [HighlightToken]()

            if let globalOptions = ast.globalOptions {
                globalOptions.options.forEach { option in
                    addColorToken(for: option.location, in: source, style: HighlightStyle.directive, to: &tokens)
                }
            }

            collectTokens(from: ast.root, in: source, into: &tokens)

            ast.diags.diags.forEach { diagnostic in
                addUnderlineToken(for: diagnostic.location, in: source, color: HighlightColor.error, priority: 100, to: &tokens)
            }

            return tokens
        }
    }

    func syntaxOptions(for options: NSRegularExpression.Options) -> SyntaxOptions {
        var syntax: SyntaxOptions = .traditional
        if options.contains(.allowCommentsAndWhitespace) {
            syntax.formUnion(.extendedSyntax)
        }
        return syntax
    }

    // swiftlint:disable:next cyclomatic_complexity
    func collectTokens(from node: AST.Node, in source: String, into tokens: inout [HighlightToken]) {
        switch node {
        case .alternation(let alternation):
            collectTokens(from: alternation, in: source, into: &tokens)

        case .concatenation(let concatenation):
            concatenation.children.forEach { child in
                collectTokens(from: child, in: source, into: &tokens)
            }

        case .group(let group):
            collectTokens(from: group, in: source, into: &tokens)

        case .conditional(let conditional):
            collectTokens(from: conditional, in: source, into: &tokens)

        case .quantification(let quantification):
            collectTokens(from: quantification, in: source, into: &tokens)

        case .quote(let quote):
            addColorToken(for: quote.location, in: source, style: HighlightStyle.escape, to: &tokens)

        case .trivia(let trivia):
            addColorToken(for: trivia.location, in: source, style: HighlightStyle.comment, to: &tokens)

        case .interpolation(let interpolation):
            addColorToken(for: interpolation.location, in: source, style: HighlightStyle.directive, to: &tokens)

        case .atom(let atom):
            collectTokens(from: atom, in: source, into: &tokens)

        case .customCharacterClass(let characterClass):
            collectTokens(from: characterClass, in: source, into: &tokens)

        case .absentFunction(let absentFunction):
            addColorToken(for: absentFunction.start, in: source, style: HighlightStyle.delimiter, to: &tokens)
            collectTokens(from: absentFunction, in: source, into: &tokens)

        case .empty:
            break
        }
    }

    func collectTokens(from alternation: AST.Alternation, in source: String, into tokens: inout [HighlightToken]) {
        alternation.pipes.forEach { pipe in
            addColorToken(for: pipe, in: source, style: HighlightStyle.structural, to: &tokens)
        }
        alternation.children.forEach { child in
            collectTokens(from: child, in: source, into: &tokens)
        }
    }

    func collectTokens(from group: AST.Group, in source: String, into tokens: inout [HighlightToken]) {
        addDelimitedToken(parent: group.location, child: group.child.location, in: source, style: HighlightStyle.delimiter, to: &tokens)
        collectTokens(from: group.child, in: source, into: &tokens)
    }

    func collectTokens(from conditional: AST.Conditional, in source: String, into tokens: inout [HighlightToken]) {
        addColorToken(for: conditional.location.start ..< conditional.condition.location.end, in: source, style: HighlightStyle.delimiter, to: &tokens)
        if let pipe = conditional.pipe {
            addColorToken(for: pipe, in: source, style: HighlightStyle.structural, to: &tokens)
        }
        addColorToken(for: conditional.falseBranch.location.end ..< conditional.location.end, in: source, style: HighlightStyle.delimiter, to: &tokens)
        collectTokens(from: conditional.trueBranch, in: source, into: &tokens)
        collectTokens(from: conditional.falseBranch, in: source, into: &tokens)
    }

    func collectTokens(from quantification: AST.Quantification, in source: String, into tokens: inout [HighlightToken]) {
        collectTokens(from: quantification.child, in: source, into: &tokens)
        addColorToken(for: quantification.amount.location, in: source, style: style(for: quantification.amount.value), to: &tokens)
        addColorToken(for: quantification.kind.location, in: source, style: HighlightStyle.quantifier, to: &tokens)
    }

    func collectTokens(from atom: AST.Atom, in source: String, into tokens: inout [HighlightToken]) {
        switch atom.kind {
        case .dot:
            addColorToken(for: atom.location, in: source, style: HighlightStyle.quantifier, to: &tokens)

        case .caretAnchor, .dollarAnchor:
            addColorToken(for: atom.location, in: source, style: HighlightStyle.characterClass, to: &tokens)

        case .char:
            if let range = sourceRange(for: atom.location, in: source), source[range].hasPrefix("\\") {
                tokens.append(
                    HighlightToken(
                        range: range,
                        attributes: [.foregroundColor: HighlightStyle.escape.color],
                        priority: HighlightStyle.escape.priority
                    )
                )
            }

        case .scalar, .scalarSequence, .property, .escaped,
             .keyboardControl, .keyboardMeta, .keyboardMetaControl,
             .namedCharacter, .backreference, .subpattern:
            addColorToken(for: atom.location, in: source, style: HighlightStyle.escape, to: &tokens)

        case .callout, .backtrackingDirective, .changeMatchingOptions:
            addColorToken(for: atom.location, in: source, style: HighlightStyle.directive, to: &tokens)

        case .invalid:
            break
        }
    }

    func collectTokens(from characterClass: AST.CustomCharacterClass, in source: String, into tokens: inout [HighlightToken]) {
        addColorToken(for: characterClass.start.location, in: source, style: HighlightStyle.characterClass, to: &tokens)

        if let closingRange = sourceRange(for: lastChildEnd(in: characterClass.members, defaultingTo: characterClass.start.location.end) ..< characterClass.location.end, in: source) {
            tokens.append(
                HighlightToken(
                    range: closingRange,
                    attributes: [.foregroundColor: HighlightStyle.characterClass.color],
                    priority: HighlightStyle.characterClass.priority
                )
            )
        }

        characterClass.members.forEach { member in
            collectTokens(from: member, in: source, into: &tokens)
        }
    }

    func collectTokens(from absentFunction: AST.AbsentFunction, in source: String, into tokens: inout [HighlightToken]) {
        let closingStart: String.Index

        switch absentFunction.kind {
        case .repeater(let node), .stopper(let node):
            collectTokens(from: node, in: source, into: &tokens)
            closingStart = node.location.end

        case .expression(let absentee, let pipe, let expression):
            collectTokens(from: absentee, in: source, into: &tokens)
            addColorToken(for: pipe, in: source, style: HighlightStyle.structural, to: &tokens)
            collectTokens(from: expression, in: source, into: &tokens)
            closingStart = expression.location.end

        case .clearer:
            closingStart = absentFunction.start.end
        }

        addColorToken(for: closingStart ..< absentFunction.location.end, in: source, style: HighlightStyle.delimiter, to: &tokens)
    }

    func collectTokens(from member: AST.CustomCharacterClass.Member, in source: String, into tokens: inout [HighlightToken]) {
        switch member {
        case .custom(let characterClass):
            collectTokens(from: characterClass, in: source, into: &tokens)

        case .range(let range):
            collectTokens(from: range.lhs, in: source, into: &tokens)
            collectTokens(from: range.rhs, in: source, into: &tokens)
            addColorToken(for: range.dashLoc, in: source, style: HighlightStyle.characterClass, to: &tokens)
            range.trivia.forEach { trivia in
                addColorToken(for: trivia.location, in: source, style: HighlightStyle.comment, to: &tokens)
            }

        case .atom(let atom):
            collectTokens(from: atom, in: source, into: &tokens)

        case .quote(let quote):
            addColorToken(for: quote.location, in: source, style: HighlightStyle.escape, to: &tokens)

        case .trivia(let trivia):
            addColorToken(for: trivia.location, in: source, style: HighlightStyle.comment, to: &tokens)

        case .setOperation(let lhs, let operation, let rhs):
            lhs.forEach { collectTokens(from: $0, in: source, into: &tokens) }
            addColorToken(for: operation.location, in: source, style: HighlightStyle.characterClass, to: &tokens)
            rhs.forEach { collectTokens(from: $0, in: source, into: &tokens) }
        }
    }

    func addDelimitedToken(
        parent: SourceLocation,
        child: SourceLocation,
        in source: String,
        style: TokenStyle,
        to tokens: inout [HighlightToken]
    ) {
        addColorToken(for: parent.start ..< child.start, in: source, style: style, to: &tokens)
        addColorToken(for: child.end ..< parent.end, in: source, style: style, to: &tokens)
    }

    func addColorToken(
        for location: SourceLocation,
        in source: String,
        style: TokenStyle,
        to tokens: inout [HighlightToken]
    ) {
        addColorToken(for: location.range, in: source, style: style, to: &tokens)
    }

    func addColorToken(
        for range: Range<String.Index>,
        in source: String,
        style: TokenStyle,
        to tokens: inout [HighlightToken]
    ) {
        guard let range = sourceRange(for: range, in: source) else {
            return
        }

        tokens.append(
            HighlightToken(
                range: range,
                attributes: [.foregroundColor: style.color],
                priority: style.priority
            )
        )
    }

    func addUnderlineToken(
        for location: SourceLocation,
        in source: String,
        color: UIColor,
        priority: Int,
        to tokens: inout [HighlightToken]
    ) {
        guard let range = sourceRange(for: location, in: source) else {
            return
        }

        tokens.append(
            HighlightToken(
                range: range,
                attributes: [
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .underlineColor: color
                ],
                priority: priority
            )
        )
    }

    func sourceRange(for location: SourceLocation, in source: String) -> Range<String.Index>? {
        sourceRange(for: location.range, in: source)
    }

    func sourceRange(for range: Range<String.Index>, in source: String) -> Range<String.Index>? {
        guard range.lowerBound >= source.startIndex,
              range.upperBound <= source.endIndex,
              range.lowerBound <= range.upperBound else {
            return nil
        }

        return range
    }

    func lastChildEnd(in members: [AST.CustomCharacterClass.Member], defaultingTo fallback: String.Index) -> String.Index {
        members.last?.location.end ?? fallback
    }

    func style(for amount: AST.Quantification.Amount) -> TokenStyle {
        switch amount {
        case .exactly, .nOrMore, .upToN, .range:
            return HighlightStyle.quantifierRange
        case .zeroOrMore, .oneOrMore, .zeroOrOne:
            return HighlightStyle.quantifier
        }
    }

}
