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
                                          urls: [URL],
                                          width: Int? = nil,
                                          completion: @escaping ([WikipediaImage]?, WikipediaError?) -> ())
        -> URLSessionDataTask? {
            
        guard let firstURL = urls.first,
                  firstURL.path != "" else {
                DispatchQueue.main.async {
                    completion(nil, .other(nil))
                }
                return nil
        }
            
            // Strip the path from the original media URLs
            // so we get the ID like "File:Flag of Lower Saxony.svg"
            var imageIDs = [String]()
            for url in urls {
                let imageID = url.path.replacingOccurrences(of: "/wiki/", with: "")
                imageIDs.append(imageID)
            }

            return self.requestSizedImageMetadata(language: language, ids: imageIDs, width: width) { imageMetadata, error in
                DispatchQueue.main.async {
                    completion(imageMetadata, error)
                }
            }
    }
    
    public func requestSizedImageMetadata(language: WikipediaLanguage,
                                          ids: [String],
                                          width: Int? = nil,
                                          completion: @escaping ([WikipediaImage]?, WikipediaError?) -> ())
        -> URLSessionDataTask? {

        let idsParameter = ids.joined(separator: "|")

        var parameters: [String:String] = [
            "action": "query",
            "format": "json",
            "formatversion" : "2",
            "titles": idsParameter,
            "prop": "imageinfo",
            "iilimit": "1",
            "iiprop": "url|size|mime|thumbmime|extmetadata",
            "iiextmetadatafilter": "ImageDescription|LicenseShortName",
            "continue": "",
            "maxage": "\(self.maxAgeInSeconds)",
            "smaxage": "\(self.maxAgeInSeconds)",
            "uselang": language.variant ?? language.code,
            ]

            if let width = width {
                parameters["iiurlwidth"] = "\(width)"
            } else {
                #if DEBUG
                    print("If no thumbnail size is passed, the resulting file format may not match (e.g. pdf instead of .pdf.png) because the original file is returned.")
                #endif
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
                DispatchQueue.main.async {
                    completion (nil, error)
                }
                return
            }
            
            guard let jsonDictionary = jsonDictionary,
                let query = jsonDictionary["query"] as? JSONDictionary,
                let pages = query["pages"] as? [JSONDictionary]
                else {
                DispatchQueue.main.async {
                    completion (nil, .decodingError)
                }
                return
            }

            var images = [WikipediaImage]()
            for page in pages {
                if let metadata = WikipediaImage(jsonDictionary: page, language: language) {
                    images.append(metadata)
                }
            }
            DispatchQueue.main.async {
                completion(images, error)
            }
        }
        
    }
}
