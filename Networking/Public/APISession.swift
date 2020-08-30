//
//  Session.swift
//  Networking
//
//  Created by Pawel Klapuch on 27/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation
import PromiseKit

public class APISession: NSObject, URLSessionDelegate, APISessionProtocol {
    
    public var onAuthenitcationRequired: ((Swift.Error?) -> Void)?
    
    public enum Error: CustomNSError, LocalizedError {
        
        case fatal
        case cancelled
        case duplicatedRequest
        case unauthorized
    
        public static var errorDomain: String { "APISession.Error" }
        public var errorCode: Int {
            switch self {
            case .fatal: return 0
            case .cancelled: return 1
            case .duplicatedRequest: return 2
            case .unauthorized: return 3
            }
        }
        
        public var errorDescription: String? {
            switch self {
            case .fatal: return "fatal"
            case .cancelled: return "cancelled"
            case .duplicatedRequest: return "duplicated request"
            case .unauthorized: return "unauthorized"
            }
        }
    }
        
    private let queue = DispatchQueue(label: "com.pk.networking.session")
    private var urlSession: URLSession!
    
    private let authenticating: APIAuthenticating?
    private let pinning: APISessionPinner?
    
    private var refreshTokenPending = false
    
    /** Requests not currently executing and waiting to be executed */
    private var queuedRequests = [APIQueuedRequest]()
    
    /** Requests currently being executed or cancelled */
    private var activeRequests = [APIActiveRequest]()
    
    /** Requests waiting for refresh token completion */
    private var authQueuedRequests = [APIQueuedRequest]()
    
    private let log = APINetworking.log
    
    public init(configuration: URLSessionConfiguration, authenticating: APIAuthenticating? = nil, pinning: APISessionPinning? = nil) {
        
        self.authenticating = authenticating
        self.pinning = APISessionPinner.create(pinning: pinning)
        super.init()
        
        self.urlSession = URLSession(configuration: configuration,
                                     delegate: self,
                                     delegateQueue: OperationQueue.main)
    }
    
    public func execute(_ request: APIRequest) -> Promise<APIResponse> {
     
        return execute_(request: request, callback: nil)
    }
    
    private func execute_( request: APIRequest, callback: APIRequest.APICallback? = nil) -> Promise<APIResponse> {
        
        return Promise<APIResponse> { r in
                     
            queue.async { [weak self] in
            
                guard let self = self else {
                    r.reject(Error.cancelled)
                    return
                }
                
                guard self.isUnique(request: request) else {
                    r.reject(Error.duplicatedRequest)
                    return
                }
                
                if let callback = callback {
                    
                    self.queuedRequests.append(APIQueuedRequest(request: request, callback: callback))
                    
                } else {
                    
                    let qR = APIQueuedRequest(request: request, callback: APIRequest.APICallback.create(with: r))
                    self.addQueuedRequest(qR)
                }
                
                self.resumeAllQueuedRequests()
            }
        }
    }
    
    private func addQueuedRequest(_ queuedRequest: APIQueuedRequest) {
        
        self.queuedRequests.append(queuedRequest)
    }
    
    private func addAuthQueuedRequest(_ queuedRequest: APIQueuedRequest) {
        
        self.authQueuedRequests.append(queuedRequest)
    }
    
    private func resumeAllQueuedRequests() {
        
        // Trigger all non-auth requests
        let nonAuthRequests = queuedRequests.filter { $0.request.authentication == .none }
        nonAuthRequests.forEach { resume(queuedRequest: $0 )}
        
        // Trigger all auth requests or wait for refresh token to complete
        guard refreshTokenPending == false else { return }
        let authRequests = queuedRequests.filter { $0.request.authentication == .oauth }
        authRequests.forEach { resume(queuedRequest: $0) }
    }
    
