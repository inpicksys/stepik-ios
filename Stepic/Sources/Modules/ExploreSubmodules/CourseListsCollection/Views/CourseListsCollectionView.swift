import SnapKit
import UIKit

final class CourseListsCollectionView: UIView {
    enum Appearance {
        static let headerViewInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        static let skeletonViewHeight: CGFloat = 149
    }

    private lazy var headerView: ExploreBlockHeaderView = {
        let view = ExploreBlockHeaderView(
            appearance: CourseListColorMode.light.exploreBlockHeaderViewAppearance
        )
        view.titleText = NSLocalizedString("RecommendationsExplore", comment: "")
        view.summaryText = NSLocalizedString("RecommendationsExploreDescription", comment: "")
        view.shouldShowAllButton = false
        return view
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()

    override var intrinsicContentSize: CGSize {
        let headerViewHeight = self.headerView.intrinsicContentSize.height
        let headerViewPadding = Appearance.headerViewInsets.top
            + Appearance.headerViewInsets.bottom
        let contentStackViewHeight = self.contentStackView
            .systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            .height
        return CGSize(
            width: UIView.noIntrinsicMetric,
            height: headerViewHeight + headerViewPadding + contentStackViewHeight
        )
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.setupView()
        self.addSubviews()
        self.makeConstraints()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.invalidateIntrinsicContentSize()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addBlockView(_ view: UIView) {
        self.contentStackView.addArrangedSubview(view)
    }

    func removeAllBlocks() {
        self.contentStackView.removeAllArrangedSubviews()
    }

    func showLoading() {
        let fakeView = UIView()
        fakeView.translatesAutoresizingMaskIntoConstraints = false
        fakeView.snp.makeConstraints { make in
            make.height.equalTo(Appearance.skeletonViewHeight)
        }
        self.contentStackView.addArrangedSubview(fakeView)

        fakeView.skeleton.viewBuilder = {
            CourseListsCollectionSkeletonView()
        }
        fakeView.skeleton.show()
    }

    func hideLoading() {
        self.contentStackView.removeAllArrangedSubviews()
        self.contentStackView.skeleton.hide()
    }
}

extension CourseListsCollectionView: ProgrammaticallyInitializableViewProtocol {
    func setupView() {
        self.backgroundColor = .stepikBackground
    }

    func addSubviews() {
        self.addSubview(self.headerView)
        self.addSubview(self.contentStackView)
    }

    func makeConstraints() {
        self.headerView.translatesAutoresizingMaskIntoConstraints = false
        self.headerView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview().offset(Appearance.headerViewInsets.left)
            make.trailing.equalToSuperview().offset(-Appearance.headerViewInsets.right)
        }

        self.contentStackView.translatesAutoresizingMaskIntoConstraints = false
        self.contentStackView.snp.makeConstraints { make in
            make.top.equalTo(self.headerView.snp.bottom)
            make.leading.trailing.equalToSuperview()
        }
    }
}
