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

class OVPObjectMapper: NSObject {
    
    static let classNameKey = "objectType"
    static let errorKey = "objectType"
    
    static func classByJsonObject(json:Any?) -> OVPBaseObject.Type? {
        
        guard let js = json else {
            return nil
        }
        
        let jsonObject = JSON(js)
        let className = jsonObject[classNameKey].string
        
        if let name = className {
            switch name {
            case "KalturaMediaEntry":
                return OVPEntry.self
            case "KalturaLiveStreamEntry", "KalturaLiveStreamAdminEntry":
                return OVPLiveStreamEntry.self
            case "KalturaPlaybackContext":
                return OVPPlaybackContext.self
            case "KalturaAPIException":
                return OVPError.self
            case "KalturaMetadata":
                return OVPMetadata.self
            case "KalturaBaseEntryListResponse":
                return OVPBaseEntryList.self
            case "KalturaMetadataListResponse":
                return OVPMetadataList.self
            case "KalturaPlaylist":
                return OVPPlaylist.self
            case "KalturaExternalMediaEntry":
                return OVPExternalMediaEntry.self
            default:
                return nil
            }
        }
        return nil
    }
}
