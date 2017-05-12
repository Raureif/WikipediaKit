//
//  Wikipedia+ImageMeta.swift
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
    
    public func requestSizedImageMetadata(language: WikipediaLanguage,
                                          url: URL,
                                          width: Int,
                                          completion: @escaping (WikipediaImage?, WikipediaError?) -> ())
        -> URLSessionDataTask? {
            
        guard url.path != "" else {
                DispatchQueue.main.async {
                    completion(nil, .other(nil))
                }
                return nil
        }
            
        // Strip the path from the original media URL
        // so we get the ID like "File:Flag of Lower Saxony.svg"
        let imageID = url.path.replacingOccurrences(of: "/wiki/", with: "")
        return self.requestSizedImageMetadata(language: language, id: imageID, width: width) { imageMetadata, error in
            DispatchQueue.main.async {
                completion(imageMetadata, error)
            }
        }
    }
    
    public func requestSizedImageMetadata(language: WikipediaLanguage,
                                          id: String,
                                          width: Int,
                                          completion: @escaping (WikipediaImage?, WikipediaError?) -> ())
        -> URLSessionDataTask? {
            
        let parameters: [String:String] = [
            "action": "query",
            "format": "json",
            "formatversion" : "2",
            "titles": id,
            "prop": "imageinfo",
            "iilimit": "1",
            "iiprop": "url|size|mime|thumbmime|extmetadata",
            "iiextmetadatafilter": "ImageDescription|LicenseShortName",
            "iiurlwidth": "\(width)",
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
            
            let imageProperties = WikipediaImage(jsonDictionary: jsonDictionary, language: language)
            DispatchQueue.main.async {
                completion(imageProperties, error)
            }
        }
        
    }
}
