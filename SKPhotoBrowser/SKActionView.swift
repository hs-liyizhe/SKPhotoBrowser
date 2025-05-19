//
//  SKOptionalActionView.swift
//  SKPhotoBrowser
//
//  Created by keishi_suzuki on 2017/12/19.
//  Copyright © 2017年 suzuki_keishi. All rights reserved.
//

import UIKit

class SKActionView: UIView {
    internal weak var browser: SKPhotoBrowser?
    internal var closeButton: UIButton!
    internal var deleteButton: SKDeleteButton!
    
    // Action
    fileprivate var cancelTitle = "Cancel"
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(frame: CGRect, browser: SKPhotoBrowser) {
        self.init(frame: frame)
        self.browser = browser

        configureCloseButton()
        configureDeleteButton()
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let view = super.hitTest(point, with: event) {
            if closeButton.frame.contains(point) || deleteButton.frame.contains(point) {
                return view
            }
            return nil
        }
        return nil
    }
    
    func updateFrame(frame: CGRect) {
        self.frame = frame
        setNeedsDisplay()
    }

    func updateCloseButton(image: UIImage, size: CGSize? = nil) {
        configureCloseButton(image: image, size: size)
    }
    
    func updateDeleteButton(image: UIImage, size: CGSize? = nil) {
        configureDeleteButton(image: image, size: size)
    }
    
    func animate(hidden: Bool) {
        
        /** 2025-9-1，用 alpha 效果已经足够了，frame 这个属性舍弃了
        let closeFrame: CGRect = hidden ? closeButton.hideFrame : closeButton.showFrame
         */
        let deleteFrame: CGRect = hidden ? deleteButton.hideFrame : deleteButton.showFrame
        UIView.animate(withDuration: 0.35,
                       animations: { () -> Void in
                        let alpha: CGFloat = hidden ? 0.0 : 1.0

                        if SKPhotoBrowserOptions.displayCloseButton {
                            self.closeButton.alpha = alpha
                            // self.closeButton.frame = closeFrame
                        }
                        if SKPhotoBrowserOptions.displayDeleteButton {
                            self.deleteButton.alpha = alpha
                            self.deleteButton.frame = deleteFrame
                        }
        }, completion: nil)
    }
    
    @objc func closeButtonPressed(_ sender: UIButton) {
        browser?.determineAndClose()
    }
    
    @objc func deleteButtonPressed(_ sender: UIButton) {
        guard let browser = self.browser else { return }
        
        browser.delegate?.removePhoto?(browser, index: browser.currentPageIndex) { [weak self] in
            self?.browser?.deleteImage()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let closeButton {
            closeButton.frame.origin = safeAreaAdjustedPosition()
        }
    }
}

extension SKActionView {
    func configureCloseButton(image: UIImage? = nil, size: CGSize? = nil) {
        if closeButton == nil {
            let origin = safeAreaAdjustedPosition()
            
            closeButton = UIButton.init(
                frame: .init(
                    origin: origin,
                    size: size ?? .init(width: 44, height: 44)
                )
            )
            closeButton.addTarget(self, action: #selector(closeButtonPressed(_:)), for: .touchUpInside)
            closeButton.isHidden = !SKPhotoBrowserOptions.displayCloseButton
            closeButton.contentMode = .scaleAspectFill
            
            // 添加阴影
            closeButton.layer.shadowColor = UIColor.black.cgColor  // 阴影颜色
            closeButton.layer.shadowOffset = CGSize(width: 0, height: 2)  // 阴影偏移量
            closeButton.layer.shadowOpacity = 0.5  // 阴影透明度 (0 - 1)
            closeButton.layer.shadowRadius = 4  // 阴影模糊半径
            
            addSubview(closeButton)
        }

        if let size {
            let frame = CGRect.init(origin: closeButton.frame.origin, size: size)
            closeButton.frame = frame
        }
        
        if let image = image {
            closeButton.setImage(image, for: .normal)
        }
    }
    
    func configureDeleteButton(image: UIImage? = nil, size: CGSize? = nil) {
        if deleteButton == nil {
            deleteButton = SKDeleteButton(frame: .zero)
            deleteButton.addTarget(self, action: #selector(deleteButtonPressed(_:)), for: .touchUpInside)
            deleteButton.isHidden = !SKPhotoBrowserOptions.displayDeleteButton
            addSubview(deleteButton)
        }
        
        if let size = size {
            deleteButton.setFrameSize(size)
        }
        
        if let image = image {
            deleteButton.setImage(image, for: .normal)
        }
    }
    
    private func safeAreaAdjustedPosition() -> CGPoint {
        var top: CGFloat = 20
        var left: CGFloat = 0
        
        if #available(iOS 11.0, *) {
            let safeAreaInsets = UIApplication.shared.windows.first?.safeAreaInsets
            top = safeAreaInsets?.top ?? 20
            left = safeAreaInsets?.left ?? 0
        }
        
        return CGPoint(x: left, y: top)
    }
    
}
