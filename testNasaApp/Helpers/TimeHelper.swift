//
//  TimeHelper.swift
//  testNasaApp
//
//  Created by Sai Leung on 1/12/22.
//

import Foundation

class TimeHelper {
    
    func dateToString(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: date)
    }
    
    func stringToDateString(string: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, y"
        
        let dateFormatter2 = DateFormatter()
        dateFormatter2.dateFormat = "yyyy-MM-dd"
        if let apodPickedDate = dateFormatter2.date(from: string) {
            return formatter.string(from: apodPickedDate)
        } else {
            return "Unknown Date"
        }
        
    }
    
    func checkUserLocalTimeIsAheadOfNasaPostingTime() -> Bool {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "EST")
        formatter.setLocalizedDateFormatFromTemplate("yyyy-MM-dd")
        let usTimeString = formatter.string(from: Date())
        
        guard let usTime = formatter.date(from: usTimeString) else {
            return false
        }
        
        formatter.dateFormat = "dd"
        let usDay = formatter.string(from: usTime)
        let localTimeDay = formatter.string(from: Date())
        
        return (Date() > usTime) && (usDay != localTimeDay)
    }
}
