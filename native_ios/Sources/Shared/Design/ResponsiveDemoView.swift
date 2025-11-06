#if os(iOS)
import SwiftUI

@available(iOS 17, *)
struct ResponsiveDemoView: View {
    var body: some View {
        Text("Responsive demo placeholder")
            .font(.title3)
            .padding()
    }
}

#Preview {
    ResponsiveDemoView()
}

#endif
