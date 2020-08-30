//
//  Promise+Wrapper.swift
//  Networking
//
//  Created by Pawel Klapuch on 29/08/2020.
//  Copyright © 2020 Pawel Klapuch. All rights reserved.
//

import Foundation
import PromiseKit

extension Promise {
    
    static func delay(_ seconds: Double) -> Promise<Void> {
        
        return Promise<Void> { resolver in
            
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + seconds) {
             
                resolver.fulfill_()
            }
        }
    }

    static func instantVoid() -> Promise<Void> {
        
        let (promise, resolver) = Promise<Void>.pending()
        
        resolver.fulfill_()
        
        return promise
    }
    
    static func instantOptional<T>(_ value: T?) -> Promise<T?> {
        
        let (promise, resolver) = Promise<T?>.pending()
        
        resolver.fulfill(value)
        
        return promise
    }
    
    static func instantValue<T>(_ value: T) -> Promise<T> {
        
        let (promise, resolver) = Promise<T>.pending()
        
        resolver.fulfill(value)
        
        return promise
    }
    
    static func instantError<T>(_ error: Swift.Error) -> Promise<T> {
        
        let (promise, resolver) = Promise<T>.pending()
        
        resolver.reject(error)
        
        return promise
    }
    
    func executeDiscardingResult() {
        
        self.done { _ in
        }.catch { error in
        }
    }
}
