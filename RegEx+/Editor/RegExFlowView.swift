//
//  RegExFlowView.swift
//  RegEx+
//
//  Created by Lex on 2026/4/11.
//  Copyright © 2020 Lex.sh. All rights reserved.
//
// swiftlint:disable file_length type_body_length cyclomatic_complexity

import SwiftUI
import _RegexParser

struct RegExFlowView: View {
    let pattern: String

    private var diagram: FlowComponent {
        var builder = FlowDiagramBuilder(source: pattern)
        return builder.build()
    }

    private var breakdown: FlowPatternBreakdown {
        FlowPatternBreakdownBuilder(source: pattern).build()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if pattern.isEmpty {
                Text("Enter a regular expression to see the flow diagram")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: true) {
                    HStack {
                        Spacer(minLength: 0)
                        FlowDiagramView(component: diagram)
                            .padding(.vertical, 4)
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity)
                }

                if breakdown.hasItems {
                    PatternBreakdownView(breakdown: breakdown)
                        .padding(.top, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }
}

private struct FlowDiagramBuilder {
    let source: String
    private var captureGroupIndex = 0

    init(source: String) {
        self.source = source
    }

    mutating func build() -> FlowComponent {
        let ast = parseWithRecovery(source, .traditional)
        var components = [FlowComponent]()

        if let globalOptions = ast.globalOptions {
            components.append(contentsOf: globalOptions.options.map { option in
                .node(
                    FlowNode(
                        style: .directive,
                        label: sourceText(for: option.location) ?? "Options"
                    )
                )
            })
        }

        let root = component(from: ast.root)
        switch root {
        case .sequence(let children):
            components.append(contentsOf: children)
        case .empty:
            break
        default:
            components.append(root)
        }

        return normalizedSequence(components)
    }

    private mutating func component(from node: AST.Node) -> FlowComponent {
        switch node {
        case .alternation(let alternation):
            var branches = [[FlowComponent]]()
            for child in alternation.children {
                branches.append(branch(from: child))
            }
            return .alternation(branches)

        case .concatenation(let concatenation):
            var children = [FlowComponent]()
            for child in concatenation.children {
                if let component = semanticComponent(from: child) {
                    children.append(component)
                }
            }
            return normalizedSequence(children)

        case .group(let group):
            let groupKind = group.kind.value
            return .group(
                FlowGroup(
                    style: style(for: groupKind),
                    title: title(for: groupKind, captureReference: nextCaptureReference(for: groupKind)),
                    content: component(from: group.child)
                )
            )

        case .conditional(let conditional):
            return .group(
                FlowGroup(
                    style: .assertion,
                    title: "Conditional \(conditionLabel(for: conditional.condition))",
                    content: .alternation([
                        branch(from: conditional.trueBranch),
                        branch(from: conditional.falseBranch)
                    ])
                )
            )

        case .quantification(let quantification):
            return .quantified(
                component(from: quantification.child),
                quantifier(for: quantification)
            )

        case .quote(let quote):
            return .node(
                FlowNode(
                    style: .literal,
                    label: sourceText(for: quote.location) ?? quote.literal
                )
            )

        case .trivia:
            return .empty

        case .interpolation(let interpolation):
            return .node(
                FlowNode(
                    style: .directive,
                    label: sourceText(for: interpolation.location) ?? interpolation.contents
                )
            )

        case .atom(let atom):
            return .node(flowNode(for: atom))

        case .customCharacterClass(let characterClass):
            return .node(
                FlowNode(
                    style: .characterClass,
                    label: sourceText(for: characterClass.location) ?? "[...]"
                )
            )

        case .absentFunction(let absentFunction):
            return .node(
                FlowNode(
                    style: .special,
                    label: sourceText(for: absentFunction.location) ?? "(?~...)"
                )
            )

        case .empty:
            return .empty
        }
    }

    private mutating func semanticComponent(from node: AST.Node) -> FlowComponent? {
        let component = component(from: node)
        if case .empty = component {
            return nil
        }
        return component
    }

    private mutating func branch(from node: AST.Node) -> [FlowComponent] {
        let resolved = component(from: node)
        switch resolved {
        case .sequence(let children):
            return children.isEmpty ? [.empty] : children
        case .empty:
            return [.empty]
        default:
            return [resolved]
        }
    }

    private func normalizedSequence(_ components: [FlowComponent]) -> FlowComponent {
        let flattened = components.flatMap { component -> [FlowComponent] in
            switch component {
            case .sequence(let children):
                return children
            case .empty:
                return []
            default:
                return [component]
            }
        }
        let compacted = mergeContinuousLiteralNodes(in: flattened)

        switch compacted.count {
        case 0:
            return .empty
        case 1:
            return compacted[0]
        default:
            return .sequence(compacted)
        }
    }

    private func mergeContinuousLiteralNodes(in components: [FlowComponent]) -> [FlowComponent] {
        var merged = [FlowComponent]()

        for component in components {
            guard case .node(let node) = component, node.style == .literal else {
                merged.append(component)
                continue
            }

            if let last = merged.last, case .node(let previous) = last, previous.style == .literal {
                merged.removeLast()
                merged.append(
                    .node(
                        FlowNode(
                            style: .literal,
                            label: previous.label + node.label
                        )
                    )
                )
            } else {
                merged.append(component)
            }
        }

        return merged
    }

    private func quantifier(for quantification: AST.Quantification) -> FlowQuantifier {
        let label: String
        if let sourceLabel = sourceText(
            from: quantification.amount.location.start,
            to: quantification.location.end
        ) {
            label = sourceLabel
        } else {
            let amount: String
            switch quantification.amount.value {
            case .zeroOrMore:
                amount = "*"
            case .oneOrMore:
                amount = "+"
            case .zeroOrOne:
                amount = "?"
            case .exactly(let number):
                amount = "{\(number.value ?? 0)}"
            case .nOrMore(let number):
                amount = "{\(number.value ?? 0),}"
            case .upToN(let number):
                amount = "{,\(number.value ?? 0)}"
            case .range(let lower, let upper):
                amount = "{\(lower.value ?? 0),\(upper.value ?? 0)}"
            }

            label = amount + quantification.kind.value.rawValue
        }

        return FlowQuantifier(
            label: label,
            isOptional: isOptional(quantification.amount.value)
        )
    }

    private func isOptional(_ amount: AST.Quantification.Amount) -> Bool {
        switch amount {
        case .zeroOrMore, .zeroOrOne, .upToN:
            return true
        case .range(let lower, _):
            return (lower.value ?? 0) == 0
        case .exactly, .nOrMore, .oneOrMore:
            return false
        }
    }

    private func flowNode(for atom: AST.Atom) -> FlowNode {
        let label = sourceText(for: atom.location) ?? fallbackLabel(for: atom)

        switch atom.kind {
        case .dot:
            return FlowNode(style: .wildcard, label: "Any char")

        case .caretAnchor:
            return FlowNode(style: .anchor, label: "^ Start")

        case .dollarAnchor:
            return FlowNode(style: .anchor, label: "$ End")

        case .property, .escaped:
            return FlowNode(style: escapedStyle(for: atom), label: label)

        case .backreference, .subpattern:
            return FlowNode(style: .special, label: label)

        case .callout, .backtrackingDirective, .changeMatchingOptions:
            return FlowNode(style: .directive, label: label)

        case .invalid:
            return FlowNode(style: .invalid, label: label)

        case .char, .scalar, .scalarSequence, .keyboardControl,
             .keyboardMeta, .keyboardMetaControl, .namedCharacter:
            return FlowNode(style: .literal, label: label)
        }
    }

    private func escapedStyle(for atom: AST.Atom) -> FlowNode.Style {
        guard case .escaped(let builtin) = atom.kind else {
            return .characterClass
        }

        switch builtin {
        case .wordBoundary, .notWordBoundary:
            return .assertion
        case .startOfSubject, .endOfSubjectBeforeNewline,
             .endOfSubject, .firstMatchingPositionInSubject:
            return .anchor
        case .alarm, .escape, .formfeed, .newline,
             .carriageReturn, .tab, .backspace:
            return .literal
        default:
            return .characterClass
        }
    }

    private func fallbackLabel(for atom: AST.Atom) -> String {
        switch atom.kind {
        case .char(let character):
            return String(character)
        case .scalar(let scalar):
            return String(scalar.value)
        case .scalarSequence(let sequence):
            return sequence.scalarValues.map(String.init).joined()
        case .property:
            return "Property"
        case .escaped(let builtin):
            return "\\\(builtin.character)"
        case .keyboardControl(let character):
            return "\\C-\(character)"
        case .keyboardMeta(let character):
            return "\\M-\(character)"
        case .keyboardMetaControl(let character):
            return "\\M-\\C-\(character)"
        case .namedCharacter(let name):
            return "\\N{\(name)}"
        case .dot:
            return "."
        case .caretAnchor:
            return "^"
        case .dollarAnchor:
            return "$"
        case .backreference:
            return "Backreference"
        case .subpattern:
            return "Subpattern"
        case .callout:
            return "Callout"
        case .backtrackingDirective:
            return "Directive"
        case .changeMatchingOptions:
            return "Options"
        case .invalid:
            return "Invalid"
        }
    }

    private func style(for kind: AST.Group.Kind) -> FlowNode.Style {
        switch kind {
        case .capture, .namedCapture, .balancedCapture:
            return .capturingGroup
        case .lookahead, .negativeLookahead, .nonAtomicLookahead,
             .lookbehind, .negativeLookbehind, .nonAtomicLookbehind:
            return .assertion
        case .changeMatchingOptions:
            return .directive
        case .scriptRun, .atomicScriptRun:
            return .special
        case .nonCapture, .nonCaptureReset, .atomicNonCapturing:
            return .grouping
        }
    }

    private func title(for kind: AST.Group.Kind, captureReference: String?) -> String {
        let suffix = captureReference.map { " \($0)" } ?? ""

        switch kind {
        case .capture:
            return "Group\(suffix)"
        case .namedCapture(let name):
            return "Group <\(name.value)>\(suffix)"
        case .balancedCapture(let balanced):
            let current = balanced.name?.value ?? ""
            return "Group <\(current)-\(balanced.priorName.value)>\(suffix)"
        case .nonCapture:
            return "Group"
        case .nonCaptureReset:
            return "Branch Reset Group"
        case .atomicNonCapturing:
            return "Atomic Group"
        case .lookahead:
            return "Lookahead"
        case .negativeLookahead:
            return "Negative Lookahead"
        case .nonAtomicLookahead:
            return "Non-atomic Lookahead"
        case .lookbehind:
            return "Lookbehind"
        case .negativeLookbehind:
            return "Negative Lookbehind"
        case .nonAtomicLookbehind:
            return "Non-atomic Lookbehind"
        case .scriptRun:
            return "Script Run"
        case .atomicScriptRun:
            return "Atomic Script Run"
        case .changeMatchingOptions:
            return "Scoped Options"
        }
    }

    private mutating func nextCaptureReference(for kind: AST.Group.Kind) -> String? {
        switch kind {
        case .capture, .namedCapture, .balancedCapture:
            captureGroupIndex += 1
            return "$\(captureGroupIndex)"
        default:
            return nil
        }
    }

    private func conditionLabel(for condition: AST.Conditional.Condition) -> String {
        switch condition.kind {
        case .groupMatched:
            return "if group matched"
        case .recursionCheck:
            return "if recursion"
        case .groupRecursionCheck:
            return "if group recursion"
        case .defineGroup:
            return "define group"
        case .pcreVersionCheck:
            return "if PCRE version"
        case .group:
            return "if nested pattern"
        }
    }

    private func sourceText(for location: SourceLocation) -> String? {
        sourceText(from: location.start, to: location.end)
    }

    private func sourceText(from start: String.Index, to end: String.Index) -> String? {
        guard start >= source.startIndex,
              end <= source.endIndex,
              start <= end else {
            return nil
        }

        return String(source[start..<end])
    }
}

private struct FlowPatternBreakdownBuilder {
    let source: String

    func build() -> FlowPatternBreakdown {
        let ast = parseWithRecovery(source, .traditional)
        let catalog = CheatSheetCatalog.shared
        var collector = FlowPatternBreakdownCollector(source: source, catalog: catalog)

        if let globalOptions = ast.globalOptions {
            globalOptions.options.forEach { option in
                collector.collectGlobalOption(option)
            }
        }

        collector.collect(from: ast.root)
        return collector.result
    }
}

private struct FlowPatternBreakdown {
    let metacharacters: [FlowCheatSheetMatch]
    let operators: [FlowCheatSheetMatch]

    var hasItems: Bool {
        !metacharacters.isEmpty || !operators.isEmpty
    }
}

private struct FlowCheatSheetMatch: Hashable {
    let id: String
    let title: String
    let description: String
}

private enum FlowCheatSheetKey: String {
    case alarm
    case startOfInput
    case wordBoundary
    case backspaceInSet
    case notWordBoundary
    case controlCharacter
    case decimalDigit
    case notDecimalDigit
    case escapeCharacter
    case quoteEnd
    case formFeed
    case previousMatchEnd
    case newline
    case namedCharacter
    case unicodeProperty
    case unicodePropertyInverted
    case quoteStart
    case carriageReturn
    case whitespace
    case notWhitespace
    case tab
    case unicodeScalar4
    case unicodeScalar8
    case wordCharacter
    case notWordCharacter
    case hexScalarBraced
    case hexScalar2
    case graphemeCluster
    case endOfInputBeforeNewline
    case endOfInput
    case backreference
    case octalScalar
    case customCharacterClass
    case wildcard
    case lineStart
    case lineEnd
    case escapedLiteral
    case alternation
    case zeroOrMore
    case oneOrMore
    case zeroOrOne
    case exactlyN
    case nOrMore
    case range
    case zeroOrMoreReluctant
    case oneOrMoreReluctant
    case zeroOrOneReluctant
    case exactlyNReluctant
    case nOrMoreReluctant
    case rangeReluctant
    case zeroOrMorePossessive
    case oneOrMorePossessive
    case zeroOrOnePossessive
    case exactlyNPossessive
    case nOrMorePossessive
    case rangePossessive
    case capturingGroup
    case nonCapturingGroup
    case atomicGroup
    case commentGroup
    case lookahead
    case negativeLookahead
    case lookbehind
    case negativeLookbehind
    case scopedOptionChange
    case inlineOptionChange
}

private struct CheatSheetCatalog {
    static let shared = CheatSheetCatalog.load()

    let metacharacters: [FlowCheatSheetKey: CheatSheetPlist.Item]
    let operators: [FlowCheatSheetKey: CheatSheetPlist.Item]

    func metacharacter(for key: FlowCheatSheetKey) -> CheatSheetPlist.Item? {
        metacharacters[key]
    }

    func operatorItem(for key: FlowCheatSheetKey) -> CheatSheetPlist.Item? {
        operators[key]
    }

    private static func load() -> CheatSheetCatalog {
        let plist = CheatSheetPlist.localizedCheatSheet ?? CheatSheetPlist(metacharacters: [], operators: [])

        let metacharacters = Dictionary(
            uniqueKeysWithValues: plist.metacharacters.compactMap { item -> (FlowCheatSheetKey, CheatSheetPlist.Item)? in
                guard let key = metacharacterKey(for: item.exp, description: item.des) else {
                    return nil
                }
                return (key, item)
            }
        )

        let operators = Dictionary(
            uniqueKeysWithValues: plist.operators.compactMap { item -> (FlowCheatSheetKey, CheatSheetPlist.Item)? in
                guard let key = operatorKey(for: item.exp) else {
                    return nil
                }
                return (key, item)
            }
        )

        return CheatSheetCatalog(metacharacters: metacharacters, operators: operators)
    }

    private static func metacharacterKey(for expression: String, description: String) -> FlowCheatSheetKey? {
        switch expression {
        case "\\a": return .alarm
        case "\\A": return .startOfInput
        case "\\b, outside of a [Set]": return .wordBoundary
        case "\\b, within a [Set]": return .backspaceInSet
        case "\\B": return .notWordBoundary
        case "\\cX": return .controlCharacter
        case "\\d": return .decimalDigit
        case "\\D": return .notDecimalDigit
        case "\\e": return .escapeCharacter
        case "\\E": return .quoteEnd
        case "\\f": return .formFeed
        case "\\G": return .previousMatchEnd
        case "\\n":
            return description.contains("Back Reference") ? .backreference : .newline
        case "\\N{UNICODE CHARACTER NAME}": return .namedCharacter
        case "\\p{UNICODE PROPERTY NAME}": return .unicodeProperty
        case "\\P{UNICODE PROPERTY NAME}": return .unicodePropertyInverted
        case "\\Q": return .quoteStart
        case "\\r": return .carriageReturn
        case "\\s": return .whitespace
        case "\\S": return .notWhitespace
        case "\\t": return .tab
        case "\\uhhhh": return .unicodeScalar4
        case "\\Uhhhhhhhh": return .unicodeScalar8
        case "\\w": return .wordCharacter
        case "\\W": return .notWordCharacter
        case "\\x{hhhh}": return .hexScalarBraced
        case "\\xhh": return .hexScalar2
        case "\\X": return .graphemeCluster
        case "\\Z": return .endOfInputBeforeNewline
        case "\\z": return .endOfInput
        case "\\0ooo": return .octalScalar
        case "[pattern]": return .customCharacterClass
        case ".": return .wildcard
        case "^": return .lineStart
        case "$": return .lineEnd
        case "\\": return .escapedLiteral
        default: return nil
        }
    }

    private static func operatorKey(for expression: String) -> FlowCheatSheetKey? {
        switch expression {
        case "|": return .alternation
        case "*": return .zeroOrMore
        case "+": return .oneOrMore
        case "?": return .zeroOrOne
        case "{n}": return .exactlyN
        case "{n,}": return .nOrMore
        case "{n,m}": return .range
        case "*?": return .zeroOrMoreReluctant
        case "+?": return .oneOrMoreReluctant
        case "??": return .zeroOrOneReluctant
        case "{n}?": return .exactlyNReluctant
        case "{n,}?": return .nOrMoreReluctant
        case "{n,m}?": return .rangeReluctant
        case "*+": return .zeroOrMorePossessive
        case "++": return .oneOrMorePossessive
        case "?+": return .zeroOrOnePossessive
        case "{n}+": return .exactlyNPossessive
        case "{n,}+": return .nOrMorePossessive
        case "{n,m}+": return .rangePossessive
        case "(...)": return .capturingGroup
        case "(?:...)": return .nonCapturingGroup
        case "(?>...)": return .atomicGroup
        case "(?# ... )": return .commentGroup
        case "(?= ... )": return .lookahead
        case "(?! ... )": return .negativeLookahead
        case "(?<= ... )": return .lookbehind
        case "(?<! ... )": return .negativeLookbehind
        case "(?ismwx-ismwx: ... )": return .scopedOptionChange
        case "(?ismwx-ismwx)": return .inlineOptionChange
        default: return nil
        }
    }
}

private struct FlowPatternBreakdownCollector {
    let source: String
    let catalog: CheatSheetCatalog

    private(set) var metacharacters = [FlowCheatSheetMatch]()
    private(set) var operators = [FlowCheatSheetMatch]()
    private var seenMetacharacters = Set<String>()
    private var seenOperators = Set<String>()

    init(source: String, catalog: CheatSheetCatalog) {
        self.source = source
        self.catalog = catalog
    }

    var result: FlowPatternBreakdown {
        FlowPatternBreakdown(metacharacters: metacharacters, operators: operators)
    }

    mutating func collect(from node: AST.Node) {
        switch node {
        case .alternation(let alternation):
            addOperator(.alternation)
            alternation.children.forEach { collect(from: $0) }

        case .concatenation(let concatenation):
            concatenation.children.forEach { collect(from: $0) }

        case .group(let group):
            collect(group)

        case .conditional(let conditional):
            collect(condition: conditional.condition)
            collect(from: conditional.trueBranch)
            collect(from: conditional.falseBranch)

        case .quantification(let quantification):
            addOperator(quantifierSignature(for: quantification))
            collect(from: quantification.child)

        case .quote:
            addMetacharacter(.quoteStart)
            addMetacharacter(.quoteEnd)

        case .trivia(let trivia):
            if sourceText(for: trivia.location)?.hasPrefix("(?#") == true {
                addOperator(.commentGroup)
            }

        case .interpolation:
            break

        case .atom(let atom):
            collect(atom)

        case .customCharacterClass(let characterClass):
            addMetacharacter(.customCharacterClass)
            characterClass.members.forEach { collect(characterClassMember: $0) }

        case .absentFunction, .empty:
            break
        }
    }

    mutating func collectGlobalOption(_ option: AST.GlobalMatchingOption) {
        addOperator(.inlineOptionChange, display: sourceText(for: option.location))
    }

    private mutating func collect(_ group: AST.Group) {
        switch group.kind.value {
        case .capture, .namedCapture, .balancedCapture:
            addOperator(.capturingGroup)
        case .nonCapture, .nonCaptureReset:
            addOperator(.nonCapturingGroup)
        case .atomicNonCapturing:
            addOperator(.atomicGroup)
        case .lookahead, .nonAtomicLookahead:
            addOperator(.lookahead)
        case .negativeLookahead:
            addOperator(.negativeLookahead)
        case .lookbehind, .nonAtomicLookbehind:
            addOperator(.lookbehind)
        case .negativeLookbehind:
            addOperator(.negativeLookbehind)
        case .changeMatchingOptions:
            addOperator(.scopedOptionChange, display: sourceText(for: group.location))
        case .scriptRun, .atomicScriptRun:
            break
        }

        collect(from: group.child)
    }

    private mutating func collect(condition: AST.Conditional.Condition) {
        if case .group(let group) = condition.kind {
            collect(group)
        }
    }

    private mutating func collect(_ atom: AST.Atom) {
        let text = sourceText(for: atom.location)

        switch atom.kind {
        case .char:
            if text?.hasPrefix("\\") == true {
                addMetacharacter(.escapedLiteral, display: text)
            }
        case .scalar:
            if let text {
                if text.hasPrefix("\\u") {
                    addMetacharacter(.unicodeScalar4, display: text)
                } else if text.hasPrefix("\\U") {
                    addMetacharacter(.unicodeScalar8, display: text)
                } else if text.hasPrefix("\\x{") {
                    addMetacharacter(.hexScalarBraced, display: text)
                } else if text.hasPrefix("\\x") {
                    addMetacharacter(.hexScalar2, display: text)
                } else if text.hasPrefix("\\0") {
                    addMetacharacter(.octalScalar, display: text)
                }
            }
        case .scalarSequence:
            addMetacharacter(.hexScalarBraced, display: text)
        case .property(let property):
            addMetacharacter(property.isInverted ? .unicodePropertyInverted : .unicodeProperty, display: text)
        case .escaped(let builtin):
            collectEscapedBuiltin(builtin, display: text)
        case .keyboardControl:
            addMetacharacter(.controlCharacter, display: text)
        case .keyboardMeta, .keyboardMetaControl:
            break
        case .namedCharacter:
            addMetacharacter(.namedCharacter, display: text)
        case .dot:
            addMetacharacter(.wildcard, display: text)
        case .caretAnchor:
            addMetacharacter(.lineStart, display: text)
        case .dollarAnchor:
            addMetacharacter(.lineEnd, display: text)
        case .backreference:
            addMetacharacter(.backreference, display: text)
        case .subpattern:
            break
        case .callout, .backtrackingDirective:
            break
        case .changeMatchingOptions:
            addOperator(.inlineOptionChange, display: text)
        case .invalid:
            break
        }
    }

    private mutating func collectEscapedBuiltin(_ builtin: AST.Atom.EscapedBuiltin, display: String?) {
        switch builtin {
        case .alarm: addMetacharacter(.alarm, display: display)
        case .escape: addMetacharacter(.escapeCharacter, display: display)
        case .formfeed: addMetacharacter(.formFeed, display: display)
        case .newline: addMetacharacter(.newline, display: display)
        case .carriageReturn: addMetacharacter(.carriageReturn, display: display)
        case .tab: addMetacharacter(.tab, display: display)
        case .decimalDigit: addMetacharacter(.decimalDigit, display: display)
        case .notDecimalDigit: addMetacharacter(.notDecimalDigit, display: display)
        case .whitespace: addMetacharacter(.whitespace, display: display)
        case .notWhitespace: addMetacharacter(.notWhitespace, display: display)
        case .wordCharacter: addMetacharacter(.wordCharacter, display: display)
        case .notWordCharacter: addMetacharacter(.notWordCharacter, display: display)
        case .graphemeCluster: addMetacharacter(.graphemeCluster, display: display)
        case .wordBoundary: addMetacharacter(.wordBoundary, display: display)
        case .notWordBoundary: addMetacharacter(.notWordBoundary, display: display)
        case .startOfSubject: addMetacharacter(.startOfInput, display: display)
        case .endOfSubjectBeforeNewline: addMetacharacter(.endOfInputBeforeNewline, display: display)
        case .endOfSubject: addMetacharacter(.endOfInput, display: display)
        case .firstMatchingPositionInSubject: addMetacharacter(.previousMatchEnd, display: display)
        case .backspace: addMetacharacter(.backspaceInSet, display: display)
        case .singleDataUnit, .horizontalWhitespace, .notHorizontalWhitespace,
             .notNewline, .newlineSequence, .verticalTab, .notVerticalTab,
             .resetStartOfMatch, .trueAnychar, .textSegment, .notTextSegment:
            break
        }
    }

    private mutating func collect(characterClassMember member: AST.CustomCharacterClass.Member) {
        switch member {
        case .custom(let characterClass):
            addMetacharacter(.customCharacterClass)
            characterClass.members.forEach { collect(characterClassMember: $0) }
        case .range(let range):
            collect(range.lhs)
            collect(range.rhs)
        case .atom(let atom):
            collect(atom)
        case .quote:
            addMetacharacter(.quoteStart)
            addMetacharacter(.quoteEnd)
        case .trivia:
            break
        case .setOperation(let lhs, _, let rhs):
            lhs.forEach { collect(characterClassMember: $0) }
            rhs.forEach { collect(characterClassMember: $0) }
        }
    }

    private func quantifierSignature(for quantification: AST.Quantification) -> FlowCheatSheetKey {
        switch (quantification.amount.value, quantification.kind.value) {
        case (.zeroOrMore, .eager): return .zeroOrMore
        case (.oneOrMore, .eager): return .oneOrMore
        case (.zeroOrOne, .eager): return .zeroOrOne
        case (.exactly, .eager): return .exactlyN
        case (.nOrMore, .eager): return .nOrMore
        case (.range, .eager), (.upToN, .eager): return .range
        case (.zeroOrMore, .reluctant): return .zeroOrMoreReluctant
        case (.oneOrMore, .reluctant): return .oneOrMoreReluctant
        case (.zeroOrOne, .reluctant): return .zeroOrOneReluctant
        case (.exactly, .reluctant): return .exactlyNReluctant
        case (.nOrMore, .reluctant): return .nOrMoreReluctant
        case (.range, .reluctant), (.upToN, .reluctant): return .rangeReluctant
        case (.zeroOrMore, .possessive): return .zeroOrMorePossessive
        case (.oneOrMore, .possessive): return .oneOrMorePossessive
        case (.zeroOrOne, .possessive): return .zeroOrOnePossessive
        case (.exactly, .possessive): return .exactlyNPossessive
        case (.nOrMore, .possessive): return .nOrMorePossessive
        case (.range, .possessive), (.upToN, .possessive): return .rangePossessive
        }
    }

    private mutating func addMetacharacter(_ key: FlowCheatSheetKey, display: String? = nil) {
        guard let item = catalog.metacharacter(for: key),
              seenMetacharacters.insert(key.rawValue).inserted else {
            return
        }

        metacharacters.append(
            FlowCheatSheetMatch(
                id: key.rawValue,
                title: display ?? item.exp,
                description: item.des
            )
        )
    }

    private mutating func addOperator(_ key: FlowCheatSheetKey, display: String? = nil) {
        guard let item = catalog.operatorItem(for: key),
              seenOperators.insert(key.rawValue).inserted else {
            return
        }

        operators.append(
            FlowCheatSheetMatch(
                id: key.rawValue,
                title: display ?? item.exp,
                description: item.des
            )
        )
    }

    private func sourceText(for location: SourceLocation) -> String? {
        guard location.start >= source.startIndex,
              location.end <= source.endIndex,
              location.start <= location.end else {
            return nil
        }

        return String(source[location.start..<location.end])
    }
}

private indirect enum FlowComponent {
    case node(FlowNode)
    case group(FlowGroup)
    case sequence([FlowComponent])
    case alternation([[FlowComponent]])
    case quantified(FlowComponent, FlowQuantifier)
    case empty
}

private struct FlowQuantifier {
    let label: String
    let isOptional: Bool
}

private struct FlowNode {
    enum Style: Equatable {
        case literal
        case characterClass
        case capturingGroup
        case grouping
        case assertion
        case anchor
        case wildcard
        case directive
        case special
        case invalid
    }

    let style: Style
    let label: String
}

private struct FlowGroup {
    let style: FlowNode.Style
    let title: String
    let content: FlowComponent
}

private struct FlowDiagramView: View {
    let component: FlowComponent

    var body: some View {
        FlowComponentView(component: component)
            .fixedSize(horizontal: true, vertical: true)
    }
}

private struct FlowComponentView: View {
    let component: FlowComponent
    var borderStyle: FlowBorderStyle = .solid

    var body: some View {
        switch component {
        case .node(let node):
            NodeView(node: node, borderStyle: borderStyle)

        case .group(let group):
            GroupView(group: group, borderStyle: borderStyle)

        case .sequence(let components):
            FlowSequenceView(components: components)

        case .alternation(let branches):
            AlternationView(branches: branches)

        case .quantified(let child, let quantifier):
            QuantifiedFlowView(
                component: child,
                quantifier: quantifier,
                borderStyle: child.supportsBorderStyling && quantifier.isOptional ? .dashed : .solid
            )

        case .empty:
            NodeView(node: FlowNode(style: .special, label: "Empty"), borderStyle: borderStyle)
        }
    }
}

private struct PatternBreakdownView: View {
    let breakdown: FlowPatternBreakdown

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !breakdown.metacharacters.isEmpty {
                PatternBreakdownSectionView(
                    title: "Metacharacters",
                    items: breakdown.metacharacters
                )
            }

            if !breakdown.operators.isEmpty {
                PatternBreakdownSectionView(
                    title: "Operators",
                    items: breakdown.operators
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PatternBreakdownSectionView: View {
    let title: LocalizedStringKey
    let items: [FlowCheatSheetMatch]

    var body: some View {
        let tokenColumnWidth: CGFloat = 112
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(FlowPalette.sectionLabel)
                .textCase(.uppercase)
                .tracking(1.2)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    HStack(alignment: .center, spacing: 14) {
                        Text(verbatim: item.title)
                            .font(.callout.monospaced().weight(.semibold))
                            .foregroundStyle(FlowPalette.ink)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                            .multilineTextAlignment(.center)
                            .frame(width: tokenColumnWidth)
                            .frame(minHeight: 42)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(FlowPalette.tokenBoxFill)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(FlowPalette.tokenBoxBorder, lineWidth: 1)
                                    )
                            )

                        Text(verbatim: item.description)
                            .font(.subheadline)
                            .foregroundStyle(FlowPalette.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 10)

                    if index < items.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }
}

private struct FlowSequenceView: View {
    let components: [FlowComponent]

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            ForEach(Array(components.enumerated()), id: \.offset) { index, component in
                if index > 0 {
                    Spacer(minLength: 6)
                    Image(systemName: "arrow.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(FlowPalette.connector)
                        .frame(width: 14)
                    Spacer(minLength: 6)
                }

                FlowComponentView(component: component)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

private struct AlternationView: View {
    let branches: [[FlowComponent]]

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            ForEach(Array(branches.enumerated()), id: \.offset) { index, branch in
                if index > 0 {
                    FlowAlternationDivider()
                }

                FlowSequenceView(components: branch)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 2)
    }
}

private struct GroupView: View {
    let group: FlowGroup
    let borderStyle: FlowBorderStyle

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(group.title.uppercased())
                .font(.caption.weight(.bold))
                .tracking(1.6)
                .foregroundStyle(titleColor)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)

            VStack(alignment: .center, spacing: 8) {
                FlowComponentView(component: group.content)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(borderColor, style: borderStyle.strokeStyle(lineWidth: 1.5))
        )
    }

    private var borderColor: Color {
        styleColor(for: group.style).opacity(0.28)
    }

    private var titleColor: Color {
        styleColor(for: group.style)
    }
}

private struct QuantifiedFlowView: View {
    let component: FlowComponent
    let quantifier: FlowQuantifier
    let borderStyle: FlowBorderStyle

    var body: some View {
        VStack(spacing: 2) {
            FlowComponentView(component: component, borderStyle: borderStyle)

            Text(quantifier.label)
                .font(.caption2.monospaced())
                .foregroundStyle(quantifierColor)
        }
    }

    private var quantifierColor: Color {
        if quantifier.label.contains("?") {
            return FlowPalette.quantifierSecondary
        }
        return FlowPalette.quantifierPrimary
    }
}

private struct NodeView: View {
    let node: FlowNode
    let borderStyle: FlowBorderStyle

    var body: some View {
        Text(node.label)
            .font(.system(size: 13, weight: .semibold, design: .monospaced))
            .lineLimit(1)
            .foregroundStyle(labelColor)
            .frame(minWidth: 40, minHeight: 40)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(fillColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(borderColor, style: borderStyle.strokeStyle(lineWidth: 1))
                    )
            )
            .fixedSize()
    }

    private var fillColor: Color {
        if isEndpoint {
            return FlowPalette.endpointFill
        }
        return FlowPalette.nodeFill
    }

    private var borderColor: Color {
        if isEndpoint {
            return FlowPalette.endpointBorder
        }
        return color.opacity(0.28)
    }

    private var labelColor: Color {
        FlowPalette.ink
    }

    private var isEndpoint: Bool {
        node.style == .anchor && (node.label.contains("Start") || node.label.contains("End"))
    }

    private var color: Color {
        styleColor(for: node.style)
    }
}

private enum FlowBorderStyle {
    case solid
    case dashed

    func strokeStyle(lineWidth: CGFloat) -> StrokeStyle {
        switch self {
        case .solid:
            return StrokeStyle(lineWidth: lineWidth)
        case .dashed:
            return StrokeStyle(lineWidth: lineWidth, dash: [6, 4])
        }
    }
}

private extension FlowComponent {
    var supportsBorderStyling: Bool {
        switch self {
        case .node, .group:
            return true
        case .sequence, .alternation, .quantified, .empty:
            return false
        }
    }
}

private struct FlowAlternationDivider: View {
    var body: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(FlowPalette.divider)
                .frame(height: 1)

            Text("OR")
                .font(.caption.weight(.bold))
                .tracking(1.4)
                .foregroundStyle(FlowPalette.secondaryText)

            Rectangle()
                .fill(FlowPalette.divider)
                .frame(height: 1)
        }
        .padding(.horizontal, 6)
    }
}

private func styleColor(for style: FlowNode.Style) -> Color {
    switch style {
    case .literal:
        return FlowPalette.literal
    case .characterClass:
        return FlowPalette.characterClass
    case .capturingGroup:
        return FlowPalette.group
    case .grouping:
        return FlowPalette.grouping
    case .assertion:
        return FlowPalette.assertion
    case .anchor:
        return FlowPalette.anchor
    case .wildcard:
        return FlowPalette.wildcard
    case .directive:
        return FlowPalette.directive
    case .special:
        return FlowPalette.special
    case .invalid:
        return FlowPalette.invalid
    }
}

private enum FlowPalette {
    static let nodeFill = Color(uiColor: .secondarySystemBackground)
    static let endpointFill = Color.accentColor.opacity(0.18)
    static let endpointBorder = Color.accentColor.opacity(0.45)
    static let connector = Color.secondary.opacity(0.45)
    static let divider = Color.secondary.opacity(0.22)
    static let ink = Color.primary
    static let secondaryText = Color.secondary
    static let sectionLabel = Color.accentColor
    static let tokenBoxFill = Color(uiColor: .secondarySystemBackground)
    static let tokenBoxBorder = Color.accentColor.opacity(0.20)
    static let quantifierPrimary = Color(red: 0.267, green: 0.553, blue: 0.942)
    static let quantifierSecondary = Color(red: 0.000, green: 0.620, blue: 0.592)

    static let literal = Color(red: 0.430, green: 0.620, blue: 0.920)
    static let characterClass = Color(red: 0.336, green: 0.700, blue: 0.650)
    static let group = Color(red: 0.290, green: 0.560, blue: 0.900)
    static let grouping = Color(red: 0.500, green: 0.620, blue: 0.860)
    static let assertion = Color(red: 0.396, green: 0.690, blue: 0.880)
    static let anchor = Color(red: 0.420, green: 0.560, blue: 0.840)
    static let wildcard = Color(red: 0.290, green: 0.700, blue: 0.820)
    static let directive = Color(red: 0.510, green: 0.620, blue: 0.920)
    static let special = Color(red: 0.470, green: 0.650, blue: 0.850)
    static let invalid = Color(red: 0.650, green: 0.690, blue: 0.760)
}

private extension CheatSheetPlist {
    static let localizedCheatSheet: CheatSheetPlist? = {
        guard let url = Bundle.main.url(forResource: "CheatSheet", withExtension: "plist"),
              let data = try? Data(contentsOf: url) else {
            return nil
        }

        return try? PropertyListDecoder().decode(CheatSheetPlist.self, from: data)
    }()
}
// swiftlint:enable file_length type_body_length cyclomatic_complexity
