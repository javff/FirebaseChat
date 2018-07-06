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
import AVFoundation

open class AudioMessageView: UIView, AudioPlayerDelegate {

	enum PlayingState {
		case playing (CMTime)
		case paused
		case finished
	}

	// Properties

	private let buttonSize = CGSize(width: 35, height: 35)

	open lazy var playButtonView: PlayButtonView = {
		let playButtonView = PlayButtonView()
		playButtonView.frame.size = buttonSize
		return playButtonView
	}()

	open lazy var pauseButtonView: PauseButtonView = {
		let pauseButtonView = PauseButtonView()
		pauseButtonView.frame.size = buttonSize
		return pauseButtonView
	}()

	open lazy var buttonContainerView: UIView = {
		let buttonView = UIView()
		buttonView.frame.size = buttonSize
		return buttonView
	}()

	open weak var audioPlayer: AudioPlayer?
	open var avAsset: AVAsset?
	private var currentTime: CMTime?

	open let audioPlayerBackgroundColor = UIColor(red: 144.0/255.0, green: 224.0/255.0, blue: 149.0/255.0, alpha: 1.0)

	private var radius: CGFloat?

	var playerProgressSlider = AudioSlider(frame: CGRect(x: 64.0, y: 24.0, width: 206.0, height: 20.0))

	var progressWidth: CGFloat!
	var progressHeight: CGFloat {
		get {
			return self.playerProgressSlider.bounds.size.height
		}

		set (newHeight){
			self.playerProgressSlider.trackHeight = newHeight
		}
	}

	var progressColor: UIColor! {
		get {
			return self.playerProgressSlider.minimumTrackTintColor
		}

		set (newColor) {
			self.playerProgressSlider.minimumTrackTintColor = newColor
		}
	}

	var progressBackgroundColor: UIColor! {
		get {
			return self.playerProgressSlider.maximumTrackTintColor
		}

		set (newColor) {
			self.playerProgressSlider.maximumTrackTintColor = newColor
		}
	}

	var positionViewLeading: NSLayoutConstraint?

	private lazy var playButtonImage: UIImage = {
		return UIImage(named: "ic_up-1")!
	}()

	private lazy var pauseButtonImage: UIImage = {
		return UIImage(named: "ic_up-1")!
	}()


	// MARK: - Initializers
	override public init(frame: CGRect) {
		super.init(frame: frame)
		prepareView()
	}

	convenience public init() {
		self.init(frame: .zero)
	}

	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Internal methods

	internal func prepareView() {
		backgroundColor = audioPlayerBackgroundColor
		contentMode = .scaleAspectFill
		layer.masksToBounds = true
		clipsToBounds = true

		progressBackgroundColor = UIColor(white: 1.0, alpha: 0.5)
		playerProgressSlider.translatesAutoresizingMaskIntoConstraints = false
		playerProgressSlider.addTarget(self, action: #selector(self.sliderValueDidChange), for: .valueChanged)
		addSubview(playerProgressSlider)

		playButtonView.translatesAutoresizingMaskIntoConstraints = false
		pauseButtonView.translatesAutoresizingMaskIntoConstraints = false
		buttonContainerView.translatesAutoresizingMaskIntoConstraints = false

		showPlayButton()
		addSubview(buttonContainerView)
		let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.buttonAction(_:)))
		buttonContainerView.addGestureRecognizer(tapGesture)

		setupConstraints()

