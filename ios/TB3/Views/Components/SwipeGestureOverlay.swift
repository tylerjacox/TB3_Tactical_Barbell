// TB3 iOS — UIKit swipe gesture overlay for tab navigation
// Uses UISwipeGestureRecognizer which works alongside ScrollView/List/Form

import SwiftUI
import UIKit

struct SwipeGestureOverlay: UIViewRepresentable {
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        let leftSwipe = UISwipeGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleSwipe(_:)))
        leftSwipe.direction = .left
        leftSwipe.delegate = context.coordinator
        view.addGestureRecognizer(leftSwipe)

        let rightSwipe = UISwipeGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleSwipe(_:)))
        rightSwipe.direction = .right
        rightSwipe.delegate = context.coordinator
        view.addGestureRecognizer(rightSwipe)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onSwipeLeft = onSwipeLeft
        context.coordinator.onSwipeRight = onSwipeRight
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onSwipeLeft: onSwipeLeft, onSwipeRight: onSwipeRight)
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onSwipeLeft: () -> Void
        var onSwipeRight: () -> Void

        init(onSwipeLeft: @escaping () -> Void, onSwipeRight: @escaping () -> Void) {
            self.onSwipeLeft = onSwipeLeft
            self.onSwipeRight = onSwipeRight
        }

        @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
            switch gesture.direction {
            case .left:
                onSwipeLeft()
            case .right:
                onSwipeRight()
            default:
                break
            }
        }

        // Allow swipe gestures to work simultaneously with scroll views
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
    }
}
