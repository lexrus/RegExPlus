//
//  CheatSheetView.swift
//  RegEx+
//
//  Created by Lex on 2020/4/21.
//  Copyright © 2020 Lex.sh. All rights reserved.
//

import SwiftUI


// Official documentation of NSRegularExpression
private let kNSRegularExpressionDocumentLink = "https://developer.apple.com/documentation/foundation/nsregularexpression"


struct CheatSheetView: View {
    @State var showingSafari = false
    
    var body: some View {
        List {
            Section(header: Text("Metacharacters")) {
                Group {
                    RowView(title: "\\a", content: "Match a BELL, \\u0007")
                    RowView(title: "\\A", content: "Match at the beginning of the input. Differs from ^ in that \\A will not match after a new line within the input.")
                    RowView(title: "\\b, outside of a [Set]", content: "Match if the current position is a word boundary. Boundaries occur at the transitions between word (\\w) and non-word (\\W) characters, with combining marks ignored. For better word boundaries, see useUnicodeWordBoundaries.")
                    RowView(title: "\\b, within a [Set]", content: "Match a BACKSPACE, \\u0008.")
                    RowView(title: "\\B", content: "Match if the current position is not a word boundary.")
                    RowView(title: "\\cX", content: "Match a control-X character")
                    RowView(title: "\\d", content: "Match any character with the Unicode General Category of Nd (Number, Decimal Digit.)")
                    RowView(title: "\\D", content: "Match any character that is not a decimal digit.")
                    RowView(title: "\\e", content: "Match an ESCAPE, \\u001B.")
                    RowView(title: "\\E", content: "Terminates a \\Q ... \\E quoted sequence.")
                }
                Group {
                    RowView(title: "\\f", content: "Match a FORM FEED, \\u000C.")
                    RowView(title: "\\G", content: "Match if the current position is at the end of the previous match.")
                    RowView(title: "\\n", content: "Match a LINE FEED, \\u000A.")
                    RowView(title: "\\N{UNICODE CHARACTER NAME}", content: "Match the named character.")
                    RowView(title: "\\p{UNICODE PROPERTY NAME}", content: "Match any character with the specified Unicode Property.")
                    RowView(title: "\\P{UNICODE PROPERTY NAME}", content: "Match any character not having the specified Unicode Property.")
                    RowView(title: "\\Q", content: "Quotes all following characters until \\E.")
                    RowView(title: "\\r", content: "Match a CARRIAGE RETURN, \\u000D.")
                    RowView(title: "\\s", content: "Match a white space character. White space is defined as [\\t\\n\\f\\r\\p{Z}].")
                    RowView(title: "\\S", content: "Match a non-white space character.")
                }
                Group {
                    RowView(title: "\\t", content: "Match a HORIZONTAL TABULATION, \\u0009.")
                    RowView(title: "\\uhhhh", content: "Match the character with the hex value hhhh.")
                    RowView(title: "\\Uhhhhhhhh", content: "Match the character with the hex value hhhhhhhh. Exactly eight hex digits must be provided, even though the largest Unicode code point is \\U0010ffff.")
                    RowView(title: "\\w", content: "Match a word character. Word characters are [\\p{Ll}\\p{Lu}\\p{Lt}\\p{Lo}\\p{Nd}].")
                    RowView(title: "\\W", content: "Match a non-word character.")
                    RowView(title: "\\x{hhhh}", content: "Match the character with hex value hhhh. From one to six hex digits may be supplied.")
                    RowView(title: "\\xhh", content: "Match the character with two digit hex value hh.")
                    RowView(title: "\\X", content: "Match a Grapheme Cluster.")
                    RowView(title: "\\Z", content: "Match if the current position is at the end of input, but before the final line terminator, if one exists.")
                    RowView(title: "\\z", content: "Match if the current position is at the end of input.")
                }
                Group {
                    RowView(title: "\\n", content: "Back Reference. Match whatever the nth capturing group matched. n must be a number ≥ 1 and ≤ total number of capture groups in the pattern.")
                    RowView(title: "\\0ooo", content: "Match an Octal character. ooo is from one to three octal digits. 0377 is the largest allowed Octal character. The leading zero is required; it distinguishes Octal constants from back references.")
                    RowView(title: "[pattern]", content: "Match any one character from the pattern.")
                    RowView(title: ".", content: "Match any character.")
                    RowView(title: "^", content: "Match at the beginning of a line.")
                    RowView(title: "$", content: "Match at the end of a line.")
                    RowView(title: "\\", content: "Quotes the following character. Characters that must be quoted to be treated as literals are * ? + [ ( ) { } ^ $ | \\ . /")
                }
            }
            
            Section(header: Text("Operators")) {
                Group {
                    RowView(title: "|", content: "Alternation. A|B matches either A or B.")
                    RowView(title: "*", content: "Match 0 or more times. Match as many times as possible.")
                    RowView(title: "+", content: "Match 1 or more times. Match as many times as possible.")
                    RowView(title: "?", content: "Match zero or one times. Prefer one.")
                    RowView(title: "{n}", content: "Match exactly n times.")
                    RowView(title: "{n,}", content: "Match at least n times. Match as many times as possible.")
                    RowView(title: "{n,m}", content: "Match between n and m times. Match as many times as possible, but not more than m.")
                    RowView(title: "*?", content: "Match 0 or more times. Match as few times as possible.")
                    RowView(title: "+?", content: "Match 1 or more times. Match as few times as possible.")
                    RowView(title: "??", content: "Match zero or one times. Prefer zero.")
                }
                Group {
                    RowView(title: "{n}?", content: "Match exactly n times.")
                    RowView(title: "{n,}?", content: "Match at least n times, but no more than required for an overall pattern match.")
                    RowView(title: "{n,m}?", content: "Match between n and m times. Match as few times as possible, but not less than n.")
                    RowView(title: "*+", content: "Match 0 or more times. Match as many times as possible when first encountered, do not retry with fewer even if overall match fails (Possessive Match).")
                    RowView(title: "++", content: "Match 1 or more times. Possessive match.")
                    RowView(title: "?+", content: "Match zero or one times. Possessive match.")
                    RowView(title: "{n}+", content: "Match exactly n times.")
                    RowView(title: "{n,}+", content: "Match at least n times. Possessive Match.")
                    RowView(title: "{n,m}+", content: "Match between n and m times. Possessive Match.")
                    RowView(title: "(...)", content: "Capturing parentheses. Range of input that matched the parenthesized subexpression is available after the match.")
                }
                Group {
                    RowView(title: "(?:...)", content: "Non-capturing parentheses. Groups the included pattern, but does not provide capturing of matching text. Somewhat more efficient than capturing parentheses.")
                    RowView(title: "(?>...)", content: "Atomic-match parentheses. First match of the parenthesized subexpression is the only one tried; if it does not lead to an overall pattern match, back up the search for a match to a position before the \"(?>\"")
                    RowView(title: "(?# ... )", content: "Free-format comment (?# comment ).")
                    RowView(title: "(?= ... )", content: "Look-ahead assertion. True if the parenthesized pattern matches at the current input position, but does not advance the input position.")
                    RowView(title: "(?! ... )", content: "Negative look-ahead assertion. True if the parenthesized pattern does not match at the current input position. Does not advance the input position.")
                    RowView(title: "(?<= ... )", content: "Look-behind assertion. True if the parenthesized pattern matches text preceding the current input position, with the last character of the match being the input character just before the current position. Does not alter the input position. The length of possible strings matched by the look-behind pattern must not be unbounded (no * or + operators.")
                    RowView(title: "(?<! ... )", content: "Negative Look-behind assertion. True if the parenthesized pattern does not match text preceding the current input position, with the last character of the match being the input character just before the current position. Does not alter the input position. The length of possible strings matched by the look-behind pattern must not be unbounded (no * or + operators.")
                    RowView(title: "(?ismwx-ismwx: ... )", content: "Flag settings. Evaluate the parenthesized expression with the specified flags enabled or -disabled. The flags are defined in Flag Options.")
                    RowView(title: "(?ismwx-ismwx)", content: "Flag settings. Change the flag settings. Changes apply to the portion of the pattern following the setting. For example, (?i) changes to a case insensitive match.The flags are defined in Flag Options.")
                }
            }
        }
        .navigationBarTitle("Cheat Sheet")
        .navigationBarItems(trailing: safariButton)
    }
    
    private var safariButton: some View {
        Button(action: {
            self.showingSafari.toggle()
        }) {
            Image(systemName: "safari")
                .imageScale(.large)
        }
        .sheet(isPresented: $showingSafari, content: {
            SafariView(url: URL(string: kNSRegularExpressionDocumentLink)!)
        })
    }
}

struct CheatSheetView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CheatSheetView()
                .navigationBarTitle("Cheat Sheet")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

private struct RowView: View {
    @State var title: String
    @State var content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .foregroundColor(.accentColor)
            Text(content)
                .font(.subheadline)
        }
    }
}
