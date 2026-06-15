import SwiftUI

struct TestView: View {
    var body: some View {
        Text("Test")
            .glassEffect(in: RoundedRectangle(cornerRadius: 16))
    }
}
