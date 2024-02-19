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
    
    @State var metacharacters: [CheatSheetPlist.Item] = []
    @State var operators: [CheatSheetPlist.Item] = []
    
    var body: some View {
        List {
            Section(header: Text("Metacharacters")) {
                ForEach(metacharacters, id: \.exp) {
                    RowView(title: $0.exp, content: $0.des)
                }
            }
            
            Section(header: Text("Operators")) {
                ForEach(operators, id: \.exp) {
                    RowView(title: $0.exp, content: $0.des)
                }
            }
        }
        .navigationBarTitle("Cheat Sheet")
        .navigationBarItems(trailing: safariButton)
        .onAppear(perform: loadPlist)
    }
    
    private func loadPlist() {
        guard let url = Bundle.main.url(forResource: "CheatSheet", withExtension: "plist") else {
            assertionFailure("Missing CheatSheet.plist!")
            return
        }
        
        let plistDecoder = PropertyListDecoder()
        
        do {
            let data = try Data(contentsOf: url)
            let dict = try plistDecoder.decode(CheatSheetPlist.self, from: data)
            metacharacters = dict.metacharacters
            operators = dict.operators
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private var safariButton: some View {
        let url = URL(string: kNSRegularExpressionDocumentLink)!

        return Button(action: {
            #if targetEnvironment(macCatalyst)
            UIApplication.shared.open(url)
            #else
            showingSafari.toggle()
            #endif
        }) {
            Image(systemName: "safari")
                .imageScale(.large)
                .padding(EdgeInsets(top: 8, leading: 24, bottom: 8, trailing: 0))
        }
        .sheet(isPresented: $showingSafari, content: {
            SafariView(url: url)
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
    var title: String
    var content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.headline)
                .foregroundColor(.accentColor)
            Text(content)
                .font(.subheadline)
        }
        .padding(.vertical, 6)
    }
}

struct CheatSheetPlist: Decodable {
    struct Item: Decodable, Hashable {
        var exp: String
        var des: String
    }
    
    var metacharacters: [Item]
    var operators: [Item]
    
}
