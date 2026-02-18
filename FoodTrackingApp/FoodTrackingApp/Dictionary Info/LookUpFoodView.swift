//
//  LookUpFoodView.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 2/15/26.
//
import SwiftUI
import UIKit

// for clicking off search bar and clearing keyboard
extension UIApplication {
    func dismissKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder),
                   to: nil, from: nil, for: nil)
    }
}

enum LookupMode: String, CaseIterable, Identifiable {
    case foundation = "Basic" // USDA Foudnational
    case survey = "Everyday" // USDA Survery
    case brands = "Brands" // USDA Brands
    case fastFood = "Fast Food" // in progress
    
    // I think we should switch it to Basic, Everyday, Brands, with the info button explaining each
    var id: String { rawValue }
}

struct LookUpFoodView: View {
    @ObservedObject var foodModel: FoodModel
    
    @State private var searchText: String = ""
    @State private var debugOutput = "Type something and press Search…"
    @State private var isLoading: Bool = false
    @State private var showConfirmSheet: Bool = false
    @State private var proposedFood: FoodItem? = nil
    @State private var mode: LookupMode = .foundation
    @State private var results: [USDAFoodChoice] = []
    @State private var resultQueryNormalized: String = ""
    @State private var macrosByFdcId: [Int: MacrosPer100g] = [:] // cache for loading results from USDA
    @State private var modeInfo: Bool = false
    
    @Environment(\.horizontalSizeClass) private var hSizeClass
    
    private let usdaService = USDANutritionService()
    
    // placeholder text for search string
    var placeholder : String {
        switch mode {
        case .foundation: return "Search Whole Foods…"
        case .brands: return "Search Brands"
        case .survey: return "Search Common Foods…"
        case .fastFood: return "Search Fast Food"
        }
    }
    
    var body: some View {
        VStack(spacing: 0){
            VStack(alignment: .leading, spacing: 12) {
                SearchBar(text: $searchText, placeholder: placeholder, onSubmit: {runUSDASearch()},  showsSearchButton: true)
                modeChips
                if isLoading {
                    ProgressView("Searching...")
                        .padding(.horizontal, 20)
                }
            }
            .background(AppTheme.background)
            
            // Results (scrolls)
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if !results.isEmpty {
                        ForEach(results, id: \.fdcId) { choice in
                            Button {
                                selectChoice(choice)
                            } label: {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text(choice.description)
                                            .foregroundColor(AppTheme.textPrimary)
                                            .lineLimit(2)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(AppTheme.textTertiary)
                                    }
                                    Label("100g", systemImage: "scalemass")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppTheme.textSecondary)
                                    
                                    // Preview macros (if loaded)
                                    if let m = macrosByFdcId[choice.fdcId] {
                                        HStack(spacing: 8) {
                                            MacroPill(value: "\(Int(m.caloriesKcal.rounded()))", label: "cal", color: AppTheme.calorieColor)
                                            MacroPill(value: String(format: "%.0f", m.proteinG), label: "P", color: AppTheme.proteinColor)
                                            MacroPill(value: String(format: "%.0f", m.carbsG), label: "C", color: AppTheme.carbColor)
                                            MacroPill(value: String(format: "%.0f", m.fatG), label: "F", color: AppTheme.fatColor)
                                        }
                                    } else {
                                        // optional tiny placeholder so it doesn’t feel empty
                                        Text("Loading macros…")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(AppTheme.textTertiary)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(AppTheme.cardBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(AppTheme.border, lineWidth: 1)
                                        )
                                )
                                .padding(.horizontal, 20)
                            }
                            .buttonStyle(.plain)
                        }
                    }
    
