// ===================================================================================================
// Copyright (C) 2018 Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================

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
import PlayKitCustomized

@objc public enum AssetType: Int, CustomStringConvertible {
    case epg
    case recording
    case media
    case unset
    
    public var description: String {
        switch self {
        case .epg: return "epg"
        case .recording: return "recording"
        case .media: return "media"
        case .unset: return "<unset>"
        }
    }
    
    public init(_ serverValue: Int) {
        switch serverValue {
        case 0:
            self = .epg
        case 1:
            self = .recording
        case _ where serverValue > 1:
            self = .media
        default:
            self = .unset
        }
    }
}

@objc public enum AssetReferenceType: Int, CustomStringConvertible {
    case media
    case epgInternal
    case epgExternal
    case npvr
    case unset
    
    public var description: String {
        switch self {
        case .media: return "media"
        case .epgInternal: return "epgInternal"
        case .epgExternal: return "epgExternal"
        case .npvr: return "npvr"
        case .unset: return "<unset>"
        }
    }
}

@objc public enum PlaybackContextType: Int, CustomStringConvertible {
    
    case download
    case trailer
    case catchup
    case startOver
    case playback
    case unset
    
    public var description: String {
        switch self {
        case .download: return "DOWNLOAD"
        case .trailer: return "TRAILER"
        case .catchup: return "CATCHUP"
        case .startOver: return "START_OVER"
        case .playback: return "PLAYBACK"
        case .unset: return "<unset>"
        }
    }
}

/************************************************************/
// MARK: - PhoenixMediaProviderError
/************************************************************/

public enum PhoenixMediaProviderError: PKError {
    
    case invalidInputParam(param: String)
    case unableToParseData(data: Any)
    case noSourcesFound
    case serverError(code:String, message:String)
    /// in case the response data is empty
    case emptyResponse
    
    public static let domain = "com.kaltura.playkit.error.PhoenixMediaProvider"
    
    public var code: Int {
        switch self {
        case .invalidInputParam: return 0
        case .unableToParseData: return 1
        case .noSourcesFound: return 2
        case .serverError: return 3
        case .emptyResponse: return 4
        }
    }
    
    public var errorDescription: String {
        
        switch self {
        case .invalidInputParam(let param): return "Invalid input param: \(param)"
        case .unableToParseData(let data): return "Unable to parse object (data: \(String(describing: data)))"
        case .noSourcesFound: return "No source found to play content"
        case .serverError(let code, let message): return "Server Error code: \(code), \n message: \(message)"
        case .emptyResponse: return "Response data is empty"
        }
    }
    
    public var userInfo: [String: Any] {
        switch self {
        case .serverError(let code, let message): return [ProviderServerErrorCodeKey: code,
                                                          ProviderServerErrorMessageKey: message]
        default:
            return [String: Any]()
        }
    }
}

/************************************************************/
// MARK: - PhoenixMediaProvider
/************************************************************/

/* Description
 
    Using Session provider will help you create PKMediaEntry in order to play content with the player
    It's requestig the asset data and creating sources with relevant information for ex' contentURL, licenseURL, fiarPlay certificate and etc'
 
    #Example of code
    ````
    let phoenixMediaProvider = PhoenixMediaProvider()
    .set(type: AssetType.media)
    .set(assetId: asset.assetID)
    .set(fileIds: [file.fileID.stringValue])
    .set(networkProtocol: "https")
    .set(playbackContextType: isTrailer ? PlaybackContextType.trailer : PlaybackContextType.playback)
    .set(sessionProvider: PhoenixSessionManager.shared)

    phoenixMediaProvider.loadMedia(callback: { (media, error) in
    
    if let mediaEntry = media, error == nil {
        self.player?.prepare(MediaConfig.config(mediaEntry: mediaEntry, startTime: params.startOver ? 0 : asset.currentMediaPositionInSeconds))
    }else{
        print("error loading asset: \(error?.localizedDescription)")
        self.delegate?.corePlayer(self, didFailWith:LS("player_error_unable_to_load_entry"))
    }
    ````
})
*/
@objc public class PhoenixMediaProvider: NSObject, MediaEntryProvider {
    
