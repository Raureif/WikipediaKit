//
//  Wikipedia+Article.swift
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
    
    public func requestArticle(language: WikipediaLanguage,
                               title: String,
                               fragment: String? = nil,
                               imageWidth: Int,
                               completion: @escaping (WikipediaArticle?, WikipediaError?)->())
        -> URLSessionDataTask? {
            
        
        if let cachedArticle = self.articleCache.get(language: language, title: title) {
            DispatchQueue.main.async {
                completion(cachedArticle, nil)
            }
            return nil
        }
        
        let parameters: [String:String] = [
            "action": "mobileview",
            "format": "json",
            "page": title,
            "mobileformat": "1",
            "prop": "id|text|sections|languagecount|displaytitle|description|image|thumb|pageprops",
            "sections": "all",
            "sectionprop": "toclevel|level|line|anchor",
            "thumbwidth" : "\(imageWidth)",
            "redirect": "yes",
            "maxage": "\(self.maxAgeInSeconds)",
            "smaxage": "\(self.maxAgeInSeconds)",
            "uselang": language.variant ?? language.code,
            ]
        
        guard let request = Wikipedia.buildURLRequest(language: language, parameters: parameters) else {
                DispatchQueue.main.async {
                    completion(nil, .other(nil))
                }
                return nil
        }
        
        return WikipediaNetworking.shared.loadJSON(urlRequest: request) { jsonDictionary, error in
            
            guard error == nil else {
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
            
            if let apiError = jsonDictionary["error"] as? JSONDictionary,
                let apiErrorInfo = apiError["info"] as? String {
                
                var wikipediaError: WikipediaError
                
                if let apiErrorCode = apiError["code"] as? String,
                       apiErrorCode == "missingtitle" {
                    
                    wikipediaError = .notFound
                } else {
                    wikipediaError = .apiError(apiErrorInfo)
                }
                
                DispatchQueue.main.async {
                    completion (nil, wikipediaError)
                }
                return
            }
            
            let article = WikipediaArticle(jsonDictionary: jsonDictionary, language: language, title: title, fragment: fragment)
            
            if let article = article {
                self.articleCache.add(article)
            }
            
            DispatchQueue.main.async {
                completion(article, error)
            }
        }
    }
}
