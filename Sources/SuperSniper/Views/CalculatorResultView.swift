import SwiftUI

struct CalculatorResultView: View {
    let result: MathManager.MathResult
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // Left Side - Expression
                VStack(spacing: 12) {
                    Text(result.expression)
                        .font(.system(size: 32, weight: .semibold, design: .default))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    Text("Expression")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(6)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                
                // Arrow Divider
                ZStack {
                    Divider()
                        .frame(width: 1)
                        .background(Color.secondary.opacity(0.2))
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                        .padding(8)
                        .background(Color(NSColor.windowBackgroundColor))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                }
                .frame(width: 40)
                
                // Right Side - Result
                VStack(spacing: 12) {
                    Text(result.formattedResult)
                        .font(.system(size: 32, weight: .bold, design: .default))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    Text(result.spelledOut)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(6)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            }
            .background(Color.black.opacity(0.15))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
    }
}
