import UIKit
import WordPressShared
import Gridicons

@objc protocol ReaderCommentCellDelegate: WPRichContentViewDelegate {
    func cell(_ cell: ReaderCommentCell, didTapAuthor comment: Comment)
    func cell(_ cell: ReaderCommentCell, didTapLike comment: Comment)
    func cell(_ cell: ReaderCommentCell, didTapReply comment: Comment)
}

class ReaderCommentCell: UITableViewCell {
    struct Constants {
        // Because a stackview is managing layout we tweak text insets to fine tune things.
        // Insets:
        // Top 2: Just a bit of vertical padding so the text isn't too close to the label above.
        // Left -4: So the left edge of the text matches the left edge of the other views.
        // Bottom -16: Removes some of the padding normally added to the bottom of a textview.
        static let textViewInsets = UIEdgeInsets(top: 2, left: -4, bottom: -16, right: 0)
        static let buttonSize = CGSize(width: 20, height: 20)
    }

    @objc var enableLoggedInFeatures = false

    @IBOutlet var parentStackView: UIStackView!
    @IBOutlet var avatarImageView: UIImageView!
    @IBOutlet var authorButton: UIButton!
    @IBOutlet var timeLabel: LongPressGestureLabel!
    @IBOutlet var replyButton: UIButton!
    @IBOutlet var likeButton: UIButton!
    @IBOutlet var actionBar: UIStackView!
    @IBOutlet var leadingContentConstraint: NSLayoutConstraint!

    private let textView: WPRichContentView = {
        let newTextView = WPRichContentView(frame: .zero, textContainer: nil)
        newTextView.isScrollEnabled = false
        newTextView.isEditable = false
        newTextView.translatesAutoresizingMaskIntoConstraints = false

        return newTextView
    }()

    @objc weak var delegate: ReaderCommentCellDelegate? {
        didSet {
            textView.delegate = delegate
        }
    }

    @objc var comment: Comment?

    @objc var attributedString: NSAttributedString?

    @objc var showReply: Bool {
        get {
            if let comment = comment, let post = comment.post as? ReaderPost {
                return post.commentsOpen && enableLoggedInFeatures
            }
            return false
        }
    }

    override var indentationLevel: Int {
        didSet {
            updateLeadingContentConstraint()
        }
    }

    override var indentationWidth: CGFloat {
        didSet {
            updateLeadingContentConstraint()
        }
    }

    /// onTimeStampLongPress: Executed whenever the user long press on the time label
    ///
    @objc var onTimeStampLongPress: (() -> Void)?

    // MARK: - Lifecycle Methods

    override func awakeFromNib() {
        super.awakeFromNib()

        setupContentView()
        setupReplyButton()
        setupLikeButton()
        applyStyles()
    }


    // MARK: = Setup

    @objc func applyStyles() {
        WPStyleGuide.applyReaderCardSiteButtonStyle(authorButton)
        WPStyleGuide.applyReaderCardBylineLabelStyle(timeLabel)

        authorButton.titleLabel?.lineBreakMode = .byTruncatingTail

        textView.textContainerInset = Constants.textViewInsets

        let backgroundView = UIView()
        backgroundView.backgroundColor = .primary(shade: .shade0)
        selectedBackgroundView = backgroundView
    }

    func setupContentView() {
        // This method should be called exactly once.
        assert(textView.superview == nil)

        parentStackView.insertArrangedSubview(textView, at: 1)
    }

    @objc func setupReplyButton() {
        let icon = Gridicon.iconOfType(.reply, withSize: Constants.buttonSize).rotate180Degrees()
        replyButton.setImage(icon, for: .normal)
        replyButton.setImage(icon, for: .highlighted)

        let title = NSLocalizedString("Reply", comment: "Verb. Title of the Reader comments screen reply button. Tapping the button sends a reply to a comment or post.")
        replyButton.setTitle(title, for: .normal)

        WPStyleGuide.applyReaderActionButtonStyle(replyButton)
    }


