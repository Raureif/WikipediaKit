//
//  String+Wikipedia.swift
//  WikipediaKit
//
//  Created by Frank Rausch on 2015-04-07.
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

extension String {
    
    public func wikipediaURLEncodedString(replaceSpacesWithUnderscores: Bool = true, encodeSlashes: Bool = false) -> String {
        var string = self
        
        // Wikipedia URL encoding specialties:
        // - Spaces can be replaced with underscores
        // - Colons and parentheses are allowed
        
        if replaceSpacesWithUnderscores {
            string = string.replacingOccurrences(of: " ", with: "_")
        }
        
        var characterSet = NSMutableCharacterSet.urlQueryAllowed
        
        // Comma must not be encoded, otherwise the Most Read articles API call will not work on ru.wikipedia.org
        var delimitersToEncode = ":#[]@!$?&'()*+="

        if encodeSlashes {
            delimitersToEncode.append("/")
        }

        characterSet.remove(charactersIn: delimitersToEncode)
        
        return string.addingPercentEncoding(withAllowedCharacters: characterSet as CharacterSet) ?? string
    }

}
