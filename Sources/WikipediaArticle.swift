//
//  WikipediaArticle.swift
//  WikipediaKit
//
//  Created by Frank Rausch on 2020-09-01.
//  Copyright © 2020 Raureif GmbH / Frank Rausch
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
    convenience init?(jsonDictionary dict: JSONDictionary, language: WikipediaLanguage, title: String, fragment: String? = nil, imageWidth: Int = 320) {
        
        guard let lead = dict["lead"] as? JSONDictionary,
              let leadSections = lead["sections"] as? [JSONDictionary],
              let leadFirstSection = leadSections.first,
              let leadText = leadFirstSection["text"] as? String
        else {
                return nil
        }

        var text = ""
        
        if let hatnotes = lead["hatnotes"] as? String {
            text += #"<div class="wikipediakit-hatnotes">"#
            text += hatnotes
            text += "</div>"
        }

        text += leadText

        var toc = [WikipediaTOCItem]()

        if let remaining = dict["remaining"] as? JSONDictionary,
           let remainingSections = remaining["sections"] as? [JSONDictionary] {

            for section in remainingSections {
                if let sectionText = section["text"] as? String {
                    // The first section (intro) does not have an anchor
                    if let sectionAnchor = section["anchor"] as? String {
                        var sectionTitle = (section["line"] as? String ?? "")
                        sectionTitle = (Wikipedia.sharedFormattingDelegate?.format(context: .tableOfContentsItem,
                                                                                   rawText: sectionTitle,
                                                                                   title: title,
                                                                                   language: language,
                                                                                   isHTML: true)) ?? sectionTitle
                        let sectionTocLevel = section["toclevel"] as? Int ?? 1
                        toc.append(WikipediaTOCItem(title: sectionTitle, anchor: sectionAnchor, tocLevel: sectionTocLevel))

                        text += "<h\(sectionTocLevel) id=\"\(sectionAnchor)\">\(sectionTitle)</h\(sectionTocLevel)>"
                    }
                    text += sectionText
                }
            }
        }
        
        let title = lead["normalizedtitle"] as? String ?? title

        let rawDisplayTitle = (lead["displaytitle"] as? String) ?? title
        
        self.init(language: language, title: title, displayTitle: rawDisplayTitle)

        self.scrollToFragment = fragment
        self.rawText = text
        self.toc = toc

        if let imageProperties = lead["image"] as? JSONDictionary,
            let imageID = imageProperties["file"] as? String,
            let thumbs = imageProperties["urls"] as? JSONDictionary {

            self.imageID = imageID

            let availableWidths: [Int] = Array(thumbs.keys).compactMap { return Int($0) }.sorted()

            var bestSize = availableWidths.first ?? imageWidth
            for width in availableWidths {
                bestSize = width
                if width >= imageWidth {
                    continue
                }
            }

            if let imageURLString = thumbs["\(bestSize)"] as? String,
                let imageURL = URL(string: imageURLString) {
                self.imageURL = imageURL
            }
        }

        if let languageCount = lead["languagecount"] as? Int {
            self.languageCount = languageCount
        }
        self.areOtherLanguagesAvailable = languageCount > 0

        if let wikibaseItem = lead["wikibase_item"] as? String {
            self.wikidataID = wikibaseItem
        }

        if let geo = lead["geo"] as? JSONDictionary,
           let latitude = geo["latitude"] as? Double,
           let longitude = geo["longitude"] as? Double {
            self.coordinate = (latitude, longitude)
        }
    }
}
