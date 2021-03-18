//
//  Power.swift
//  Draggy
//
//  Created by El D on 18.03.2021.
//

import IOKit.pwr_mgt

class SleepPreventor {

    init?(_ activityDescription: String? = nil) {

        let assertionProperties: Dictionary<String, String> = [
            kIOPMAssertionTypeKey: kIOPMAssertionTypePreventUserIdleSystemSleep
            , kIOPMAssertionNameKey : activityDescription ?? "basic description"
        ]

        var assertionID: IOPMAssertionID = 0
        guard IOPMAssertionCreateWithProperties(assertionProperties as CFDictionary, &assertionID) == kIOReturnSuccess else {
            return nil
        }
        self.assertionID = assertionID
    }
    
    deinit {
        let result = IOPMAssertionRelease(assertionID)
        assert(result == kIOReturnSuccess)
    }
    
    let assertionID: IOPMAssertionID
}
