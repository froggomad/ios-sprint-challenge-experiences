//
//  PhotoExperienceViewController.swift
//  Experiences
//
//  Created by Kenny on 6/5/20.
//  Copyright © 2020 Hazy Studios. All rights reserved.
//

import UIKit
import AVFoundation
import MapKit

class PhotoExperienceViewController: UIViewController {
    // MARK: - Properties -
    var experience: PhotoExperience?

    private var filterSegueID = "AddFilterVC"

    var locationManager: CLLocationManager!
    var currentLocation: Location?

    var recordedURL: URL?


    let experienceController = ExperienceController.shared
    lazy var photoController = PhotoController(delegate: self)
    lazy var audioController = AudioPlayer(delegate: self)
    lazy var recordingController = AudioRecorder(delegate: self)

    weak var delegate: PhotoUIDelegate?

    let textViewPlaceholderText = "Tell your story here (optional)"
    //Photos
    @IBOutlet weak var photoFilterImageView: UIImageView!
    @IBOutlet weak var selectPhotoButton: UIButton!

    @IBAction func choosePhoto(_ sender: UIButton) {
        photoController.requestPermissionAndPresentImagePicker()
    }
    //Text
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var storyTextView: UITextView!
    //Audio
    @IBOutlet weak var timeElapsedLabel: UILabel!
    //Recording
    @IBOutlet weak var recordButton: UIButton!

    @IBAction func toggleRecording() {
        if !playButton.isSelected {
            playButton.isUserInteractionEnabled = false
            recordingController.toggleRecording()
        }
    }
    //Playback
    @IBOutlet weak var playButton: UIButton!

    @IBAction func togglePlaying() {
        if !recordButton.isSelected {
            recordButton.isUserInteractionEnabled = false
            audioController.togglePlaying()
        }
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        titleTextField.delegate = self
        storyTextView.delegate = self
        getLocation()
        updateViews()
        styleFields()
    }

    private func getLocation() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        try? recordingController.prepareAudioSession()
        updateViews()
        if recordedURL != nil {
            audioController.togglePlaying()
        }
    }

    private func updateViews() {
        updateRecordingUI()
        updatePlayerUI()

        guard let experience = experience else { return }

        titleTextField.text = experience.title
        storyTextView.text = experience.body
        recordedURL = experience.audioFile

        guard let data = experience.photo else { return }
        selectPhotoButton.setTitle("", for: .normal)
        selectPhotoButton.backgroundColor = .clear
        photoFilterImageView.image = UIImage(data: data)
    }

    private func styleFields() {
        storyTextView.layer.borderWidth = 1
        storyTextView.layer.borderColor = UIColor.black.cgColor
        titleTextField.layer.borderWidth = 1
        titleTextField.layer.borderColor = UIColor.black.cgColor
    }


    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == filterSegueID {
            guard let destination = segue.destination as? FilterImageViewController else { return }
            destination.image = photoFilterImageView.image
            destination.delegate = self
        }
    }

    @IBAction func saveButton() {
        var fields: [String] = []
        if photoFilterImageView.image == nil {
            fields.append("An image")
        }
        if titleTextField.text?.isEmpty ?? true {
            fields.append("A title")
        }
        let message = fields.joined(separator: ",\n")
        if !fields.isEmpty {
            Alert.show(
                title: "Your experience is missing:",
                message: message,
                vc: self
            )
        }
        guard let title = titleTextField.text,
            !title.isEmpty,
            let location = currentLocation,
            let image = photoFilterImageView.image
        else { return }

        var text = storyTextView.text
        if text == textViewPlaceholderText {
            text = nil
        }

        if let experience = experience {
            experience.subject = title
            experience.body = text
            experience.photo = image.jpegData(compressionQuality: 60.0)
            experience.audioFile = recordedURL
        } else {
            let experience = PhotoExperience(
                location: location,
                subject: title,
                body: text,
                audioFile: recordedURL,
                photo: image.jpegData(compressionQuality: 60.0)
            )
            experienceController.append(experience)
        }

        navigationController?.popViewController(animated: true)
    }

    func presentFilterViewController() {
        performSegue(withIdentifier: filterSegueID, sender: nil)
    }

}

extension PhotoExperienceViewController: PhotoUIDelegate {


}

extension PhotoExperienceViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func presentImagePickerController() {

        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            Alert.show(
                title: "Error",
                message: "The photo library is unavailable",
                vc: self
            )
            return
        }

        DispatchQueue.main.async {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            self.present(imagePicker, animated: true)
        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        selectPhotoButton.setTitle("", for: [])
        UIView.animate(withDuration: 2) {
            self.selectPhotoButton.backgroundColor = .clear
        }


        picker.dismiss(animated: true, completion: nil)

        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            print("unkown error getting image")
            return
        }
        self.photoFilterImageView.image = image
        Alert.withYesNoPrompt(
            title: "Filter This Photo?",
            message: "Would you like to add a filter?",
            vc: self
        ) { (filterChosen) in
            if filterChosen {
                self.presentFilterViewController()
            } else {

            }
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Audio -
extension PhotoExperienceViewController: AudioPlayerUIDelegate {
    func updatePlayerUI() {
        playButton.isSelected = audioController.isPlaying
        displayElapsedTime()
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        displayElapsedTime()
        recordButton.isUserInteractionEnabled = true
    }
}

extension PhotoExperienceViewController: AudioRecorderDelegate {


    func updateRecordingUI() {
        recordButton.isSelected = recordingController.isRecording
        displayElapsedTime()
    }

    private func displayElapsedTime() {
        if recordButton.isSelected {
            let elapsedTime = recordingController.recorder?.currentTime ?? 0
            timeElapsedLabel.text = recordingController.timeIntervalFormatter.string(from: elapsedTime)
        } else if playButton.isSelected {
            let elapsedTime = audioController.player?.currentTime ?? 0
            timeElapsedLabel.text = recordingController.timeIntervalFormatter.string(from: elapsedTime)
        }
    }

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        recordedURL = recorder.url
        print("Recorded to: \(recorder.url)")
        playButton.isUserInteractionEnabled = true
        audioController.togglePlaying()
    }
}

extension PhotoExperienceViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last{
            self.currentLocation = Location(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        }
    }
}
