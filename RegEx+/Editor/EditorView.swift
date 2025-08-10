//
//  EditorView.swift
//  RegEx+
//
//  Created by Lex on 2020/4/21.
//  Copyright © 2020 Lex.sh. All rights reserved.
//

import SwiftUI

struct EditorView: View, Equatable {

    static func == (lhs: EditorView, rhs: EditorView) -> Bool {
        lhs.regEx.objectID == rhs.regEx.objectID
    }

    let regEx: RegEx
    @StateObject private var viewModel = EditorViewModel()
    @State private var isSharePresented = false
    @State private var copyButtonText = "Copy"

    init(regEx: RegEx) {
        self.regEx = regEx
    }

    var body: some View {
        Group {
            if let regExBinding = Binding($viewModel.regEx) {
                List {
                    Section(header: Text("Name")) {
                        TextField("Name", text: regExBinding.name)
                            .font(.headline)
                    }

                    RegExTextViewSection(regEx: regExBinding)

                    Section(header: SampleHeaderView(count: viewModel.matches.count)) {
                        MatchesTextView(
                            "$56.78 $90.12",
                            text: regExBinding.sample,
                            matches: $viewModel.matches
                        )
                        .equatable()
                        .padding(kTextFieldPadding)
                    }

                    SubstitutionSection(
                        regExBinding: regExBinding,
                        substitutionResult: viewModel.substitutionResult,
                        copyButtonText: copyButtonText,
                        copyAction: copyToClipboard
                    )
                }
                .navigationTitle(regExBinding.name)
                .toolbar {
#if !targetEnvironment(macCatalyst)
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        shareButton.padding()
                        cheatSheetButton().padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 0))
                    }
#endif
                }
                .gesture(dismissKeyboardDesture)
                .listStyle(InsetGroupedListStyle())
                .onDisappear(perform: {
                    viewModel.updateLastModified()
                    DataManager.shared.saveContext()
                })
            } else {
                Text("Loading...")
                    .navigationTitle("RegEx+")
            }
        }
        .onAppear {
            viewModel.configure(with: regEx)
        }
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = viewModel.substitutionResult
        copyButtonText = "Copied"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copyButtonText = "Copy"
        }
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
        }
        .accessibilityLabel("Share")
        .accessibilityHint("Share this regular expression")
        .sheet(isPresented: $isSharePresented) {
            if let regEx = viewModel.regEx {
                ActivityViewController(activityItems: [regEx.description])
            }
        }
    }
}

private func cheatSheetButton() -> some View {
#if targetEnvironment(macCatalyst)
    ZStack {
        Image(systemName: "wand.and.stars")
            .imageScale(.large)
            .foregroundColor(.accentColor)
        NavigationLink(destination: CheatSheetView()) {
            EmptyView()
        }
        .opacity(0)
    }
    .accessibilityLabel("Cheat Sheet")
    .accessibilityHint("View regular expression reference guide")
#else
    NavigationLink(destination: CheatSheetView()) {
        Image(systemName: "wand.and.stars")
            .imageScale(.large)
            .foregroundColor(.accentColor)
    }
    .accessibilityLabel("Cheat Sheet")
    .accessibilityHint("View regular expression reference guide")
#endif
}

private struct RegExTextViewSection: View {

    @Binding var regEx: RegEx
    @State private var isOptionsVisible = false

    var body: some View {
        Section(header: Text("Regular Expression")) {
#if targetEnvironment(macCatalyst)

            HStack {
                RegExTextView("Type RegEx here", text: $regEx.raw, showShortcutBar: false)
                    .equatable()
                    .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 5))

                cheatSheetButton()
                    .frame(width: 20)
            }

#else

            RegExTextView("Type RegEx here", text: $regEx.raw, showShortcutBar: true)
                .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 5))

#endif

            Button(action: {
                isOptionsVisible.toggle()
            }) {
                HStack {
                    Text("Options")

                    if !isOptionsVisible {
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

    var body: some View {
        HStack {
            Text("Sample Text")
            if count > 0 {
                Spacer()
                Text(count == 1 ? "1 match" : "\(count) matches")
                    .font(.footnote)
                    .foregroundColor(Color.secondary)
                    .padding(EdgeInsets(top: 1, leading: 6, bottom: 1, trailing: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.secondary, lineWidth: 1)
                    )
            }
        }
        .frame(minHeight: 20)
    }
}

private let kTextFieldPadding = EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 5)

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
        Group {
            NavigationView {
                EditorView(regEx: regEx)
            }
            .environment(\.sizeCategory, .extraLarge)
            .previewLayout(.device)
            .previewDevice("iPhone 11")
            NavigationView {
                EditorView(regEx: regEx)
            }
            .previewDevice("iPhone 11")
            .preferredColorScheme(.dark)
            .environment(\.sizeCategory, .large)
        }
    }
}

private struct SubstitutionSection: View {
    @Binding var regExBinding: RegEx
    let substitutionResult: String
    let copyButtonText: String
    let copyAction: () -> Void
    
    var body: some View {
        Section(header: Text("Substitution Template")) {
#if targetEnvironment(macCatalyst)
            TextField("Price: $$$1\\.$2\\n", text: $regExBinding.substitution)
                .padding(kTextFieldPadding)
#else
            RegExTextView("Price: $$$1\\.$2\\n", text: $regExBinding.substitution, showShortcutBar: true)
                .padding(kTextFieldPadding)
#endif
        }

        if !regExBinding.substitution.isEmpty {
            Section(header: Text("Substitution Result")) {
                HStack {
                    Text(substitutionResult)
                        .padding(kTextFieldPadding)
                    if !substitutionResult.isEmpty {
                        Spacer()
                        Button(action: copyAction) {
                            Text("\(copyButtonText)")
                                .font(.footnote)
                                .foregroundColor(Color.accentColor)
                                .padding(EdgeInsets(top: 1, leading: 6, bottom: 1, trailing: 6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.accentColor, lineWidth: 1)
                                )
                        }
                        .accessibilityLabel("Copy substitution result")
                        .accessibilityHint("Copies the substitution result to clipboard")
                    }
                }
            }
        }
    }
}
#endif
