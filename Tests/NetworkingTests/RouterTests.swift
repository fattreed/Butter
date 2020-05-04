import XCTest
@testable import Networking

final class RouterTests: XCTestCase {
    func testMakeRequestSuccess() {
        // given
        let session = MockURLSession_Success()
        let router = Router()
        let endpoint = MockEndpointSuccess()
        
        // when
        var data: Data?
        let expectation = XCTestExpectation(description: "successful completion")
        router.makeRequest(session: session, endpoint: endpoint) { result in
            if case .success(let resultData) = result {
                data = resultData
            }
            expectation.fulfill()
        }
        
        // then
        wait(for: [expectation], timeout: 0.5)
        XCTAssertNotNil(data)
    }
    
    func testMakeRequestFailure_status400() {
        // given
        let session = MockURLSession_Failure_400Code()
        let router = Router()
        let endpoint = MockEndpointSuccess()
        
        // when
        var requestError: Error?
        let expectation = XCTestExpectation(description: "completion with error")
        router.makeRequest(session: session, endpoint: endpoint) { result in
            if case .failure(let error) = result {
                requestError = error
            }
            expectation.fulfill()
        }
        
        // then
        wait(for: [expectation], timeout: 0.5)
        XCTAssertNotNil(requestError)
    }
    
    func testMakeRequestFailure_networkFailure() {
        let session = MockURLSession_Failure_NetworkError()
        let router = Router()
        let endpoint = MockEndpointSuccess()
        
        // when
        var requestError: Error?
        let expectation = XCTestExpectation(description: "completion with error")
        router.makeRequest(session: session, endpoint: endpoint) { result in
            if case .failure(let error) = result {
                requestError = error
            }
            expectation.fulfill()
        }
        
        // then
        wait(for: [expectation], timeout: 0.5)
        XCTAssertNotNil(requestError)
    }
    
    func testMakeRequestFailure_invalidEndpoint() {
        let session = MockURLSession_Success()
        let router = Router()
        let endpoint = MockEndpointBadHost()
        
        // when
        var requestError: Error?
        let expectation = XCTestExpectation(description: "completion with error")
        router.makeRequest(session: session, endpoint: endpoint) { result in
            if case .failure(let error) = result {
                requestError = error
            }
            expectation.fulfill()
        }
        
        // then
        wait(for: [expectation], timeout: 0.5)
        XCTAssertNotNil(requestError)
    }
    
    func testTaskCancellation() {
        // given
        let session = URLSession.shared
        let router = Router()
        let endpoint = MockEndpointSuccess()
        
        // when
        var errorCode: Int?
        let exp = XCTestExpectation(description: "finish with cancelation")
        router.makeRequest(session: session, endpoint: endpoint) { result in
            if case .failure(let error as NSError) = result {
                errorCode = error.code
            }
            exp.fulfill()
        }
        
        // then
        router.cancel()
        wait(for: [exp], timeout: 0.5)
        XCTAssertEqual(errorCode, -999)
    }
}

