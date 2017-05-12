//
//  WikipediaArticleLanguageLink.swift
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

public struct WikipediaArticleLanguageLink {
    
    public let language: WikipediaLanguage
    public let title: String
    public let url: URL
    
    public init(language: WikipediaLanguage, title: String, url: URL) {
        self.language = language
        self.title = Wikipedia.sharedFormattingDelegate?.format(context: .articleTitle, rawText: title, title: title, language: language, isHTML: false) ?? title
        self.url = url
    }
}

extension WikipediaArticleLanguageLink {
    init?(jsonDictionary dict: JSONDictionary) {
        guard let languageCode = dict["lang"] as? String,
            let localizedName = dict["langname"] as? String,
            let autonym = dict["autonym"] as? String,
            let title = dict["title"] as? String, // TODO: Can we also get the display title here?
            let urlString = dict["url"] as? String,
            let url = URL(string: urlString)
        else { return nil }
        
        if !WikipediaLanguage.isBlacklisted(languageCode: languageCode) {
            let language = WikipediaLanguage(code: languageCode, localizedName: localizedName, autonym: autonym)
            self.init(language: language, title: title, url: url)
        } else {
            return nil
        }
    }
}
