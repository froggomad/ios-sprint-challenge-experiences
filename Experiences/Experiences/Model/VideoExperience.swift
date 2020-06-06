//
//  VideoExperience.swift
//  Experiences
//
//  Created by Kenny on 6/4/20.
//  Copyright © 2020 Hazy Studios. All rights reserved.
//

import Foundation
import MapKit

class VideoExperience: NSObject, ExperienceProtocol {
    let id: UUID
    var date: Date
    var lastEdit: Date?
    var location: Location
    var title: String
    var body: String?
    var audioFile: URL?
    var videoFile: URL?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        lastEdit: Date? = nil,
        location: Location,
        title: String,
        body: String,
        audioFile: URL?,
        videoFile: URL?
        ) {

        self.id = id
        self.date = date
        self.lastEdit = lastEdit
        self.location = location
        self.title = title
        self.body = body
        self.audioFile = audioFile
        super.init()

    }
}
