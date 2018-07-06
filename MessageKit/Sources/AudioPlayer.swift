//
//  AudioPlayer.swift
//  MessageKit
//
//  Created by Miroslav Perovic on 9/29/17.
//

import Foundation
import AVFoundation

public enum PlayerState {
	case playing
	case paused
	case reserved
	case unknown
}

@objc protocol AudioPlayerDelegate: class {

	// Playing progress slider
	var playerProgressSlider: AudioSlider { get set }

	// Player did updated duration time
	func playerDidUpdateDurationTime(_ player: AudioPlayer, durationTime: CMTime)

	// Player did change time playing
	func playerDidUpdateCurrentTimePlaying(_ player: AudioPlayer, currentTime: CMTime)

	// Player begin start
	func playerDidStart(_ player: AudioPlayer)

	// Player stoped
	func playerDidStoped(_ player: AudioPlayer)

	// Player did finish playing
	func playerDidFinishPlaying(_ player: AudioPlayer)

	// Change player button image
	func showPlayButton()
	func showPauseButton()

}

open class AudioPlayer: NSObject {

	// Properties

	var delegate : AudioPlayerDelegate?

	private var currentTime = kCMTimeZero

	open var state: PlayerState = .unknown

	// when the playing message is onscreen, holds the reference to it. nil if playing message is offscreen.
	private var activeCell: AudioMessageCell?

	private var activeMessageUUID: String?

	private var avPlayer = AVPlayer() {
		didSet {
			avPlayer.addObserver(self, forKeyPath: "rate", options: NSKeyValueObservingOptions.new, context: nil)
		}
	}

	var timer = Timer()

	// Methods

	open func configureAudioWith(avAsset: AVAsset?) {
		if avPlayer.currentItem != nil, let audioDelegate = self.delegate {
			audioDelegate.showPlayButton()
		}
		if let asset = avAsset {
			let playerItem = AVPlayerItem(asset: asset)
			avPlayer = AVPlayer(playerItem:playerItem)
			avPlayer.rate = 1.0;
			avPlayer.pause()
		} else {
			avPlayer.pause()
			avPlayer.replaceCurrentItem(with: nil)
		}
	}

	override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		if keyPath == "rate" {
			if let rate = change?[NSKeyValueChangeKey.newKey] as? Float {
				if rate == 0.0 {
					print("playback stopped")

					// Call delegate
					if self.delegate != nil {
						self.delegate?.playerDidStoped(self)
					}

					// Cancel timer update laber title
					cancelTimer()
					state = .paused
					delegate?.showPlayButton()
				}

				if rate == 1.0 {
					print("normal playback")

					// Call delegate
					if self.delegate != nil {
						delegate?.playerDidStart(self)
						delegate?.playerDidUpdateDurationTime(self, durationTime: (avPlayer.currentItem?.asset.duration)!)
					}


					// Begin update label time
					startTimer()
					state = .playing
					delegate?.showPauseButton()
				}

				if rate == -1.0 {
					print("reverse playback")
					state = .reserved
					delegate?.showPauseButton()
				}
			}
		}
	}

	open func pause() {
		avPlayer.pause()
	}

	open func play() {
		avPlayer.play()
	}

	open func seek(to time: CMTime) {
		return avPlayer.seek(to: time)
	}

	var currentItem: AVPlayerItem? {
		get {
			return avPlayer.currentItem
		}
	}

	// MARK: - Timer update status of player
	func startTimer() {
		timer.invalidate() // just in case this button is tapped multiple times

		// start the timer
		timer = Timer.scheduledTimer(
			timeInterval: 0.5,
			target: self,
			selector: #selector(timerAction),
			userInfo: nil,
			repeats: true
		)
	}

	// stop timer
	func cancelTimer() {
		timer.invalidate()
	}

	@objc func timerAction() {
//		self.timeLabel.text = CMTimeMakeWithSeconds(CMTimeGetSeconds(self.audioPlayer.currentItem!.asset.duration) - CMTimeGetSeconds(self.audioPlayer.currentTime()), 1).durationText
		let rate = Float(CMTimeGetSeconds(avPlayer.currentTime())/CMTimeGetSeconds(avPlayer.currentItem!.asset.duration))

		delegate?.playerProgressSlider.setValue(rate, animated: false)

		// Call delegate
		if(CMTimeGetSeconds(avPlayer.currentItem!.asset.duration) - CMTimeGetSeconds(avPlayer.currentTime()) < 1 && delegate != nil) {
			delegate?.playerDidFinishPlaying(self)
		}

		if self.delegate != nil {
			delegate?.playerDidUpdateCurrentTimePlaying(self, currentTime: (avPlayer.currentItem?.currentTime())!)
		}
	}

}

//MARK: CMTime extension
extension CMTime {
	var durationText:String {
		let totalSeconds = CMTimeGetSeconds(self)
		let hours: Int = Int(totalSeconds / 3600)
		let minutes: Int = Int(totalSeconds.truncatingRemainder(dividingBy: 3600) / 60)
		let seconds: Int = Int(totalSeconds.truncatingRemainder(dividingBy: 60))

		if hours > 0 {
			return String(format: "%i:%02i:%02i", hours, minutes, seconds)
		} else {
			return String(format: "%02i:%02i", minutes, seconds)
		}
	}
}