    @objc public var sessionProvider: SessionProvider?
    @objc public var assetId: String?
    @objc public var epgId: String?
    @objc public var type: AssetType = .unset
    @objc public var refType: AssetReferenceType = .unset
    @objc public var formats: [String]?
    @objc public var fileIds: [String]?
    @objc public var playbackContextType: PlaybackContextType = .unset
    @objc public var networkProtocol: String = "https"
    @objc public var referrer: String?
    @objc public var urlType: String?
    @objc public var streamerType: String?
    @objc public var adapterData: [String: String]?
    
    public weak var responseDelegate: PKMediaEntryProviderResponseDelegate? = nil
    
    public var executor: RequestExecutor?
    
    public override init() { }
    
    /// - Parameter sessionProvider: This provider provider the ks for all wroking request.
    /// If ks is nil, the provider will load the media with anonymous ks
    /// - Returns: Self ( so you con continue set other parameters after it )
    @discardableResult
    @nonobjc public func set(sessionProvider: SessionProvider?) -> Self {
        self.sessionProvider = sessionProvider
        return self
    }
    
    /// Required parameter
    ///
    /// - Parameter assetId: Asset identifier
    /// - Returns: Self
    @discardableResult
    @nonobjc public func set(assetId: String?) -> Self {
        self.assetId = assetId
        return self
    }
    
    /// - Parameter epgId: The epgId if available for live/ iveDvr
    /// - Returns: Self
    @discardableResult
    @nonobjc public func set(epgId: String?) -> Self {
        self.epgId = epgId
        return self
    }
    
    /// - Parameter type: Asset Object type if it is EPG, Recording or Media
    /// - Returns: Self
    @discardableResult
    @nonobjc public func set(type: AssetType) -> Self {
        self.type = type
        return self
    }
    
    /// - Parameter refType: Asset reference type
    /// - Returns: Self
    @discardableResult
    @nonobjc public func set(refType: AssetReferenceType) -> Self {
        self.refType = refType
        return self
    }
    
    /// - Parameter playbackContextType: Trailer/Playback/StartOver/Catchup
    /// - Returns: Self
    @discardableResult
    @nonobjc public func set(playbackContextType: PlaybackContextType) -> Self {
        self.playbackContextType = playbackContextType
        return self
    }
    
    /// - Parameter formats: Asset's requested file formats,
    /// According to this formats array order the sources will be ordered in the mediaEntry
    /// According to this formats sources will be filtered when creating the mediaEntry
    /// - Returns: Self
    @discardableResult
    @nonobjc public func set(formats: [String]?) -> Self {
        self.formats = formats
        return self
    }
    
    /// - Parameter formats: Asset's requested file ids,
    /// According to this files array order the sources will be ordered in the mediaEntry
    /// According to this ids sources will be filtered when creating the mediaEntry
    /// - Returns: Self
    @discardableResult
    @nonobjc public func set(fileIds: [String]?) -> Self {
        self.fileIds = fileIds
        return self
    }
    
    /// - Parameter networkProtocol: http/https
    /// - Returns: Self
    @discardableResult
    @nonobjc public func set(networkProtocol: String) -> Self {
        self.networkProtocol = networkProtocol
        return self
    }
    
    /// - Parameter referrer: The referrer
    /// - Returns: Self
    @discardableResult
    @nonobjc public func set(referrer: String?) -> Self {
        self.referrer = referrer
        return self
    }
    
    /// - Parameter urlType: The url type
    /// - Returns: Self
    @discardableResult
    @nonobjc public func set(urlType: String?) -> Self {
        self.urlType = urlType
        return self
    }
    
