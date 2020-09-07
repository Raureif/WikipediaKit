//
//  Wikipedia+Article.swift
//  WikipediaKit
//
//  Created by Frank Rausch on 2020-09-01.
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

extension Wikipedia {
    
    public func requestArticle(language: WikipediaLanguage,
                               title: String,
                               fragment: String? = nil,
                               imageWidth: Int,
                               completion: @escaping (Result<WikipediaArticle, WikipediaError>)->())
        -> URLSessionDataTask? {
            
        
        if let cachedArticle = self.articleCache.get(language: language, title: title) {
            DispatchQueue.main.async {
                completion(.success(cachedArticle))
            }
            return nil
        }

        let title = title.wikipediaURLEncodedString(encodeSlashes: true)

        let urlString = "https://\(language.code).wikipedia.org/api/rest_v1/page/mobile-sections/\(title)"

        guard let url = URL(string: urlString)
            else {
                DispatchQueue.main.async {
                    completion(.failure(.other(nil)))
                }
                return nil
        }

        let request = URLRequest(url: url)

        return WikipediaNetworking.shared.loadJSON(urlRequest: request) { jsonDictionary, error in
            
            guard error == nil else {
                DispatchQueue.main.async {
                    completion (.failure(error!))
                }
                return
            }
            
            guard let jsonDictionary = jsonDictionary  else {
                DispatchQueue.main.async {
                    completion (.failure(.decodingError))
                }
                return
            }

            if let article = WikipediaArticle(jsonDictionary: jsonDictionary, language: language, title: title, fragment: fragment, imageWidth: imageWidth) {
                self.articleCache.add(article)
                DispatchQueue.main.async {
                    completion(.success(article))
                }
            } else {
                DispatchQueue.main.async {
                    completion(.failure(.decodingError))
                }
            }
        }
    }
}
