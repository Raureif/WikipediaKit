//
//  WikipediaSearchResultsCache.swift
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

class WikipediaSearchResultsCache {
    
    let cache = NSCache<AnyObject,WikipediaSearchResults>()
    
    
    func add(_ searchResults: WikipediaSearchResults) {
        let cacheKey = self.cacheKey(method: searchResults.searchMethod, language: searchResults.language, term: searchResults.term)
        self.cache.setObject(searchResults, forKey: cacheKey as AnyObject)
    }
    
    func get(method: WikipediaSearchMethod, language: WikipediaLanguage, term: String) -> WikipediaSearchResults? {
        let cacheKey = self.cacheKey(method: method, language: language, term: term)
        let cachedSearchResult = self.cache.object(forKey: cacheKey as AnyObject)
        return cachedSearchResult
    }
    
    func cacheKey(method: WikipediaSearchMethod, language: WikipediaLanguage, term: String) -> String {
        let languageKey = language.variant ?? language.code
        let cacheKey = "\(method.rawValue)/\(languageKey)/\(term)"
        return cacheKey
    }
    
}

