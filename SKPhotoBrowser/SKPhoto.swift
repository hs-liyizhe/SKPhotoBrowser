//
//  SKPhoto.swift
//  SKViewExample
//
//  Created by suzuki_keishi on 2015/10/01.
//  Copyright © 2015 suzuki_keishi. All rights reserved.
//

import UIKit
#if canImport(SKPhotoBrowserObjC)
import SKPhotoBrowserObjC
#endif

@objc public protocol SKPhotoProtocol: NSObjectProtocol {
    var index: Int { get set }
    var underlyingImage: UIImage! { get set }
    var caption: String? { get }
    var contentMode: UIView.ContentMode { get set }
    func loadUnderlyingImageAndNotify()
    func checkCache()
}

// MARK: - SKPhoto
open class SKPhoto: NSObject, SKPhotoProtocol {
    open var index: Int = 0
    open var underlyingImage: UIImage!
    open var caption: String?
    open var contentMode: UIView.ContentMode = .scaleAspectFill
    open var shouldCachePhotoURLImage: Bool = false
    open var photoURL: String!

    override init() {
        super.init()
    }
    
    convenience init(image: UIImage) {
        self.init()
        underlyingImage = image
    }
    
    convenience init(url: String) {
        self.init()
        photoURL = url
    }
    
    convenience init(url: String, holder: UIImage?) {
        self.init()
        photoURL = url
        underlyingImage = holder
    }
    
    open func checkCache() {
        guard let photoURL = photoURL else {
            return
        }
        guard shouldCachePhotoURLImage else {
            return
        }
        
        if SKCache.sharedCache.imageCache is SKRequestResponseCacheable {
            let request = URLRequest(url: URL(string: photoURL)!)
            if let img = SKCache.sharedCache.imageForRequest(request) {
                underlyingImage = img
            }
        } else {
            SKCache.sharedCache.imageForKey(photoURL) { img in
                if let img {
                    self.underlyingImage = img
                }
            }
        }
    }
    
    open func loadUnderlyingImageAndNotify() {
        guard photoURL != nil, let URL = URL(string: photoURL) else { return }
        
        if self.shouldCachePhotoURLImage {
            if SKCache.sharedCache.imageCache is SKRequestResponseCacheable {
                let request = URLRequest(url: URL)
                if let img = SKCache.sharedCache.imageForRequest(request) {
                    DispatchQueue.main.async {
                        self.underlyingImage = img
                        self.loadUnderlyingImageComplete()
                    }
                } else {
                    fetchImage(URL)
                }
            } else {
                SKCache.sharedCache.imageForKey(photoURL) { img in
                    if let img {
                        DispatchQueue.main.async {
                            self.underlyingImage = img
                            self.loadUnderlyingImageComplete()
                        }
                    } else {
                        self.fetchImage(URL)
                    }
                }
            }
        } else {
            fetchImage(URL)
        }
    }
    
    func fetchImage(_ URL: URL) {
        let session = URLSession(configuration: SKPhotoBrowserOptions.sessionConfiguration)
            var task: URLSessionTask?
            task = session.dataTask(with: URL, completionHandler: { [weak self] (data, response, error) in
                guard let self = self else { return }
                defer { session.finishTasksAndInvalidate() }

                guard error == nil else {
                    DispatchQueue.main.async {
                        self.loadUnderlyingImageComplete()
                    }
                    return
                }

                if let data = data, let response = response, let image = UIImage.init(data: data) {
                    if self.shouldCachePhotoURLImage {
                        if SKCache.sharedCache.imageCache is SKRequestResponseCacheable {
                            SKCache.sharedCache.setImageData(data, response: response, request: task?.originalRequest)
                        } else {
                            SKCache.sharedCache.setImage(image, forKey: self.photoURL)
                        }
                    }
                    DispatchQueue.main.async {
                        self.underlyingImage = image
                        self.loadUnderlyingImageComplete()
                    }
                }
                
            })
            task?.resume()
    }

    open func loadUnderlyingImageComplete() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: SKPHOTO_LOADING_DID_END_NOTIFICATION), object: self)
    }
    
}

// MARK: - Static Function

extension SKPhoto {
    public static func photoWithImage(_ image: UIImage) -> SKPhoto {
        return SKPhoto(image: image)
    }
    
    public static func photoWithImageURL(_ url: String) -> SKPhoto {
        return SKPhoto(url: url)
    }
    
    public static func photoWithImageURL(_ url: String, holder: UIImage?) -> SKPhoto {
        return SKPhoto(url: url, holder: holder)
    }
}
