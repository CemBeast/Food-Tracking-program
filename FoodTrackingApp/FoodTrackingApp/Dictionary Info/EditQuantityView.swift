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
            
            VStack(spacing: 28.scaled) {
                // Header
                VStack(spacing: 8.scaled) {
                    Text(entry.food.name)
                        .font(.system(size: 20.scaled, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text("Edit Quantity")
                        .font(.system(size: 14.scaled))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding(.top, 24.scaled)
                
                // Current Value
                VStack(spacing: 4.scaled) {
                    Text("CURRENT")
                        .font(.system(size: 11.scaled, weight: .bold))
                        .tracking(1.2.scaled)
                        .foregroundColor(AppTheme.textTertiary)
                    
                    Text("\(String(format: "%.0f", entry.quantity)) \(entry.mode == .serving ? "serving\(entry.quantity > 1 ? "s" : "")" : entry.servingUnit.rawValue)")
                        .font(.system(size: 16.scaled, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                // Input Field
                VStack(spacing: 12.scaled) {
                    Text("NEW QUANTITY")
                        .font(.system(size: 11.scaled, weight: .bold))
                        .tracking(1.2.scaled)
                        .foregroundColor(AppTheme.textTertiary)
                    
                    HStack {
                        TextField("0", text: $quantityInput)
                            .keyboardType(.decimalPad)
                            .focused($isFocused)
                            .font(.system(size: 48.scaled, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        Text(entry.mode == .serving ? "srv" : entry.servingUnit.rawValue)
                            .font(.system(size: 20.scaled, weight: .medium))
                            .foregroundColor(AppTheme.textTertiary)
                    }
                    .padding(.horizontal, 32.scaled)
                }
                .padding(.vertical, 20.scaled)
                .background(
                    RoundedRectangle(cornerRadius: 16.scaled)
                        .fill(Color.white.opacity(0.05))
                )
                .padding(.horizontal, 20.scaled)
                
                Spacer()
                
                // Buttons
                VStack(spacing: 12.scaled) {
                    Button {
                        if let parsed = Double(quantityInput), parsed > 0 {
                            let newQty = min(parsed, maxLoggableQuantity)
                            onSave(newQty)
                            dismiss()
                        }
                    } label: {
                        HStack(spacing: 8.scaled) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18.scaled))
                            Text("Save Changes")
                        }
                    }
                    .buttonStyle(SleekButtonStyle())
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 15.scaled, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                .padding(.horizontal, 20.scaled)
                .padding(.bottom, 32.scaled)
            }
        }
        .onAppear {
            isFocused = true
        }
        .presentationDetents([.scaledMedium])
        .presentationDragIndicator(.visible)
    }
}
