//
//  WikipediaArticleCache.swift
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

class WikipediaArticleCache {
    
    let cache = NSCache<AnyObject,WikipediaArticle>()
    
    func add(_ article: WikipediaArticle) {
        let cacheKey = self.cacheKey(language: article.language, title: article.title)
        self.cache.setObject(article, forKey: cacheKey)
    }
    
    func get(language: WikipediaLanguage, title: String) -> WikipediaArticle? {
        let cacheKey = self.cacheKey(language: language, title: title)
        let cachedSearchResult = self.cache.object(forKey: cacheKey)
        return cachedSearchResult
    }
    
    func cacheKey(language: WikipediaLanguage, title: String) -> AnyObject {
        let languageKey = language.variant ?? language.code
        let cacheKey = "\(languageKey)/\(title)"
        return cacheKey as AnyObject
    }
}
