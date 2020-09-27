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
        .navigationTitle("Cheat Sheet")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                safariButton
            }
        }
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
            self.metacharacters = dict.metacharacters
            self.operators = dict.operators
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private var safariButton: some View {
        Button(action: {
            self.showingSafari.toggle()
        }) {
            Image(systemName: "safari")
                .imageScale(.large)
                .padding(EdgeInsets(top: 8, leading: 24, bottom: 8, trailing: 0))
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
                .navigationTitle("Cheat Sheet")
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
