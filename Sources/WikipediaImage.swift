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
    public let description: String
    public let license: String
    
    static let allowedImageMimeTypes = [
        "image/jpeg",
        "image/png",
        "image/gif"
    ]
    
    init(language: WikipediaLanguage, id: String, url: URL, description: String, license: String) {
        self.language = language
        self.id = id
        self.url = url
        self.description = description
        self.license = license
    }
}

extension WikipediaImage {
    
    convenience init?(jsonDictionary dict: JSONDictionary, language: WikipediaLanguage) {
        guard let query = dict["query"] as? JSONDictionary,
            let pages = query["pages"] as? [JSONDictionary],
            let image = pages.first,
            let imageInfoWrapper = image["imageinfo"] as? [JSONDictionary]
            else { return nil }

        guard let imageInfo = imageInfoWrapper.first,
            let urlString = imageInfo["thumburl"] as? String,
            let url = URL(string: urlString)
            else {
                return nil
        }
        
        guard let mime = imageInfo["thumbmime"] as? String,
            WikipediaImage.allowedImageMimeTypes.contains(mime)
            else {
                return nil
        }
        
        let id = image["title"] as? String ?? ""
        
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
        
        self.init(language: language, id: id, url: url, description: description, license: license)
    }
}
