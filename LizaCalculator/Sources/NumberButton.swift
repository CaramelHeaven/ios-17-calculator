import UIKit

final class NumberButton: UIControl {
    /// Instrument - AC, +/-, %
    enum SelfType {
        case number, operation, instrument
        var highlightedColor: UIColor {
            switch self {
            case .number: .hex("#5c5a5d")
            case .operation: .hex("#C3B4E0")
            case .instrument: .hex("#d0ced1")
            }
        }

        var defaultColor: UIColor {
            switch self {
            case .number: .hex("#3a3a3c")
            case .operation: .hex("#B6A3D6")
            case .instrument: .hex("#8f8f94")
            }
        }

        var defaultTextColor: UIColor {
            switch self {
            case .number, .operation: .white
            case .instrument: .black
            }
        }

        var selectedTextColor: UIColor {
            switch self {
            case .number, .instrument: .red
            case .operation: .hex("#8E79B7")
            }
        }

        var selectedBackgroundColor: UIColor {
            switch self {
            case .operation: .hex("#D2C7E8")
            case .number, .instrument: .white
            }
        }
    }

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

    private let type: SelfType
    let label = UILabel()

    init(_ type: SelfType) {
        self.type = type
        super.init(frame: .zero)
        drawSelf()
        makeConstraints()
        makeAppearance()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func drawSelf() {
        label.text = "1"
        label.textColor = .white
        label.font = .systemFont(ofSize: 40)
        addSubview(label)
    }

    private func makeConstraints() {
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    private func makeAppearance() {
        backgroundColor = isSelected
            ? type.selectedBackgroundColor
            : isHighlighted ? type.highlightedColor : type.defaultColor
        label.textColor = isSelected ? type.selectedTextColor : type.defaultTextColor
    }
}
