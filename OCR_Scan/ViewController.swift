//
//  ViewController.swift
//  OCR_Scan
//
//  Created by Luiza Fattori on 28/02/22.
//

import UIKit
import Vision
import VisionKit
import AVFoundation

class ViewController: UIViewController{

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var textView: UITextView!

    @IBAction func buttonVoice(_ sender: Any) {
        if textView.text != ""{
            let reprodutor = AVSpeechUtterance(string: textView.text)
            reprodutor.voice = AVSpeechSynthesisVoice(language: "pt-BR")
            reprodutor.rate = 0.5
            let saida = AVSpeechSynthesizer()
            saida.speak(reprodutor)
        }else{
            let reprodutor = AVSpeechUtterance(string: "Nenhum texto escaneado")
            reprodutor.voice = AVSpeechSynthesisVoice(language: "pt-BR")
            reprodutor.rate = 0.5
            let saida = AVSpeechSynthesizer()
            saida.speak(reprodutor)
        }
    }

    var requests = [VNRequest]()
    var request = VNRecognizeTextRequest(completionHandler: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        stopAnimating()
    }

    private func startAnimating(){
        self.activityIndicator.startAnimating()
    }

    private func stopAnimating(){
        self.activityIndicator.stopAnimating()
    }

    @IBAction func touchUpInsideCameraButton(_ sender: Any) {
        //setupGallery()
        setupCamera()
    }

    //metodo de foto pela galeria
    private func setupGallery(){
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            let imagePhotoLibraryPicker = UIImagePickerController()
            imagePhotoLibraryPicker.delegate = self
            imagePhotoLibraryPicker.allowsEditing = true
            imagePhotoLibraryPicker.sourceType = .photoLibrary
            self.present(imagePhotoLibraryPicker, animated: true, completion: nil)
        }
    }

    //metodo de foto pela camera
    private func setupCamera(){
        let documentCameraController = VNDocumentCameraViewController()
        documentCameraController.delegate = self
        present(documentCameraController, animated: true, completion: nil)
    }

    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true, completion: nil)
    }

    //Chamado caso o usuario nao permita acesso a camera, trabalhar em uma mensagem ao usuário
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        print(error)
        controller.dismiss(animated: true, completion: nil)
    }

    //reconhecimento do texto da imagem de parametro
    private func setupVisionTextRecognizeImage(image: UIImage?){
        var textString =  ""

        request = VNRecognizeTextRequest(completionHandler:{ (request,error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                fatalError("Recieved Invalid Observation")
            }

            for observation in observations{
                guard let topCandidate = observation.topCandidates(1).first else{
                    print("No candidate")
                    continue
                }
                textString += topCandidate.string
                textString += "\n"
                DispatchQueue.main.async{
                    self.stopAnimating()
                    self.textView.text = textString
                }
            }
        })

        request.customWords = ["cust0m"]
        request.minimumTextHeight = 0.03125
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["pt_BR"]
        request.usesLanguageCorrection = true

        let requests = [request]


        DispatchQueue.global(qos: .userInitiated).async{
            guard let img = image?.cgImage else {
                fatalError("Missing image to scan")
            }
            let handle = VNImageRequestHandler(cgImage: img,options: [:])
            try? handle.perform(requests)
        }
    }
    //Processamento da image capturada pela camera
    private func processImage(image: UIImage) {
        guard let cgImage = image.cgImage else {
            print("Failed to get cgimage from input image")
            return
        }
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }

    }
}
//Utilizar foto da galeria
extension ViewController:UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        startAnimating()
        self.textView.text=""

        let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        self.imageView.image = image

        setupVisionTextRecognizeImage(image: image)
    }
}
//Utilizar foto capturada pela camera
extension ViewController:VNDocumentCameraViewControllerDelegate{
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        startAnimating()
        self.textView.text = ""
        for pageNumber in 0 ..< scan.pageCount {
            let image = scan.imageOfPage(at: pageNumber)
            self.processImage(image: image)
            self.imageView.image = image
            self.setupVisionTextRecognizeImage(image: image)
        }
        controller.dismiss(animated: true)
    }
}
