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

    private var cornerRadius: CGFloat {
        #if targetEnvironment(macCatalyst)
            5
        #else
            18
        #endif
    }

    var body: some View {
        TextField("Search...", text: $text)
            .padding(.horizontal, 32)
            .padding(.vertical, 5)
            .background(Color(.systemGray6))
            .cornerRadius(cornerRadius)
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
                        .buttonStyle(.borderless)
                    }
                }
            )
            .disableAutocorrection(true)
            .onTapGesture {
                self.isEditing = true
            }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            SearchView(text: .constant(""))
                .preferredColorScheme(.dark)
        }
        .padding()
        .background(Color.white)
    }
}
