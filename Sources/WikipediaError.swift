//
//  WikipediaError.swift
//  WikipediaKit
//
//  Created by Frank Rausch on 2016-08-22.
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


public func ==(lhs: WikipediaError, rhs: WikipediaError) -> Bool {
    switch (lhs, rhs) {
    case (.apiError(let a), .apiError(let b)):
        return a == b
    case (.cancelled, .cancelled):
        return true
    case (.notFound, .notFound):
        return true
    case (.noInternetConnection, .noInternetConnection):
        return true
    case (.notEnoughResults, .notEnoughResults):
        return true
    case (.decodingError, .decodingError):
        return true
    case (.badResponse, .badResponse):
        return true
    case (.other(let a), .other(let b)):
        return a == b
    default:
        return false
    }
}

public enum WikipediaError: Error, Equatable {
    case apiError(String)
    case cancelled
    case notFound
    case noInternetConnection
    case notEnoughResults
    case decodingError
    case badResponse
    case other(String?)
}

