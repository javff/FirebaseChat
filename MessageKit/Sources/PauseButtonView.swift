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
import CoreGraphics

open class PauseButtonView: UIView {

	// MARK: - Properties

	open var cornerRadius: CGFloat = 1.0

	// MARK: - Initializers

	convenience init(frame: CGRect, cornerRadius: CGFloat) {
		self.init(frame: frame)

		self.cornerRadius = cornerRadius
	}

	override public init(frame: CGRect) {
		super.init(frame: frame)

		backgroundColor = .clear
	}

	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Methods

	override open func draw(_ rect: CGRect) {
		//// Color Declarations
		let color = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1.000)

		//// Oval Drawing
		let ovalPath = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: rect.width, height: rect.height))
		UIColor.playButtonLightGray.setFill()
		ovalPath.fill()

		//// Rectangle 1 Drawing
		let rectangle1Path = UIBezierPath(roundedRect: CGRect(x: ceil(rect.width * 0.2286), y: ceil(rect.width * 0.1714), width: ceil(rect.width * 0.1714), height: ceil(rect.width * 0.6571)), cornerRadius: cornerRadius)
		color.setFill()
		rectangle1Path.fill()

		//// Rectangle 2 Drawing
		let rectangle2Path = UIBezierPath(roundedRect: CGRect(x: ceil(rect.width * 0.600), y: ceil(rect.width * 0.1714), width: ceil(rect.width * 0.1714), height: ceil(rect.width * 0.6571)), cornerRadius: cornerRadius)
		color.setFill()
		rectangle2Path.fill()
	}

}