    /// - Parameter streamerType: The streamer type
    /// - Returns: Self
    @discardableResult
    @nonobjc public func set(streamerType: String?) -> Self {
        self.streamerType = streamerType
        return self
    }
    
    /// - Parameter adapterData: The adapter data
    /// - Returns: Self
    @discardableResult
    @nonobjc public func set(adapterData: [String: String]?) -> Self {
        self.adapterData = adapterData
        return self
    }
    
    /// - Parameter executor: Executor which will be used to send request.
    ///    Default is KNKRequestExecutor
    /// - Returns: Self
    @discardableResult
    @nonobjc public func set(executor: RequestExecutor?) -> Self {
        self.executor = executor
        return self
    }
    
    /// - Parameter responseDelegate: responseDelegate which will be used to get the response of the requests are being sent by the mediaProvider
    ///    default is nil
    /// - Returns: Self
    @discardableResult
    @nonobjc public func set(responseDelegate: PKMediaEntryProviderResponseDelegate?) -> Self {
        self.responseDelegate = responseDelegate
        return self
    }
    
    /// This  object is created before loading the media in order to make sure all required attributes are set and we are ready to load
    public struct LoaderInfo {
        var sessionProvider: SessionProvider
        var assetId: String
        var assetType: AssetTypeAPI
        var assetRefType: AssetReferenceTypeAPI?
        var playbackContextType: PlaybackTypeAPI
        var formats: [String]?
        var fileIds: [String]?
        var networkProtocol: String
        var urlType: String?
        var streamerType: String?
        var adapterData: [String: String]?
        var executor: RequestExecutor
    }
    
    @objc public func loadMedia(callback: @escaping (PKMediaEntry?, Error?) -> Void) {
        
        guard let sessionProvider = self.sessionProvider else {
            callback(nil, PhoenixMediaProviderError.invalidInputParam(param: "sessionProvider" ).asNSError )
            return
        }
        
        guard let assetId = self.assetId else {
            callback(nil, PhoenixMediaProviderError.invalidInputParam(param: "assetId" ).asNSError)
            return
        }
        
        if self.playbackContextType == .unset {
            self.playbackContextType = .playback    // default
        }
        
        if self.type == .unset {
            switch self.playbackContextType {
            case .unset, .playback, .trailer, .download:
                self.type = .media
            case .startOver, .catchup:
                self.type = .epg
            }
        }
        
        if self.refType == .unset {
            switch self.type {
            case .media:
                self.refType = .media   // default if type is media
            case .epg:
                self.refType = .epgInternal
            case .recording:
                self.refType = .npvr
            default:
                break
            }
        }
        
        let executor = self.executor ?? KNKRequestExecutor.shared
        
        let loaderParams = LoaderInfo(sessionProvider: sessionProvider,
                                      assetId: assetId,
                                      assetType: self.toAPIType(type: self.type),
                                      assetRefType: PhoenixMediaProvider.toAPIType(type: self.refType),
                                      playbackContextType: self.toAPIType(type: self.playbackContextType),
                                      formats: self.formats,
                                      fileIds: self.fileIds,
                                      networkProtocol: self.networkProtocol,
                                      urlType: self.urlType,
                                      streamerType: self.streamerType,
                                      adapterData: self.adapterData,
                                      executor: executor)
        
        self.startLoad(loaderInfo: loaderParams, callback: callback)
    }
    
    // This is not implemened yet
    public func cancel() {
        
    }
    
