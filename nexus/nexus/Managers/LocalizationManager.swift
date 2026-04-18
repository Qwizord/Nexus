import Foundation
import SwiftUI

// MARK: - LocalizationManager
// Простой синглтон без ObservableObject/Published —
// не триггерит SwiftUI ре-рендер и не конфликтует с UIKit popovers/sheets.
// Смена языка применяется немедленно для L("key") вызовов.

final class LocalizationManager {
    static let shared = LocalizationManager()

    private(set) var currentLanguage: String = "ru_RU"
    private var bundle: Bundle = .main

    private init() {
        if let saved = UserDefaults.standard.string(forKey: "app_language") {
            setLanguage(saved, notify: false)
        }
    }

    func setLanguage(_ languageCode: String, notify: Bool = true) {
        currentLanguage = languageCode
        UserDefaults.standard.set(languageCode, forKey: "app_language")

        let lprojCode = lprojName(for: languageCode)
        if let path = Bundle.main.path(forResource: lprojCode, ofType: "lproj"),
           let langBundle = Bundle(path: path) {
            bundle = langBundle
        } else {
            bundle = .main
        }
    }

    func localizedString(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: key, table: "Localizable")
    }

    private func lprojName(for code: String) -> String {
        let map: [String: String] = [
            "en_US": "en", "ru_RU": "ru", "es_ES": "es",
            "fr_FR": "fr", "de_DE": "de", "it_IT": "it",
            "pt_BR": "pt-BR", "ja_JP": "ja", "ko_KR": "ko",
            "zh_CN": "zh-Hans", "ar_SA": "ar", "hi_IN": "hi",
            "tr_TR": "tr", "uk_UA": "uk", "pl_PL": "pl"
        ]
        return map[code] ?? "ru"
    }
}

// MARK: - Глобальная функция

/// L("tab.health") → "Здоровье" / "Health" / etc на текущем языке
func L(_ key: String) -> String {
    LocalizationManager.shared.localizedString(key)
}
