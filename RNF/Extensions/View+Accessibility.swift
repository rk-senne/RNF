import SwiftUI

extension View {
    /// Ensures a minimum 44x44pt tap target per Apple HIG.
    func minimumTapTarget() -> some View {
        self.frame(minWidth: 44, minHeight: 44)
    }
}
