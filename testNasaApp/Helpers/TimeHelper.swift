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
        let usDateformatter = DateFormatter()
        let dateFormatString = "dd"
        usDateformatter.timeZone = TimeZone(abbreviation: "EST")
        usDateformatter.setLocalizedDateFormatFromTemplate("yyyy-MM-dd")
        let usTimeString = usDateformatter.string(from: Date())
        let localDateFormatter = DateFormatter()
        
        guard let usTime = usDateformatter.date(from: usTimeString) else {
            return false
        }
        
        usDateformatter.dateFormat = dateFormatString
        localDateFormatter.dateFormat = dateFormatString
        let usDay = usDateformatter.string(from: usTime)
        let localTimeDay = localDateFormatter.string(from: Date())
        
        return (Date() > usTime) && (usDay != localTimeDay)
    }
}
