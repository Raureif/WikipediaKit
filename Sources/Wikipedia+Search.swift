//
//  Wikipedia+Search.swift
//  WikipediaKit
//
//  Created by Frank Rausch on 2017-03-21.
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

extension Wikipedia {
    
    public func requestOptimizedSearchResults(language: WikipediaLanguage,
                                              term: String,
                                              existingSearchResults: WikipediaSearchResults? = nil,
                                              imageWidth: Int = 200,
                                              minCount: Int = 10,
                                              maxCount: Int = 15,
                                              completion: @escaping (WikipediaSearchResults?, WikipediaError?) -> ())
        -> URLSessionDataTask? {
        
        let searchMethod = existingSearchResults?.searchMethod ?? .prefix
        let minCount: Int? = searchMethod == .prefix ? minCount : nil // ignore the minCount for fullText search
        
        self.secondSearchRequest?.cancel()
        
        return self.requestSearchResults(method: searchMethod, language: language, term: term, existingSearchResults: existingSearchResults, imageWidth: imageWidth, minCount: minCount, maxCount: maxCount) { searchResults, error in
            
            if searchMethod != .fullText,
                let error = error,
                error == WikipediaError.notEnoughResults || error == WikipediaError.notFound {
                
                var prefixSearchResults: WikipediaSearchResults?
                if error == .notEnoughResults {
                    prefixSearchResults = searchResults
                }
                
                self.secondSearchRequest = self.requestSearchResults(method: .fullText, language: language, term: term, existingSearchResults: nil, imageWidth: imageWidth, maxCount: maxCount) { fullTextSearchResults, error in
                    if (fullTextSearchResults?.items.count ?? 0) >= (prefixSearchResults?.items.count ?? 0) {
                        DispatchQueue.main.async {
                            completion(fullTextSearchResults, error)
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion(prefixSearchResults, nil)
                        }
                    }
                    return
                }
            } else {
                DispatchQueue.main.async {
                    completion(searchResults, error)
                }
            }
        }
    }
    
