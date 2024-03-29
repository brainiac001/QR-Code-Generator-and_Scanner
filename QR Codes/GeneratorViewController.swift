//
//  FirstViewController.swift
//  QR Codes
//
//  Created by Kyle Howells on 31/12/2019.
//  Copyright © 2019 Kyle Howells. All rights reserved.
//

import UIKit
import CoreImage

class GeneratorViewController: UIViewController, UITextViewDelegate {
	
	@IBOutlet weak var scrollView: UIScrollView!
	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var textView: UITextView!
	@IBOutlet weak var correctionLevelSegmentControl: UISegmentedControl!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.textView.delegate = self
		self.registerForKeyboardNotifications()
		
		self.imageView.layer.magnificationFilter = .nearest
		self.imageView.layer.minificationFilter = .nearest
		
		let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.shareImage))
		self.imageView.addGestureRecognizer(longPress)
		self.imageView.isUserInteractionEnabled = true // UIImageView is(was?) the only UIView class this defaults to false
		
		self.refreshQRCode()
	}
	
	@IBAction func correctionLevelChanged(_ sender: Any) {
		self.refreshQRCode()
	}
	
	func textViewDidChange(_ textView: UITextView) {
		self.refreshQRCode()
	}
	
	// MARK: - Generate QR Code
	
	func refreshQRCode() {
		let text:String = self.textView.text
		
		// Generate the image
		guard let qrCode:CIImage = self.createQRCodeForString(text) else {
			print("Failed to generate QRCode")
			self.imageView.image = nil
			return
		}
		
		// Display
		self.imageView.image = UIImage(ciImage: qrCode)
	}
	
	
	/// Generate a CoreImage image for the text passed in.
	/// This string is converted to ISOLatin1 string encoding, not the usual UTF8.
	/// Then the resulting binary data is past as the input to a CIFilter which makes the QRCode for us
	/// - Parameter text: The text to turn into a QRCode
	func createQRCodeForString(_ text: String) -> CIImage? {
		let data = text.data(using: .isoLatin1)
		//let data = text.data(using: .utf8)
		
		let qrFilter = CIFilter(name: "CIQRCodeGenerator")
		// Input text
		qrFilter?.setValue(data, forKey: "inputMessage")
		// Error correction
		let values = ["L", "M", "Q", "H"]
		// Trick to limit the result to the bounds (0, array.maxIndex) - max(_MIN_, min(_value_, _MAX_))
		let index = max(0, min(self.correctionLevelSegmentControl.selectedSegmentIndex, (values.count-1)))
		let correctionLevel = values[index]
		qrFilter?.setValue(correctionLevel, forKey: "inputCorrectionLevel")
		
		return qrFilter?.outputImage
	}
	
	
	
	
	// MARK: Share Image
	
	@objc func shareImage() {
		guard let image = self.imageView.image else {
			return
		}
		
		let activityViewController = UIActivityViewController(activityItems: [ self.sharableImage(image) ], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.imageView // so that iPads won't crash
        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
	}
	
	// Lots of the share extensions don't seem to handle UIImage's originating from CoreImage images properly
	// Even though it shouldn't be needed, re-rendering it seems to help reliability of some sharing options
	func sharableImage(_ image: UIImage) -> UIImage
	{
		let sharableWidth: CGFloat = max(image.size.width, 512)
		let renderSize: CGSize = CGSize(width: sharableWidth, height: sharableWidth)
		
		let renderer = UIGraphicsImageRenderer(size: renderSize, format: image.imageRendererFormat)
		let img = renderer.image(actions: { ctx in
			image.draw(in: CGRect(origin: .zero, size: renderSize))
		})
		return img
	}
	
	
	
	
	
	// MARK: - Keyboard Handling
	
	func registerForKeyboardNotifications(){
		NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWasShown), name: UIResponder.keyboardDidShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillBeHidden), name: UIResponder.keyboardWillHideNotification, object: nil)
	}
	
	@objc func keyboardWasShown(_ aNotification: NSNotification) {
		let info = aNotification.userInfo!
		let kbSize:CGSize = (info[UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue.size
		let contentInsets:UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: kbSize.height, right: 0)
		self.scrollView.contentInset = contentInsets
		self.scrollView.scrollIndicatorInsets = contentInsets
		
		// If active text field is hidden by keyboard, scroll it so it's visible
		// Your application might not need or want this behaviour.
		var aRect:CGRect = self.view.frame
		aRect.size.height -= kbSize.height
		
		if (!aRect.contains(self.textView.frame.origin)) {
			let scrollPoint:CGPoint = CGPoint(x: 0, y: self.textView.frame.origin.y-kbSize.height)
			self.scrollView.setContentOffset(scrollPoint, animated: true)
		}
	}
	
	@objc func keyboardWillBeHidden(_ aNotification: NSNotification) {
		let contentInsets = UIEdgeInsets.zero
		self.scrollView.contentInset = contentInsets;
		self.scrollView.scrollIndicatorInsets = contentInsets;
	}
}
