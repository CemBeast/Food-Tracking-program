//
//  AppTheme.swift
//  FoodTrackingApp
//
//  Professional monochrome theme with macro accent colors
//

import SwiftUI

// MARK: - Theme Colors
struct AppTheme {
    // Primary backgrounds
    static let background = Color("PrimaryBackground")
    static let cardBackground = Color("CardBackground")
    static let secondaryBackground = Color("SecondaryBackground")
    
    // Text colors
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextPrimary").opacity(0.6)
    static let textTertiary = Color("TextPrimary").opacity(0.4)
    
    // Monochrome accents
    static let accent = Color.white
    static let border = Color.white.opacity(0.12)
    static let divider = Color.white.opacity(0.08)
    
    // Macro colors - preserved for nutrition display
    static let calorieColor = Color.red
    static let proteinColor = Color.yellow
    static let carbColor = Color.green
    static let fatColor = Color.purple
    
    // Button colors
    static let buttonPrimary = Color.white
    static let buttonSecondary = Color.white.opacity(0.15)
    static let destructive = Color.red.opacity(0.8)
}

// MARK: - Unified Button Style
struct SleekButtonStyle: ButtonStyle {
    var isDestructive: Bool = false
    var isSecondary: Bool = false
    
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold, design: .default))
            .foregroundColor(isDestructive ? .red : (isSecondary ? AppTheme.textPrimary : .black))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .background(
                Group {
                    if isDestructive {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                    } else if isSecondary {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                    }
                }
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.45)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Compact Button Style (for inline buttons)
struct CompactButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.black)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Navigation Link Button Style
struct NavigationButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppTheme.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppTheme.textTertiary)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.06))
        )
        .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
        .opacity(configuration.isPressed ? 0.8 : 1.0)
        .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Card Container
struct ThemedCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 16
    
    init(padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
            )
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 12, weight: .semibold, design: .default))
            .foregroundColor(AppTheme.textTertiary)
            .tracking(1.2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
    }
}

// MARK: - Styled TextField
struct ThemedTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboardType)
            .font(.system(size: 16))
            .foregroundColor(AppTheme.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
            )
    }
}

// MARK: - Form Row
struct FormRow: View {
    let label: String
    let content: AnyView
    
    init<Content: View>(label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = AnyView(content())
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(AppTheme.textSecondary)
            Spacer()
            content
        }
        .padding(.vertical, 4)
    }
}

// MARK: - View Extensions
extension View {
    func themedBackground() -> some View {
        self.background(AppTheme.background.ignoresSafeArea())
    }
    
    func cardStyle() -> some View {
        self
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
            )
    }
}

// MARK: - Navigation Appearance Setup
struct NavigationAppearanceModifier: ViewModifier {
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppTheme.background)
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(AppTheme.textPrimary),
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(AppTheme.textPrimary),
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = .white
    }
    
    func body(content: Content) -> some View {
        content
    }
}

extension View {
    func setupNavigationAppearance() -> some View {
        self.modifier(NavigationAppearanceModifier())
    }
}

// MARK: - Tab Bar Appearance
struct TabBarAppearanceModifier: ViewModifier {
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppTheme.cardBackground)
        
        // Normal state
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.5)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.white.withAlphaComponent(0.5)
        ]
        
        // Selected state
        appearance.stackedLayoutAppearance.selected.iconColor = .white
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    func body(content: Content) -> some View {
        content
    }
}

extension View {
    func setupTabBarAppearance() -> some View {
        self.modifier(TabBarAppearanceModifier())
    }
}