    /// This method is creating the request in order to get playback context, when ks id nil we are adding anonymous login request so some times we will have just get context request and some times we will have multi request with getContext request + anonymouse login
    /// - Parameters:
    ///   - ks: ks if exist
    ///   - loaderInfo: info regarding entry to load
    /// - Returns: request builder
    func loaderRequestBuilder(ks: String?, loaderInfo: LoaderInfo) -> KalturaMultiRequestBuilder? {
        
        let multiRequestBuilder = KalturaMultiRequestBuilder(url: loaderInfo.sessionProvider.serverURL)?.setOTTBasicParams()
        
        let playbackContextOptions = PlaybackContextOptions(playbackContextType: loaderInfo.playbackContextType,
                                                            mediaProtocol: loaderInfo.networkProtocol,
                                                            assetFileIds: loaderInfo.fileIds,
                                                            referrer: self.referrer,
                                                            urlType: loaderInfo.urlType,
                                                            streamerType: self.streamerType,
                                                            adapterData: loaderInfo.adapterData)
        
        var ksString: String
        
        if let token = ks, token.isEmpty == false {
            ksString = token
        } else {
            let anonymousLogin = OTTUserService.anonymousLogin(baseURL: loaderInfo.sessionProvider.serverURL,
                                                               partnerId: loaderInfo.sessionProvider.partnerId)
            
            if let anonymousLoginRequest = anonymousLogin {
                multiRequestBuilder?.add(request: anonymousLoginRequest)
            }
            
            ksString = "{1:result:ks}"
        }
        
        if let getPlaybackContext = OTTAssetService.getPlaybackContext(baseURL:loaderInfo.sessionProvider.serverURL,
                                                                       ks: ksString,
                                                                       assetId: loaderInfo.assetId,
                                                                       type: loaderInfo.assetType,
                                                                       playbackContextOptions: playbackContextOptions) {
            
            multiRequestBuilder?.add(request: getPlaybackContext)
        }
        
        // getMetaData is only valid if assetRefType is not nil
        if let refType = loaderInfo.assetRefType {
            if let getMetaData = OTTAssetService.getMetaData(baseURL: loaderInfo.sessionProvider.serverURL,
                                                             ks: ksString,
                                                             assetId: loaderInfo.assetId,
                                                             refType: refType) {
                
                multiRequestBuilder?.add(request: getMetaData)
            }
        }
        
        return multiRequestBuilder
    }
    
    /// This method is called after all input is valid and we can start loading media
    ///
    /// - Parameters:
    ///   - loaderInfo: load info
    ///   - callback: completion clousor
    func startLoad(loaderInfo: LoaderInfo, callback: @escaping (PKMediaEntry?, Error?) -> Void) {
        loaderInfo.sessionProvider.loadKS { (ks, error) in
            
            guard let multiRequestBuilder: KalturaMultiRequestBuilder =  self.loaderRequestBuilder(ks: ks, loaderInfo: loaderInfo) else {
                callback(nil, PhoenixMediaProviderError.invalidInputParam(param:"requests params"))
                return
            }
            
            let request: Request = multiRequestBuilder.set(completion: { (response: Response) in
                
                PKLog.debug("Response:\nStatus Code: \(response.statusCode)\nError: \(response.error?.localizedDescription ?? "")\nData: \(response.data ?? "")")
                
                if let delegate = self.responseDelegate {
                    delegate.providerGotResponse(sender: self, response: response)
                }
                
                if let error = response.error {
                    // if error is of type `PKError` pass it as `NSError` else pass the `Error` object.
                    callback(nil, (error as? PKError)?.asNSError ?? error)
                    return
                }
                
                guard let responseData = response.data else {
                    callback(nil, PhoenixMediaProviderError.emptyResponse.asNSError)
                    return
                }
                
                var objects: [OTTBaseObject] = []
                
                do {
                    objects = try OTTMultiResponseParser.parse(data: responseData)
                    
                } catch {
                    callback(nil, PhoenixMediaProviderError.unableToParseData(data: responseData).asNSError)
                }
                
                var playbackContext: OTTPlaybackContext? = nil
                var mediaAsset: OTTMediaAsset? = nil
                var error: OTTError? = nil
                
                for object in objects {
                    if let context = object as? OTTPlaybackContext {
                        playbackContext = context
                    }
                    else if let asset = object as? OTTMediaAsset {
                        mediaAsset = asset
                    }
                    else if let errorObject = object as? OTTError {
                        error = errorObject
                    }
                }
             
                if let anError = error {
                    callback(nil, PhoenixMediaProviderError.serverError(code: anError.code ?? "", message: anError.message ?? "").asNSError)
                    return
                }
                
                if let context = playbackContext {
                    let tuple = PhoenixMediaProvider.createMediaEntry(loaderInfo: loaderInfo, context: context, asset: mediaAsset)
                    if let error = tuple.1 {
                        callback(nil, error)
                    } else if let media = tuple.0 {
                        if let sources = media.sources, sources.count > 0 {
                            callback(media, nil)
                        } else {
                            callback(nil, PhoenixMediaProviderError.noSourcesFound.asNSError)
                        }
                    }
                } else {
                    callback(nil, PhoenixMediaProviderError.unableToParseData(data: responseData).asNSError)
                }
            }).build()
            
            PKLog.debug("Sending requests: \(multiRequestBuilder.description)")
            loaderInfo.executor.send(request: request)
        }
    }
    
