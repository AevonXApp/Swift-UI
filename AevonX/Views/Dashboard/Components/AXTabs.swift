
import SwiftUI

public struct AXTabs: View {
    let tabs: [String]
    @Binding var selectedTab: Int
    
    public init(tabs: [String], selectedTab: Binding<Int>) {
        self.tabs = tabs
        self._selectedTab = selectedTab
    }
    
    public var body: some View {
        HStack(spacing: AXSpacing.md) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tabs[index])
                            .font(AXTypography.subheadline)
                            .fontWeight(selectedTab == index ? .bold : .medium)
                            .foregroundColor(selectedTab == index ? .axTextPrimary : .axTextTertiary)
                        
                        // Underline
                        ZStack {
                            Capsule()
                                .fill(Color.clear)
                                .frame(height: 3)
                            
                            if selectedTab == index {
                                Capsule()
                                    .fill(Color.axAccentBlue)
                                    .frame(height: 3)
                                    .transition(.opacity.combined(with: .scale))
                            }
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
        }
    }
}
