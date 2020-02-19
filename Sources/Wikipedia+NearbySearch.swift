//
//  Wikipedia+NearbySearch.swift
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
    
    public func requestNearbyResults(language: WikipediaLanguage,
                                     latitude: Double,
                                     longitude: Double,
                                     maxCount: Int = 10,
                                     // 10_000 meters is the API max limit:
                                     maxRadiusInMeters: Double = 10_000,
                                     imageWidth: Int = 200,
                                     loadExtracts: Bool = false,
                                     completion: @escaping ([WikipediaArticlePreview]?, WikipediaLanguage, WikipediaError?) -> ())
        -> URLSessionDataTask? {
            
            if imageWidth == 0 {
                #if DEBUG
                    print("WikipediaKit: The response will have no thumbnails because the imageWidth you passed is 0")
                #endif
            }

            var parameters = [
                "action": "query",
                "ggscoord": "\(latitude)|\(longitude)",
                "format": "json",
                "formatversion": "2",
                "generator": "geosearch",
                "ggsradius": "\(Int(maxRadiusInMeters))",
                "prop": "coordinates|pageimages|pageterms",
                "codistancefrompoint": "\(latitude)|\(longitude)",
                "colimit": "50",
                "pithumbsize": "\(imageWidth)",
                "pilimit": "50",
                "wbptterms": "description",
                "continue": "",
                "maxage": "\(self.maxAgeInSeconds)",
                "smaxage": "\(self.maxAgeInSeconds)",
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
                        if !results.contains(result)
                            && result.coordinate != nil
                            && !(result.initialDistance ?? 0 > maxRadiusInMeters) {
                            results.append(result)
                        }
                    }
                }
                
                // sort locations by distance
                results.sort(by: { $0.initialDistance ?? 0 < $1.initialDistance ?? 0 } )
                
                // Wikipedia API docs recommend requesting more results 
                // than needed and then discarding the surplus
                // See https://www.mediawiki.org/wiki/Extension:GeoData#API
                results = Array(results.prefix(maxCount))
                
                DispatchQueue.main.async {
                    completion(results, language, error)
                }
                
            }
    }
}
