import SwiftUI

// P20-EXP-04b: Discipline Card Renderer — converts card view to shareable image
struct DisciplineCardRenderer {
    @MainActor
    static func renderImage(card: DisciplineCardView) -> UIImage? {
        let renderer = ImageRenderer(content: card.frame(width: 720, height: 1040))
        renderer.scale = 2.0
        return renderer.uiImage
    }
}