		setCorner(radius: nil)
	}

	internal func setupConstraints() {

		let margins = self.layoutMarginsGuide

		DispatchQueue.main.async { [weak self] in
			guard let `self` = self else { return }

			// buttonContainer
			let buttonContainerWidth = self.buttonContainerView.widthAnchor.constraint(equalToConstant: 35.0)
			let buttonContainerHeight = self.buttonContainerView.heightAnchor.constraint(equalToConstant: 35.0)
			let buttonContainerCenterY = self.buttonContainerView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
			let buttonContainerLeading = self.buttonContainerView.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: 13.0)
			NSLayoutConstraint.activate([buttonContainerWidth, buttonContainerHeight, buttonContainerCenterY, buttonContainerLeading])

			// playerProgressSlider
			let playerProgressSliderLeading = self.playerProgressSlider.leadingAnchor.constraint(equalTo: self.buttonContainerView.trailingAnchor, constant: 12.0)
			let playerProgressSliderTrailing = self.playerProgressSlider.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: -22.0)
			let playerProgressSliderCenterY = self.playerProgressSlider.centerYAnchor.constraint(equalTo: self.centerYAnchor)
			let playerProgressSliderHeight = self.playerProgressSlider.heightAnchor.constraint(equalToConstant: 20.0)
			NSLayoutConstraint.activate([playerProgressSliderCenterY, playerProgressSliderHeight, playerProgressSliderLeading, playerProgressSliderTrailing])
		}

	}

	private func addToButtonContainerView(_ buttonView: UIView) {
		DispatchQueue.main.async { [weak self] in
			guard let `self` = self else { return }

			// First remove old subview if exists
			for subview in self.buttonContainerView.subviews {
				subview.removeFromSuperview()
			}

			self.buttonContainerView.addSubview(buttonView)

			let buttonContainerWidth = buttonView.widthAnchor.constraint(equalTo: self.buttonContainerView.widthAnchor)
			let buttonContainerHeight = buttonView.heightAnchor.constraint(equalTo: self.buttonContainerView.heightAnchor)
			let buttonContainerLeading = buttonView.leadingAnchor.constraint(equalTo: self.buttonContainerView.leadingAnchor)
			let buttonContainerTop = buttonView.topAnchor.constraint(equalTo: self.buttonContainerView.topAnchor)
			NSLayoutConstraint.activate([buttonContainerWidth, buttonContainerHeight, buttonContainerLeading, buttonContainerTop])
		}
	}

	@objc private func buttonAction(_ sender: UITapGestureRecognizer) {
		if audioPlayer?.delegate == nil {
			setViewAsAudioDelegate()
		} else if let audioDelegate = audioPlayer?.delegate, audioDelegate as! AudioMessageView != self {
			setViewAsAudioDelegate()
		}
		if audioPlayer?.state == .playing {
			audioPlayer?.pause()
		} else {
			if let currentTime = self.currentTime {
				audioPlayer?.seek(to: currentTime)
			}
			audioPlayer?.play()
		}
	}

	private func setViewAsAudioDelegate() {
		audioPlayer?.configureAudioWith(avAsset: avAsset)
		audioPlayer?.delegate = self
	}

	@objc private func sliderValueDidChange(sender:UISlider!) {
		if let duration = audioPlayer?.currentItem?.asset.duration {
			let seekTime = CMTimeMakeWithSeconds(Double(sender.value) * CMTimeGetSeconds(duration), 1)
			audioPlayer?.seek(to: seekTime)
			currentTime = audioPlayer?.currentItem?.currentTime()
		}
	}


	// MARK: - Open setters

	open func setCorner(radius: CGFloat?) {
		guard let radius = radius else {
			//if corner radius not set default to Circle
			let cornerRadius = min(frame.width, frame.height)
			layer.cornerRadius = cornerRadius/2

			return
		}
		self.radius = radius
		layer.cornerRadius = radius
	}


	// AudioPlayerDelegate Methods

	// Player did updated duration time
	func playerDidUpdateDurationTime(_ player: AudioPlayer, durationTime: CMTime) {

	}

	// Player did change time playing
	func playerDidUpdateCurrentTimePlaying(_ player: AudioPlayer, currentTime: CMTime) {
		self.currentTime = currentTime
	}

	// Player begin start
	func playerDidStart(_ player: AudioPlayer) {

	}

	// Player stoped
	func playerDidStoped(_ player: AudioPlayer) {

	}

	// Player did finish playing
	func playerDidFinishPlaying(_ player: AudioPlayer) {

	}

	// Change player button image
	func showPlayButton() {
		addToButtonContainerView(playButtonView)
	}

	func showPauseButton() {
		addToButtonContainerView(pauseButtonView)
	}

}

class AudioSlider: UISlider {
	var trackHeight: CGFloat = 6

	override func trackRect(forBounds bounds: CGRect) -> CGRect {
		var result = super.trackRect(forBounds: bounds)

		result.origin.x = 0
		result.size.width = bounds.size.width
		result.size.height = max(trackHeight, 4)

		return result
	}
}

extension AudioMessageView: Comparable {
	public static func <(lhs: AudioMessageView, rhs: AudioMessageView) -> Bool {
		return true
	}

	static func ==(lhs: AudioMessageView, rhs: AudioMessageView) -> Bool {
		return lhs.avAsset == rhs.avAsset
	}

}
