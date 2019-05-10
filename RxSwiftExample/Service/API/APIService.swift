//
//  APIService.swift
//  RxSwiftExample
//
//  Created by pham.van.ducd on 5/7/19.
//  Copyright © 2019 pham.van.ducd. All rights reserved.
//

import Foundation
import RxSwift
import Alamofire
import ObjectMapper

struct APIService {
    
    static let share = APIService()
    
    private var alamofireManager = Alamofire.SessionManager.default
    
    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 30
        alamofireManager = Alamofire.SessionManager(configuration: configuration)
       // alamofireManager.adapter = CustomRequestAdapter()
    }
    
    func request<T: Mappable>(input: BaseRequest) ->  Observable<T> {
        return Observable.create { observer in
            self.alamofireManager.request(input.url, method: input.requestType,
                                          parameters: input.body, encoding: input.encoding)
                .validate(statusCode: 200..<500)
                .responseJSON { response in
                    switch response.result {
                    case .success(let value):
                        if let statusCode = response.response?.statusCode {
                            if statusCode == 200 {
                                if let object = Mapper<T>().map(JSONObject: value) {
                                    observer.onNext(object)
                                }
                            } else {
                                if let object = Mapper<ErrorResponse>().map(JSONObject: value) {
                                    observer.onError(BaseError.apiFailure(error: object))
                                } else {
                                    observer.onError(BaseError.httpError(httpCode: statusCode))
                                }
                            }
                        } else {
                            observer.on(.error(BaseError.unexpectedError))
                        }
                        observer.onCompleted()
                        
                    case .failure:
                        observer.onError(BaseError.networkError)
                        observer.onCompleted()
                    }
            }
            return Disposables.create()
        }
    }
    
}
