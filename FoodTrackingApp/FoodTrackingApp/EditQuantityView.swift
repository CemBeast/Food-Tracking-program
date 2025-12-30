//
//  EditQuantityView.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 5/22/25.
//
import SwiftUI

struct EditQuantityView: View {
    @Environment(\.dismiss) private var dismiss
    let entry: LoggedFoodEntry
    var onSave: (Double) -> Void
    @State private var quantityInput: String
    @FocusState private var isFocused: Bool

    init(entry: LoggedFoodEntry, onSave: @escaping (Double) -> Void) {
        self.entry = entry
        self.onSave = onSave
        self._quantityInput = State(initialValue: String(format: "%.0f", entry.quantity))
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 28) {
                // Header
                VStack(spacing: 8) {
                    Text(entry.food.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text("Edit Quantity")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding(.top, 24)
                
                // Current Value
                VStack(spacing: 4) {
                    Text("CURRENT")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.2)
                        .foregroundColor(AppTheme.textTertiary)
                    
                    Text("\(String(format: "%.0f", entry.quantity)) \(entry.mode == .serving ? "serving\(entry.quantity > 1 ? "s" : "")" : entry.servingUnit.rawValue)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                // Input Field
                VStack(spacing: 12) {
                    Text("NEW QUANTITY")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.2)
                        .foregroundColor(AppTheme.textTertiary)
                    
                    HStack {
                        TextField("0", text: $quantityInput)
                            .keyboardType(.decimalPad)
                            .focused($isFocused)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        Text(entry.mode == .serving ? "srv" : entry.servingUnit.rawValue)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(AppTheme.textTertiary)
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                )
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Buttons
                VStack(spacing: 12) {
                    Button {
                        if let newQty = Double(quantityInput), newQty > 0 {
                            onSave(newQty)
                            dismiss()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                            Text("Save Changes")
                        }
                    }
                    .buttonStyle(SleekButtonStyle())
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            isFocused = true
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