    /// Sorting and filtering source accrding to file formats or file ids
    static func sortedAndFilterSources(by fileIds: [String]?, or fileFormats: [String]?, sources: [OTTPlaybackSource]) -> [OTTPlaybackSource] {
        
        let orderedSources = sources.filter({ (source: OTTPlaybackSource) -> Bool in
            if let formats = fileFormats {
                return formats.contains(source.type)
            } else if let  fileIds = fileIds {
                return fileIds.contains("\(source.id)")
            } else {
                return true
            }
        })
            .sorted { (source1: OTTPlaybackSource, source2: OTTPlaybackSource) -> Bool in
                
                if let formats = fileFormats {
                    let index1 = formats.firstIndex(of: source1.type) ?? 0
                    let index2 = formats.firstIndex(of: source2.type) ?? 0
                    return index1 < index2
                } else if let  fileIds = fileIds {
                    
                    let index1 = fileIds.firstIndex(of: "\(source1.id)") ?? 0
                    let index2 = fileIds.firstIndex(of: "\(source2.id)") ?? 0
                    return index1 < index2
                } else {
                    return false
                }
        }
        
        return orderedSources
    }
    
    static public func createMediaEntry(loaderInfo: LoaderInfo, context: OTTPlaybackContext, asset: OTTMediaAsset?) -> (PKMediaEntry?, NSError?) {
        
        if context.hasBlockAction() != nil {
            if let error = context.hasErrorMessage() {
                return (nil, PhoenixMediaProviderError.serverError(code: error.code ?? "", message: error.message ?? "").asNSError)
            }
            return (nil, PhoenixMediaProviderError.serverError(code: "Blocked", message: "Blocked").asNSError)
        }
        
        let sortedSources = sortedAndFilterSources(by: loaderInfo.fileIds, or: loaderInfo.formats, sources: context.sources)
        
        var maxDuration: Float = 0.0
        let mediaSources =  sortedSources.compactMap { (source: OTTPlaybackSource) -> PKMediaSource? in
            
            let format = FormatsHelper.getMediaFormat(format: source.format, hasDrm: source.drm != nil)
            guard  FormatsHelper.supportedFormats.contains(format) else {
                return nil
            }
            
            var drm: [DRMParams]? = nil
            if let drmData = source.drm, drmData.count > 0 {
                drm = drmData.compactMap({ (drmData: OTTDrmData) -> DRMParams? in
                    
                    let scheme = convertScheme(scheme: drmData.scheme)
                    guard FormatsHelper.supportedSchemes.contains(scheme) else {
                        return nil
                    }
                    
                    switch scheme {
                    case .fairplay:
                        // if the scheme is type fair play and there is no certificate or license URL
                        guard let certifictae = drmData.certificate
                            else { return nil }
                        return FairPlayDRMParams(licenseUri: drmData.licenseURL, base64EncodedCertificate: certifictae)
                    default:
                        return DRMParams(licenseUri: drmData.licenseURL, scheme: scheme)
                    }
                })
                
                // checking if the source is supported with his drm data, cause if the source has drm data but from some reason the mapped drm data is empty the source is not playable
                guard let mappedDrmData = drm, mappedDrmData.count > 0  else {
                    return nil
                }
            }
            
            let mediaSource = PKMediaSource(id: "\(source.id)")
            mediaSource.contentUrl = source.url
            mediaSource.mediaFormat = format
            mediaSource.drmData = drm
            
            maxDuration = max(maxDuration, source.duration)
            return mediaSource
        }
        
        let mediaEntry = PKMediaEntry(loaderInfo.assetId, sources: mediaSources, duration: TimeInterval(maxDuration))
        mediaEntry.name = asset?.name
        
        mediaEntry.metadata = createMetadata(from: asset, loaderInfo: loaderInfo)
        
        let metadata = asset?.arrayOfMetas()
        if let tags = metadata?["tags"] {
            mediaEntry.tags = tags
        }
        
        if let asset = asset as? OTTLiveAsset {
            mediaEntry.mediaType = .live
            
            if let enableTrickPlay = asset.enableTrickPlay, enableTrickPlay {
                mediaEntry.mediaType = .dvrLive
            }
        }
        
        if loaderInfo.assetType == .epg && loaderInfo.playbackContextType == .startOver {
            mediaEntry.mediaType = .dvrLive
        }
        
        return (mediaEntry, nil)
    }
    
