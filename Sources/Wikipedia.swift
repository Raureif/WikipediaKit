//
//  Wikipedia.swift
//  WikipediaKit
//
//  Created by Frank Rausch on 2016-07-25.
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

typealias JSONDictionary = [String:AnyObject]

public class Wikipedia {

    // Public initializer is required if we don’t use the shared singleton
    public init() {}

    public static let shared: Wikipedia = {
        return Wikipedia()
    }()

    public static weak var sharedFormattingDelegate: WikipediaTextFormattingDelegate?
    public static weak var sharedBlacklistDelegate: WikipediaBlacklistDelegate?

    let articleCache: WikipediaArticleCache = {
       return WikipediaArticleCache()
    }()

    let searchResultsCache: WikipediaSearchResultsCache = {
        return WikipediaSearchResultsCache()
    }()
    
    // This cache setting will be mirrored in the headers returned by Wikipedia’s servers
    // and thus respected by NSURLSession’s NSURLCache
    public var maxAgeInSeconds = 60 * 60 * 2 // 2 hours by default
    
    public static func baseURL(language: WikipediaLanguage) -> URL? {
        return URL(string:"https://\(language.code).wikipedia.org/w/api.php")
    }
    
    // We need a way to cancel these nested requests before starting new ones.
    // TODO: Find a more elegant solution than these properties
    var secondSearchRequest: URLSessionDataTask?
    var mostReadArticleDetailsRequest: URLSessionDataTask?
    
    static func buildURLRequest(language: WikipediaLanguage, parameters: [String:String]) -> URLRequest? {
        guard let baseUrl = self.baseURL(language: language) else { return nil }
        
        guard let url = Wikipedia.buildURL(baseUrl, queryParameters: parameters) else { return nil }
        let request = URLRequest(url: url)
        
        return request
    }
    
    static func buildURL(_ URL : URL, queryParameters : Dictionary<String, String>) -> URL? {
        let URLString = "\(URL.absoluteString)?\(self.stringFromQueryParameters(queryParameters))"
        return Foundation.URL(string: URLString)
    }
    
    static func stringFromQueryParameters(_ queryParameters : Dictionary<String, String>) -> String {
        var parts: [String] = []
        
        for (name, value) in queryParameters {
            let escapedName = name.wikipediaURLEncodedString(replaceSpacesWithUnderscores: false)
            let escapedValue = value.wikipediaURLEncodedString(replaceSpacesWithUnderscores: false)
            let part = "\(escapedName)=\(escapedValue)"
            
            parts.append(part as String)
        }
        
        return parts.joined(separator: "&")
    }
   
}
