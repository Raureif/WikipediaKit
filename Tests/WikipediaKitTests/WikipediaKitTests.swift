//
//  WikipediaKitTests.swift
//  WikipediaKitTests
//
//  Created by Frank Rausch on 2017-05-02.
//  Copyright © 2017 Raureif GmbH / Frank Rausch. All rights reserved.
//

import XCTest
import WikipediaKit

class WikipediaKitTests: XCTestCase {
    // FIXME: Add tests for everything.
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSearchRequest() {
        let expectation = self.expectation(description: "Wait for async network operation")
        
        let _ = Wikipedia.shared.requestOptimizedSearchResults(language: WikipediaLanguage("en"), term: "Soft rime") {
            (searchResults, error) in
            
            expectation.fulfill()
            
            XCTAssert(searchResults != nil, "Search results should not be nil")
            XCTAssert(error == nil, "Search should not return an error")
            XCTAssert(searchResults!.items.count > 0, "Search results should be more than 0")
            
            print("Search Term: \(searchResults!.term)")
            print("---")
            for r in searchResults!.items {
                print("Title: \(r.displayTitle)")
                print("Text: \(r.displayText)")
                if let imageURL = r.imageURL {
                    print("Image URL: \(imageURL)")
                }
                print("---")
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testRandomArticlesRequest() {
        let expectation = self.expectation(description: "Wait for async network operation")
        
        let _ = Wikipedia.shared.requestRandomArticles(language: WikipediaLanguage("en"), imageWidth: 640, loadExtracts: true) {
            (articlePreviews, language, error) in
            
            expectation.fulfill()
            
            XCTAssert(articlePreviews != nil, "Search results should not be nil")
            XCTAssert(error == nil, "Search should not return an error")
            XCTAssert(articlePreviews!.count > 0, "Search results should be more than 0")

            for r in articlePreviews! {
                print("Title: \(r.displayTitle)")
                print("Text: \(r.displayText)")
                if let imageURL = r.imageURL {
                    print("Image URL: \(imageURL)")
                }
                print("---")
            }
            
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
}
