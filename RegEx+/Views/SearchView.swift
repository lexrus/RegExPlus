//
//  SearchView.swift
//  RegEx+
//
//  Created by Lex on 2020/10/4.
//  Copyright © 2020 Lex.sh. All rights reserved.
//

import SwiftUI

struct SearchView: View {
    @Binding var text: String

    @State private var isEditing = false

    var body: some View {
        HStack(spacing: 8) {
            TextField("Search...", text: $text)
                .padding(.horizontal, 32)
                .padding(.vertical, 5)
                .background(Color(.systemGray6))
                .cornerRadius(15)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 10)

                        if isEditing && !text.isEmpty {
                            Button(action: {
                                self.text = ""
                            }) {
                                Image(systemName: "multiply.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                    .id(text)
                )
                .disableAutocorrection(true)
                .onTapGesture {
                    self.isEditing = true
                }

            if isEditing {
                Button(action: {
                    self.isEditing = false
                    self.text = ""
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }) {
                    Text("Cancel")
                        .font(.body)
                }
                .transition(.move(edge: .trailing))
                .animation(.easeOut)
            }
        }
        .clipped()
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(text: .constant(""))
            .preferredColorScheme(.dark)
    }
}
