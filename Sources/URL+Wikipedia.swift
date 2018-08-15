//
//  URL+Wikipedia.swift
//  WikipediaKit
//
//  Created by Frank Rausch on 2015-04-08.
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

extension URL {
    
    public func extractWikipediaArticleParameters() -> (title: String, languageCode: String?, fragment: String) {
        var articleTitle = self.path.replacingOccurrences(of: "/wiki/", with: "").replacingOccurrences(of: "_", with: " ")
        let articleLanguage = self.host?.components(separatedBy: ".").first
        let fragment = self.fragment ?? ""
        // Remove hash from title:
        if !fragment.isEmpty {
            articleTitle = articleTitle.replacingOccurrences(of: "#\(fragment)", with: "")
        }
        return (articleTitle, articleLanguage, fragment)
    }
    
    public func isWikipediaArticleURL() -> Bool {
        let pattern = "^(https?://)?(www\\.)?([^.].*\\.wikipedia.org)?/wiki/.+$"
        
        let absoluteURLString = self.absoluteString
        if let _ = absoluteURLString.range(of: pattern, options: .regularExpression) {
            return true
        }
        return false
    }
        
    public func isWikipediaImageURL() -> Bool {
        // This list includes SVG and PDF because currently the Wikipedia API 
        // will always return a flattened bitmap (PNG or JPG)
        // when requesting these types.
        let supportedImageFileExtensions = ["tiff", "tif", "jpg", "jpeg", "gif", "bmp", "bmpf", "ico", "cur", "xbm", "png", "svg", "pdf"]
        var imageExtension = self.pathExtension
        if imageExtension.isEmpty {
            // For the rare case where the path extension is not recognized by Foundation, like this one:
            // https://en.wikipedia.org/wiki/Megalodon#/media/File:Giant_white_shark_coprolite_(Miocene;_coastal_waters_of_South_Carolina,_USA).jpg
            // TODO: Use a regex to clean this up and to allow a 3 or 4 character suffix.
            let suffix = String(self.absoluteString.suffix(4))
            if suffix.prefix(1) == "." {
                imageExtension = String(suffix.suffix(3))
            }
        }
        return supportedImageFileExtensions.contains(imageExtension.lowercased())
    }
    
    public func isWikipediaMediaURL() -> Bool {
        let supportedMediaFileExtensions = ["ogg", "ogv", "oga", "flac", "webm"]
        let imageExtension = self.pathExtension
        return supportedMediaFileExtensions.contains(imageExtension.lowercased())
    }
    
    public func isWikipediaScrollURL() -> Bool {
        let isHostWikipedia = self.host != nil ? self.host!.range(of: ".wikipedia.org") != nil : false
        let pathPointsToSiteRoot = self.path != "" ? self.path == "/" : false
        let hasFragment = self.fragment != nil ? (self.fragment!).count > 0 : false
        return isHostWikipedia && pathPointsToSiteRoot && hasFragment
    }
    
}
