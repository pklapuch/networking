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
        case invalidURL
        case duplicatedRequest
        case unauthorized
        case backend(String)
    
        public static var errorDomain: String { "APISession.Error" }
        public var errorCode: Int {
            switch self {
            case .cancelled: return 1
            case .invalidURL: return 2
            case .duplicatedRequest: return 3
            case .unauthorized: return 4
            case .backend(_): return 5
            }
        }
        
        public var errorDescription: String? {
            switch self {
            case .cancelled: return "cancelled"
            case .invalidURL: return "invalid URL"
            case .duplicatedRequest: return "duplicated request"
            case .unauthorized: return "unauthorized"
            case .backend(let message): return "backend: \(message)"
            }
        }
    }
        
    private let queue = DispatchQueue(label: "com.pk.networking.session")
    private var urlSession: URLSession!
    
    private let signing: APISigning?
    private let pinning: APISessionPinner?
    private let resolver: APIEndpointResolver?
    
    // Session specific headers
    private var headers: APIHTTPHeaders? = nil
    
    private var signatureRenewalPending = false
    
    /** Requests not currently executing and waiting to be executed */
    private var queuedRequests = [APIQueuedRequest]()
    
    /** Requests currently being executed or cancelled */
    private var activeRequests = [APIActiveRequest]()
    
    public init(configuration: URLSessionConfiguration,
                signing: APISigning? = nil,
                pinning: APISessionPinning? = nil,
                resolver: APIEndpointResolver? = nil) {
        
        self.signing = signing
        self.pinning = APISessionPinner.create(pinning: pinning)
        self.resolver = resolver
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
    
    public func getURL(for request: APIRequest) throws -> URL {
        
        var url: URL?
        
        if let requestResolver = request.resolver {
            url = try requestResolver.resolve(relativePath: request.path)
        } else if let sessionResolver = resolver {
            url = try sessionResolver.resolve(relativePath: request.path)
        } else {
            url = try URL.create(from: request.path)
        }
        
        guard var finalURL = url else { throw Error.cancelled }
        for item in request.urlParameters {
            try finalURL.appendQueryItem(name: item.key, value: item.value)
        }
        
        return finalURL
    }
    
    /** ATM will attempt to cancel request - if request already completed -> will take no further action */
    public func cancel(request: APIRequest) {
       
        queue.async { [weak self] in
            self?.cancel_(request: request)
        }
    }
    
    private func resumeAllQueuedRequests() {
                
        guard signatureRenewalPending == false else { return }
        
        let requests = queuedRequests
        queuedRequests.removeAll()
        
        requests.forEach { resume(queuedRequest: $0) }
    }
    
    private func resume(queuedRequest: APIQueuedRequest) {
        
        do {
        
            let url = try self.getURL(for: queuedRequest.request)
            let urlRequest = try queuedRequest.request.urlRequest(with: url, sessionHeaders: headers)
            sign(urlRequset: urlRequest, queuedRequest: queuedRequest)
           
        } catch {
            self.request(queuedRequest, didFailWithError: error)
        }
    }
    
    private func sign(urlRequset: URLRequest, queuedRequest: APIQueuedRequest) {
        
        if let signing = signing {
            
            signing.sign(urlRequset) { [weak self] signedRequset in
                
                guard let self = self else { return }
                self.queue.async {
                
                    let task = self.urlSession.createTask(with: signedRequset)
                    self.request(queuedRequest, didPrepareSessionTask: task)
                }
                
            } onFailure: { [weak self] error in
                
                guard let self = self else { return }
                self.queue.async {
                    self.request(queuedRequest, didFailWithError: error)
                }
            }

        } else {
            
            let task = urlSession.createTask(with: urlRequset)
            self.request(queuedRequest, didPrepareSessionTask: task)
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
        
        if let signing = signing {
            if signing.isSignatureRejected(rawResponse.data, status: rawResponse.status) {
                request(queuedRequest, didFailWithError: InternalError.signatureExpired)
                return
            }
        }
        
        let httpGroupCode = APIHTTPGroupCode.create(from: rawResponse.status)
        
        if httpGroupCode == .group3xx {
            request(queuedRequest, didFinishWithResponse: APIResponse(raw: rawResponse, model: nil))
            return
        }
        
        if httpGroupCode == .group2xx {
            
            do {
                let model = try queuedRequest.request.parse(data: rawResponse.data ?? Data(), httpGroupCode: httpGroupCode)
                request(queuedRequest, didFinishWithResponse: APIResponse(raw: rawResponse, model: model))
            } catch {
                request(queuedRequest, didFailWithError: error)
            }
            return
        }
        
        do {
            if let errorModel = try queuedRequest.request.parse(data: rawResponse.data ?? Data(), httpGroupCode: httpGroupCode) {
                request(queuedRequest, didFailWithError: Error.backend(String(describing: errorModel)))
            } else {
                request(queuedRequest, didFailWithError: Error.backend("unknown"))
            }
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
        
        if error.isError(.signatureExpired) {
            addQueuedRequest(queuedRequest)
            requestSignatureRenewal()
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
        
        return true
    }

    private func requestSignatureRenewal() {
        
        APINetworking.log?.apiLog(message: "refresh grant", type: .info)
        signatureRenewalPending = true
        
        if let signing = signing {
            
            signing.renewSignature { [weak self] in
                self?.refreshTokenDidComplete(with: nil)
            } onFailure: { [weak self] error in
                self?.refreshTokenDidComplete(with: error)
            }

        } else {
            
            refreshTokenDidComplete(with: Error.unauthorized)
        }
    }
    
    private func refreshTokenDidComplete(with error: Swift.Error?) {
        
        queue.async { [weak self] in
            guard let self = self else { return }
        
            self.signatureRenewalPending = false
            
            if let error = error {
                APINetworking.log?.apiLog(message: "failed to refresh token (\(error)", type: .error)
                self.queuedRequests.forEach { $0.callback.onError(Error.cancelled) }
                self.onAuthenitcationRequired?(error)
                
            } else {
                APINetworking.log?.apiLog(message: "did refresh token", type: .info)
            }
            
            self.resumeAllQueuedRequests()
        }
    }
    
    private func forget(request: APIRequest) {
        
        if let index = queuedRequests.firstIndex(where: { $0.ID == request.identifier }) {
            //print("delete request from queued_inactive (\(request.identifier)")
            queuedRequests.remove(at: index)
        }

        if let index = activeRequests.firstIndex(where: { $0.ID == request.identifier }) {
            //print("delete request from active (\(request.identifier)")
            activeRequests.remove(at: index)
        }
    }
    
    private func addQueuedRequest(_ queuedRequest: APIQueuedRequest) {
        
        self.queuedRequests.append(queuedRequest)
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

extension APISession {
    
    // MRAK: Logging
    
    private func logOutgoing(request: APIRequest, sessionTask: APISessionTask) {
        
        logOutgoingURL(for: request, urlRequest: sessionTask.urlRequest)
        logOutgoingHeaders(for: request, urlRequest: sessionTask.urlRequest)
        logOutgoingPayload(for: request, urlRequest: sessionTask.urlRequest)
    }
    
    private func logOutgoingURL(for request: APIRequest, urlRequest: URLRequest) {
        
        // NOTE: If needed, add URL obfuscation for log message when initializing APIRequest!
        
        APINetworking.log?.apiLog(message: "OUT: \(urlRequest.url?.absoluteString ?? request.path) (\(request.method.rawValue))", type: .info)
    }
    
    private func logOutgoingHeaders(for request: APIRequest, urlRequest: URLRequest) {
        
        // NOTE: If needed, add Headers obfuscation for log message when initializing APIRequest!
        
        APINetworking.log?.apiLog(message: "OUT headers: \( urlRequest.getHeadersDescription())", type: .info)
    }
    
    private func logOutgoingPayload(for request: APIRequest, urlRequest: URLRequest) {
        
        // NOTE: If needed, add Payload obfuscation for log message when initializing APIRequest!
        
        var desc: String?
        if let logger = request.outgoingLogger?.payload {
            desc = logger.getPayloadDescription(for: urlRequest.httpBody)
        } else {
            desc = PayloadUtility.getLogDescription(for: urlRequest.httpBody)
        }

        APINetworking.log?.apiLog(message: "OUT payload: \(desc ?? "--")", type: .info)
    }
    
    private func logIncoming(request: APIRequest, data: Data?, urlResponse: URLResponse?) {
        
        logIncomingURL(for: request, urlResponse: urlResponse)
        logIncomingHeaders(for: request, urlResponse: urlResponse)
        logIncomingPayload(for: request, data: data)
    }
    
    private func logIncomingURL(for request: APIRequest, urlResponse: URLResponse?) {
        
        // NOTE: If needed, add URL obfuscation for log message when initializing APIRequest!
        
        let httpUrlResponse = urlResponse as? HTTPURLResponse
        let code = httpUrlResponse?.statusCode
        
        APINetworking.log?.apiLog(message: "IN: \(urlResponse?.url?.absoluteString ?? request.path) (\(request.method.rawValue)) - \(code ?? -1)", type: .info)
    }
    
    private func logIncomingHeaders(for request: APIRequest, urlResponse: URLResponse?) {
        
        // NOTE: If needed, add Headers obfuscation for log message when initializing APIRequest!
        
        APINetworking.log?.apiLog(message: "IN headers: \( urlResponse?.getHeadersDescription() ?? "--")", type: .info)
    }
    
    private func logIncomingPayload(for request: APIRequest, data: Data?) {
        
        var desc: String?
        if let logger = request.incomingLogger?.payload {
            desc = logger.getPayloadDescription(for: data)
        } else {
            desc = PayloadUtility.getLogDescription(for: data)
        }
        
        APINetworking.log?.apiLog(message: "IN payload: \(desc ?? "--")", type: .info)
    }
}
