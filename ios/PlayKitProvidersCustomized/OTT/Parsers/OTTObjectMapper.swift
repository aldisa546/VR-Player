// ===================================================================================================
// Copyright (C) 2017 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

import UIKit
import kSwiftyJSON

class OTTObjectMapper: NSObject {

    static let classNameKey = "objectType"
    static let errorKey = "error"

    static func classByJsonObject(json: Any?) -> OTTBaseObject.Type? {
        guard let js = json else { return nil }
        let jsonObject = JSON(js)
        let className = jsonObject[classNameKey].string

        if let name = className {
            switch name {
            case "KalturaPlaybackSource":
                return OTTPlaybackSource.self
            case "KalturaPlaybackContext":
                return OTTPlaybackContext.self
            case "KalturaMediaAsset":
                return OTTMediaAsset.self
            case "KalturaProgramAsset":
                return OTTProgramAsset.self
            case "KalturaMediaFile":
                return OTTMediaFile.self
            case "KalturaMultilingualStringValue":
                return OTTMultilingualStringValue.self
            case "KalturaBooleanValue":
                return OTTBooleanValue.self
            case "KalturaLiveAsset":
                return OTTLiveAsset.self
            case "KalturaRecordingAsset":
                return OTTRecordingAsset.self
            default:
                return nil
            }
        } else {
            if jsonObject[errorKey].dictionary != nil {
                return OTTError.self
            } else {
                return nil
            }
        }
    }
}
