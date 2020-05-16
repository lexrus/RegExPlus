//
//  EditorView.swift
//  RegEx+
//
//  Created by Lex on 2020/4/21.
//  Copyright © 2020 Lex.sh. All rights reserved.
//

import SwiftUI


struct EditorView: View {
    
    @ObservedObject var viewModel: EditorViewModel
    @State private var isSharePresented = false
    
    init(regEx: RegEx) {
        self.viewModel = EditorViewModel(regEx: regEx)
    }
    
    var body: some View {
        List {
            RegExTextViewSection(regEx: $viewModel.regEx)
            
            Section(header: SampleHeaderView(count: viewModel.matches.count)) {
                MatchesTextView("$56.78 $90.12", text: $viewModel.regEx.sample, matches: $viewModel.matches)
                    .padding(kTextFieldPadding)
                    .background(kTextFieldBackground)
            }
            
            Section(header: Text("Substitution Template")) {
                TextField("Price: $$$1\\.$2\\n", text: $viewModel.regEx.substitution)
                    .padding(kTextFieldPadding)
                    .background(kTextFieldBackground)
            }
            
            if !viewModel.regEx.substitution.isEmpty {
                Section(header: Text("Substitution Result")) {
                    Text(viewModel.substitutionResult)
                }
            }
            
        }
        .onDisappear(perform: {
            self.viewModel.updateLastModified()
            DataManager.shared.saveContext()
        })
        .keyboardObserving()
        .listStyle(GroupedListStyle())
        .navigationViewStyle(StackNavigationViewStyle())
        .navigationBarItems(trailing: HStack(spacing: 8) {
            shareButton
            cheatSheetButton
        })
        .navigationBarTitle(viewModel.regEx.name)
        .gesture(dismissKeyboardDesture)
        
    }
    
    // https://stackoverflow.com/questions/56491386/how-to-hide-keyboard-when-using-swiftui
    private var dismissKeyboardDesture: some Gesture {
        DragGesture().onChanged { _ in
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    private var shareButton: some View {
        Button(action: {
            self.isSharePresented = true
        }) {
            Image(systemName: "square.and.arrow.up")
                .imageScale(.large)
                .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 8))
        }
        .sheet(isPresented: $isSharePresented) {
            ActivityViewController(activityItems: [self.viewModel.regEx.description])
        }
    }
    
    private var cheatSheetButton: some View {
        NavigationLink(destination: CheatSheetView()) {
            Image(systemName: "wand.and.stars")
                .imageScale(.large)
                .padding(EdgeInsets(top: 8, leading: 24, bottom: 8, trailing: 0))
        }
    }
}

private struct RegExTextViewSection: View {
    @Binding var regEx: RegEx
    @State private var isOptionsVisible = false
    @State private var showingSheet = false
    
    var body: some View {
        Section(header: Text("Regular Expression")) {
            TextField("Name", text: $regEx.name)
            
            RegExTextView("Type RegEx here", text: $regEx.raw)
                .padding(kTextFieldPadding)
                .background(kTextFieldBackground)
            
            Button(action: {
                self.isOptionsVisible.toggle()
            }) {
                HStack {
                    Text("Options")
                    Spacer()
                    VStack(alignment: .trailing) {
                        if regEx.caseInsensitive {
                            Text("Case Insensitive")
                        }
                        if regEx.allowCommentsAndWhitespace {
                            Text("Allow Comments and Whitespace")
                        }
                        if regEx.ignoreMetacharacters {
                            Text("Ignore Metacharacters")
                        }
                        if regEx.anchorsMatchLines {
                            Text("Anchors Match Lines")
                        }
                        if regEx.dotMatchesLineSeparators {
                            Text("Dot Matches Line Separators")
                        }
                        if regEx.useUnixLineSeparators {
                            Text("Use Unix Line Separators")
                        }
                        if regEx.useUnicodeWordBoundaries {
                            Text("Use Unicode Word Boundaries")
                        }
                    }
                    .font(.footnote)
                }
                .foregroundColor(isOptionsVisible ? .secondary : .accentColor)
            }

            if isOptionsVisible {
                Toggle("Case Insensitive", isOn: $regEx.caseInsensitive)
                Toggle("Allow Comments and Whitespace", isOn: $regEx.allowCommentsAndWhitespace)
                Toggle("Ignore Metacharacters", isOn: $regEx.ignoreMetacharacters)
                Toggle("Anchors Match Lines", isOn: $regEx.anchorsMatchLines)
                Toggle("Dot Matches Line Separators", isOn: $regEx.dotMatchesLineSeparators)
                Toggle("Use Unix Line Separators", isOn: $regEx.useUnixLineSeparators)
                Toggle("Use Unicode Word Boundaries", isOn: $regEx.useUnicodeWordBoundaries)
            }
        }
    }
}

private struct SampleFooterView: View {
    var count: Int
    
    private var matchesString: String {
        return self.count == 1 ? "1 match" : "\(count) matches"
    }
    
    var body: some View {
        Text(matchesString)
    }
}

private struct SampleHeaderView: View {
    var count: Int
    
    private var matchesString: String {
        return self.count == 1 ? "1 match" : "\(count) matches"
    }
    
    var body: some View {
        HStack {
            Text("Sample Text")
            if count > 0 {
                Spacer()
                Text(matchesString)
                    .font(.footnote)
                    .foregroundColor(Color.secondary)
                    .padding(EdgeInsets(top: 1, leading: 6, bottom: 1, trailing: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.secondary, lineWidth: 1)
                    )
            }
        }
    }
}

private let kTextFieldBackground = Color.secondary.opacity(0.05)
private let kTextFieldPadding = EdgeInsets(top: 8, leading: 5, bottom: 8, trailing: 5)

#if DEBUG
struct EditorView_Previews: PreviewProvider {
    private static var regEx: RegEx = {
        var r: RegEx = RegEx(context: DataManager.shared.persistentContainer.viewContext)
        r.name = "Dollars"
        r.raw = #"\$?((\d+)\.?(\d\d)?)"#
        r.sample = "$100.00 12.50 $10"
        r.substitution = "$3"
        return r
    }()

    static var previews: some View {
        NavigationView {
            EditorView(regEx: regEx)
        }
    }
}
#endif
