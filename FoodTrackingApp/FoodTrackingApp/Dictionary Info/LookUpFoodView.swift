//
//  LookUpFoodView.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 2/15/26.
//
import SwiftUI


struct LookUpFoodView: View {
    @ObservedObject var foodModel: FoodModel
    
    @State private var searchText: String = ""
    @State private var debugOutput = "Type something and press Search…"
    @State private var isLoading: Bool = false
    @State private var showConfirmSheet: Bool = false
    @State private var proposedFood: FoodItem? = nil
    
    private let usdaService = USDANutritionService()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SearchBar(text: $searchText, placeholder: "Search USDA...", onSubmit: {runUSDASearch()},  showsSearchButton: true)
            if isLoading {
                ProgressView("Searching...")
                    .padding(.horizontal, 20)
            }
            ScrollView {
                Text(debugOutput)
                    .font(.system(.body, design: .monospaced))
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
            }
            Spacer()
        }
        .sheet(isPresented: $showConfirmSheet) {
            if let item = proposedFood {
                EditFoodItemView(
                    foodItem: item,
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
        .navigationTitle("USDA Debug")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppTheme.background.ignoresSafeArea())
        
    }
    
    private func runUSDASearch() {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else {
            debugOutput = "Empty Query"
            return
        }
        
        isLoading = true
        debugOutput = "Searching for: \"\(q)\" ..."
        
        Task {
            do {
                let res = try await usdaService.fetchSurveyMacrosPer100g(query: q)
                
                let output =
                                """
                                ✅ Found match

                                Query normalized: \(res.queryNormalized)

                                fdcId: \(res.choice.fdcId)
                                description: \(res.choice.description)
                                dataType: \(res.choice.dataType)

                                Macros per 100g:
                                calories: \(res.macros.caloriesKcal)
                                protein:  \(res.macros.proteinG) g
                                carbs:    \(res.macros.carbsG) g
                                fat:      \(res.macros.fatG) g
                                """
                
                let item = FoodItem(
                    name: res.choice.description,
                    weightInGrams: 100,
                    servings: 1,
                    calories: Int(res.macros.caloriesKcal.rounded()),
                    protein: res.macros.proteinG,
                    carbs: res.macros.carbsG,
                    fats: res.macros.fatG,
                    servingUnit: .grams
                )

                await MainActor.run {
                    proposedFood = item
                    showConfirmSheet = true
                    debugOutput = output
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
