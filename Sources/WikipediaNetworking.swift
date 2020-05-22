//
//  WikipediaNetworking.swift
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

public class WikipediaNetworking {
    
    public static var appAuthorEmailForAPI = ""
    
    public static let shared: WikipediaNetworking = {
        return WikipediaNetworking()
    }()

    public static var debugPerformance = false

    private func logMessage(_ message: String) {
        #if DEBUG
        if WikipediaNetworking.debugPerformance {
            print("WikipediaKit: \(message)")
        }
        #endif
    }

    public static weak var sharedActivityIndicatorDelegate: WikipediaNetworkingActivityDelegate?
    
    let session = URLSession(configuration: URLSessionConfiguration.default)
    
    func loadJSON(urlRequest: URLRequest,
                  completion: @escaping (JSONDictionary?, WikipediaError?) -> ())
        -> URLSessionDataTask {

        let startTime: Date
        #if DEBUG
            startTime = Date()
            self.logMessage("Fetching \(urlRequest.url!.absoluteString)")
        #endif
        
        var urlRequest = urlRequest
        urlRequest.setValue(self.userAgent, forHTTPHeaderField: "User-Agent")

        // Here’s the weird trick to get the correct Chinese variant (Traditional/Simplified/etc.):
        // We check with the OS if the user’s list of preferred languages contains Chinese.
        // We then use the topmost Chinese variant and prioritize it over the primary system language,
        // passing it in the Accept-Language header. This guarantees that the user sees
        // their preferred Chinese variant, even if Chinese is not the primary system language.
            
        urlRequest.setValue(WikipediaLanguage.preferredChineseVariant
                            ?? WikipediaLanguage.systemLanguage.variant
                            ?? WikipediaLanguage.systemLanguage.code,
                            forHTTPHeaderField: "Accept-Language")
        
        WikipediaNetworking.sharedActivityIndicatorDelegate?.start()
        let task = session.dataTask(with: urlRequest) { data, response, error in
            WikipediaNetworking.sharedActivityIndicatorDelegate?.stop()

            #if DEBUG
                let endNetworkingTime = Date()
                let totalNetworkingTime: Double = endNetworkingTime.timeIntervalSince(startTime)
                self.logMessage("\(totalNetworkingTime) seconds for network retrieval")
            #endif

            if let error = error {
                var wikipediaError: WikipediaError
                if (error as NSError).code == NSURLErrorCancelled {
                    wikipediaError = .cancelled
                } else {
                    // Fallback description from NSError; tends do be rather user-unfriendly
                    wikipediaError = .other(error.localizedDescription)
                    // See http://nshipster.com/nserror/
                    if (error as NSError).domain == NSURLErrorDomain {
                        switch (error as NSError).code {
                        case NSURLErrorNotConnectedToInternet:
                            fallthrough
                        case NSURLErrorNetworkConnectionLost:
                            fallthrough
                        case NSURLErrorResourceUnavailable:
                            wikipediaError = .noInternetConnection
                        case NSURLErrorBadServerResponse:
                            wikipediaError = .badResponse
                        default: ()
                        }
                    }
                }
                completion(nil, wikipediaError)
                return
            }

            guard let data = data,
                let response = response as? HTTPURLResponse,
                200...299 ~= response.statusCode
                else {
                    completion(nil, .badResponse)
                    return
            }

            guard let json = try? JSONSerialization.jsonObject(with: data, options: []),
                let jsonDictionary = json as? JSONDictionary
                else {
                    completion(nil, .decodingError)
                    return
            }

            #if DEBUG
                let endTime = NSDate()
                let totalTime = endTime.timeIntervalSince(startTime as Date)
                self.logMessage("\(totalTime) seconds for network retrieval & JSON decoding")
            #endif
            
            completion(jsonDictionary, nil)
        }
        task.resume()
        return task
    }

    public var userAgent: String = {
        let framework: String
        if let frameworkInfo = Bundle(for: WikipediaNetworking.self).infoDictionary,
            let frameworkMarketingVersion = frameworkInfo["CFBundleShortVersionString"] as? String {
            framework = "WikipediaKit/\(frameworkMarketingVersion)"
        } else {
            framework = "WikipediaKit"
        }

        if let infoDictionary = Bundle.main.infoDictionary {
            let bundleName = infoDictionary[kCFBundleExecutableKey as String] as? String ?? "Unknown App"
            let bundleID = infoDictionary[kCFBundleIdentifierKey as String] as? String ?? "Unkown Bundle ID"
            let marketingVersionString = infoDictionary["CFBundleShortVersionString"] as? String ?? "Unknown Version"
            
            let userAgent = "\(bundleName)/\(marketingVersionString) (\(bundleID); \(WikipediaNetworking.appAuthorEmailForAPI)) \(framework)"
            #if DEBUG
                print(userAgent)
                if WikipediaNetworking.appAuthorEmailForAPI.isEmpty {
                    print("IMPORTANT: Please set your email address in WikipediaNetworking.appAuthorEmailForAPI on launch (or before making the first API call), for example in your App Delegate.\nSee https://www.mediawiki.org/wiki/API:Main_page#Identifying_your_client")
                }
            #endif
            return userAgent
        }
        
        return framework // fallback, should never be reached
    }()

}
