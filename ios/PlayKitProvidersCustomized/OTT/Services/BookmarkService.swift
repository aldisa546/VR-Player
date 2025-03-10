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
import KalturaNetKit

internal class BookmarkService {

    internal static func actionAdd(baseURL: String,
                                   partnerId: Int,
                                   ks: String,
                                   eventType: String,
                                   currentTime: Int32,
                                   assetId: String,
                                   epgId: String?,
                                   assetType: String,
                                   contextType: String,
                                   fileId: String) -> KalturaRequestBuilder? {
        
        let bookmark = createBookmark(eventType: eventType,
                                      position: currentTime,
                                      assetId: assetId,
                                      epgId: epgId,
                                      assetType: assetType,
                                      contextType: contextType,
                                      fileId: fileId)
        
        if let request: KalturaRequestBuilder = KalturaRequestBuilder(url: baseURL, service: "bookmark", action: "add") {
            request
                .setOTTBasicParams()
                .set(method: .post)
                .setBody(key: "ks", value: JSON(ks))
                .setBody(key: "bookmark", value: bookmark)
            return request
        } else {
            return nil
        }
    }
    
    private static func createBookmark(eventType: String,
                                       position: Int32,
                                       assetId: String,
                                       epgId: String? = nil,
                                       assetType: String,
                                       contextType: String,
                                       fileId: String) -> JSON {
        
        var json: JSON = JSON.init(["objectType": "KalturaBookmark"])
        json["type"] = JSON(assetType)
        json["context"] = JSON(contextType)
        json["id"] = JSON(assetId)
        if let epgId = epgId, !epgId.isEmpty {
            json["programId"] = JSON(epgId)
        }
        json["position"] = JSON(position)
        json["playerData"] = JSON.init(["action": JSON(eventType),
                                        "objectType": JSON("KalturaBookmarkPlayerData"),
                                        "fileId": JSON(fileId)])
        
        return json
    }
}
