//
//  Created by Christopher Erdos on 5/1/20.
//

import Foundation

public typealias NetworkCompletion<T: Decodable> = (Result<T, Error>) -> ()

// MARK - Injection Point for URLSession
public protocol URLSessionDataTaskInterface {
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask
}

extension URLSession: URLSessionDataTaskInterface { }

// MARK - Main Router Interface
public class Router {
    private var task: URLSessionDataTask?
    private var session: URLSessionDataTaskInterface
	private (set) var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy?
    
    public init(session: URLSessionDataTaskInterface = URLSession.shared) {
        self.session = session
    }
	
	public func setDecodingStrategy(_ strat: JSONDecoder.DateDecodingStrategy) {
		self.dateDecodingStrategy = strat
	}
    
	public func makeRequest<T: Decodable>(responseType: T.Type,
										  endpoint: Endpoint,
                                          completion: @escaping NetworkCompletion<T>) {
        do {
            let requestBuilder = URLRequestBuilder()
            let request = try requestBuilder.request(from: endpoint)
            task = session.dataTask(with: request) { data, response, error in
                self.handleDataTaskResponse(data: data,
                                            response: response,
                                            error: error,
                                            completion: completion)
            }
            task?.resume()
        } catch {
            completion(.failure(error))
        }
    }
    
    private func handleDataTaskResponse<T: Decodable>(data: Data?,
                                                      response: URLResponse?,
                                                      error: Error?,
                                                      completion: NetworkCompletion<T>) {
        if let error = error {
            completion(.failure(error))
            return
        }
        
        if let response = response as? HTTPURLResponse,
            let error = NetworkResponseError(statusCode: response.statusCode) {
            completion(.failure(error))
		} else if let data = data {
			do {
				let decoder = JSONDecoder()
				if let strat = self.dateDecodingStrategy {
					decoder.dateDecodingStrategy = strat
				}
				let ret = try decoder.decode(T.self, from: data)
				completion(.success(ret))
			} catch {
				completion(.failure(error))
			}
		} else {
			let error = ButterError.unknown(debugInfo: "No error, no data.")
			completion(.failure(error))
        }
    }
    
    public func cancel() {
        task?.cancel()
    }
}
