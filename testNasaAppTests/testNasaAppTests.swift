//
//  testNasaAppTests.swift
//  testNasaAppTests
//
//  Created by Sai Leung on 1/11/22.
//

import XCTest
@testable import testNasaApp

class testNasaAppTests: XCTestCase {
    
    var timeHelper: TimeHelper!

    override func setUpWithError() throws {
        timeHelper = TimeHelper()
    }

    override func tearDownWithError() throws {
        TimeZone.ReferenceType.resetSystemTimeZone()
    }

    func testTimeHelperDateToString() throws {
        let stringDate = "2022-01-12"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let testDate = formatter.date(from: stringDate) else {
            return
        }
        XCTAssertEqual(timeHelper.dateToString(date: testDate), stringDate)
    }
    
    func testTimeHelperStringToDateString() throws {
        let stringDate = "2022-01-12"
        let expectedResult = "Jan 12, 2022"
        XCTAssertEqual(timeHelper.stringToDateString(string: stringDate), expectedResult)
    }
    
    func testEastCoastLocalTimeIsNotAheadOfNasaPostingTime() throws {
        TimeZone.ReferenceType.default = TimeZone(abbreviation: "EST")!
        XCTAssertFalse(timeHelper.checkUserLocalTimeIsAheadOfNasaPostingTime())
    }

}
