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

class OVPMultiResponseParser: NSObject {
    
    static func parse(data: Any) -> [OVPBaseObject] {
        
        let jsonResponse = JSON(data)
        if let resultArrayJSON = jsonResponse.array {
            
            var resultArray: [OVPBaseObject] = [OVPBaseObject]()
            for jsonResult: JSON in resultArrayJSON {
                var object: OVPBaseObject? = nil
                if let parsedItem = OVPMultiResponseParser.parseSingleItem(json: jsonResult) {
                    object = parsedItem
                } else if let objects = jsonResult["objects"].array {
                    var parsedObjects: [OVPBaseObject] = [OVPBaseObject]()
                    for object in objects {
                        if let OVPObject: OVPBaseObject = OVPMultiResponseParser.parseSingleItem(json: object) {
                            parsedObjects.append(OVPObject)
                        }
                    }
                    object = OVPList(objects: parsedObjects)
                } else if let items = jsonResult.array {
                    object = OVPList(objects: items.compactMap { OVPMultiResponseParser.parseSingleItem(json: $0) })
                } else {
                    // Unrecognized object
                }
                
                if let obj = object {
                    resultArray.append(obj)
                }
            }
            return resultArray
        } else {
            return [OVPBaseObject]()
        }
    }
    
    static func  parseSingleItem(json:JSON) -> OVPBaseObject? {
        
        let objectType: OVPBaseObject.Type? = OVPObjectMapper.classByJsonObject(json: json.dictionaryObject)
        if let type = objectType {
            let object: OVPBaseObject? = type.init(json: json.object)
            return object
        } else {
            return nil
        }
    }
}
