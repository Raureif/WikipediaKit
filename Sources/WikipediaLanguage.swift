//
//  WikipediaLanguage.swift
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

public func ==(lhs: WikipediaLanguage, rhs: WikipediaLanguage) -> Bool {
    if lhs.code == rhs.code && lhs.variant == rhs.variant {
        return true
    }
    return false
}


public struct WikipediaLanguage: Hashable, Equatable {
    
    public let code: String
    
    // including language code; for example: Traditional and Simplified Chinese (zh-hant, zh-hans)
    public let variant: String?
    
    // language name, localized for the user’s preferred language
    public let localizedName: String
    
    // language name in that language
    public let autonym: String
    
    public let isRightToLeft: Bool

    public lazy var locale: Locale = {
       return Locale(identifier: self.code)
    }()

    public init(code languageCode: String, variant: String? = nil, localizedName: String = "", autonym: String) {
        if languageCode.isEmpty {
            #if DEBUG
                fatalError("Could not initialize WikipediaLanguage with empty language code.")
            #else
                self.code = "en"
                self.localizedName = "English (Fallback)"
                self.autonym = "English (Fallback)"
                self.isRightToLeft = false
                self.variant = nil
            #endif
        } else {
            self.code = languageCode.lowercased()
            self.localizedName = localizedName
        
            var v = variant
            if v == nil && languageCode == "zh" {
                v = WikipediaLanguage.preferredChineseVariant
            }
            self.variant = v

            self.autonym = autonym
            self.isRightToLeft = WikipediaLanguage.rightToLeftLanguageCodes.contains(languageCode)
        }
    }

