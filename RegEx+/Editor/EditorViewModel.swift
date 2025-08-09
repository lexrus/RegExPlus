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

    @Published var regEx: RegEx?
    
    @Published var matches = [NSTextCheckingResult]()
    @Published var substitutionResult = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.regEx = nil
        setupBindings()
    }
    
    func configure(with regEx: RegEx) {
        self.regEx = regEx
    }
    
    private func setupBindings() {
        let optionsObservable = $regEx
            .compactMap { $0 }
            .map(\.regularExpressionOptions)
        
        let regExObservable = $regEx
            .compactMap { $0 }
            .map(\.raw)
            .throttle(for: 0.2, scheduler: RunLoop.main, latest: true)
            .removeDuplicates()
            .combineLatest(optionsObservable)
            .compactMap { (raw, options) in
                try? NSRegularExpression(pattern: raw, options: options)
            }
        
        let sampleObservable = $regEx
            .compactMap { $0 }
            .map(\.sample)
            .throttle(for: 0.2, scheduler: RunLoop.main, latest: true)
            .removeDuplicates()

        let substitutionObservalbe = $regEx
            .compactMap { $0 }
            .map(\.substitution)
            .throttle(for: 0.2, scheduler: RunLoop.main, latest: true)
            .removeDuplicates()

        let subAndSampleObservable = substitutionObservalbe.combineLatest(sampleObservable)
            .map { ($0.0, $0.1) }

        regExObservable
            .combineLatest(sampleObservable)
            .sink { [weak self] (reg: NSRegularExpression, sample: String) in
                let range = NSRange(location: 0, length: sample.count)
                self?.matches = reg.matches(in: sample, options: [], range: range)
            }
            .store(in: &cancellables)
        
        regExObservable
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
            .store(in: &cancellables)
    }
    
    // Keep the old initializer for compatibility
    convenience init(regEx: RegEx) {
        self.init()
        self.regEx = regEx
    }
    
    func updateLastModified() {
        if let regEx, regEx.hasChanges {
            regEx.updatedAt = Date()
        }
    }

    static func == (lhs: EditorViewModel, rhs: EditorViewModel) -> Bool {
        if let lr = lhs.regEx, let rr = rhs.regEx {
            return lr.isEqual(to: rr) == true
            && lhs.substitutionResult == rhs.substitutionResult
            && lhs.matches == rhs.matches
        }
        return false
    }

}
