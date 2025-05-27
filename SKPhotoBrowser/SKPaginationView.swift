//
//  SKPaginationView.swift
//  SKPhotoBrowser
//
//  Created by keishi_suzuki on 2017/12/20.
//  Copyright © 2017年 suzuki_keishi. All rights reserved.
//

import UIKit

class SKPaginationView: UIView {
    var counterLabel: UILabel?
    var prevButton: UIButton?
    var nextButton: UIButton?
    private var margin: CGFloat = 100
    private var extraMargin: CGFloat = SKMesurement.isPhoneX ? 40 : 0
    
    fileprivate weak var browser: SKPhotoBrowser?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(frame: CGRect, browser: SKPhotoBrowser?) {
        self.init(frame: frame)
        self.frame = CGRect(x: 0, y: frame.height - margin - extraMargin, width: frame.width, height: 100)
        self.browser = browser

        setupApperance()
        setupCounterLabel()
        setupPrevButton()
        setupNextButton()
        
        update(browser?.currentPageIndex ?? 0)
        NotificationCenter.default.addObserver(self, selector: #selector(handleOrientationChange), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let view = super.hitTest(point, with: event) {
            if let counterLabel = counterLabel, counterLabel.frame.contains(point) {
                return view
            } else if let prevButton = prevButton, prevButton.frame.contains(point) {
                return view
            } else if let nextButton = nextButton, nextButton.frame.contains(point) {
                return view
            }
            return nil
        }
        return nil
    }
    
    func updateFrame(frame: CGRect) {
        /*
         调整 originY 为 safeAreaInsets.top，和 close button 一致
         */
        var topMargin: CGFloat = 20
        if #available(iOS 11.0, *) {
            if let topEdge = UIApplication.shared.windows.first?.safeAreaInsets.top {
                topMargin = topEdge
            }
        }
        self.frame = CGRect(x: 0, y: topMargin, width: frame.width, height: 100)
    }
    
    func update(_ currentPageIndex: Int) {
        guard let browser = browser else { return }
        
        if browser.photos.count > 1 {
            counterLabel?.text = "\(currentPageIndex + 1) / \(browser.photos.count)"
        } else {
            counterLabel?.text = nil
        }
        
        guard let prevButton = prevButton, let nextButton = nextButton else { return }
        prevButton.isEnabled = (currentPageIndex > 0)
        nextButton.isEnabled = (currentPageIndex < browser.photos.count - 1)
    }
    
    func setControlsHidden(hidden: Bool) {
        let alpha: CGFloat = hidden ? 0.0 : 1.0
        
        UIView.animate(withDuration: 0.35,
                       animations: { () -> Void in self.alpha = alpha },
                       completion: nil)
    }
    
    func updateCounterLabelUI() {
        guard let counterLabel = counterLabel else { return }

        let isLandscape = UIDevice.current.orientation.isValidInterfaceOrientation ?
                          UIDevice.current.orientation.isLandscape :
                          UIScreen.main.bounds.width > UIScreen.main.bounds.height
        
        let labelHeight: CGFloat = 44
        var offsetY: CGFloat = 0
        
        if isLandscape {
            counterLabel.backgroundColor = .white
            counterLabel.layer.cornerRadius = 22
            counterLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
            
            offsetY = 16
            counterLabel.font = SKToolbarOptions.fontInLandscape
        } else {
            counterLabel.backgroundColor = .clear
            counterLabel.layer.cornerRadius = 0
            counterLabel.textColor = .white
            
            counterLabel.font = SKToolbarOptions.font
            offsetY = 0
        }
        
        counterLabel.center = CGPoint(x: frame.width / 2, y: labelHeight / 2 + offsetY)
    }
    
    @objc private func handleOrientationChange() {
        updateCounterLabelUI()
    }
    
    deinit {
        print("\(#file) deinit")
        NotificationCenter.default.removeObserver(self)
    }
}

private extension SKPaginationView {
    func setupApperance() {
        backgroundColor = .clear
        clipsToBounds = true
    }
    
    func setupCounterLabel() {
        guard SKPhotoBrowserOptions.displayCounterLabel else { return }
        
        /*
         设置 label height 高度为 44，和 close button 一致
         */
        let labelHeight: CGFloat = 44
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 86, height: labelHeight))
        label.textAlignment = .center
        label.backgroundColor = .white
        label.layer.cornerRadius = 22
        label.clipsToBounds = true
        label.shadowColor = SKToolbarOptions.textShadowColor
        label.shadowOffset = CGSize(width: 0.0, height: 1.0)
        label.textColor = SKToolbarOptions.textColor
        label.translatesAutoresizingMaskIntoConstraints = true
        label.autoresizingMask = [.flexibleBottomMargin,
                                  .flexibleLeftMargin,
                                  .flexibleRightMargin,
                                  ]
        addSubview(label)
        counterLabel = label
        updateCounterLabelUI()
    }
    
    func setupPrevButton() {
        guard SKPhotoBrowserOptions.displayBackAndForwardButton else { return }
        guard browser?.photos.count ?? 0 > 1 else { return }
        
        let button = SKPrevButton(frame: frame)
        button.center = CGPoint(x: frame.width / 2 - 100, y: frame.height / 2)
        button.addTarget(browser, action: #selector(SKPhotoBrowser.gotoPreviousPage), for: .touchUpInside)
        addSubview(button)
        prevButton = button
    }
    
    func setupNextButton() {
        guard SKPhotoBrowserOptions.displayBackAndForwardButton else { return }
        guard browser?.photos.count ?? 0 > 1 else { return }
        
        let button = SKNextButton(frame: frame)
        button.center = CGPoint(x: frame.width / 2 + 100, y: frame.height / 2)
        button.addTarget(browser, action: #selector(SKPhotoBrowser.gotoNextPage), for: .touchUpInside)
        addSubview(button)
        nextButton = button
    }
}

class SKPaginationButton: UIButton {
    let insets: UIEdgeInsets = UIEdgeInsets(top: 13.25, left: 17.25, bottom: 13.25, right: 17.25)
    
    func setup(_ imageName: String) {
        backgroundColor = .clear
        imageEdgeInsets = insets
        translatesAutoresizingMaskIntoConstraints = true
        autoresizingMask = [.flexibleBottomMargin,
                            .flexibleLeftMargin,
                            .flexibleRightMargin,
                            .flexibleTopMargin]
        contentMode = .center

        setImage(UIImage.bundledImage(named: imageName), for: .normal)
    }
}

class SKPrevButton: SKPaginationButton {
    let imageName = "btn_common_back_wh"
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        setup(imageName)
    }
}

class SKNextButton: SKPaginationButton {
    let imageName = "btn_common_forward_wh"
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        setup(imageName)
    }
}
