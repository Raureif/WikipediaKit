//
//  Wikipedia+RandomArticles.swift
//  WikipediaKit
//
//  Created by Frank Rausch on 2017-06-07.
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

    public func requestSingleRandomArticle(language: WikipediaLanguage,
                                      maxCount: Int = 1,
                                      imageWidth: Int,
                                      loadExtracts: Bool = false,
                                      completion: @escaping (WikipediaArticlePreview?, WikipediaLanguage, WikipediaError?)-> ())
    -> URLSessionDataTask? {
        if WikipediaRandomArticlesBuffer.shared.language == language,
           let nextArticlePreview = WikipediaRandomArticlesBuffer.shared.nextArticlePreview() {
            completion(nextArticlePreview, language, nil)
            return nil
        } else {
            return Wikipedia.shared.requestRandomArticles(language: language, maxCount: maxCount, imageWidth: imageWidth, loadExtracts: loadExtracts) { articlePreviews, language, error in
                
                guard let articlePreviews = articlePreviews else {
                    DispatchQueue.main.async {
                        completion(nil, language, error)
                    }
                    return
                }
                
                WikipediaRandomArticlesBuffer.shared.articlePreviews = articlePreviews
                
                let articlePreview = WikipediaRandomArticlesBuffer.shared.nextArticlePreview()
                DispatchQueue.main.async {
                    completion(articlePreview, language, error)
                }
            }
        }
    }
    
    public func requestRandomArticles(language: WikipediaLanguage,
                                      maxCount: Int = 8,
                                      imageWidth: Int,
                                      loadExtracts: Bool = false,
                                      completion: @escaping ([WikipediaArticlePreview]?, WikipediaLanguage, WikipediaError?)-> ())
    -> URLSessionDataTask? {
        
        if imageWidth == 0 {
            print("WikipediaKit: The response will have no thumbnails because the imageWidth you passed is 0")
        }

        var parameters = [
            "action": "query",
            "format": "json",
            "formatversion": "2",
            "generator": "random",
            "grnfilterredir": "nonredirects",
            "grnlimit": "\(maxCount)",
            "grnnamespace": "\(WikipediaNamespace.main.rawValue)",
            "prop": "pageterms|pageimages|pageprops",
            "pithumbsize": "\(imageWidth)",
            "pilimit": "\(maxCount)",
            "continue": "",
            // no caching for random articles
            "maxage": "0",
            "smaxage": "0",
        ]

        if loadExtracts {
            parameters["prop"] = "\(parameters["prop"] ?? "")|extracts"
            
            let extraParameters = [
                "explaintext": "1",
                "exintro": "1",
                // 20 is the API max limit:
                "exlimit": "20",
                ]
            extraParameters.forEach { parameters[$0] = $1 }
        }

        guard let request = Wikipedia.buildURLRequest(language: language, parameters: parameters)
            else {
                DispatchQueue.main.async {
                    completion(nil, language, .other(nil))
                }
                return nil
        }
        
        return WikipediaNetworking.shared.loadJSON(urlRequest: request) { jsonDictionary, error in
            
            guard error == nil else {
                // (also occurs when the request was cancelled programmatically)
                DispatchQueue.main.async {
                    completion (nil, language, error)
                }
                return
            }
            
            guard let jsonDictionary = jsonDictionary else {
                DispatchQueue.main.async {
                    completion (nil, language, .decodingError)
                }
                return
            }
            
            guard let query = jsonDictionary["query"] as? JSONDictionary else {
                DispatchQueue.main.async {
                    // If nothing is found,
                    // there is no “query” key,
                    // but unfortunately no error message either
                    completion (nil, language, .notFound)
                }
                return
            }
            
            if let error = query["error"] as? JSONDictionary,
                let info = error["info"] as? String {
                DispatchQueue.main.async {
                    completion (nil, language, .apiError(info))
                }
                return
            }

            guard let pages = query["pages"] as? [JSONDictionary] else {
                DispatchQueue.main.async {
                    completion (nil, language, .notFound)
                }
                return
            }

            var results = [WikipediaArticlePreview]()

            for page in pages {
                if let result = WikipediaArticlePreview(jsonDictionary: page, language: language) {
                    if !(Wikipedia.sharedBlacklistDelegate?.isBlacklistedForRecommendations(title: result.title, language: result.language) ?? false) {
                        results.append(result)
                    }
                }
            }
            
            DispatchQueue.main.async {
                completion(results, language, error)
            }
        }
    }
}