    func requestSearchResults(method: WikipediaSearchMethod,
                              language: WikipediaLanguage,
                              term: String,
                              existingSearchResults: WikipediaSearchResults? = nil,
                              imageWidth: Int = 200,
                              minCount: Int? = nil,
                              maxCount: Int = 15,
                              completion: @escaping (WikipediaSearchResults?, WikipediaError?) -> ())
        -> URLSessionDataTask? {
        
        var searchResults: WikipediaSearchResults
        
        if let sr = existingSearchResults {
            
            guard sr.language == language,
                sr.term == term else {
                    DispatchQueue.main.async {
                        completion(nil, .other(nil))
                    }
                    return nil
            }
            
            searchResults = sr
        } else {
            searchResults = WikipediaSearchResults(language: language, term: term)
        }
        
        searchResults.searchMethod = method
        
        if let cachedSearchResults = self.searchResultsCache.get(method: method, language: language, term: term) {
            if cachedSearchResults.items.count > searchResults.items.count {
                DispatchQueue.main.async {
                    completion(cachedSearchResults, nil)
                }
                return nil
            } else {
                searchResults = cachedSearchResults
            }
        }
        
        searchResults.offset = searchResults.items.last?.index ?? 0
        
        if imageWidth == 0 {
            print("WikipediaKit: The response will have no thumbnails because the imageWidth you passed is 0")
        }

        let parameters: [String:String]
        
        switch method {
        case .prefix:
            parameters = [
                "action": "query",
                "format": "json",
                "generator": "prefixsearch",
                "gpssearch": term,
                "gpsnamespace": "\(WikipediaNamespace.main.rawValue)",
                "gpslimit": "\(maxCount)",
                "gpsoffset": "\(searchResults.offset)",
                "prop": "extracts|pageterms|pageimages",
                "piprop": "thumbnail",
                "pithumbsize": "\(imageWidth)",
                "pilimit": "\(maxCount)",
                "exlimit": "\(maxCount)",
                "explaintext": "1",
                "exintro": "1",
                "formatversion": "2",
                "continue": "",
                "redirects": "1",
                "converttitles": "1",
                // get search suggestions
                "srsearch": term,
                "srwhat": "text",
                "srlimit": "1",
                "srnamespace": "\(WikipediaNamespace.main.rawValue)",
                "list": "search",
                "srinfo": "suggestion",
                "maxage": "\(self.maxAgeInSeconds)",
                "smaxage": "\(self.maxAgeInSeconds)",
                "uselang": language.variant ?? language.code,
            ]
            
        case .fullText:
            parameters = [
                "action": "query",
                "format": "json",
                "generator": "search",
                "gsrsearch": term,
                "gsrnamespace": "\(WikipediaNamespace.main.rawValue)",
                "gsrlimit": "\(maxCount)",
                "gsroffset": "\(searchResults.offset)",
                "prop": "extracts|pageterms|pageimages",
                "piprop": "thumbnail",
                "pithumbsize": "\(imageWidth)",
                "pilimit": "\(maxCount)",
                "exlimit": "\(maxCount)",
                "explaintext": "1",
                "exintro": "1",
                "formatversion": "2",
                "continue": "",
                "redirects": "1",
                "converttitles": "1",
                // get search suggestions
                "list": "search",
                "srsearch": term,
                "srwhat": "text",
                "srlimit": "1",
                "sroffset": "\(searchResults.offset)",
                "srnamespace": "\(WikipediaNamespace.main.rawValue)",
                "srinfo": "suggestion",
                "maxage": "\(self.maxAgeInSeconds)",
                "smaxage": "\(self.maxAgeInSeconds)",
                "uselang": language.variant ?? language.code,
            ]
        }
        
        guard let request = Wikipedia.buildURLRequest(language: language, parameters: parameters)
            else {
                DispatchQueue.main.async {
                    completion(nil, .other(nil))
                }
                return nil
        }
        
        return WikipediaNetworking.shared.loadJSON(urlRequest: request) { jsonDictionary, error in
            
            guard error == nil else {
                // (also occurs when the request was cancelled programmatically)
                DispatchQueue.main.async {
                    completion (searchResults, error)
                }
                return
            }
            
            guard let jsonDictionary = jsonDictionary else {
                DispatchQueue.main.async {
                    completion (searchResults, .decodingError)
                }
                return
            }
            
            guard let query = jsonDictionary["query"] as? JSONDictionary else {
                DispatchQueue.main.async {
                    completion (searchResults, .notFound)
                }
                return
            }
            
            if let searchinfo = query["searchinfo"] as? JSONDictionary,
                let suggestion = searchinfo["suggestion"] as? String {
                searchResults.suggestions.removeAll()
                let capitalizedSuggestion = suggestion.capitalized(with: Locale(identifier: searchResults.language.code))
                searchResults.suggestions.append(capitalizedSuggestion)
            }
            
            if let pages = query["pages"] as? [JSONDictionary] {
                
                var results = [WikipediaArticlePreview]()
                for page in pages {
                    if let result = WikipediaArticlePreview(jsonDictionary: page, language: language) {
                        if !searchResults.items.contains(result) {
                            results.append(result)
                        }
                    }
                }
                
                // The check for <= 1 fixes a Wikipedia API bug where it will indefinitely
                // load the same item over and over again
                if jsonDictionary["continue"] == nil || results.count <= 1 {
                    searchResults.canLoadMore = false
                }
                
                results.sort { $0.index < $1.index }
                searchResults.items.append(contentsOf: results)
                
                if searchResults.offset == 0,
                    let minCount = minCount,
                    pages.count < minCount {
                    
                    DispatchQueue.main.async {
                        completion (searchResults, .notEnoughResults)
                    }
                    return
                }
                
                self.searchResultsCache.add(searchResults)
                
                DispatchQueue.main.async {
                    completion(searchResults, error)
                }
                
            }  else {
                
                // No pages and offset of 0; this means that there are no results for this query.
                if searchResults.offset == 0 {
                    DispatchQueue.main.async {
                        completion (searchResults, .notFound)
                    }
                    return
                } else {
                    // No pages found but there are already search results; this means that there are no more results.
                    searchResults.canLoadMore = false
                    DispatchQueue.main.async {
                        completion (searchResults, error)
                    }
                    return
                }
                
            }
            
        }
        
    }
}
