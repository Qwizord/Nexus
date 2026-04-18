import SwiftUI
import UIKit

// MARK: - Barrel Carousel (Telegram-style cylinder scroll)
///
/// Horizontal UIKit UIScrollView that applies per-subview CATransform3D
/// on every scroll tick — rotates each card around Y with an X-arc offset
/// and Y-dip at the edges, producing a genuine cylinder/barrel effect
/// the way Telegram's archive-folders strip does.
///
/// - `data`     : items to render
/// - `spacing`  : gap between cards
/// - `hPadding` : left/right padding inside the scroll view
/// - `content`  : builds a SwiftUI view for each item
///
/// Each item is hosted via `UIHostingController` so you can use any SwiftUI view.
struct BarrelCarousel<Data: RandomAccessCollection, Content: View>: UIViewRepresentable
where Data.Element: Hashable {

    let data: Data
    var spacing: CGFloat = 10
    var hPadding: CGFloat = 20
    let content: (Data.Element) -> Content

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIScrollView {
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        scroll.delegate = context.coordinator
        scroll.backgroundColor = .clear
        scroll.clipsToBounds = false   // чтобы трансформы за краями не резало

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = spacing
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor .constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor,  constant: hPadding),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -hPadding),
            stack.topAnchor     .constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            stack.bottomAnchor  .constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            stack.heightAnchor  .constraint(equalTo: scroll.frameLayoutGuide.heightAnchor)
        ])

        // Добавляем все карточки через UIHostingController
        for item in data {
            let host = UIHostingController(rootView: content(item))
            host.view.backgroundColor = .clear
            if #available(iOS 16.0, *) {
                host.sizingOptions = [.intrinsicContentSize]
            }
            host.view.translatesAutoresizingMaskIntoConstraints = false
            stack.addArrangedSubview(host.view)
            context.coordinator.hosts.append(host)
        }

        context.coordinator.scroll = scroll
        context.coordinator.stack  = stack

        // Первое применение трансформаций после layout
        DispatchQueue.main.async {
            context.coordinator.applyTransforms()
        }
        return scroll
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        // Перерисовать после layout-pass
        DispatchQueue.main.async {
            context.coordinator.applyTransforms()
        }
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, UIScrollViewDelegate {
        weak var scroll: UIScrollView?
        weak var stack:  UIStackView?
        var hosts: [UIHostingController<Content>] = []

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            applyTransforms()
        }

        func scrollViewDidLayoutSubviews(_ scrollView: UIScrollView) {
            applyTransforms()
        }

        /// Вычисляет позицию каждой карточки относительно центра viewport
        /// и применяет CATransform3D: поворот Y + X-arc + Y-dip.
        func applyTransforms() {
            guard let scroll = scroll, let stack = stack,
                  scroll.bounds.width > 0 else { return }

            let viewportCenter = scroll.contentOffset.x + scroll.bounds.width / 2
            let halfW          = scroll.bounds.width / 2

            // Параметры цилиндра
            let maxAngleDeg: CGFloat = 55
            let maxAngleRad: CGFloat = maxAngleDeg * .pi / 180
            let radius:      CGFloat = 140
            let dipStrength: CGFloat = 22

            for view in stack.arrangedSubviews {
                // Центр карточки в координатах scroll.content
                let cardCenterX = view.convert(CGPoint(x: view.bounds.midX, y: 0),
                                               to: scroll).x + scroll.contentOffset.x
                let normalized  = max(-1.2, min(1.2, (cardCenterX - viewportCenter) / halfW))
                let angle       = normalized * maxAngleRad

                // X-arc: проекция линейной позиции на окружность
                let arcX = radius * sin(angle) - normalized * radius * maxAngleRad
                // Y-dip: карточки у краёв опускаются
                let dipY = (1 - cos(angle)) * dipStrength
                // Scale/opacity для глубины
                let focus    = 1 - abs(normalized)
                let scale    = 0.80 + 0.20 * focus
                let opacity  = 0.45 + 0.55 * focus

                var t = CATransform3DIdentity
                t.m34 = -1.0 / 650           // перспектива
                t = CATransform3DTranslate(t, arcX, dipY, 0)
                t = CATransform3DRotate(t, angle, 0, 1, 0)
                t = CATransform3DScale(t, scale, scale, 1)

                view.layer.transform = t
                view.layer.opacity   = Float(opacity)
                view.layer.zPosition = -abs(normalized) * 10   // центральная сверху
            }
        }
    }
}
