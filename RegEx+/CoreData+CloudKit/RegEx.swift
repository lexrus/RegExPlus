//
//  RegEx+CoreDataClass.swift
//  RegEx+
//
//  Created by Lex on 2020/5/3.
//  Copyright © 2020 Lex.sh. All rights reserved.
//
//

import Foundation
import CoreData

@objc(RegEx)
public class RegEx: NSManagedObject {

    @NSManaged public var name: String
    @NSManaged public var raw: String
    @NSManaged public var sample: String
    @NSManaged public var substitution: String
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    
    @NSManaged public var allowCommentsAndWhitespace: Bool
    @NSManaged public var anchorsMatchLines: Bool
    @NSManaged public var caseInsensitive: Bool
    @NSManaged public var dotMatchesLineSeparators: Bool
    @NSManaged public var ignoreMetacharacters: Bool
    @NSManaged public var useUnicodeWordBoundaries: Bool
    @NSManaged public var useUnixLineSeparators: Bool

    convenience init(name: String = "Untitled") {
        self.init()
        self.name = name
        self.raw = ""
        self.sample = ""
        self.substitution = ""
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    public var regularExpressionOptions: NSRegularExpression.Options {
        var options: NSRegularExpression.Options = []
        if allowCommentsAndWhitespace {
            options.insert(.allowCommentsAndWhitespace)
        }
        if anchorsMatchLines {
            options.insert(.anchorsMatchLines)
        }
        if caseInsensitive {
            options.insert(.caseInsensitive)
        }
        if dotMatchesLineSeparators {
            options.insert(.dotMatchesLineSeparators)
        }
        if ignoreMetacharacters {
            options.insert(.ignoreMetacharacters)
        }
        if useUnicodeWordBoundaries {
            options.insert(.useUnicodeWordBoundaries)
        }
        if useUnixLineSeparators {
            options.insert(.useUnixLineSeparators)
        }
        return options
    }
    
    public var flagOptions: String {
        ""
            + (caseInsensitive ? "i" : "")
            + (allowCommentsAndWhitespace ? "x" : "")
            + (dotMatchesLineSeparators ? "." : "")
            + (anchorsMatchLines ? "m" : "")
            + (useUnicodeWordBoundaries ? "w" : "")
    }
    
    public override var description: String {
        "/\(raw)/\(flagOptions)"
    }

    public func isEqual(to object: RegEx) -> Bool {
        name == object.name
        && regularExpressionOptions == object.regularExpressionOptions
        && raw == object.raw
        && sample == object.sample
        && substitution == object.substitution
        && allowCommentsAndWhitespace == object.allowCommentsAndWhitespace
        && anchorsMatchLines == object.anchorsMatchLines
        && caseInsensitive == object.caseInsensitive
        && dotMatchesLineSeparators == object.dotMatchesLineSeparators
        && ignoreMetacharacters == object.ignoreMetacharacters
        && useUnicodeWordBoundaries == object.useUnicodeWordBoundaries
        && useUnixLineSeparators == object.useUnixLineSeparators
    }

}