    @objc func setupLikeButton() {
        let size = Constants.buttonSize
        let star = Gridicon.iconOfType(.star, withSize: size)
        let starOutline = Gridicon.iconOfType(.starOutline, withSize: size)

        likeButton.setImage(starOutline, for: .normal)
        likeButton.setImage(star, for: .highlighted)
        likeButton.setImage(star, for: .selected)
        likeButton.setImage(star, for: [.selected, .highlighted])

        WPStyleGuide.applyReaderActionButtonStyle(likeButton)
    }

    // MARK: - Configuration


    @objc func configureCell(comment: Comment, attributedString: NSAttributedString) {
        self.comment = comment
        self.attributedString = attributedString

        configureAvatar()
        configureAuthorButton()
        configureTime()
        configureText()
        configureActionBar()
    }


    @objc func configureAvatar() {
        guard let comment = comment else {
            return
        }

        let placeholder = UIImage(named: "gravatar")
        if let url = comment.avatarURLForDisplay() {
            avatarImageView.downloadImage(from: url, placeholderImage: placeholder)
        } else {
            avatarImageView.image = placeholder
        }
    }


    @objc func configureAuthorButton() {
        guard let comment = comment else {
            return
        }

        authorButton.isEnabled = true
        authorButton.setTitle(comment.authorForDisplay(), for: .normal)
        authorButton.setTitleColor(.primaryLight, for: .highlighted)
        authorButton.setTitleColor(.neutral(shade: .shade60), for: .disabled)

        if comment.authorIsPostAuthor() {
            authorButton.setTitleColor(.accent, for: .normal)
        } else if comment.hasAuthorUrl() {
            authorButton.setTitleColor(.primary, for: .normal)
        } else {
            authorButton.isEnabled = false
        }
    }


    @objc func configureTime() {
        guard let comment = comment else {
            return
        }

        timeLabel.text = (comment.dateForDisplay() as NSDate).mediumString()
        timeLabel.isUserInteractionEnabled = true
        timeLabel.longPressAction = { [weak self] in self?.onTimeStampLongPress?() }
    }


    @objc func configureText() {
        guard let comment = comment, let attributedString = attributedString else {
            return
        }

        textView.isPrivate = comment.isPrivateContent()
        // Use `content` vs `contentForDisplay`. Hierarchcial comments are already
        // correctly formatted during the sync process.
        textView.attributedText = attributedString
    }


    @objc func configureActionBar() {
        guard let comment = comment else {
            return
        }

        actionBar.isHidden = !enableLoggedInFeatures
        replyButton.isHidden = !showReply

        var title = NSLocalizedString("Like", comment: "Verb. Button title. Tap to like a commnet")
        let count = comment.numberOfLikes().intValue
        if count == 1 {
            title = "\(count) \(title)"
        } else if count > 1 {
            title = NSLocalizedString("Likes", comment: "Noun. Button title.  Tap to like a comment.")
            title = "\(count) \(title)"
        }
        likeButton.setTitle(title, for: .normal)
        likeButton.isSelected = comment.isLiked
    }


    @objc func updateLeadingContentConstraint() {
        leadingContentConstraint.constant = CGFloat(indentationLevel) * indentationWidth
    }


    @objc func ensureTextViewLayout() {
        textView.updateLayoutForAttachments()
    }


    // MARK: - Actions


    @IBAction func handleAuthorTapped(sender: UIButton) {
        guard let comment = comment else {
            return
        }
        delegate?.cell(self, didTapAuthor: comment)
    }


    @IBAction func handleReplyTapped(sender: UIButton) {
        guard let comment = comment else {
            return
        }
        delegate?.cell(self, didTapReply: comment)
    }


    @IBAction func handleLikeTapped(sender: UIButton) {
        guard let comment = comment else {
            return
        }
        delegate?.cell(self, didTapLike: comment)
    }

}
