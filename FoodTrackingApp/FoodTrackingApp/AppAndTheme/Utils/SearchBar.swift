//
//  SearchBar.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 2/15/26.
//
import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search..."
    var onSubmit: (() -> Void)? = nil
    var showsSearchButton: Bool = false

    var body: some View {
        HStack(spacing: 12.scaled) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16.scaled))
                .foregroundColor(AppTheme.textTertiary)

            TextField(placeholder, text: $text)
                .font(.system(size: 16.scaled))
                .foregroundColor(AppTheme.textPrimary)
                .submitLabel(.search)
                .onSubmit { onSubmit?() }

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16.scaled))
                        .foregroundColor(AppTheme.textTertiary)
                }
            }

            if showsSearchButton {
                Button {
                    onSubmit?()
                } label: {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 18.scaled))
                        .foregroundColor(AppTheme.textPrimary)
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(.horizontal, 16.scaled)
        .padding(.vertical, 12.scaled)
        .background(
            RoundedRectangle(cornerRadius: 12.scaled)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12.scaled)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
        )
        .padding(.horizontal, 20.scaled)
        .padding(.top, 16.scaled)
        .padding(.bottom, 12.scaled)
    }
}
