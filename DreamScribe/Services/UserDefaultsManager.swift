import Foundation

extension UserDefaults {
    enum Keys {
        static let audioInputMode = "audioInputMode"
        static let selectedAudioDeviceUID = "selectedAudioDeviceUID"
        static let prioritizedDevices = "prioritizedDevices"
        static let affiliatePromotionDismissed = "DreamScribeAffiliatePromotionDismissed"
        static let legacyAffiliatePromotionDismissed = "VoiceInkAffiliatePromotionDismissed"
    }

    // MARK: - Audio Input Mode
    var audioInputModeRawValue: String? {
        get { string(forKey: Keys.audioInputMode) }
        set { setValue(newValue, forKey: Keys.audioInputMode) }
    }

    // MARK: - Selected Audio Device UID
    var selectedAudioDeviceUID: String? {
        get { string(forKey: Keys.selectedAudioDeviceUID) }
        set { setValue(newValue, forKey: Keys.selectedAudioDeviceUID) }
    }

    // MARK: - Prioritized Devices
    var prioritizedDevicesData: Data? {
        get { data(forKey: Keys.prioritizedDevices) }
        set { setValue(newValue, forKey: Keys.prioritizedDevices) }
    }

    // MARK: - Affiliate Promotion Dismissal
    // Reads new key first; falls back to legacy VoiceInk key and migrates on read.
    var affiliatePromotionDismissed: Bool {
        get {
            if object(forKey: Keys.affiliatePromotionDismissed) != nil {
                return bool(forKey: Keys.affiliatePromotionDismissed)
            }
            if object(forKey: Keys.legacyAffiliatePromotionDismissed) != nil {
                let legacyValue = bool(forKey: Keys.legacyAffiliatePromotionDismissed)
                setValue(legacyValue, forKey: Keys.affiliatePromotionDismissed)
                return legacyValue
            }
            return false
        }
        set { setValue(newValue, forKey: Keys.affiliatePromotionDismissed) }
    }
}