    private func resume(queuedRequest: APIQueuedRequest) {
        
        queuedRequests.removeAll(where: { $0.ID == queuedRequest.ID })
        let request = queuedRequest.request
        
        createSessionHeaders(for: request).then(on: self.queue) { sessionHeaders in
            
             request.createURLRequest(sessionHeaders: sessionHeaders)
            
        }.then(on: self.queue) { [weak self] urlRequset -> Promise<APISessionTask> in
            
            guard let self = self else { throw Error.cancelled }
            return self.urlSession.createTask(with: urlRequset)
            
        }.then(on: self.queue) { [weak self] sessionTask -> Promise<(Data?, URLResponse?)>  in
            
            guard let self = self else { throw Error.cancelled }
            self.activeRequests.append(APIActiveRequest.create(fromQueuedRequest: queuedRequest, sessionTask: sessionTask))
            self.logOutgoing(request: request, sessionTask: sessionTask)
            return sessionTask.resume()
            
        }.then { [weak self] (data, urlResponse) -> Promise<APIRawResponse> in
            
            self?.logIncoming(request: request, data: data, urlResponse: urlResponse)
            guard let self = self else { throw Error.cancelled }
            return self.getRawResponse(from: request, data: data, urlResponse: urlResponse)
        
        }.then(on: queue) { [weak self] response -> Promise<APIResponse> in
            
            guard let self = self else { throw Error.cancelled }
            return self.process(rawResponse: response, forRequest: request)
            
        }.done(on: queue) { [weak self] response in
            
            self?.forget(request: request)
            queuedRequest.callback.onSuccess(response)
            
        }.catch(on: queue) { [weak self] error in
            
            self?.forget(request: request)
            
            if error.domain == InternalError.tokenExpired.domain && error.code == InternalError.tokenExpired.errorCode {
                
                self?.addAuthQueuedRequest(queuedRequest)
                self?.refreshToken()
                
            } else {
                
                queuedRequest.callback.onError(error)
                self?.resumeAllQueuedRequests()
            }
        }
    }
    
    /** ATM will attempt to cancel request - if request already completed -> will take no further action */
    public func cancel(request: APIRequest) {
        
        queue.async { [weak self] in
            self?.cancel_(request: request)
        }
    }
    
    /** ATM will attempt to cancel request - if request already completed -> will take no further action */
    func cancel_(request: APIRequest) {
        
        log?.apiLog(message: "cancel request \(request.identifier)", type: .info)
        
        if let index = queuedRequests.firstIndex(where: { $0.ID == request.identifier }) {
            
            queuedRequests[index].callback.onError(Error.cancelled)
            queuedRequests.remove(at: index)
            log?.apiLog(message: "request cancelled (while inactive/queued) \(request.identifier)", type: .info)
            
        } else if let index = activeRequests.firstIndex(where: { $0.ID == request.identifier }) {
            
            activeRequests[index].sessionTask.cancel()
            log?.apiLog(message: "request cancelled (while active) \(request.identifier)", type: .info)
        }
    }
        
    private func getRawResponse(from request: APIRequest, data: Data?, urlResponse: URLResponse?) -> Promise<APIRawResponse> {
        
        let httpUrlResponse = urlResponse as? HTTPURLResponse
        let statusCode = httpUrlResponse?.statusCode
                
        var headers: APIHTTPHeaders?
        if let allHttpHeaders = httpUrlResponse?.allHeaderFields as? [String: String] {
            headers = APIHTTPHeaders(allHttpHeaders)
        }
        
        let rawResponse = APIRawResponse(status: statusCode,
                                         headers: headers ?? APIHTTPHeaders(),
                                         data: data)
        
        return Promise<APIRawResponse>.instantValue(rawResponse)
    }
    
    private func process(rawResponse: APIRawResponse, forRequest request: APIRequest) -> Promise<APIResponse> {
        
        let httpCode = APIHttpCode.create(from: rawResponse.status)
        
        if rawResponse.status == 401 {
            
            if request.authentication == .none {
                return Promise<APIResponse>.instantError(Error.unauthorized)
            } else {
                return Promise<APIResponse>.instantError(InternalError.tokenExpired)
            }
            
        } else {
            
            if let data = rawResponse.data {
                
                do {
                    let model = try request.parse(data: data, httpCode: httpCode)
                    return Promise<APIResponse>.instantValue(APIResponse(raw: rawResponse, model: model))
                } catch {
                    return Promise<APIResponse>.instantError(error)
                }
                
            } else {
                return Promise<APIResponse>.instantValue(APIResponse(raw: rawResponse, model: nil))
            }
        }
    }
 
    private func isUnique(request: APIRequest) -> Bool {
        
        guard queuedRequests.first(where: { $0.ID == request.identifier }) == nil else { return false }
        guard activeRequests.first(where: { $0.ID == request.identifier }) == nil else { return false }
        guard authQueuedRequests.first(where: { $0.ID == request.identifier }) == nil else { return false }
        
        return true
    }

    private func refreshToken() {
        
        log?.apiLog(message: "refresh token", type: .info)
        refreshTokenPending = true
        
        if let authenticating = authenticating {
            
            authenticating.refresh().done(on: queue) { [weak self] _ in
                self?.didRefreshToken()
            }.catch(on: queue) { [weak self] error in
                self?.didFailToRefreshToken(error: error)
            }
        } else {
            didFailToRefreshToken(error: Error.unauthorized)
        }
    }
    
