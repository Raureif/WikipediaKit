//
//  WikipediaImage.swift
//  WikipediaKit
//
//  Created by Frank Rausch on 2016-07-25.
//  Copyright © 2017 Raureif GmbH / Frank Rausch
//
//  MIT License
//
//  Permission is hereby granted, free of charge, to any person obtaining a
//  copy of this software and associated documentation files (the
//  “Software”), to deal in the Software without restriction, including
//  without limitation the rights to use, copy, modify, merge, publish,
//  distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to
//  the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.
//

import Foundation

public class WikipediaImage {
    
    public let language: WikipediaLanguage
    public let id: String
    public let url: URL
    public let originalURL: URL
    public let descriptionURL: URL
    public let description: String
    public let license: String
    
    static let allowedImageMimeTypes = [
        "image/jpeg",
        "image/png",
        "image/gif"
    ]
    
    init(language: WikipediaLanguage, id: String, url: URL, originalURL: URL, descriptionURL: URL, description: String, license: String) {
        self.language = language
        self.id = id
        self.url = url
        self.originalURL = originalURL
        self.descriptionURL = descriptionURL
        self.description = description
        self.license = license
    }
}

extension WikipediaImage {
    
    convenience init?(jsonDictionary dict: JSONDictionary, language: WikipediaLanguage) {
        guard let imageInfoWrapper = dict["imageinfo"] as? [JSONDictionary]
            else { return nil }

        guard let imageInfo = imageInfoWrapper.first else {
                return nil
        }

        let url: URL

        guard let originalURLString = imageInfo["url"] as? String,
              let originalURL = URL(string: originalURLString) else {
                return nil
        }

        let mime: String?
        if let thumbURLString = imageInfo["thumburl"] as? String,
           let thumbURL = URL(string: thumbURLString) {
            url = thumbURL
            mime = imageInfo["thumbmime"] as? String
        } else {
            url = originalURL
            mime = imageInfo["mime"] as? String
        }

        guard let thumbMime = mime, WikipediaImage.allowedImageMimeTypes.contains(thumbMime) else {
            return nil
        }

        guard let descriptionURLString = imageInfo["descriptionurl"] as? String,
            let descriptionURL = URL(string: descriptionURLString) else {
                return nil
        }


        let id = dict["title"] as? String ?? ""
        
        var description = ""
        var license = ""

        if let meta = imageInfo["extmetadata"] as? JSONDictionary {
            
            if let descriptionWrapper = meta["ImageDescription"] as? JSONDictionary,
                let descriptionValue = descriptionWrapper["value"] as? String {
                description = descriptionValue
            }
            
            if let licenseWrapper = meta["LicenseShortName"] as? JSONDictionary,
                let licenseValue = licenseWrapper["value"] as? String {
                license = licenseValue
            }
        }
        
        self.init(language: language, id: id, url: url, originalURL: originalURL, descriptionURL: descriptionURL, description: description, license: license)
    }
}
