import UIKit

final class NumberButton: UIControl {
    override var isSelected: Bool {
        didSet {
            makeAppearance()
        }
    }

    override var isHighlighted: Bool {
        didSet {
            makeAppearance()
        }
    }

    private let imageView = UIImageView()
    init() {
        super.init(frame: .zero)
        drawSelf()
        makeAppearance()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func drawSelf() {
    }

    private func makeAppearance() {
        print("isHighlighted: \(isHighlighted), isSelected: \(isEnabled)")
        backgroundColor = isSelected ? .white : isHighlighted ? .hex("#f3c996") : .hex("#f2a33a")
    }
}
