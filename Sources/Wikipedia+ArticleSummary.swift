//
//  Wikipedia+ArticleSummary.swift
//  WikipediaKit
//
//  Created by Frank Rausch on 2018-07-30.
//  Copyright © 2018 Raureif GmbH / Frank Rausch
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

    public func requestArticleSummary(language: WikipediaLanguage,
                               title: String,
                               completion: @escaping (WikipediaArticlePreview?, WikipediaError?)->())
        -> URLSessionDataTask? {

            let title = title.wikipediaURLEncodedString(encodeSlashes: true)

            // We use the REST API here because that’s what the Wikipedia website calls for the link hover previews.
            // It’s very fast.
            let urlString = "https://\(language.code).wikipedia.org/api/rest_v1/page/summary/\(title)"

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

                let articlePreview = WikipediaArticlePreview(jsonDictionary: jsonDictionary, language: language)

                DispatchQueue.main.async {
                    completion(articlePreview, error)
                }
            }
    }
}
