//
//  TimeInterval+extension.swift
//  Mock POS
//
//  Created by Milan Djordjevic on 25/10/2022.
//

import Foundation

extension TimeInterval {
    var toMinSec: String {
        String(format:"%d m %02d s", minute, second)
    }
    var toMinSecMili: String {
        String(format:"%d m %02d s %03d", minute, second, millisecond)
    }
    
    var minute: Int {
        Int((self/60.0).truncatingRemainder(dividingBy: 60))
    }
    
    var second: Int {
        Int(self.truncatingRemainder(dividingBy: 60))
    }
    
    var millisecond: Int {
        Int((self*1000).truncatingRemainder(dividingBy: 1000) )
    }
}
