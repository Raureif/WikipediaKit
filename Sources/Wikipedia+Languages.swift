//
//  Wikipedia+Languages.swift
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
    
    public func requestAvailableLanguages(for article: WikipediaArticle,
                                          completion: @escaping (WikipediaArticle, WikipediaError?)->())
        -> URLSessionDataTask? {
            
        guard article.languageLinks == nil, // has not been populated previously
              article.areOtherLanguagesAvailable // other languages are available
              else {
                DispatchQueue.main.async {
                    completion(article, nil)
                }
                return nil
        }
            
        let parameters: [String:String] = [
            "action": "parse",
            "format": "json",
            "formatversion": "2",
            "page" : article.title,
            "prop": "langlinks",
            "maxage": "\(self.maxAgeInSeconds)",
            "smaxage": "\(self.maxAgeInSeconds)",
            "uselang": WikipediaLanguage.systemLanguage.variant ?? WikipediaLanguage.systemLanguage.code,
            ]
        
        guard let request = Wikipedia.buildURLRequest(language: article.language, parameters: parameters)
            else {
                DispatchQueue.main.async {
                    completion(article, .other(nil))
                }
                return nil
        }
        
        return WikipediaNetworking.shared.loadJSON(urlRequest: request) { jsonDictionary, error in
            
            guard error == nil else {
                // (also occurs when the request was cancelled programmatically)
                DispatchQueue.main.async {
                    completion (article, error)
                }
                return
            }
            
            guard let jsonDictionary = jsonDictionary  else {
                DispatchQueue.main.async {
                    completion (article, .decodingError)
                }
                return
            }
            
            guard let parse = jsonDictionary["parse"] as? JSONDictionary,
                let langlinks = parse["langlinks"] as? [JSONDictionary]
                else {
                    DispatchQueue.main.async {
                        completion (article, .decodingError)
                    }
                    return
            }
            let languages = langlinks.compactMap(WikipediaArticleLanguageLink.init)
            article.languageLinks = languages
            DispatchQueue.main.async {
                completion(article, error)
            }
        }
    }
}