    static func createMetadata(from asset: OTTMediaAsset?, loaderInfo: LoaderInfo) -> [String: String] {
        var metadata: [String: String] = asset?.arrayOfMetas() ?? [:]
        
        if let recordingAsset = asset as? OTTRecordingAsset {
            metadata["recordingId"] = recordingAsset.recordingId
            metadata["recordingType"] = recordingAsset.recordingType.map { $0.rawValue }
        }
        
        // programAsset.epgId will be set both for OTTRecordingAsset and OTTProgramAsset
        if let programAsset = asset as? OTTProgramAsset {
            metadata["epgId"] = programAsset.epgId
        }
        
        metadata["assetType"] = loaderInfo.assetType.description
        metadata["contextType"] = loaderInfo.playbackContextType.description
        
        // Add entryId to the metadata
        if let entryId = asset?.entryId {
            metadata["entryId"] = entryId
        }
        
        return metadata
    }
    
    // Mapping between server scheme and local definision of scheme
    static func convertScheme(scheme: String) -> DRMParams.Scheme {
        switch (scheme) {
        case "WIDEVINE_CENC":
            return .widevineCenc
        case "PLAYREADY_CENC":
            return .playreadyCenc
        case "WIDEVINE":
            return .widevineClassic
        case "FAIRPLAY":
            return .fairplay
        default:
            return .unknown
        }
    }
    
    func toAPIType(type: AssetType) -> AssetTypeAPI {
        switch type {
        case .epg:
            return .epg
        case .media:
            return .media
        case .recording:
            return .recording
        case .unset:
            fatalError("Invalid AssetType")
        }
    }
    
    static func toAPIType(type: AssetReferenceType) -> AssetReferenceTypeAPI? {
        switch type {
        case .media:
            return .media
        case .epgInternal:
            return .epgInternal
        case .epgExternal:
            return .epgExternal
        case .npvr:
            return .npvr
        case .unset:
            return nil
        }
    }
    
    func toAPIType(type: PlaybackContextType) -> PlaybackTypeAPI {
        switch type {
        case .download:
            return .download
        case .catchup:
            return .catchup
        case .playback:
            return .playback
        case .startOver:
            return .startOver
        case .trailer:
            return .trailer
        case .unset:
            fatalError("Invalid PlaybackContextType")
        }
    }
}
