//
//  WikipediaFeatured.swift
//  WikipediaKit
//
//  Created by Frank Rausch on 2020-08-28.
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

public struct WikipediaFeatured {
    public let date: Date
    public let language: WikipediaLanguage

    public let articleOfTheDay: WikipediaArticlePreview?
    public let mostReadArticles: [WikipediaArticlePreview]
}

extension WikipediaFeatured {
    init?(jsonDictionary dict: JSONDictionary, language: WikipediaLanguage) {

        var articleOfTheDay: WikipediaArticlePreview?

        if let tfa = dict["tfa"] as? JSONDictionary,
           let articlePreview = WikipediaArticlePreview(jsonDictionary: tfa, language: language) {
            articleOfTheDay = articlePreview
        }

        guard let mostRead = dict["mostread"] as? JSONDictionary,
              let articles = mostRead["articles"] as? [JSONDictionary] else {
            return nil
        }

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = .withFullDate
        let dateString = mostRead["date"] as? String
        let date = dateFormatter.date(from: dateString ?? "") ?? Date()

        var mostReadArticles = [WikipediaArticlePreview]()

        for articleDict in articles {
            if let articlePreview = WikipediaArticlePreview(jsonDictionary: articleDict, language: language) {
                mostReadArticles.append(articlePreview)
            }
        }

        self.init(date: date, language: language, articleOfTheDay: articleOfTheDay, mostReadArticles: mostReadArticles)
    }
}
