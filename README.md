**⚠️ On 6 July 2023, Wikimedia [introduced a breaking change](https://lists.wikimedia.org/hyperkitty/list/wikitech-l@lists.wikimedia.org/thread/4MVQQTONJT7FJAXNVOFV3WWVVMCHRINE/) to their Wikipedia API / [Mobile Content Service](https://phabricator.wikimedia.org/T328036), which broke the [`requestArticle`](#articles) feature in this framework.**

## WikipediaKit · API Client Framework for Swift

The [Wikipedia API](https://www.mediawiki.org/wiki/Special:ApiSandbox) can do a lot, but it’s not easy to get started.

With WikipediaKit, it’s easy to build apps that search and show Wikipedia content—without worrying about the raw API. Instead of exposing all options and endpoints, WikipediaKit provides comfortable access to the most interesting parts for building a reader app. WikipediaKit comes with opinions and an attitude—but that’s the point!

The WikipediaKit framework is written in Swift, has no third-party dependencies, and runs on macOS, iOS, watchOS, and tvOS.

## Installation

### Swift Package Manager (preferred)
WikipediaKit can be added to your Xcode project using the [Swift Package Manager](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app).

### Carthage
You can use [Carthage](https://github.com/Carthage/Carthage) to install and update WikipediaKit.

### Manual
Drag and drop the `WikipediaKit.xcodeproj` to your app project and add the `WikipediaKit` embedded framework in your app project’s build settings.


## Usage

### Getting started

The `Wikipedia` class connects your app to Wikipedia’s API. You can search, get articles, and list nearby places by querying a freshly created `Wikipedia` instance…

```swift
let wikipedia = Wikipedia()
```

…or by using the `shared` singleton instance:

```swift
let wikipedia = Wikipedia.shared
```

Before doing anything else, make sure to add your email address:

```swift
WikipediaNetworking.appAuthorEmailForAPI = "appauthor@example.com"
```

WikipediaKit will use this email address and your app’s bundle info to generate and send a `User-Agent` header. This will identify your app to Wikipedia’s servers with every API request, as required by the [API guidelines](https://www.mediawiki.org/wiki/API:Main_page#Identifying_your_client).

The `User-Agent` header is printed to your Xcode console when you make the first API request. It’ll look similar to this:

```
User-Agent: ExampleApp/1.0 (com.example.ExampleApp; appauthor@example.com) WikipediaKit/1.0
```

Please double-check that the `User-Agent` header is correct before shipping your app.

### Return Type and Asynchronous Networking

The return type of all `Wikipedia` methods is
a standard [`URLSessionTask`](https://developer.apple.com/reference/foundation/urlsessiontask):

```swift
let language = WikipediaLanguage("en")

let searchSessionTask = Wikipedia.shared.requestOptimizedSearchResults(language: language, term: "Soft rime") { (searchResults, error) in
    // This code will be called asynchronously
    // whenever the results have been downloaded.
    // …
}
```

A `URLSessionTask` can be cancelled like this:

```swift
searchSessionTask.cancel()
```

See the [`URLSessionTask`](https://developer.apple.com/reference/foundation/urlsessiontask) documentation for further reading.

### Languages

A `WikipediaLanguage` has a language code, a localized name, an [autonym](https://en.wikipedia.org/wiki/Exonym_and_endonym), and sometimes a variant (e.g. `zh-hans` for Simplified Chinese and `zh-hant` for Traditional Chinese).

```swift
// French language, localized name for German, no variant
let l = WikipediaLanguage(code: "fr",
                          localizedName: "Französisch", // FR in DE
                          autonym: "Français") // FR in FR
```


WikipediaKit comes with a list of Wikipedia languages and their autonyms. This lets you initialize a `WikipediaLanguage` by passing the language code. Please note that if you use this shorthand method, the localized names will be in English.

```swift
let language = WikipediaLanguage("fr")
// code: "fr", localizedName: "French", autonym: "Français"
```

### Search

Search Wikipedia—e.g. for the term “[Soft rime](https://en.wikipedia.org/wiki/Soft_rime)” in English—like this:

```swift
let language = WikipediaLanguage("en")

let _ = Wikipedia.shared.requestOptimizedSearchResults(language: language, term: "Soft rime") { (searchResults, error) in

    guard error == nil else { return }
    guard let searchResults = searchResults else { return }

    for articlePreview in searchResults.items {
        print(articlePreview.displayTitle)
    }
}
```

The `searchResults` are a `WikipediaSearchResults` object.

#### Search Batch Size (Paging Search Results)

To load more search results for a query, simply start another search for the same `language:` and `term:`, passing the previous `WikipediaSearchResults` object as the `existingSearchResults:` parameter.

The default batch size is `15`, but can be changed by passing a different number in the `maxCount` parameter.

#### Search Methods

There are two supported search methods (`WikipediaSearchMethod`) to search for articles on Wikipedia. You can pass them to `requestSearchResults(method:language:term:)`.

- `.prefix` searches the article titles only
- `.fullText` searches the complete articles

**For better search results quality,** use `requestOptimizedSearchResults(language:term:)`, which doesn’t take a `method:` parameter (see the example above). This will use the `.prefix` search and then fall back to the `.fullText` search whenever there are few or no results for a search term.

You can adjust the minimum number of results—before the fallback `.fullText` search is triggered—with the `minCount:` parameter.

#### Search Thumbnail Image Size

The desired maximum pixel width of the `WikipediaArticlePreview`’s image URL can be adjusted in the optional `imageWidth:` parameter.

#### Search Cache

Searches are cached automatically until the app quits (see section on caching below).

### Article Previews

`WikipediaArticlePreview` objects represent search result items. They’re similar to full articles, but contain only an excerpt of the article text.

The `displayTitle` and `displayText` can be formatted via your `WikipediaFormattingDelegate`.

### Articles

*Update: Since WikipediaKit 3.0, this method uses the new Wikipedia REST API. The rewrite was a good opportunity to modernize WikipediaKit and return a `Result<WikipediaArticle, WikipediaError>` type.*

Load the article about “[Soft rime](https://en.wikipedia.org/wiki/Soft_rime)” in English like this:

```swift
let language = WikipediaLanguage("en")

let _ = Wikipedia.shared.requestArticle(language: language, title: "Soft rime") { result in
    switch result {
    case .success(let article):
      print(article.displayTitle)
      print(article.displayText)
    case .failure(let error):
      print(error)
    }
}
```


The `displayTitle` and `displayText` can be formatted via your `WikipediaFormattingDelegate`.

Wikipedia articles come with a table of contents, stored in a array of `WikipediaTOCItem`. The section titles can be formatted in your `WikipediaFormattingDelegate`.

To query other available languages for a given article, use the `requestAvailableLanguages(for:)` call on your `Wikipedia` instance, passing the existing article.

Articles are cached automatically until the app is restarted (see section on caching below).

### Nearby Search

This search mode returns geo-tagged articles around a specific location. Pass in a coordinate (latitude and longitude) around which to search:

```swift
let language = WikipediaLanguage("en")

let _ = Wikipedia.shared.requestNearbyResults(language: language, latitude: 52.4555592, longitude: 13.3175333) { (articlePreviews, resultsLanguage, error) in

    guard error == nil else { return }
    guard let articlePreviews = articlePreviews else { return }

    for a in articlePreviews {
        print(a.displayTitle)
        if let coordinate = a.coordinate {
            print(coordinate.latitude)
            print(coordinate.longitude)
        }
    }
}
```


### Featured Articles

The `requestFeaturedArticles(language:date:)` query gets a list of the most popular articles for a specific date from Wikipedia’s official analytics.

*Please note: Versions of WikipediaKit before 3.0 used the raw data from an older Wikipedia API to implement this feature. The new (current) implementation uses the same new API as the official Wikipedia app, which seems to filter the articles, stripping out potentially offensive content.*

```swift
let language = WikipediaLanguage("en")

let dayBeforeYesterday = Date(timeIntervalSinceNow: -60 * 60 * 48)

let _ = Wikipedia.shared.requestFeaturedArticles(language: language, date: dayBeforeYesterday) { result in
    switch result {
    case .success(let featuredCollection):
	    for a in featuredCollection.mostReadArticles {
	        print(a.displayTitle)
	    }
    case .failure(let error):
      print(error)
    }
}
```

### Image Metadata

To find out the URL for a given Wikipedia image at a specific size, use this call:

```swift
let language = WikipediaLanguage("en")

// You can pass multiple images here.
// Make sure to limit the number somehow
// because the API server will bail out
// if the query URL gets too long.

let urls = ["https://en.wikipedia.org/wiki/File:Raureif2.JPG"]

let _ = Wikipedia.shared.(language: language, urls: urls, width: 1000) { (imagesMetadata, error) in
    guard error == nil else { return }
    for metadata in imagesMetadata {
	    print(metadata.url) // URL for 1000px width version
	    print(metadata.description)
	    print(metadata.license)
	  }
}

```

Instead of the `urls:` parameter, you can specify image IDs; in this case the `ids:` parameter would be `["File:Raureif2.JPG"]`.

## Delegates

WikipediaKit comes with a few delegate protocols that help you track state, filter, and format.

### Networking Delegate

```swift
WikipediaNetworking.sharedActivityIndicatorDelegate = MyActivityIndicatorDelegate.shared
```

Set a `WikipediaNetworkingActivityDelegate` to receive `start()` and `stop()` calls whenever a network operation starts and stops.

### Formatting Delegate

```swift
Wikipedia.sharedFormattingDelegate = MyFormattingDelegate.shared
```

The `WikipediaArticle` and `WikipediaArticlePreview` classes have a `displayTitle` and a `displayText` property.

You can parse and reformat article texts, titles, and the table of contents in your `WikipediaFormattingDelegate` before it’s being cached.

```swift
class MyFormattingDelegate: WikipediaTextFormattingDelegate {

    static let shared = MyFormattingDelegate()

    func format(context: WikipediaTextFormattingDelegateContext, rawText: String, title: String?, language: WikipediaLanguage, isHTML: Bool) -> String {
        // Do something to rawText before returning…
        return rawText
    }
}
```


## Caching

Caching happens automatically (*after* processing and formatting) for search results and articles. WikipediaKit uses simple `NSCache` instances.

There’s also the automatic [`NSURLCache`](http://nshipster.com/nsurlcache/), controlled by the server’s cache headers. You can modify the cache duration headers to be included API response in `Wikipedia.maxAgeInSeconds`.


## Random Articles

Request an array of random `WikipediaArticlePreview` objects like this:

```swift
Wikipedia.shared.requestRandomArticles(language: self.language, maxCount: 8, imageWidth: 640) {
    (articlePreviews, language, error) in

    guard let articlePreviews = articlePreviews else { return }

    for article in articlePreviews {
        print(article.displayTitle)
    }
}
```

WikipediaKit has this convenience function that gets one single random `WikipediaArticlePreview` at a time:

```swift
Wikipedia.shared.requestSingleRandomArticle(language: self.language, maxCount: 8, imageWidth: 640) {
    (article, language, error) in

    guard let article = article else { return }

    print(article.displayTitle)
}
```

If `maxCount` is larger than `1`, the surplus results from the API query are buffered in a shared `WikipediaRandomArticlesBuffer` object and will be returned one-by-one with every subsequent call of `requestSingleRandomArticle`. A new network request is only triggered when there are no buffered random articles left or when the query language changes.


## About

WikipediaKit was created by Frank Rausch.

© 2017–22 Raureif GmbH / Frank Rausch

### License

MIT License; please read the `LICENSE` file in this repository.

### Disclaimer

This project is not affiliated with the official Wikipedia projects or the Wikimedia Foundation.

### Trademarks

Wikipedia® is a registered trademark of the Wikimedia Foundation, Inc., a non-profit organization.
