//
//  RegExEditorViewModel.swift
//  RegEx+
//
//  Created by Lex on 2020/4/25.
//  Copyright © 2020 Lex.sh. All rights reserved.
//

import Foundation
import Combine


class EditorViewModel : ObservableObject, Equatable {

    @Published var regEx: RegEx
    
    @Published var matches = [NSTextCheckingResult]()
    @Published var substitutionResult = ""
    
    var matchCancellable: AnyCancellable?
    var substitutionCancellable: AnyCancellable?
    
    init(regEx: RegEx) {
        self.regEx = regEx
        
        let optionsObservable = $regEx
            .map(\.regularExpressionOptions)
        
        let regExObservable = $regEx
            .map(\.raw)
            .throttle(for: 0.2, scheduler: RunLoop.main, latest: true)
            .removeDuplicates()
            .combineLatest(optionsObservable)
            .compactMap { (raw, options) in
                try? NSRegularExpression(pattern: raw, options: options)
            }
        
        let sampleObservable = $regEx
            .map(\.sample)
            .throttle(for: 0.2, scheduler: RunLoop.main, latest: true)
            .removeDuplicates()

        let substitutionObservalbe = $regEx
            .map(\.substitution)
            .throttle(for: 0.2, scheduler: RunLoop.main, latest: true)
            .removeDuplicates()

        let subAndSampleObservable = substitutionObservalbe.combineLatest(sampleObservable)
            .map { ($0.0, $0.1) }

        matchCancellable = regExObservable
            .combineLatest(sampleObservable)
            .sink { [weak self] (reg: NSRegularExpression, sample: String) in
                let range = NSRange(location: 0, length: sample.count)
                self?.matches = reg.matches(in: sample, options: [], range: range)
            }
        
        substitutionCancellable = regExObservable
            .combineLatest(subAndSampleObservable)
            .map { ($0, $1.0, $1.1) }
            .sink { [weak self] (reg: NSRegularExpression, sub: String, sample: String) in
                let range = NSRange(location: 0, length: sample.count)
                self?.substitutionResult = reg.stringByReplacingMatches(
                    in: sample,
                    options: [],
                    range: range,
                    withTemplate: sub
                )
            }
    }
    
    func updateLastModified() {
        if regEx.hasChanges {
            regEx.updatedAt = Date()
        }
    }

    static func == (lhs: EditorViewModel, rhs: EditorViewModel) -> Bool {
        lhs.regEx.isEqual(to: rhs.regEx)
        && lhs.substitutionResult == rhs.substitutionResult
        && lhs.matches == rhs.matches
    }

}
