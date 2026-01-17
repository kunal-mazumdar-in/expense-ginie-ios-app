import SwiftUI

struct ToastView: View {
    let message: String
    let isError: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(isError ? .orange : .green)
            
            Text(message)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
        }
        .padding(.horizontal, 16)
    }
}

// Toast modifier for easy use
struct ToastModifier: ViewModifier {
    @Binding var message: String?
    var isError: Bool
    var duration: TimeInterval
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let message = message {
                    ToastView(message: message, isError: isError)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 8)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    self.message = nil
                                }
                            }
                        }
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: message)
    }
}

extension View {
    func toast(message: Binding<String?>, isError: Bool = false, duration: TimeInterval = 3.0) -> some View {
        modifier(ToastModifier(message: message, isError: isError, duration: duration))
    }
}

#Preview {
    VStack {
        ToastView(message: "5 expenses added to review", isError: false)
        ToastView(message: "Failed to parse PDF", isError: true)
    }
    .padding()
}

