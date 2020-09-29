//
//  Session.swift
//  Networking
//
//  Created by Pawel Klapuch on 27/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

public class APISession: NSObject, URLSessionDelegate, APISessionProtocol {
    
    public var onAuthenitcationRequired: OptionalErrorBlock?
    
    public enum Error: CustomNSError, LocalizedError {
        
        case cancelled
        case duplicatedRequest
        case unauthorized
    
        public static var errorDomain: String { "APISession.Error" }
        public var errorCode: Int {
            switch self {
            case .cancelled: return 1
            case .duplicatedRequest: return 2
            case .unauthorized: return 3
            }
        }
        
        public var errorDescription: String? {
            switch self {
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
    
    public init(configuration: URLSessionConfiguration,
                authenticating: APIAuthenticating? = nil,
                pinning: APISessionPinning? = nil) {
        
        self.authenticating = authenticating
        self.pinning = APISessionPinner.create(pinning: pinning)
        super.init()
        self.urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
    
    public func execute(_ request: APIRequest, onSuccess:@escaping ResponseBlock, onError:@escaping ErrorBlock) {
     
        queue.async { [weak self] in

            guard let self = self else { return }
            guard self.isUnique(request: request) else { onError(Error.duplicatedRequest); return }

            let callback = APIRequest.APICallback(onSuccess: onSuccess, onError: onError)
            self.queuedRequests.append(APIQueuedRequest(request: request, callback: callback))
            self.resumeAllQueuedRequests()
        }
    }
    
    /** ATM will attempt to cancel request - if request already completed -> will take no further action */
    public func cancel(request: APIRequest) {
       
        queue.async { [weak self] in
            self?.cancel_(request: request)
        }
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
        
        createSessionHeaders(for: request, onSuccess: { [weak self] sessionHeaders in
            self?.request(queuedRequest, didPrepareSessionHeaders: sessionHeaders)
        }) { [weak self] error in
            self?.request(queuedRequest, didFailWithError: error)
        }
    }
    
    private func request(_ queuedRequest: APIQueuedRequest, didPrepareSessionHeaders sessionHeaders: APIHTTPHeaders) {
        
        queue.async { [weak self] in
            guard let self = self else { return }
            do {
                let urlRequest = try queuedRequest.request.urlRequest(with: sessionHeaders)
                self.request(queuedRequest, didPrepareSessionTask: self.urlSession.createTask(with: urlRequest))
            } catch {
                self.request(queuedRequest, didFailWithError: error)
            }
        }
    }
    
    private func request(_ queuedRequest: APIQueuedRequest, didPrepareSessionTask task: APISessionTask) {
        
        queue.async { [weak self] in
            guard let self = self else { return }
            let activeRequest = APIActiveRequest.create(fromQueuedRequest: queuedRequest, sessionTask: task)
            self.activeRequests.append(activeRequest)
            self.logOutgoing(request: queuedRequest.request, sessionTask: task)
            
            task.resume(onSuccess: { [weak self] data, urlResponse in
                self?.request(queuedRequest, didGetURLResponse: urlResponse, andData: data)
            }) { [weak self] error in
                self?.request(queuedRequest, didFailWithError: error)
            }
        }
    }

    private func request(_ queuedRequest: APIQueuedRequest, didGetURLResponse urlResponse: URLResponse?, andData data: Data?) {
        
        queue.async { [weak self] in
            guard let self = self else { return }
            self.logIncoming(request: queuedRequest.request, data: data, urlResponse: urlResponse)
            self.request(queuedRequest, didGetRawResopsne: self.getRawResponse(fromData: data, urlResponse: urlResponse))
        }
    }
    
    private func request(_ queuedRequest: APIQueuedRequest, didGetRawResopsne rawResponse: APIRawResponse) {
        
        guard rawResponse.status != 401 else {
            
            if queuedRequest.request.authentication == .none {
                request(queuedRequest, didFailWithError: Error.unauthorized)
            } else {
                request(queuedRequest, didFailWithError: InternalError.tokenExpired)
            }
            return
        }
        
        let httpGroupCode = APIHTTPGroupCode.create(from: rawResponse.status)
        
        guard let data = rawResponse.data else {
            request(queuedRequest, didFinishWithResponse: APIResponse(raw: rawResponse, model: nil)); return
        }
        
        do {
            let model = try queuedRequest.request.parse(data: data, httpGroupCode: httpGroupCode)
            request(queuedRequest, didFinishWithResponse: APIResponse(raw: rawResponse, model: model))
        } catch {
            request(queuedRequest, didFailWithError: error)
        }
    }
    
    private func request(_ queuedRequest: APIQueuedRequest, didFinishWithResponse response: APIResponse) {
        
        forget(request: queuedRequest.request)
        queuedRequest.callback.onSuccess(response)
    }
    
    private func request(_ queuedRequest: APIQueuedRequest, didFailWithError error: Swift.Error) {
        
        forget(request: queuedRequest.request)
        
        if error.isError(.tokenExpired) {
            addAuthQueuedRequest(queuedRequest)
            refreshToken()
        } else {
            queuedRequest.callback.onError(error)
        }
    }

    /** ATM will attempt to cancel request - if request already completed -> will take no further action */
    func cancel_(request: APIRequest) {
        
        APINetworking.log?.apiLog(message: "cancel request \(request.identifier)", type: .info)
        
        if let index = queuedRequests.firstIndex(where: { $0.ID == request.identifier }) {
            
            queuedRequests[index].callback.onError(Error.cancelled)
            queuedRequests.remove(at: index)
            APINetworking.log?.apiLog(message: "request cancelled (while inactive/queued) \(request.identifier)", type: .info)
            
        } else if let index = activeRequests.firstIndex(where: { $0.ID == request.identifier }) {
            
            activeRequests[index].sessionTask.cancel()
            APINetworking.log?.apiLog(message: "request cancelled (while active) \(request.identifier)", type: .info)
        }
    }
        
    private func getRawResponse(fromData data: Data?, urlResponse: URLResponse?) -> APIRawResponse {
        
        let httpUrlResponse = urlResponse as? HTTPURLResponse
        let statusCode = httpUrlResponse?.statusCode
                
        var headers: APIHTTPHeaders?
        if let allHttpHeaders = httpUrlResponse?.allHeaderFields as? [String: String] {
            headers = APIHTTPHeaders(allHttpHeaders)
        }
        
        return APIRawResponse(status: statusCode, headers: headers ?? APIHTTPHeaders(), data: data)
    }
 
    private func isUnique(request: APIRequest) -> Bool {
        
        guard queuedRequests.first(where: { $0.ID == request.identifier }) == nil else { return false }
        guard activeRequests.first(where: { $0.ID == request.identifier }) == nil else { return false }
        guard authQueuedRequests.first(where: { $0.ID == request.identifier }) == nil else { return false }
        
        return true
    }

    private func refreshToken() {
        
        APINetworking.log?.apiLog(message: "refresh token", type: .info)
        refreshTokenPending = true
        
        if let auth = authenticating {
            
            auth.refresh(onSuccess: { [weak self] _ in
                self?.refreshTokenDidComplete(with: nil)
            }) { [weak self] error in
                self?.refreshTokenDidComplete(with: error)
            }

        } else {
            refreshTokenDidComplete(with: Error.unauthorized)
        }
    }
    
    private func refreshTokenDidComplete(with error: Swift.Error?) {
        
        queue.async { [weak self] in
            guard let self = self else { return }
        
            self.refreshTokenPending = false
            
            if let error = error {
                APINetworking.log?.apiLog(message: "failed to refresh token (\(error)", type: .error)
                self.authQueuedRequests.forEach { $0.callback.onError(Error.cancelled) }
                self.onAuthenitcationRequired?(error)
                
            } else {
                APINetworking.log?.apiLog(message: "did refresh token", type: .info)
                self.queuedRequests.append(contentsOf: self.authQueuedRequests)
            }
            
            self.resumeAllQueuedRequests()
            self.authQueuedRequests.removeAll()
        }
    }
    
    private func createSessionHeaders(for request: APIRequest,
                                      onSuccess:@escaping HeadersBlock,
                                      onError:@escaping ErrorBlock) {
        
        switch request.authentication {
            
            case .none: onSuccess(APIHTTPHeaders())
            case .oauth:
            
                guard let auth = authenticating else { onError(Error.unauthorized); return }
                auth.getCurrentToken(onSuccess: { token in
                    onSuccess(APIHTTPHeaders(["authorization": "Bearer \(token.getAccessToken())"]))
                }, onError: onError)
        }
    }
    
    /** LOG -  IN & OUT */
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
        
        APINetworking.log?.apiLog(message: "OUT: \(request.url.absoluteString) (\(request.method.rawValue))", type: .info)
        APINetworking.log?.apiLog(message: "OUT headers: \( sessionTask.urlRequest.getHeadersDescription())", type: .info)
        APINetworking.log?.apiLog(message: "OUT payload: \(sessionTask.getPayloadDescription())", type: .info)
    }
    
    private func logIncoming(request: APIRequest, data: Data?, urlResponse: URLResponse?) {
        
        let httpUrlResponse = urlResponse as? HTTPURLResponse
        let code = httpUrlResponse?.statusCode
                
        APINetworking.log?.apiLog(message: "IN: \(request.url.absoluteString) (\(request.method.rawValue)) - \(code ?? -1)", type: .info)
        APINetworking.log?.apiLog(message: "IN headers: \( urlResponse?.getHeadersDescription() ?? "--")", type: .info)
        APINetworking.log?.apiLog(message: "IN payload: \(getPayloadDescription(payload: data))", type: .info)
    }
    
    private func forget(request: APIRequest) {
        
        if let index = queuedRequests.firstIndex(where: { $0.ID == request.identifier }) {
            print("delete request from queued_inactive (\(request.identifier)")
            queuedRequests.remove(at: index)
        }

        if let index = activeRequests.firstIndex(where: { $0.ID == request.identifier }) {
            print("delete request from active (\(request.identifier)")
            activeRequests.remove(at: index)
        }
        
        if let index = authQueuedRequests.firstIndex(where: { $0.ID == request.identifier }) {
            print("delete request from queued_auth (\(request.identifier)")
            authQueuedRequests.remove(at: index)
        }
    }
    
    private func addQueuedRequest(_ queuedRequest: APIQueuedRequest) {
        
        self.queuedRequests.append(queuedRequest)
    }
    
    private func addAuthQueuedRequest(_ queuedRequest: APIQueuedRequest) {
        
        self.authQueuedRequests.append(queuedRequest)
    }
}

extension Swift.Error {
    
    fileprivate func isError(_ error: APISession.InternalError) -> Bool {
        return domain == error.domain && code == error.code
    }
}

extension APISession: URLSessionTaskDelegate {
    
    public func urlSession(_ session: URLSession,
                           didReceive challenge: URLAuthenticationChallenge,
                           completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
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
    
    fileprivate func createTask(with urlRequest: URLRequest) -> APISessionTask {
        return APISessionTask(request: urlRequest, session: self)
    }
}
