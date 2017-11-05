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
    
    public func extractWikipediaArticleParameters() -> (title: String, languageCode: String?, hash: String) {
        var articleTitle = self.path.replacingOccurrences(of: "/wiki/", with: "").replacingOccurrences(of: "_", with: " ")
        let articleLanguage = self.host?.components(separatedBy: ".").first
        let hash = self.fragment ?? ""
        // Remove hash from title:
        if !hash.isEmpty {
            articleTitle = articleTitle.replacingOccurrences(of: "#\(hash)", with: "")
        }
        return (articleTitle, articleLanguage, hash)
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
        let imageExtension = self.pathExtension
        guard supportedImageFileExtensions.contains(imageExtension.lowercased()) else { return false }
        return true
    }
    
    public func isWikipediaMediaURL() -> Bool {
        let supportedMediaFileExtensions = ["ogg", "ogv", "oga", "flac", "webm"]
        let imageExtension = self.pathExtension
        guard supportedMediaFileExtensions.contains(imageExtension.lowercased()) else { return false }
        return true
    }
    
    public func isWikipediaScrollURL() -> Bool {
        let isHostWikipedia = self.host != nil ? self.host!.range(of: ".wikipedia.org") != nil : false
        let pathPointsToSiteRoot = self.path != "" ? self.path == "/" : false
        let hasHash = self.fragment != nil ? (self.fragment!).count > 0 : false
        return isHostWikipedia && pathPointsToSiteRoot && hasHash
    }
    
}
