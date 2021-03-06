//
//  VideoExperience.swift
//  Experiences
//
//  Created by Kenny on 6/4/20.
//  Copyright © 2020 Hazy Studios. All rights reserved.
//

import Foundation

class VideoExperience: NSObject, ExperienceProtocol {
    let id: UUID
    var date: Date
    var lastEdit: Date?
    var location: Location
    var subject: String
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
        self.subject = title
        if body == "Tell your story here (optional)" {
           self.body = nil //redundant, but more clear
        } else {
           self.body = body
        }
        self.audioFile = audioFile
        super.init()

    }
}
