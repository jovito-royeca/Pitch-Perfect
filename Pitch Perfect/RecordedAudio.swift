//
//  RecordedAudio.swift
//  Pitch Perfect
//
//  Created by Jovit Royeca on 1/5/16.
//  Copyright © 2016 Jovito Royeca. All rights reserved.
//

import Foundation

class RecordedAudio: NSObject {
    var filePathUrl: NSURL!
    var title: String!
    
    init(filePathUrl:NSURL, title:String) {
        self.filePathUrl = filePathUrl
        self.title = title
    }
}
