/*
 MIT License
 
 Copyright (c) 2017 MessageKit
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import UIKit

open class MessageInputBar: UIView {
    
    public enum UIStackViewPosition {
        case left, right, bottom
    }
    
    // MARK: - Properties
    
    open weak var delegate: MessageInputBarDelegate?
    
    /// A background view that adds a blur effect. Shown when 'isTransparent' is set to TRUE. Hidden by default.
    open let blurView: UIView = {
        let blurEffect = UIBlurEffect(style: .extraLight)
        let view = UIVisualEffectView(effect: blurEffect)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    /// When set to true, the blurView in the background is shown and the backgroundColor is set to .clear. Default is FALSE
    open var isTranslucent: Bool = false {
        didSet {
            blurView.isHidden = !isTranslucent
            backgroundColor = UIColor(red: 94/255, green: 103/255, blue: 109/255, alpha: 1)
        }
    }
    
    /// A boarder line anchored to the top of the view
    open let separatorLine: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    open let leftStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.translatesAutoresizingMaskIntoConstraints = false
        view.distribution = .fill
        view.alignment = .fill
        view.spacing = 15
        return view
    }()
    
    open let rightStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.translatesAutoresizingMaskIntoConstraints = false
        view.distribution = .fill
        view.alignment = .fill
        view.spacing = 15
        return view
    }()
    
    open let bottomStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.translatesAutoresizingMaskIntoConstraints = false
        view.distribution = .fill
        view.alignment = .fill
        view.spacing = 15
        return view
    }()
    
    open lazy var inputTextView: InputTextView = { [weak self] in
        let textView = InputTextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.messageInputBar = self
        return textView
    }()
    
    /// The padding around the textView that separates it from the stackViews
    open var textViewPadding: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8) {
        didSet {
            textViewLayoutSet?.bottom?.constant = -textViewPadding.bottom
            textViewLayoutSet?.left?.constant = textViewPadding.left
            textViewLayoutSet?.right?.constant = -textViewPadding.right
            bottomStackViewLayoutSet?.top?.constant = textViewPadding.bottom
        }
    }

    open var sendButton: InputBarButtonItem = {
        return InputBarButtonItem()
            .configure {
                $0.setSize(CGSize(width: 52, height: 28), animated: false)
                $0.isEnabled = false
                $0.title = "Send"
                $0.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
            }.onTouchUpInside {
                $0.messageInputBar?.didSelectSendButton()
        }
    }()
    
    open var sendButtonImage: InputBarButtonItem = {
        return InputBarButtonItem().configure {
            $0.setSize(CGSize(width: 26, height: 26), animated: false)
            $0.image = UIImage(named:"ic_up-1")!
            $0.isHidden = true
            }.onTouchUpInside {
                $0.messageInputBar?.didSelectSendButton()
        }
    }()
    
    open var sendMediaButton: InputBarButtonItem = {
        return InputBarButtonItem().configure {
            $0.setSize(CGSize(width: 19.2, height: 21), animated: false)
            $0.image =  UIImage(named:"ic_camera")!
            }.onTouchUpInside {
                $0.messageInputBar?.didSelectMediaButton()
        }
    }()

    open var sendAudioButton: InputBarButtonItem = {
        return InputBarButtonItem().configure {
            
            let image = UIImage(named:"microphone")!.withRenderingMode(.alwaysTemplate)
            $0.tintColor = .white
            $0.image = image
        
            }.onTouchDownInside {
                $0.messageInputBar?.didSelectAudioButton($0)
            }.onTouchUpInside {
               $0.messageInputBar?.didLeaveAudioButton($0)
        }
    }()
    
    /// The anchor contants used by the UIStackViews and InputTextView to create padding within the InputBarAccessoryView
    open var padding: UIEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12) {
        didSet {
            updateViewContraints()
        }
    }
    
    override open var intrinsicContentSize: CGSize {
        let maxSize = CGSize(width: inputTextView.bounds.width, height: .greatestFiniteMagnitude)
        let sizeToFit = inputTextView.sizeThatFits(maxSize)
        var heightToFit = sizeToFit.height.rounded() + padding.top + padding.bottom

        if heightToFit >= maxHeight {
            inputTextView.isScrollEnabled = true
            heightToFit = maxHeight
        } else {
            inputTextView.isScrollEnabled = false
            inputTextView.invalidateIntrinsicContentSize()
        }

        let size = CGSize(width: bounds.width, height: heightToFit)

        if previousIntrinsicContentSize != size {
            delegate?.messageInputBar(self, didChangeIntrinsicContentTo: size)
        }

        previousIntrinsicContentSize = size
        return size
    }
    
    /// The maximum intrinsicContentSize height. When reached the delegate 'didChangeIntrinsicContentTo' will be called.
    open var maxHeight: CGFloat = UIScreen.main.bounds.height / 3 {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    /// The fixed widthAnchor constant of the leftStackView
    private(set) var leftStackViewWidthContant: CGFloat = 52 {
        didSet {
            leftStackViewLayoutSet?.width?.constant = leftStackViewWidthContant
        }
    }
    
    /// The fixed widthAnchor constant of the rightStackView
    private(set) var rightStackViewWidthContant: CGFloat = 52 {
        didSet {
            rightStackViewLayoutSet?.width?.constant = rightStackViewWidthContant
        }
    }
    
    /// The InputBarItems held in the leftStackView
    private(set) var leftStackViewItems: [InputBarButtonItem] = []
    
    /// The InputBarItems held in the rightStackView
    private(set) var rightStackViewItems: [InputBarButtonItem] = []
    
    /// The InputBarItems held in the bottomStackView
    private(set) var bottomStackViewItems: [InputBarButtonItem] = []
    
    /// The InputBarItems held to make use of their hooks but they are not automatically added to a UIStackView
    open var nonStackViewItems: [InputBarButtonItem] = []
    
    /// Returns a flatMap of all the items in each of the UIStackViews
    public var items: [InputBarButtonItem] {
        return [leftStackViewItems, rightStackViewItems, bottomStackViewItems, nonStackViewItems].flatMap { $0 }
    }
    
    // MARK: - Auto-Layout Management
    
    private var textViewLayoutSet: NSLayoutConstraintSet?
    private var leftStackViewLayoutSet: NSLayoutConstraintSet?
    private var rightStackViewLayoutSet: NSLayoutConstraintSet?
    private var bottomStackViewLayoutSet: NSLayoutConstraintSet?
    private var previousIntrinsicContentSize: CGSize?
    
    // MARK: - Initialization
    
    public convenience init() {
        self.init(frame: .zero)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    
    open func setup() {
        
        backgroundColor =  .lightGray
        autoresizingMask = [.flexibleHeight]
        
        setupSubviews()
        setupConstraints()
        setupObservers()
    }
    
    private func setupSubviews() {
        
        addSubview(blurView)
        addSubview(inputTextView)
        addSubview(leftStackView)
        addSubview(rightStackView)
        addSubview(bottomStackView)
        addSubview(separatorLine)
        setStackViewItems([sendButtonImage, sendAudioButton], forStack: .right, animated: false)
        setStackViewItems([sendMediaButton], forStack: .left, animated: false)
    }
    
    private func setupConstraints() {
        
        separatorLine.addConstraints(topAnchor, left: leftAnchor, right: rightAnchor, heightConstant: 0.5)
        blurView.fillSuperview()
        
        textViewLayoutSet = NSLayoutConstraintSet(
            top:    inputTextView.topAnchor.constraint(equalTo: topAnchor, constant: padding.top),
            bottom: inputTextView.bottomAnchor.constraint(equalTo: bottomStackView.topAnchor, constant: -textViewPadding.bottom),
            left:   inputTextView.leftAnchor.constraint(equalTo: leftStackView.rightAnchor, constant: textViewPadding.left),
            right:  inputTextView.rightAnchor.constraint(equalTo: rightStackView.leftAnchor, constant: -textViewPadding.right)
            ).activate()
        
        leftStackViewLayoutSet = NSLayoutConstraintSet(
            top:    inputTextView.topAnchor.constraint(equalTo: topAnchor, constant: padding.top),
            bottom: leftStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -11),
            left:   leftStackView.leftAnchor.constraint(equalTo: leftAnchor, constant: padding.left),
            width:  leftStackView.widthAnchor.constraint(equalToConstant: leftStackViewWidthContant)
            ).activate()
        
        rightStackViewLayoutSet = NSLayoutConstraintSet(
            top:    inputTextView.topAnchor.constraint(equalTo: topAnchor, constant: padding.top),
            bottom: rightStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -9),
            right:  rightStackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -padding.right),
            width:  rightStackView.widthAnchor.constraint(equalToConstant: rightStackViewWidthContant)
            ).activate()
        
        bottomStackViewLayoutSet = NSLayoutConstraintSet(
            top:    bottomStackView.topAnchor.constraint(equalTo: inputTextView.bottomAnchor),
            bottom: bottomStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding.bottom),
            left:   bottomStackView.leftAnchor.constraint(equalTo: leftAnchor, constant: padding.left),
            right:  bottomStackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -padding.right)
            ).activate()
        
        self.heightAnchor.constraint(equalToConstant: 44)
    }
    
    private func updateViewContraints() {
        
        textViewLayoutSet?.top?.constant = padding.top
        leftStackViewLayoutSet?.top?.constant = padding.top
        leftStackViewLayoutSet?.left?.constant = padding.left
        rightStackViewLayoutSet?.top?.constant = padding.top
        rightStackViewLayoutSet?.right?.constant = -padding.right
        bottomStackViewLayoutSet?.left?.constant = padding.left
        bottomStackViewLayoutSet?.right?.constant = -padding.right
        bottomStackViewLayoutSet?.bottom?.constant = -padding.bottom
    }
    
    private func setupObservers() {
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MessageInputBar.orientationDidChange),
                                               name: .UIDeviceOrientationDidChange, object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MessageInputBar.textViewDidChange),
                                               name: .UITextViewTextDidChange, object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MessageInputBar.textViewDidBeginEditing),
                                               name: .UITextViewTextDidBeginEditing, object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MessageInputBar.textViewDidEndEditing),
                                               name: .UITextViewTextDidEndEditing, object: nil)
    }
    
    // MARK: - Layout Helper Methods
    
    /// Layout the given UIStackView's
    ///
    /// - Parameter positions: The UIStackView's to layout
    public func layoutStackViews(_ positions: [UIStackViewPosition] = [.left, .right, .bottom]) {
        
        for position in positions {
            switch position {
            case .left:
                leftStackView.setNeedsLayout()
                leftStackView.layoutIfNeeded()
            case .right:
                rightStackView.setNeedsLayout()
                rightStackView.layoutIfNeeded()
            case .bottom:
                bottomStackView.setNeedsLayout()
                bottomStackView.layoutIfNeeded()
            }
        }
    }
    
    /// Performs layout changes over the main thread
    ///
    /// - Parameters:
    ///   - animated: If the layout should be animated
    ///   - animations: Code
    internal func performLayout(_ animated: Bool, _ animations: @escaping () -> Void) {
        
        textViewLayoutSet?.deactivate()
        leftStackViewLayoutSet?.deactivate()
        rightStackViewLayoutSet?.deactivate()
        bottomStackViewLayoutSet?.deactivate()
        if animated {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.3, animations: animations)
            }
        } else {
            UIView.performWithoutAnimation { animations() }
        }
        textViewLayoutSet?.activate()
        leftStackViewLayoutSet?.activate()
        rightStackViewLayoutSet?.activate()
        bottomStackViewLayoutSet?.activate()
    }
    
    // MARK: - UIStackView InputBarItem Methods
    
    /// Removes all of the arranged subviews from the UIStackView and adds the given items. Sets the inputBarAccessoryView property of the InputBarButtonItem
    ///
    /// - Parameters:
    ///   - items: New UIStackView arranged views
    ///   - position: The targeted UIStackView
    ///   - animated: If the layout should be animated
    open func setStackViewItems(_ items: [InputBarButtonItem], forStack position: UIStackViewPosition, animated: Bool) {
        
        func setNewItems() {
            switch position {
            case .left:
                leftStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
                leftStackViewItems = items
                leftStackViewItems.forEach {
                    $0.messageInputBar = self
                    $0.parentStackViewPosition = position
                    leftStackView.addArrangedSubview($0)
                }
                leftStackView.layoutIfNeeded()
            case .right:
                rightStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
                rightStackViewItems = items
                rightStackViewItems.forEach {
                    $0.messageInputBar = self
                    $0.parentStackViewPosition = position
                    rightStackView.addArrangedSubview($0)
                }
                rightStackView.layoutIfNeeded()
            case .bottom:
                bottomStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
                bottomStackViewItems = items
                bottomStackViewItems.forEach {
                    $0.messageInputBar = self
                    $0.parentStackViewPosition = position
                    bottomStackView.addArrangedSubview($0)
                }
                bottomStackView.layoutIfNeeded()
            }
        }
        
        performLayout(animated) {
            setNewItems()
        }
    }
    
    /// Sets the leftStackViewWidthConstant
    ///
    /// - Parameters:
    ///   - newValue: New widthAnchor constant
    ///   - animated: If the layout should be animated
    open func setLeftStackViewWidthConstant(to newValue: CGFloat, animated: Bool) {
        performLayout(animated) {
            self.leftStackViewWidthContant = newValue
            self.layoutStackViews([.left])
            self.layoutIfNeeded()
        }
    }
    
    /// Sets the rightStackViewWidthConstant
    ///
    /// - Parameters:
    ///   - newValue: New widthAnchor constant
    ///   - animated: If the layout should be animated
    open func setRightStackViewWidthConstant(to newValue: CGFloat, animated: Bool) {
        performLayout(animated) {
            self.rightStackViewWidthContant = newValue
            self.layoutStackViews([.right])
            self.layoutIfNeeded()
        }
    }
    
    // MARK: - Notifications/Hooks
    
  @objc open func orientationDidChange() {
        invalidateIntrinsicContentSize()
    }
    
  @objc open func textViewDidChange() {
        let trimmedText = inputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)

        // sendButton.isEnabled = !trimmedText.isEmpty
        sendButtonImage.isHidden = trimmedText.isEmpty
        sendAudioButton.isHidden = !sendButtonImage.isHidden
        inputTextView.placeholderLabel.isHidden = !inputTextView.text.isEmpty

        items.forEach { $0.textViewDidChangeAction(with: inputTextView) }

        delegate?.messageInputBar(self, textViewTextDidChangeTo: trimmedText)
        invalidateIntrinsicContentSize()
    }
    
  @objc open func textViewDidBeginEditing() {
        self.items.forEach { $0.keyboardEditingBeginsAction() }
    }
    
  @objc open func textViewDidEndEditing() {
        self.items.forEach { $0.keyboardEditingEndsAction() }
    }
    
    // MARK: - User Actions
    
    open func didSelectSendButton() {
        delegate?.messageInputBar(self, didPressSendButtonWith: inputTextView.text)
        textViewDidChange()
    }
    
    open func didSelectMediaButton() {
        delegate?.messageInputBar(didPressSendMediaButton: self)
    }
    
    //MARK: audio user actions
    
    private var inputOriginFrame: CGFloat = 0
    private var leftStackViewOriginFrame: CGFloat = 0
    private var rightStackViewOriginFrame: CGFloat = 0
    private var timer: Timer!
    private var recordingTimeValue = 0

    
    private func getPrettyTime(seconds:Int) -> String{
        
       let (_,m,s) = (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
        
        return "\(m):\(s)"
        
    }
    
    @objc func recordingTime(_ timer: Timer){
        
        self.recordingTimeValue += 1
        let label = timer.userInfo as! UILabel
        label.text = "Grabando: \(self.getPrettyTime(seconds: self.recordingTimeValue))"
        
    }
    
    open func didSelectAudioButton(_ button: InputBarButtonItem) {
        print("DidSelectAudioButton")
        
        let view = UIView(frame: self.inputTextView.frame)
        let label = UILabel(frame: CGRect(x: -60, y: 0, width: 200, height: 20))
        label.text = "Preparando grabación"
        label.font = UIFont.boldSystemFont(ofSize: 14)
        view.addSubview(label)
        view.alpha = 0
        self.inputOriginFrame = self.inputTextView.frame.origin.y
        self.leftStackView.addSubview(view)
        
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.recordingTime(_:)), userInfo: label, repeats: true)

        
        UIView.animate(withDuration: 1) {
            button.tintColor = .red
            
            self.leftStackView.subviews.first?.alpha = 0
            self.inputTextView.alpha = 0
            view.alpha = 1
            
        }
        self.delegate?.messageInputBar(didSelectAudioMediaButton: self)
    }
    
    open func didLeaveAudioButton(_ button: InputBarButtonItem) {
        print("DidLeaveAudioButton")
        
        self.timer.invalidate()

        UIView.animate(withDuration: 1) {
            
            self.leftStackView.subviews.first?.alpha = 1
            self.inputTextView.alpha = 1
            self.leftStackView.subviews.last?.removeFromSuperview()
            button.tintColor = .white
        }
        self.delegate?.messageInputBar(didUnselectedAudioMediaButton: self,audioDuration:self.recordingTimeValue)
        self.recordingTimeValue = 0

    }
}

extension MessageInputBar {
    
    func createCopy() -> MessageInputBar? {
        return NSKeyedUnarchiver.unarchiveObject(with: NSKeyedArchiver.archivedData(withRootObject: self)) as? MessageInputBar
    }
}