//
//  WikipediaArticle.swift
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

public class WikipediaArticle {
    
    public var language: WikipediaLanguage
   
    public var title: String
    public var displayTitle: String
    
    public var rawText = ""
    public lazy var displayText: String = {
        return Wikipedia.sharedFormattingDelegate?.format(context: .article, rawText: self.rawText, title: self.title, language: self.language, isHTML: true) ?? self.rawText
    }()
    
    public var toc = [WikipediaTOCItem]()

    public var coordinate: (latitude: Double, longitude: Double)?

    public var imageURL: URL?
    public var imageID: String?

    public var wikidataID: String?

    public var scrollToFragment: String?
    
    public lazy var url: URL? = {
        let escapedTitle = self.title.wikipediaURLEncodedString()
        let urlString = "https://" + self.language.code + ".wikipedia.org/wiki/" + escapedTitle
        let url = URL(string: urlString)
        return url
    }()
    
    public lazy var editURL: URL? = {
        let escapedTitle = self.title.wikipediaURLEncodedString()
        let editURLString = "https://" + self.language.code + ".m.wikipedia.org/w/index.php?action=edit&title=" + escapedTitle
        let editURL = URL(string: editURLString)
        return editURL
    }()
    
    public init(language: WikipediaLanguage, title: String, displayTitle: String) {
        self.language = language
        self.title = title.replacingOccurrences(of: "_", with: " ")
        
        
        var formattedTitle = displayTitle.replacingOccurrences(of: "_", with: " ")
        formattedTitle = (Wikipedia.sharedFormattingDelegate?.format(context: .articleTitle,
                                                                   rawText: formattedTitle,
                                                                   title: title,
                                                                   language: language,
                                                                   isHTML: true)) ?? formattedTitle
        self.displayTitle = formattedTitle
    }
    
    public var areOtherLanguagesAvailable = false
    public var languageCount = 0
    // will only be populated with extra API call; see Wikipedia+Languages.swift
    public var languageLinks: [WikipediaArticleLanguageLink]?
}


extension WikipediaArticle {
    convenience init?(jsonDictionary dict: JSONDictionary, language: WikipediaLanguage, title: String, fragment: String? = nil) {
        
        guard let mobileview = dict["mobileview"] as? JSONDictionary,
              let sections = mobileview["sections"] as? [JSONDictionary]
        else {
                return nil
        }
        
        var text = ""
        var toc = [WikipediaTOCItem]()
        
        for section in sections {
            if let sectionText = section["text"] as? String {
                text += sectionText
                // The first section (intro) does not have an anchor
                if let sectionAnchor = section["anchor"] as? String {
                    var sectionTitle = (section["line"] as? String ?? "")
                    sectionTitle = (Wikipedia.sharedFormattingDelegate?.format(context: .tableOfContentsItem,
                                                                             rawText: sectionTitle,
                                                                             title: title,
                                                                             language: language,
                                                                             isHTML: true)) ?? sectionTitle
                    let sectionTocLevel = section["toclevel"] as? Int ?? 0
                    toc.append(WikipediaTOCItem(title: sectionTitle, anchor: sectionAnchor, tocLevel: sectionTocLevel))
                }
            }
        }
        
        
        var title = title
        
        var fragment = fragment

        if let redirectedTitle = mobileview["redirected"] as? String {
            title = redirectedTitle
            if let range = redirectedTitle.range(of: "#") {
                // A redirect may contain a fragment (Like #Scroll_Target)
                let fragmentRange = Range(uncheckedBounds: (lower: range.lowerBound, upper: redirectedTitle.endIndex))
                fragment = String(redirectedTitle[fragmentRange]) // Fragment from a redirect overwrites the passed fragment
                title.removeSubrange(fragmentRange)
            }
        }
        
        let rawDisplayTitle = (mobileview["displaytitle"] as? String) ?? title
        
        self.init(language: language, title: title, displayTitle: rawDisplayTitle)

        self.scrollToFragment = fragment

        self.rawText = text
        self.toc = toc

        if let imageProperties = mobileview["image"] as? JSONDictionary,
            let imageID = imageProperties["file"] as? String {
            
            self.imageID = imageID
        }
        
        if let thumbProperties = mobileview["thumb"] as? JSONDictionary,
            let imageURLString = thumbProperties["url"] as? String,
            var imageURL = URL(string: imageURLString) {
            if var urlComponents = URLComponents(url: imageURL, resolvingAgainstBaseURL: false),
                urlComponents.scheme == nil {
                urlComponents.scheme = "https"
                imageURL = urlComponents.url ?? imageURL
            }
            self.imageURL = imageURL
        }
        
        if let languageCount = mobileview["languagecount"] as? Int {
            self.languageCount = languageCount
        }
        self.areOtherLanguagesAvailable = languageCount > 0

        if let pageprops = mobileview["pageprops"] as? JSONDictionary,
            let wikibaseItem = pageprops["wikibase_item"] as? String {
            self.wikidataID = wikibaseItem
        }

    }
}