                    Spacer(minLength: 24)
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppTheme.background.ignoresSafeArea())
        .sheet(isPresented: $showConfirmSheet) {
            if let item = proposedFood {
                EditFoodItemView(
                    foodItem: item,
                    isAdding: true,
                    onSave: { updated in
                        foodModel.add(updated)     //adds + saves
                        proposedFood = nil
                        showConfirmSheet = false
                    },
                    onCancel: {
                        proposedFood = nil
                        showConfirmSheet = false
                    }
                )
            }
        }
        .contentShape(Rectangle()) // required for dismissing keyboard
        .onTapGesture {
                UIApplication.shared.dismissKeyboard()
        }
        .background(AppTheme.background.ignoresSafeArea())
        
    }
    

    
    @ViewBuilder
    private var modeChips: some View {
        HStack(spacing: 8) {
            ForEach(LookupMode.allCases) { option in
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        mode = option
                    }
                } label: {
                    Text(option.rawValue)
                        .font(.system(size: 12, weight: mode == option ? .semibold : .medium))
                        .foregroundColor(mode == option ? .black : AppTheme.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(mode == option ? Color.white : Color.white.opacity(0.06))
                        )
                }
            }
            
            Button {
                modeInfo.toggle()
            } label: {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .popover(
                isPresented: $modeInfo,
                attachmentAnchor: .point(.bottom),
                arrowEdge: .top
            ) {
                if #available(iOS 16.4, *) {
                    ModeInfoPopover()
                        .presentationCompactAdaptation(.none)
                } else {
                    ModeInfoPopover()
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func runUSDASearch() {
        let limitSearches = 8 // how many searches return
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else {
            debugOutput = "Empty Query"
            return
        }
        
        isLoading = true
        debugOutput = "Searching for: \"\(q)\" ..."
        
        Task {
            do {
                let q = q.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !q.isEmpty else { return }
                
                // 1) Decide scope (or return for fastFood)
                let scope: USDASearchScope
                switch mode {
                case .foundation: scope = .foundation
                case .brands:  scope = .branded
                case .survey: scope = .survey
                case .fastFood:
                    // later
                    await MainActor.run { isLoading = false }
                    return
                }

                // 2) Fetch once
                // decide scope like you already do...

                let top = try await usdaService.searchTopChoices(query: q, scope: scope, limit: limitSearches)

                await MainActor.run {
                    resultQueryNormalized = top.queryNormalized
                    results = top.choices
                    debugOutput = "✅ Found \(top.choices.count) results for: \(top.queryNormalized)"
                    isLoading = false
                }
                
                // kick off preview macro fetch AFTER results show
                fetchPreviewMacros(for: top.choices)
                
            } catch {
                await MainActor.run {
                    debugOutput = "Error: \(error.localizedDescription)"
                    isLoading = false
                }
                
            }
        }
    }
        
    // Fetches the macros for the list results provided
    private func fetchPreviewMacros(for choices: [USDAFoodChoice]) {
        Task {
            await withTaskGroup(of: (Int, MacrosPer100g)?.self) { group in
                for c in choices {
                    // cache hit -> don’t fetch
                    if macrosByFdcId[c.fdcId] != nil { continue }

                    group.addTask {
                        do {
                            let macros = try await usdaService.fetchMacrosPer100gForFood(fdcId: c.fdcId)
                            return (c.fdcId, macros)
                        } catch {
                            // ignore failures for previews (optional: log)
                            return nil
                        }
                    }
                }

                // update incrementally as results arrive
                for await result in group {
                    guard let (fdcId, macros) = result else { continue }
                    await MainActor.run {
                        macrosByFdcId[fdcId] = macros
                    }
                }
            }
        }
    }
    
    private func selectChoice(_ choice: USDAFoodChoice) {
        isLoading = true
        debugOutput = "Fetching macros for: \(choice.description)"

        Task {
            do {
                // Reuse your existing fetchMacrosForFood by adding a small public wrapper,
                // OR simplest: use your existing fetchSurveyMacrosPer100g by querying description again.
                // Better: add a public method that fetches macros by fdcId (shown below).

                let macros = try await usdaService.fetchMacrosPer100gForFood(fdcId: choice.fdcId)

                let item = FoodItem(
                    name: choice.description,
                    weightInGrams: 100,
                    servings: 1,
                    calories: Int(macros.caloriesKcal.rounded()),
                    protein: macros.proteinG,
                    carbs: macros.carbsG,
                    fats: macros.fatG,
                    servingUnit: .grams
                )

                await MainActor.run {
                    proposedFood = item
                    showConfirmSheet = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    debugOutput = "Error: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

private struct ModeInfoPopover: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                row(title: "Basic", desc: "Basic includes whole foods or raw foods. Use this for ingredients or generic foods.")
                row(title: "Everyday", desc: "Typical foods that you may find anywhere. Includes foods that consist of multiple ingredients.")
                row(title: "Brands", desc: "Foods from name brands. Use this if you are searching for a specific brands food.")
                row(title: "Fast Food", desc: "Fast Food - work in progress right now.")

            }
            Text("Tip: Start with Everyday for most foods.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .padding(.top, 2)
        }
        .padding(35)
    }
    
    private func row(title: String, desc: String) -> some View {
        HStack( spacing: 3) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 90, alignment: .leading)
            Text(desc)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    NavigationStack {
        LookUpFoodView(foodModel: FoodModel())
    }
}
