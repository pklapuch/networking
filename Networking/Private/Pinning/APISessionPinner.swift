//
//  SessionPinner.swift
//  Networking
//
//  Created by Pawel Klapuch on 29/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation

struct APISessionPinner {
    
    let pinning: APISessionPinning
    
    fileprivate struct AuthChallengeDisposition {
        
        let mode: URLSession.AuthChallengeDisposition
        let credential: URLCredential?
    }
    
    private var dispositionWhenServerTrustNotSet = URLSession.AuthChallengeDisposition.performDefaultHandling
    
    static func create(pinning: APISessionPinning?) -> APISessionPinner? {
        
        if let pinning = pinning {
            return APISessionPinner(pinning: pinning)
        } else {
            return nil
        }
    }
    
    init(pinning: APISessionPinning) {
     
        self.pinning = pinning
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(dispositionWhenServerTrustNotSet, nil); return
        }
        
        func evaluateZeroCertificatesChain() {
            let disposition = evaluate(host: host, certificates: [])
            completionHandler(disposition.mode, disposition.credential);
        }
        
        let host = challenge.protectionSpace.host
        let count = SecTrustGetCertificateCount(serverTrust) as Int
        guard count > 0 else { evaluateZeroCertificatesChain(); return }
        
        let certificates = (0..<count).map { index -> Data? in
            
            guard let certificate = SecTrustGetCertificateAtIndex(serverTrust, index) else { return nil }
            return SecCertificateCopyData(certificate) as Data
        }.compactMap { $0 }
        
        guard certificates.count > 0 else { evaluateZeroCertificatesChain(); return }
        let disposition = evaluate(host: host, certificates: certificates)
        completionHandler(disposition.mode, disposition.credential);
    }
}

extension APISessionPinner {
    
    fileprivate func evaluate(host: String, certificates: [Data]) -> AuthChallengeDisposition {
        
        if pinning.evaluate(host: host, certificates: certificates) {
            
            return AuthChallengeDisposition(mode: .performDefaultHandling, credential: nil)
            
        } else {
            
            return AuthChallengeDisposition(mode: .cancelAuthenticationChallenge, credential: nil)
        }
    }
}
