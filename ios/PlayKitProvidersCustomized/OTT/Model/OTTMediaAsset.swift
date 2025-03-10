// ===================================================================================================
// Copyright (C) 2018 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

//
//  OTTMediaAsset.swift
//  PlayKitCustomized
//
//  Created by Nilit Danan on 8/19/18.
//

import Foundation
import kSwiftyJSON

fileprivate let idKey = "id"
fileprivate let typeKey = "type"
fileprivate let nameKey = "name"
fileprivate let mediaFilesKey = "mediaFiles"
fileprivate let metasKey = "metas"
fileprivate let entryIdKey = "entryId"

public class OTTMediaAsset: OTTBaseObject {
    
    /**  Unique identifier for the asset  */
    var id: Int?
    /**  Identifies the asset type (EPG, Recording, Movie, TV Series, etc).
    Possible values: 0 – EPG linear programs, 1 - Recording; or any asset type ID
    according to the asset types IDs defined in the system.  */
    var type: Int?
    /**  Asset name  */
    var name: String?
    /**  Files  */
    var mediaFiles: [OTTMediaFile] = []
    /**  Dynamic collection of key-value pairs according to the String Meta defined in
    the system  */
    var metas: [String: OTTBaseObject] = [:]
    /**  Entry Identifier  */
    var entryId: String?
    
    public required init?(json: Any) {
        let jsonObj: JSON = JSON(json)
        
        self.id = jsonObj[idKey].int
        self.type = jsonObj[typeKey].int
        self.name = jsonObj[nameKey].string
        self.entryId = jsonObj[entryIdKey].string
        
        var mediaFiles = [OTTMediaFile]()
        jsonObj[mediaFilesKey].array?.forEach { (json) in
            if let mediaFile = OTTMediaFile(json: json.object) {
                mediaFiles.append(mediaFile)
            }
        }
        
        if !mediaFiles.isEmpty {
            self.mediaFiles = mediaFiles
        }
        
        if let metas = jsonObj[metasKey].dictionary {
            let metaKeys = metas.keys
            for key: String in metaKeys {
                if let jsonObject = metas[key] {
                    let objectType: OTTBaseObject.Type? = OTTObjectMapper.classByJsonObject(json: jsonObject.dictionaryObject)
                    if let type = objectType {
                        if let object = type.init(json: jsonObject.object) {
                            self.metas[key] = object
                        }
                    }
                }
            }
        }
    }
    
    func arrayOfMetas() -> [String: String] {
        var metas: [String: String] = [:]
        for meta in self.metas {
            if let stringValue = meta.value as? OTTMultilingualStringValue {
                metas[meta.key] = stringValue.value?.description
            }
        }
        
        return metas
    }
}
