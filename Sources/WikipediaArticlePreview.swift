//
//  WikipediaArticlePreview.swift
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

#if os(iOS)
import UIKit // required for CGSize
#endif

#if os(watchOS)
import WatchKit // required for CGSize
#endif

#if os(tvOS)
import TVMLKit // required for CGSize
#endif


public func ==(lhs: WikipediaArticlePreview, rhs: WikipediaArticlePreview) -> Bool {
    return lhs.title == rhs.title && lhs.language == rhs.language
}

public class WikipediaArticlePreview: Hashable, Equatable {
    
    public var language: WikipediaLanguage
    
    public var title: String
    public lazy var displayTitle: String = {
        // TODO: Find out if we can get the display title from the Search API
        //       (it’s possible with the Article API)
        let t = (Wikipedia.sharedFormattingDelegate?.format(context: .articleTitle,
                                                                       rawText: self.title,
                                                                       title: self.title,
                                                                       language: self.language,
                                                                       isHTML: true)) ?? self.title
        return t
    }()
    
    // The article excerpt
    public var rawText: String
    public var displayText: String
    
    // A short meta description provided by the API
    public var description = ""
    
    public var imageURL: URL?
    public var imageDimensions: CGSize?
    
    public lazy var url: URL? = {
        let escapedTitle = self.title.wikipediaURLEncodedString()
        let urlString = "https://" + self.language.code + ".wikipedia.org/wiki/" + escapedTitle
        let url = URL(string: urlString)
        return url
    }()
    
    // This index is used for sorting search results
    // The API delivers the results in a random order, but with indices
    var index = 0
    
    public var coordinate: (latitude: Double, longitude: Double)?
    
    // Distance in meters from search coordinate in NearbySearch results
    public var initialDistance: Double?
    
    static let disambiguationLocalizations = [
        // TODO: Add more translations for “disambiguation”
        // Must be lowercase
        "de" : "begriffsklärung",
        "en" : "disambiguation",
        "es" : "desambiguación",
        "fr" : "homonymie",
        "it" : "disambigua",
        "nl" : "doorverwijspagina",
        "pl" : "ujednoznacznienie",
        "sv" : "olika betydelser",
    ]
    
    public lazy var isDisambiguation: Bool = {
        // This is the most reliable way to find out whether we’re dealing with a disambiguation page
        if let localizedDisambiguation = WikipediaArticlePreview.disambiguationLocalizations[self.language.code],
            self.description.lowercased().range(of: localizedDisambiguation) != nil {
            return true
        }
        return false
    }()
    
    public init(language: WikipediaLanguage, title: String, text: String) {
        self.language = language
        self.title = title
        self.rawText = text
        // We don’t do this lazily because this will probably be needed instantly
        // in TableViews or CollectionViews
        self.displayText = Wikipedia.sharedFormattingDelegate?.format(context: .articlePreview, rawText: text, title: title, language: language, isHTML: true) ?? text
    }


    public func hash(into hasher: inout Hasher) {
        hasher.combine(title.hashValue)
        hasher.combine(language.hashValue)
    }
    
}

extension WikipediaArticlePreview {
    
    convenience init?(jsonDictionary dict: JSONDictionary, language: WikipediaLanguage) {
        
        guard let title = dict["title"] as? String else { return nil }
        
        let text = dict["extract"] as? String ?? ""
        
        self.init(language: language, title: title, text: text)
        
        if let terms = dict["terms"] as? JSONDictionary,
            let descriptions = terms["description"] as? [String] {
            let description = descriptions.first ?? ""
            self.description = (Wikipedia.sharedFormattingDelegate?.format(context: .articleDescription,
                                                                           rawText: description,
                                                                           title: title,
                                                                           language: language,
                                                                           isHTML: true)) ?? description
        }
        
        if let thumbnail = dict["thumbnail"] as? JSONDictionary,
           let source = thumbnail["source"] as? String {
           
            self.imageURL = URL(string: source)
            
            if let width = thumbnail["width"] as? Int,
               let height = thumbnail["height"] as? Int {
                self.imageDimensions = CGSize(width: CGFloat(width), height: CGFloat(height))
            }
        }
        
        if let coordinatesWrapper = dict["coordinates"] as? [JSONDictionary],
           let coordinates = coordinatesWrapper.first,
           let latitude = coordinates["lat"] as? Double,
           let longitude = coordinates["lon"] as? Double,
           let initialDistance = coordinates["dist"] as? Double {
           
            self.coordinate = (latitude: latitude, longitude: longitude)
            self.initialDistance = initialDistance
        }
        
        if let index = dict["index"] as? Int {
            self.index = index
        }
    }
}
