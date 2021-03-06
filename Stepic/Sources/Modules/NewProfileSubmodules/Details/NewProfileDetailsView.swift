import Atributika
import SnapKit
import UIKit

protocol NewProfileDetailsViewDelegate: AnyObject {
    func newProfileDetailsView(_ view: NewProfileDetailsView, didOpenURL url: URL)
    func newProfileDetailsView(_ view: NewProfileDetailsView, didSelectUserID userID: User.IdType)
}

extension NewProfileDetailsView {
    struct Appearance {
        let labelFont = UIFont.systemFont(ofSize: 17, weight: .regular)
        let labelTextColor = UIColor.stepikSystemPrimaryText

        let separatorHeight: CGFloat = 0.5
        let separatorColor = UIColor.stepikSeparator
        let separatorInsets = LayoutInsets(top: 16, right: 20)

        let userIDButtonFont = UIFont.systemFont(ofSize: 15, weight: .regular)
        let userIDButtonTextColor = UIColor.stepikSystemSecondaryText
        let userIDButtonInsets = LayoutInsets(top: 16, bottom: 16)
        let userIDButtonHeight: CGFloat = 18

        let backgroundColor = UIColor.stepikSecondaryGroupedBackground
    }
}

final class NewProfileDetailsView: UIView {
    let appearance: Appearance

    weak var delegate: NewProfileDetailsViewDelegate?

    private let htmlToAttributedStringConverter: HTMLToAttributedStringConverterProtocol

    private lazy var attributedLabel: AttributedLabel = {
        let label = AttributedLabel()
        label.numberOfLines = 0
        label.font = self.appearance.labelFont
        label.textColor = self.appearance.labelTextColor
        label.onClick = { [weak self] label, detection in
            guard let strongSelf = self else {
                return
            }

            switch detection.type {
            case .link(let url):
                strongSelf.delegate?.newProfileDetailsView(strongSelf, didOpenURL: url)
            case .tag(let tag):
                if tag.name == "a",
                   let href = tag.attributes["href"],
                   let url = URL(string: href) {
                    strongSelf.delegate?.newProfileDetailsView(strongSelf, didOpenURL: url)
                }
            default:
                break
            }
        }
        return label
    }()

    private lazy var separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = self.appearance.separatorColor
        return view
    }()

    private lazy var userIDButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = self.appearance.userIDButtonFont
        button.setTitleColor(self.appearance.userIDButtonTextColor, for: .normal)
        button.addTarget(self, action: #selector(self.userIDButtonClicked), for: .touchUpInside)
        return button
    }()

    private var userIDTopToSuperviewConstraint: Constraint?
    private var userIDTopToBottomOfSeparatorConstraint: Constraint?

    private var currentViewModel: NewProfileDetailsViewModel?

    override var intrinsicContentSize: CGSize {
        let attributedLabelHeight = self.attributedLabel.intrinsicContentSize.height
        let separatorHeightWithInsets = self.appearance.separatorInsets.top + self.appearance.separatorHeight
        let userIDButtonHeightWithInsets = self.appearance.userIDButtonInsets.top
            + self.appearance.userIDButtonHeight + self.appearance.userIDButtonInsets.bottom

        return CGSize(
            width: UIView.noIntrinsicMetric,
            height: attributedLabelHeight + separatorHeightWithInsets + userIDButtonHeightWithInsets
        )
    }

    init(
        frame: CGRect = .zero,
        appearance: Appearance = Appearance()
    ) {
        self.appearance = appearance
        self.htmlToAttributedStringConverter = HTMLToAttributedStringConverter(
            font: appearance.labelFont,
            tagTransformers: []
        )
        super.init(frame: frame)

        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(viewModel: NewProfileDetailsViewModel) {
        if let text = viewModel.profileDetailsText {
            self.attributedLabel.attributedText = self.htmlToAttributedStringConverter.convertToAttributedText(
                htmlString: text.trimmed()
            ) as? AttributedText
        } else {
            self.attributedLabel.attributedText = nil
        }

        let formattedUserID = viewModel.isOrganization
            ? "Organization ID: \(viewModel.userID)"
            : "User ID: \(viewModel.userID)"
        self.userIDButton.setTitle(formattedUserID, for: .normal)

        if self.attributedLabel.attributedText?.string.isEmpty ?? true {
            self.userIDTopToBottomOfSeparatorConstraint?.deactivate()
            self.userIDTopToSuperviewConstraint?.activate()
            self.separatorView.isHidden = true
        } else {
            self.userIDTopToBottomOfSeparatorConstraint?.activate()
            self.userIDTopToSuperviewConstraint?.deactivate()
            self.separatorView.isHidden = false
        }

        self.currentViewModel = viewModel
        self.invalidateIntrinsicContentSize()
    }

    @objc
    private func userIDButtonClicked() {
        if let lastViewModel = self.currentViewModel {
            self.delegate?.newProfileDetailsView(self, didSelectUserID: lastViewModel.userID)
        }
    }
}

extension NewProfileDetailsView: ProgrammaticallyInitializableViewProtocol {
    func setupView() {
        self.backgroundColor = self.appearance.backgroundColor
    }

    func addSubviews() {
        self.addSubview(self.attributedLabel)
        self.addSubview(self.separatorView)
        self.addSubview(self.userIDButton)
    }

    func makeConstraints() {
        self.attributedLabel.translatesAutoresizingMaskIntoConstraints = false
        self.attributedLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        self.separatorView.translatesAutoresizingMaskIntoConstraints = false
        self.separatorView.snp.makeConstraints { make in
            make.top
                .equalTo(self.attributedLabel.snp.bottom)
                .offset(self.appearance.separatorInsets.top)
            make.leading.equalToSuperview()
            make.trailing
                .equalToSuperview()
                .offset(self.appearance.separatorInsets.right)
            make.height.equalTo(self.appearance.separatorHeight)
        }

        self.userIDButton.translatesAutoresizingMaskIntoConstraints = false
        self.userIDButton.snp.makeConstraints { make in
            self.userIDTopToBottomOfSeparatorConstraint = make.top
                .equalTo(self.separatorView.snp.bottom)
                .offset(self.appearance.userIDButtonInsets.top)
                .constraint

            self.userIDTopToSuperviewConstraint = make.top.equalToSuperview().constraint
            self.userIDTopToSuperviewConstraint?.deactivate()

            make.bottom
                .equalToSuperview()
                .offset(-self.appearance.userIDButtonInsets.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(self.appearance.userIDButtonHeight)
        }
    }
}
