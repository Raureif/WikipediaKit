//
//  Wikipedia+MostRead.swift
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
    
    public func requestMostReadArticles(language: WikipediaLanguage,
                                        date: Date,
                                        imageWidth: Int = 200,
                                        maxCount: Int = 150,
                                        completion: @escaping ([WikipediaArticlePreview]?, Date, WikipediaLanguage, WikipediaError?) -> ())
        -> URLSessionDataTask? {
        
        return self.requestMostReadArticleTitles(language: language, date: date) { titles, error in
            
            guard error == nil else {
                DispatchQueue.main.async {
                    completion(nil, date, language, error)
                }
                return
            }
            
            guard var titles = titles else {
                DispatchQueue.main.async {
                    completion(nil, date, language, .notFound)
                }
                return
            }
            
            titles = Array(titles.prefix(maxCount))
            
            self.mostReadArticleDetailsRequest?.cancel()
            
            // FIXME: This cannot be cancelled. Should we save this in an ivar like the nested search?
            self.mostReadArticleDetailsRequest = self.requestMostReadArticleDetails(language: language, titles: titles, imageWidth: imageWidth, maxCount: maxCount * 2) { results, error in
                
                guard error == nil else {
                    DispatchQueue.main.async {
                        completion(nil, date, language, error)
                    }
                    return
                }
                
                guard var results = results else {
                    DispatchQueue.main.async {
                        completion(nil, date, language, error)
                    }
                    return
                }
                
                for result in results {
                    // FIXME: Not ideal that we have to put the underscores back in.
                    result.index = titles.firstIndex(of: result.title.replacingOccurrences(of: " ", with: "_")) ?? 0
                }
                
                results.sort { $0.index < $1.index }
                
                DispatchQueue.main.async {
                    completion(results, date, language, error)
                }
                return
            }
        }
    }

    
    private func requestMostReadArticleTitles(language: WikipediaLanguage,
                                              date: Date,
                                              maxCount: Int = 50,
                                              completion: @escaping ([String]?, WikipediaError?) -> ())
        -> URLSessionDataTask? {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        
        let dateString = dateFormatter.string(from: date)
        
        let urlString = "https://wikimedia.org/api/rest_v1/metrics/pageviews/top/\(language.code).wikipedia.org/all-access/" + dateString
        
        guard let url = URL(string: urlString)
            else {
                DispatchQueue.main.async {
                    completion(nil, .other(nil))
                }
                return nil
        }
        
        let request = URLRequest(url: url)
        
        return WikipediaNetworking.shared.loadJSON(urlRequest: request) { jsonDictionary, error in
            
            guard error == nil else {
                // (also occurs when the request was cancelled programmatically)
                DispatchQueue.main.async {
                    completion (nil, error)
                }
                return
            }
            
            guard let jsonDictionary = jsonDictionary  else {
                DispatchQueue.main.async {
                    completion (nil, .decodingError)
                }
                return
            }
            
            guard let itemsArray = jsonDictionary["items"] as? [JSONDictionary],
                let item = itemsArray.first,
                let articlesArray = item["articles"] as? [JSONDictionary] else {
                    DispatchQueue.main.async {
                        completion (nil, .decodingError)
                    }
                    return
            }
            
            var titles = [String]()
            
            for (i, article) in articlesArray.enumerated() {
                if let title = article["article"] as? String {
                    titles.append(title)
                    if i >= maxCount - 1 {
                        break
                    }
                }
            }
            
            DispatchQueue.main.async {
                completion(titles, error)
            }
        }
        
    }
    
    
    private func requestMostReadArticleDetails(language: WikipediaLanguage,
                                               titles: [String],
                                               imageWidth: Int,
                                               maxCount: Int,
                                               completion: @escaping ([WikipediaArticlePreview]?, WikipediaError?) -> ())
        -> URLSessionDataTask? {
        
        var titlesString = titles.joined(separator: "|")
        
        if imageWidth == 0 {
            print("WikipediaKit: The response will have no thumbnails because the imageWidth you passed is 0")
        }
            
        if titlesString.wikipediaURLEncodedString().count > 4000 {
            // FIXME: Find a more sophisticated solution for this.
            // If the complete request URL is longer than ~5,400 characters,
            // the Wikipedia server will drop the request
            // and cause the NSURLSession to fail.
            // This happens often for languages where Cyrillic is URL-encoded.
            // See https://stackoverflow.com/a/417184
            titlesString = String(titlesString.prefix(950))
        }
        
        let parameters: [String:String] = [
            "action": "query",
            "format": "json",
            "formatversion" : "2",
            "titles": titlesString,
            "prop": "pageterms|pageimages",
            "piprop": "thumbnail",
            "pithumbsize" : "\(imageWidth)",
            "pilimit": "50", // 50 is the API max
            "continue": "",
            "maxage": "\(self.maxAgeInSeconds)",
            "smaxage": "\(self.maxAgeInSeconds)",
            "uselang": language.variant ?? language.code,
            ]
        
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
                    completion (nil, error)
                }
                return
            }
            
            guard let jsonDictionary = jsonDictionary  else {
                DispatchQueue.main.async {
                    completion (nil, .decodingError)
                }
                return
            }
            
            guard let query = jsonDictionary["query"] as? JSONDictionary else {
                DispatchQueue.main.async {
                    // There is no query but also no error message if nothing is found.
                    completion (nil, .notFound)
                }
                return
            }
            
            guard let pages = query["pages"] as? [JSONDictionary] else {
                DispatchQueue.main.async {
                    completion (nil, .notFound)
                }
                return
            }
            
            var results = [WikipediaArticlePreview]()
            
            for page in pages {

                if let isMissing = page["missing"] as? Bool,
                   isMissing == true {
                    continue
                }

                if let namespace = page["ns"] as? Int,
                    namespace != WikipediaNamespace.main.rawValue {
                    continue
                }
                
                if let title = page["title"] as? String,
                    Wikipedia.sharedBlacklistDelegate?.isBlacklistedForRecommendations(title: title, language: language) ?? false {
                    continue
                }
                
                if let result = WikipediaArticlePreview(jsonDictionary: page, language: language) {
                    if !results.contains(result) {
                        if Wikipedia.sharedBlacklistDelegate?.containsBlacklistedWords(text: result.description, language: language) ?? false {
                            continue
                        }
                        
                        results.append(result)
                    }
                }
                
            }
            
            results = Array(results.prefix(maxCount))
            DispatchQueue.main.async {
                completion(results, error)
            }
        }
    }
    
}