    private func didRefreshToken() {
        
        log?.apiLog(message: "did refresh token", type: .info)
        refreshTokenPending = false
        queuedRequests.append(contentsOf: authQueuedRequests)
        authQueuedRequests.removeAll()
        resumeAllQueuedRequests()
    }
    
    private func didFailToRefreshToken(error: Swift.Error) {
        
        log?.apiLog(message: "failed to refresh token (\(error)", type: .info)
        refreshTokenPending = false
        authQueuedRequests.forEach { $0.callback.onError(Error.cancelled) }
        authQueuedRequests.removeAll()
        resumeAllQueuedRequests()
        onAuthenitcationRequired?(error)
    }
    
    private func createSessionHeaders(for request: APIRequest) -> Promise<APIHTTPHeaders> {
    
        switch request.authentication {
        case .none: return Promise<APIHTTPHeaders>.instantValue(APIHTTPHeaders())
        case .oauth:
    
            if let auth = authenticating {

                return auth.getCurrentToken().map { token in
                    return APIHTTPHeaders(["authorization": "Bearer \(token.getAccessToken())"])
                }
            } else {
                return Promise<APIHTTPHeaders>.instantError(Error.unauthorized)
            }
        }
    }
    
    /** LOG -  IN & OUT*/
    private func getPayloadDescription(payload: Data?) -> String {
        
        var formattedJSON: String?
        
        if let data = payload {
            
            if let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) {
                if let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
                    formattedJSON = String(data: prettyData, encoding: .utf8)
                }
            }
            
            if (formattedJSON == nil) {
                formattedJSON = String(data: data, encoding: .utf8)
            }
        }
        
        if let formattedJSON = formattedJSON {
            return "\(formattedJSON)"
        } else {
            return "--"
        }
    }
    
    private func logOutgoing(request: APIRequest, sessionTask: APISessionTask) {
        
        log?.apiLog(message: "OUT: \(request.url.absoluteString) (\(request.method.rawValue))", type: .info)
        log?.apiLog(message: "OUT headers: \( request.getHeadersDescription())", type: .info)
        log?.apiLog(message: "OUT payload: \(sessionTask.getPayloadDescription())", type: .info)
    }
    
    private func logIncoming(request: APIRequest, data: Data?, urlResponse: URLResponse?) {
        
        let httpUrlResponse = urlResponse as? HTTPURLResponse
        let code = httpUrlResponse?.statusCode
                
        log?.apiLog(message: "IN: \(request.url.absoluteString) (\(request.method.rawValue)) - \(code ?? -1)", type: .info)
        log?.apiLog(message: "IN headers: \( urlResponse?.getHeadersDescription() ?? "--")", type: .info)
        log?.apiLog(message: "IN payload: \(getPayloadDescription(payload: data))", type: .info)
    }
    
    private func forget(request: APIRequest) {
        
        if let index = queuedRequests.firstIndex(where: { $0.ID == request.identifier }) {
            print("delete request from queued (\(request.identifier)")
            queuedRequests.remove(at: index)
        }

        if let index = activeRequests.firstIndex(where: { $0.ID == request.identifier }) {
            print("delete request from active (\(request.identifier)")
            activeRequests.remove(at: index)
        }
        
        if let index = authQueuedRequests.firstIndex(where: { $0.ID == request.identifier }) {
            print("delete request from active (\(request.identifier)")
            authQueuedRequests.remove(at: index)
        }
    }
}

extension APISession: URLSessionTaskDelegate {
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        guard let pinning = pinning else {
            completionHandler(.performDefaultHandling, nil); return
        }
        
        pinning.urlSession(session, didReceive: challenge, completionHandler: completionHandler)
    }
}

extension URLResponse {
    
    fileprivate func getHeadersDescription() -> String {
        
        let httpUrlResponse = self as? HTTPURLResponse
        let headers = httpUrlResponse?.allHeaderFields
        
        let headersDesc = headers?.map { header -> String in return "\(header.key): \(header.value as? String ?? "--")" }
        return (headersDesc ?? []).joined(separator: "; ")
    }
}

extension URLRequest {
    
    fileprivate func getHeadersDescription() -> String {
        let headersDesc = allHTTPHeaderFields?.map { header -> String in return "\(header.key): \(header.value)" }
        return (headersDesc ?? []).joined(separator: "; ")
    }
}

extension URLSession {
    
    fileprivate func createTask(with urlRequest: URLRequest) -> Promise<APISessionTask> {
        return Promise<APISessionTask> { r in
            r.fulfill(APISessionTask(request: urlRequest, session: self))
        }
    }
}