    public init(_ languageCode: String) {
        // TODO: Use a localized description instead of the English fallback
        let (autonym, english, variant) = WikipediaLanguage.defaultLanguages[languageCode] ?? (languageCode, languageCode, nil)
        self.init(code: languageCode, variant: variant, localizedName: english, autonym: autonym)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code.hashValue)
        hasher.combine(variant?.hashValue)
    }

    public static var systemLanguageCode: String = {
        guard let preferredLanguage = Locale.preferredLanguages.first else { return "en" }
        let languageComponents = Locale.components(fromIdentifier: preferredLanguage)
        let languageCode = languageComponents[NSLocale.Key.languageCode.rawValue]
        return languageCode ?? "en"
    }()

    public static var systemLanguage: WikipediaLanguage = {
        return WikipediaLanguage(systemLanguageCode)
    }()

    public static var supportedSystemLanguage: WikipediaLanguage = {
        if defaultLanguages.keys.contains(systemLanguageCode) {
            return WikipediaLanguage(systemLanguageCode)
        } else {
            // Fallback for unsupported languages
            return WikipediaLanguage("en")
        }
    }()


    // Wikipedia supports different variants for Chinese, but the codes do not map directly to iOS locales.
    // https://meta.wikimedia.org/wiki/Automatic_conversion_between_simplified_and_traditional_Chinese

    static var supportedChineseLocaleVariants = ["cn", "hk", "mo", "my", "sg", "tw"]

    public static var preferredChineseVariant: String? = {

        let preferredLanguages = Locale.preferredLanguages

        for language in preferredLanguages {
            guard language.hasPrefix("zh") else { continue }

            let languageComponents = Locale.components(fromIdentifier: language)
            let languageCode = languageComponents[NSLocale.Key.languageCode.rawValue]
            guard let variant = languageComponents[NSLocale.Key.scriptCode.rawValue]?.lowercased(),
                  let locale = languageComponents[NSLocale.Key.countryCode.rawValue]?.lowercased()
                else {
                    continue
            }

            if WikipediaLanguage.supportedChineseLocaleVariants.contains(locale) {
                return "zh-\(locale)"
            } else {
                // Fall back to Simplified Chinese (zh-hans) for unexpected variants
                return variant == "hant" ? "zh-hant" : "zh-hans"
            }
        }
        return nil
    }()
    
    public static var rightToLeftLanguageCodes = [
        "ar",
        "arc",
        "arz",
        "ckb",
        "dv",
        "fa",
        "gan",
        "glk",
        "he",
        "mzn",
        "pnb",
        "ps",
        "sd",
        "ug",
        "ur",
        "yi"
    ]

    public static func isBlacklisted(languageCode: String) -> Bool {
        // TODO: Add all languages that are unsupported by the preinstalled OS fonts
        #if os(iOS)
            let languageBlacklist = [
                "am",
                "shn",
                "ti",
            ]
            return languageBlacklist.contains(languageCode)
        #else
            return false
        #endif
    }

    
    public static let defaultLanguages: [String : (autonym: String, english: String, variant: String?)] = [
        "aa": ("Afar", "Afar", nil),
        "ab": ("Аҧсуа", "Abkhazian", nil),
        "ace": ("Bahsa Acèh", "Acehnese", nil),
        "af": ("Afrikaans", "Afrikaans", nil),
        "ak": ("Akana", "Akan", nil),
        "als": ("Alemannisch", "Alemannic", nil),
        "am": ("አማርኛ", "Amharic", nil),
        "an": ("Aragonés", "Aragonese", nil),
        "ang": ("Englisc", "Anglo-Saxon", nil),
        "ar": ("العربية", "Arabic", nil),
        "arc": ("ܐܪܡܝܐ", "Aramaic", nil),
        "arz": ("مصرى (Maṣrī)", "Egyptian Arabic", nil),
        "as": ("অসমীয়া", "Assamese", nil),
        "ast": ("Asturianu", "Asturian", nil),
        "av": ("Авар", "Avar", nil),
        "ay": ("Aymar", "Aymara", nil),
        "az": ("Azərbaycanca", "Azerbaijani", nil),
        "ba": ("Башҡорт", "Bashkir", nil),
        "bar": ("Boarisch", "Bavarian", nil),
        "bat-smg": ("Žemaitėška", "Samogitian", nil),
        "bcl": ("Bikol", "Central Bicolano", nil),
        "be": ("Беларуская", "Belarusian", nil),
        "be-x-old": ("Беларуская (тарашкевіца)", "Belarusian (Taraškievica)", nil),
        "bg": ("Български", "Bulgarian", nil),
        "bh": ("भोजपुरी", "Bihari", nil),
        "bi": ("Bislama", "Bislama", nil),
        "bjn": ("Bahasa Banjar", "Banjar", nil),
        "bm": ("Bamanankan", "Bambara", nil),
        "bn": ("বাংলা", "Bengali", nil),
        "bo": ("བོད་སྐད", "Tibetan", nil),
        "bpy": ("ইমার ঠার/বিষ্ণুপ্রিয়া মণিপুরী", "Bishnupriya Manipuri", nil),
        "br": ("Brezhoneg", "Breton", nil),
        "bs": ("Bosanski", "Bosnian", nil),
        "bug": ("Basa Ugi", "Buginese", nil),
        "bxr": ("Буряад", "Buryat (Russia)", nil),
        "ca": ("Català", "Catalan", nil),
        "cbk-zam": ("Chavacano de Zamboanga", "Zamboanga Chavacano", nil),
        "cdo": ("Mìng-dĕ̤ng-ngṳ̄", "Min Dong", nil),
        "ce": ("Нохчийн", "Chechen", nil),
        "ceb": ("Sinugboanong Binisaya", "Cebuano", nil),
        "ch": ("Chamoru", "Chamorro", nil),
        "cho": ("Choctaw", "Choctaw", nil),
        "chr": ("ᏣᎳᎩ", "Cherokee", nil),
        "chy": ("Tsetsêhestâhese", "Cheyenne", nil),
        "ckb": ("Soranî / کوردی", "Sorani", nil),
        "co": ("Corsu", "Corsican", nil),
        "cr": ("Nehiyaw", "Cree", nil),
        "crh": ("Qırımtatarca", "Crimean Tatar", nil),
        "cs": ("Čeština", "Czech", nil),
        "csb": ("Kaszëbsczi", "Kashubian", nil),
        "cu": ("Словѣньскъ", "Old Church Slavonic", nil),
        "cv": ("Чăваш", "Chuvash", nil),
        "cy": ("Cymraeg", "Welsh", nil),
        "da": ("Dansk", "Danish", nil),
        "de": ("Deutsch", "German", nil),
        "diq": ("Zazaki", "Zazaki", nil),
        "dsb": ("Dolnoserbski", "Lower Sorbian", nil),
        "dv": ("ދިވެހިބަސް", "Divehi", nil),
        "dz": ("ཇོང་ཁ", "Dzongkha", nil),
        "ee": ("Eʋegbe", "Ewe", nil),
        "el": ("Ελληνικά", "Greek", nil),
        "eml": ("Emiliàn e rumagnòl", "Emilian-Romagnol", nil),
        "en": ("English", "English", nil),
        "eo": ("Esperanto", "Esperanto", nil),
        "es": ("Español", "Spanish", nil),
        "et": ("Eesti", "Estonian", nil),
        "eu": ("Euskara", "Basque", nil),
        "ext": ("Estremeñu", "Extremaduran", nil),
        "fa": ("فارسی", "Persian", nil),
        "ff": ("Fulfulde", "Fula", nil),
        "fi": ("Suomi", "Finnish", nil),
        "fiu-vro": ("Võro", "Võro", nil),
        "fj": ("Na Vosa Vakaviti", "Fijian", nil),
        "fo": ("Føroyskt", "Faroese", nil),
        "fr": ("Français", "French", nil),
        "frp": ("Arpitan", "Franco-Provençal/Arpitan", nil),
        "frr": ("Nordfriisk", "North Frisian", nil),
        "fur": ("Furlan", "Friulian", nil),
        "fy": ("Frysk", "West Frisian", nil),
        "ga": ("Gaeilge", "Irish", nil),
        "gag": ("Gagauz", "Gagauz", nil),
        "gan": ("贛語", "Gan", nil),
        "gd": ("Gàidhlig", "Scottish Gaelic", nil),
        "gl": ("Galego", "Galician", nil),
        "glk": ("گیلکی", "Gilaki", nil),
        "gn": ("Avañe'ẽ", "Guarani", nil),
        "got": ("𐌲𐌿𐍄𐌹𐍃𐌺", "Gothic", nil),
        "gu": ("ગુજરાતી", "Gujarati", nil),
        "gv": ("Gaelg", "Manx", nil),
        "ha": ("هَوُسَ", "Hausa", nil),
        "hak": ("Hak-kâ-fa / 客家話", "Hakka", nil),
        "haw": ("Hawai‘i", "Hawaiian", nil),
        "he": ("עברית", "Hebrew", nil),
        "hi": ("हिन्दी", "Hindi", nil),
        "hif": ("Fiji Hindi", "Fiji Hindi", nil),
        "ho": ("Hiri Motu", "Hiri Motu", nil),
        "hr": ("Hrvatski", "Croatian", nil),
        "hsb": ("Hornjoserbsce", "Upper Sorbian", nil),
        "ht": ("Krèyol ayisyen", "Haitian", nil),
        "hu": ("Magyar", "Hungarian", nil),
        "hy": ("Հայերեն", "Armenian", nil),
        "hz": ("Otsiherero", "Herero", nil),
        "ia": ("Interlingua", "Interlingua", nil),
        "id": ("Bahasa Indonesia", "Indonesian", nil),
        "ie": ("Interlingue", "Interlingue", nil),
        "ig": ("Igbo", "Igbo", nil),
        "ii": ("ꆇꉙ", "Sichuan Yi", nil),
        "ik": ("Iñupiak", "Inupiak", nil),
        "ilo": ("Ilokano", "Ilokano", nil),
        "io": ("Ido", "Ido", nil),
        "is": ("Íslenska", "Icelandic", nil),
        "it": ("Italiano", "Italian", nil),
        "iu": ("ᐃᓄᒃᑎᑐᑦ", "Inuktitut", nil),
        "ja": ("日本語", "Japanese", nil),
        "jbo": ("Lojban", "Lojban", nil),
        "jv": ("Basa Jawa", "Javanese", nil),
        "ka": ("ქართული", "Georgian", nil),
        "kaa": ("Qaraqalpaqsha", "Karakalpak", nil),
        "kab": ("Taqbaylit", "Kabyle", nil),
        "kbd": ("Адыгэбзэ (Adighabze)", "Kabardian Circassian", nil),
        "kg": ("KiKongo", "Kongo", nil),
        "ki": ("Gĩkũyũ", "Kikuyu", nil),
        "kj": ("Kuanyama", "Kuanyama", nil),
        "kk": ("Қазақша", "Kazakh", nil),
        "kl": ("Kalaallisut", "Greenlandic", nil),
        "km": ("ភាសាខ្មែរ", "Khmer", nil),
        "kn": ("ಕನ್ನಡ", "Kannada", nil),
        "ko": ("한국어", "Korean", nil),
        "koi": ("Перем Коми (Perem Komi)", "Komi-Permyak", nil),
        "kr": ("Kanuri", "Kanuri", nil),
        "krc": ("Къарачай-Малкъар (Qarachay-Malqar)", "Karachay-Balkar", nil),
        "ks": ("कश्मीरी / كشميري", "Kashmiri", nil),
        "ksh": ("Ripoarisch", "Ripuarian", nil),
        "ku": ("Kurdî / كوردی", "Kurdish", nil),
        "kv": ("Коми", "Komi", nil),
        "kw": ("Kernewek/Karnuack", "Cornish", nil),
        "ky": ("Кыргызча", "Kirghiz", nil),
        "la": ("Latina", "Latin", nil),
        "lad": ("Dzhudezmo", "Ladino", nil),
        "lb": ("Lëtzebuergesch", "Luxembourgish", nil),
        "lbe": ("Лакку", "Lak", nil),
        "lez": ("Лезги", "Lezgian", nil),
        "lg": ("Luganda", "Luganda", nil),
        "li": ("Limburgs", "Limburgish", nil),
        "lij": ("Líguru", "Ligurian", nil),
        "lmo": ("Lumbaart", "Lombard", nil),
        "ln": ("Lingala", "Lingala", nil),
        "lo": ("ລາວ", "Lao", nil),
        "lt": ("Lietuvių", "Lithuanian", nil),
        "ltg": ("Latgaļu", "Latgalian", nil),
        "lv": ("Latviešu", "Latvian", nil),
        "map-bms": ("Basa Banyumasan", "Banyumasan", nil),
        "mdf": ("Мокшень (Mokshanj Kälj)", "Moksha", nil),
        "mg": ("Malagasy", "Malagasy", nil),
        "mh": ("Ebon", "Marshallese", nil),
        "mhr": ("Олык Марий (Olyk Marij)", "Meadow Mari", nil),
        "mi": ("Māori", "Maori", nil),
        "min": ("Baso Minangkabau", "Minangkabau", nil),
        "mk": ("Македонски", "Macedonian", nil),
        "ml": ("മലയാളം", "Malayalam", nil),
        "mn": ("Монгол", "Mongolian", nil),
        "mo": ("Молдовеняскэ", "Moldovan", nil),
        "mr": ("मराठी", "Marathi", nil),
        "mrj": ("Кырык Мары (Kyryk Mary) ", "Hill Mari", nil),
        "ms": ("Bahasa Melayu", "Malay", nil),
        "mt": ("Malti", "Maltese", nil),
        "mus": ("Muskogee", "Muscogee", nil),
        "mwl": ("Mirandés", "Mirandese", nil),
        "my": ("မြန်မာဘာသာ", "Burmese", nil),
        "myv": ("Эрзянь (Erzjanj Kelj)", "Erzya", nil),
        "mzn": ("مَزِروني", "Mazandarani", nil),
        "na": ("dorerin Naoero", "Nauruan", nil),
        "nah": ("Nāhuatl", "Nahuatl", nil),
        "nap": ("Nnapulitano", "Neapolitan", nil),
        "nds": ("Plattdüütsch", "Low Saxon", nil),
        "nds-nl": ("Nedersaksisch", "Dutch Low Saxon", nil),
        "ne": ("नेपाली", "Nepali", nil),
        "new": ("नेपाल भाषा", "Newar / Nepal Bhasa", nil),
        "ng": ("Oshiwambo", "Ndonga", nil),
        "nl": ("Nederlands", "Dutch", nil),
        "nn": ("Nynorsk", "Norwegian (Nynorsk)", nil),
        "no": ("Norsk (Bokmål)", "Norwegian (Bokmål)", nil),
        "nov": ("Novial", "Novial", nil),
        "nrm": ("Nouormand/Normaund", "Norman", nil),
        "nso": ("Sesotho sa Leboa", "Northern Sotho", nil),
        "nv": ("Diné bizaad", "Navajo", nil),
        "ny": ("Chi-Chewa", "Chichewa", nil),
        "oc": ("Occitan", "Occitan", nil),
        "om": ("Oromoo", "Oromo", nil),
        "or": ("ଓଡ଼ିଆ", "Oriya", nil),
        "os": ("Иронау", "Ossetian", nil),
        "pa": ("ਪੰਜਾਬੀ", "Punjabi", nil),
        "pag": ("Pangasinan", "Pangasinan", nil),
        "pam": ("Kapampangan", "Kapampangan", nil),
        "pap": ("Papiamentu", "Papiamentu", nil),
        "pcd": ("Picard", "Picard", nil),
        "pdc": ("Deitsch", "Pennsylvania German", nil),
        "pfl": ("Pfälzisch", "Palatinate German", nil),
        "pi": ("पाऴि", "Pali", nil),
        "pih": ("Norfuk", "Norfolk", nil),
        "pl": ("Polski", "Polish", nil),
        "pms": ("Piemontèis", "Piedmontese", nil),
        "pnb": ("شاہ مکھی پنجابی", "Western Panjabi", nil),
        "pnt": ("Ποντιακά", "Pontic", nil),
        "ps": ("پښتو", "Pashto", nil),
        "pt": ("Português", "Portuguese", nil),
        "qu": ("Runa Simi", "Quechua", nil),
        "rm": ("Rumantsch", "Romansh", nil),
        "rmy": ("रोमानी", "Romani", nil),
        "rn": ("Kirundi", "Kirundi", nil),
        "ro": ("Română", "Romanian", nil),
        "roa-rup": ("Armãneashce", "Aromanian", nil),
        "roa-tara": ("Tarandíne", "Tarantino", nil),
        "ru": ("Русский", "Russian", nil),
        "rue": ("русиньскый язык", "Rusyn", nil),
        "rw": ("Ikinyarwanda", "Kinyarwanda", nil),
        "sa": ("संस्कृतम्", "Sanskrit", nil),
        "sah": ("Саха тыла (Saxa Tyla)", "Sakha", nil),
        "sc": ("Sardu", "Sardinian", nil),
        "scn": ("Sicilianu", "Sicilian", nil),
        "sco": ("Scots", "Scots", nil),
        "sd": ("سنڌي، سندھی ، सिन्ध", "Sindhi", nil),
        "se": ("Sámegiella", "Northern Sami", nil),
        "sg": ("Sängö", "Sango", nil),
        "sh": ("Srpskohrvatski / Српскохрватски", "Serbo-Croatian", nil),
        "si": ("සිංහල", "Sinhalese", nil),
        "simple": ("Simple English", "Simple English", nil),
        "sk": ("Slovenčina", "Slovak", nil),
        "sl": ("Slovenščina", "Slovenian", nil),
        "sm": ("Gagana Samoa", "Samoan", nil),
        "sn": ("chiShona", "Shona", nil),
        "so": ("Soomaaliga", "Somali", nil),
        "sq": ("Shqip", "Albanian", nil),
        "sr": ("Српски / Srpski", "Serbian", nil),
        "srn": ("Sranantongo", "Sranan", nil),
        "ss": ("SiSwati", "Swati", nil),
        "st": ("Sesotho", "Sesotho", nil),
        "stq": ("Seeltersk", "Saterland Frisian", nil),
        "su": ("Basa Sunda", "Sundanese", nil),
        "sv": ("Svenska", "Swedish", nil),
        "sw": ("Kiswahili", "Swahili", nil),
        "szl": ("Ślůnski", "Silesian", nil),
        "ta": ("தமிழ்", "Tamil", nil),
        "te": ("తెలుగు", "Telugu", nil),
        "tet": ("Tetun", "Tetum", nil),
        "tg": ("Тоҷикӣ", "Tajik", nil),
        "th": ("ไทย", "Thai", nil),
        "ti": ("ትግርኛ", "Tigrinya", nil),
        "tk": ("تركمن / Туркмен", "Turkmen", nil),
        "tl": ("Tagalog", "Tagalog", nil),
        "tn": ("Setswana", "Tswana", nil),
        "to": ("faka Tonga", "Tongan", nil),
        "tpi": ("Tok Pisin", "Tok Pisin", nil),
        "tr": ("Türkçe", "Turkish", nil),
        "ts": ("Xitsonga", "Tsonga", nil),
        "tt": ("Tatarça / Татарча", "Tatar", nil),
        "tum": ("chiTumbuka", "Tumbuka", nil),
        "tw": ("Twi", "Twi", nil),
        "ty": ("Reo Mā’ohi", "Tahitian", nil),
        "tyv": ("тыва дыл", "Tuvan", nil),
        "udm": ("Удмурт кыл", "Udmurt", nil),
        "ug": ("ئۇيغۇر تىلى", "Uyghur", nil),
        "uk": ("Українська", "Ukrainian", nil),
        "ur": ("اردو", "Urdu", nil),
        "uz": ("O‘zbek", "Uzbek", nil),
        "ve": ("Tshivenda", "Venda", nil),
        "vec": ("Vèneto", "Venetian", nil),
        "vep": ("Vepsän", "Vepsian", nil),
        "vi": ("Tiếng Việt", "Vietnamese", nil),
        "vls": ("West-Vlams", "West Flemish", nil),
        "vo": ("Volapük", "Volapük", nil),
        "wa": ("Walon", "Walloon", nil),
        "war": ("Winaray", "Waray-Waray", nil),
        "wo": ("Wolof", "Wolof", nil),
        "wuu": ("吴语", "Wu", nil),
        "xal": ("Хальмг", "Kalmyk", nil),
        "xh": ("isiXhosa", "Xhosa", nil),
        "xmf": ("მარგალური (Margaluri)", "Mingrelian", nil),
        "yi": ("ייִדיש", "Yiddish", nil),
        "yo": ("Yorùbá", "Yoruba", nil),
        "za": ("Cuengh", "Zhuang", nil),
        "zea": ("Zeêuws", "Zeelandic", nil),
        "zh": ("中文", "Chinese", nil), // variant is derived from device preferences; see above
        "zh-classical": ("古文 / 文言文", "Classical Chinese", nil),
        "zh-min-nan": ("Bân-lâm-gú", "Min Nan", nil),
        "zh-yue": ("粵語", "Cantonese", nil),
        "zu": ("isiZulu", "Zulu", nil),
    ]
}
