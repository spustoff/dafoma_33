//
//  NeumorphismDesignHelper.swift
//  TaskVantage Road
//
//  Created by Developer on 1/9/25.
//

import SwiftUI

struct NeumorphicStyle: ViewModifier {
    var isPressed: Bool = false
    var cornerRadius: CGFloat = 12
    var shadowRadius: CGFloat = 8
    var shadowOffset: CGFloat = 6
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppColorScheme.cardBackground)
                    .shadow(
                        color: isPressed ? AppColorScheme.shadowLight.opacity(0.3) : AppColorScheme.shadowDark.opacity(0.8),
                        radius: isPressed ? shadowRadius/2 : shadowRadius,
                        x: isPressed ? -shadowOffset/2 : -shadowOffset,
                        y: isPressed ? -shadowOffset/2 : -shadowOffset
                    )
                    .shadow(
                        color: isPressed ? AppColorScheme.shadowDark.opacity(0.3) : AppColorScheme.shadowLight.opacity(0.6),
                        radius: isPressed ? shadowRadius/2 : shadowRadius,
                        x: isPressed ? shadowOffset/2 : shadowOffset,
                        y: isPressed ? shadowOffset/2 : shadowOffset
                    )
            )
    }
}

struct NeumorphicButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 12
    var shadowRadius: CGFloat = 8
    var shadowOffset: CGFloat = 6
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .modifier(NeumorphicStyle(
                isPressed: configuration.isPressed,
                cornerRadius: cornerRadius,
                shadowRadius: shadowRadius,
                shadowOffset: shadowOffset
            ))
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct NeumorphicCardStyle: ViewModifier {
    var cornerRadius: CGFloat = 16
    var shadowRadius: CGFloat = 10
    var shadowOffset: CGFloat = 8
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                AppColorScheme.gradientStart,
                                AppColorScheme.gradientEnd
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: AppColorScheme.shadowDark.opacity(0.8),
                        radius: shadowRadius,
                        x: -shadowOffset,
                        y: -shadowOffset
                    )
                    .shadow(
                        color: AppColorScheme.shadowLight.opacity(0.6),
                        radius: shadowRadius,
                        x: shadowOffset,
                        y: shadowOffset
                    )
            )
    }
}

struct NeumorphicTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppColorScheme.background)
                    .shadow(
                        color: AppColorScheme.shadowDark.opacity(0.8),
                        radius: 4,
                        x: -2,
                        y: -2
                    )
                    .shadow(
                        color: AppColorScheme.shadowLight.opacity(0.6),
                        radius: 4,
                        x: 2,
                        y: 2
                    )
            )
            .foregroundColor(AppColorScheme.textPrimary)
    }
}

// MARK: - View Extensions
extension View {
    func neumorphicStyle(
        cornerRadius: CGFloat = 12,
        shadowRadius: CGFloat = 8,
        shadowOffset: CGFloat = 6
    ) -> some View {
        self.modifier(NeumorphicStyle(
            cornerRadius: cornerRadius,
            shadowRadius: shadowRadius,
            shadowOffset: shadowOffset
        ))
    }
    
    func neumorphicCard(
        cornerRadius: CGFloat = 16,
        shadowRadius: CGFloat = 10,
        shadowOffset: CGFloat = 8
    ) -> some View {
        self.modifier(NeumorphicCardStyle(
            cornerRadius: cornerRadius,
            shadowRadius: shadowRadius,
            shadowOffset: shadowOffset
        ))
    }
    
    func neumorphicButton(
        cornerRadius: CGFloat = 12,
        shadowRadius: CGFloat = 8,
        shadowOffset: CGFloat = 6
    ) -> some View {
        self.buttonStyle(NeumorphicButtonStyle(
            cornerRadius: cornerRadius,
            shadowRadius: shadowRadius,
            shadowOffset: shadowOffset
        ))
    }
}

// MARK: - Neumorphic Components
struct NeumorphicProgressBar: View {
    var progress: Double
    var height: CGFloat = 8
    var cornerRadius: CGFloat = 4
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppColorScheme.background)
                    .shadow(
                        color: AppColorScheme.shadowDark.opacity(0.8),
                        radius: 2,
                        x: -1,
                        y: -1
                    )
                    .shadow(
                        color: AppColorScheme.shadowLight.opacity(0.6),
                        radius: 2,
                        x: 1,
                        y: 1
                    )
                
                // Progress fill
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                AppColorScheme.primaryAction,
                                AppColorScheme.secondaryAction
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: height)
    }
}

struct NeumorphicToggle: View {
    @Binding var isOn: Bool
    var width: CGFloat = 50
    var height: CGFloat = 30
    
    var body: some View {
        ZStack {
            // Background track
            RoundedRectangle(cornerRadius: height / 2)
                .fill(isOn ? AppColorScheme.secondaryAction : AppColorScheme.background)
                .shadow(
                    color: AppColorScheme.shadowDark.opacity(0.8),
                    radius: 4,
                    x: -2,
                    y: -2
                )
                .shadow(
                    color: AppColorScheme.shadowLight.opacity(0.6),
                    radius: 4,
                    x: 2,
                    y: 2
                )
            
            // Thumb
            HStack {
                if isOn {
                    Spacer()
                }
                
                Circle()
                    .fill(AppColorScheme.cardBackground)
                    .frame(width: height - 4, height: height - 4)
                    .shadow(
                        color: AppColorScheme.shadowDark.opacity(0.8),
                        radius: 2,
                        x: -1,
                        y: -1
                    )
                    .shadow(
                        color: AppColorScheme.shadowLight.opacity(0.6),
                        radius: 2,
                        x: 1,
                        y: 1
                    )
                
                if !isOn {
                    Spacer()
                }
            }
            .padding(.horizontal, 2)
        }
        .frame(width: width, height: height)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                isOn.toggle()
            }
        }
    }
}
