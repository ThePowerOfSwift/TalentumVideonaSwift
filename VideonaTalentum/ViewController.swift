// ViewController.swift
//
// The MIT License (MIT)
//
// Copyright (c) 2015 ActionButton
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit
import GLKit
import AVFoundation
import CoreMedia


class ViewController: UIViewController {
    
    @IBOutlet weak var Camera: UIButton!
    @IBOutlet weak var recordPlay: UIButton!
    
    /*enum Enum {
        case EnumFace
        case EnumMouth
        case EnumEyes
        case EnumHat
    }*/
    
    
    var isFace = false
    var isMouth = false
    var isEyes = false
    var isHat = false
    var isMoustache = false

    
    let eaglContext = EAGLContext(API: .OpenGLES2)
    let captureSession = AVCaptureSession()
    
    let imageView = GLKView()
    
    
    //var enumNull = Enum.EnumFace
    
    let comicEffect = CIFilter(name: "CIComicEffect")!
    let eyeballImage = CIImage(image: UIImage(named: "eyeball.png")!)!
    let mouthballImage = CIImage(image: UIImage(named: "boca.png")!)!
    let hatBallImage = CIImage(image: UIImage(named:"sombrero.png")!)!
    
    
    var cameraImage: CIImage?
    
    var usingCamera = false
    
    lazy var ciContext: CIContext = {
        [unowned self] in
        
        return  CIContext(EAGLContext: self.eaglContext)
        }()
    
    lazy var detector: CIDetector = {
        [unowned self] in
        
        
        CIDetector(ofType: CIDetectorTypeFace,
                   context: self.ciContext,
                   options: [
                    CIDetectorAccuracy: CIDetectorAccuracyHigh,
                    CIDetectorTracking: true])
        }()
    
    
    
    var actionButton: ActionButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initialiseCaptureSession()
        
        view.addSubview(imageView)
        imageView.context = eaglContext
        imageView.delegate = self
        
        
        let eyesImage = UIImage(named: "eyes_icon.png")!
        let moustacheImage = UIImage(named: "moustache_icon.png")!
        let hatImage = UIImage(named: "hat_icon.png")!
        let mouthImage = UIImage(named: "mouth_icon.png")!
        
        
        let eyes = ActionButtonItem(title: "Eyes", image: eyesImage)
        eyes.action = { item in print("Ojitos...")
            self.isEyes = true }
        
        let moustache = ActionButtonItem(title: "Moustache", image: moustacheImage)
        moustache.action = { item in print("Bigotito...")
            self.isMoustache = true}
        
        let hat = ActionButtonItem(title: "Hat", image: hatImage)
        hat.action = { item in print("Sombrerito...")
            self.isHat = true }
        
        let mouth = ActionButtonItem(title:"Mouth", image:mouthImage)
        mouth.action = { item in print("Boca...")
            self.isMouth = true }
        
        actionButton = ActionButton(attachedToView: self.view, items: [hat, eyes, moustache, mouth])
        actionButton.action = { button in button.toggleMenu() }
        actionButton.setTitle("+", forState: .Normal)
        
        actionButton.backgroundColor = UIColor(red: 167.0/255.0, green: 169.0/255.0, blue: 173.0/255.0, alpha:0.8)
        
        self.view.bringSubviewToFront(Camera)
        self.view.bringSubviewToFront(recordPlay)
        
    }
    
    
    @IBAction func Camera(sender: AnyObject) {
        changeCamera()
    }
    
    
    func initialiseCaptureSession() {
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        
        guard let frontCamera = (AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) as! [AVCaptureDevice])
            
            .filter({ $0.position == .Front })
            .first else {
                fatalError("Unable to access front camera")
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: frontCamera)
            
            captureSession.addInput(input)
        }
        catch {
            fatalError("Unable to access front camera")
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        
        videoOutput.setSampleBufferDelegate(self, queue: dispatch_queue_create("sample buffer delegate", DISPATCH_QUEUE_SERIAL))
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        captureSession.startRunning()
    }
    
    
    
    static func deviceWithMediaType(position: AVCaptureDevicePosition) -> AVCaptureDevice {
        
        guard let device = (AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) as! [AVCaptureDevice])
            .filter({ $0.position == position })
            .first else {
                fatalError("Unable to access front camera")
        }
        
        return device
    }
    
    
    func changeCamera() {
        
        let deviceInput = self.captureSession.inputs.first as? AVCaptureDeviceInput
        let device = deviceInput?.device
        if let device = device {
            
            let position = device.position
            var videoDevice : AVCaptureDevice?
            
            switch position {
            case .Front:
                videoDevice = ViewController.deviceWithMediaType(.Back)
                
                break;
            case .Back:
                videoDevice = ViewController.deviceWithMediaType(.Front)
                break;
                
            case .Unspecified :
                break;
            }
            
            do {
                if let videoDevice = videoDevice {
                    
                    self.captureSession.removeInput(deviceInput)
                    
                    let input = try AVCaptureDeviceInput(device: videoDevice)
                    captureSession.addInput(input)
                }
            }
            catch {
                fatalError("Unable to access front camera")
            }
        }
        
    }
    
    // Detects either the left or right eye from `cameraImage` and, if detected, composites
    // `eyeballImage` over `backgroundImage`. If no eye is detected, simply returns the
    // `backgroundImage`.
    
    
    func detectFaces(cameraImage:CIImage)->[CIFeature]{
    
        return detector.featuresInImage(cameraImage)
    
    }
    
   /* func totalImage(cameraImage : CIImage, backgroundImage : CIImage, features : [CIFeature])->CIImage{
        
        let compositingFilter = CIFilter(name: "CISourceAtopCompositing")!
        let transformFilter = CIFilter(name: "CIAffineTransform")!
    
        if(isEyes){
        
            let halfEyeWidth = eyeballImage.extent.width / 2
            let halfEyeHeight = eyeballImage.extent.height / 2
            for feature in features{
                let newFeature = feature as? CIFaceFeature
                let rightEyePosition = CGAffineTransformMakeTranslation(newFeature!.rightEyePosition.x - halfEyeWidth, newFeature!.rightEyePosition.y - halfEyeHeight)
                let leftEyePosition = CGAffineTransformMakeTranslation(newFeature!.leftEyePosition.x - halfEyeWidth, newFeature!.leftEyePosition.y - halfEyeHeight)
                
                let eyesPosition = CGAffineTransformConcat(rightEyePosition, leftEyePosition)
                
                
                transformFilter.setValue(eyeballImage, forKey: "inputImage")
                transformFilter.setValue(NSValue(CGAffineTransform: eyesPosition), forKey: "inputTransform")
                
                let transformResult = transformFilter.valueForKey("outputImage") as! CIImage
                
                compositingFilter.setValue(backgroundImage, forKey: kCIInputBackgroundImageKey)
                compositingFilter.setValue(transformResult, forKey: kCIInputImageKey)
                
                return  compositingFilter.valueForKey("outputImage") as! CIImage
                
            }
        } else {
                return backgroundImage
            }
        
                
                return backgroundImage
            }
            
        }*/
        
        
        

        


    

    func eyeImage(cameraImage: CIImage, backgroundImage: CIImage, leftEye: Bool) -> CIImage {
        
       /* let compositingFilter = CIFilter(name: "CISourceAtopCompositing")!
        let transformFilter = CIFilter(name: "CIAffineTransform")!
        
        let halfEyeWidth =  eyeballImage.extent.width / 2
        let halfEyeHeight = eyeballImage.extent.height / 2
        
        if let features = detector.featuresInImage(cameraImage).first as? CIFaceFeature
            where leftEye ? features.hasLeftEyePosition : features.hasRightEyePosition {
            
            let eyePosition = CGAffineTransformMakeTranslation(
                leftEye ? features.leftEyePosition.x - halfEyeWidth : features.rightEyePosition.x - halfEyeWidth,
                leftEye ? features.leftEyePosition.y - halfEyeHeight : features.rightEyePosition.y - halfEyeHeight)
            
            
            let eyeDimensions = CGAffineTransformScale(eyePosition, 1, 1)
            let myCGFloat = CGFloat(features.faceAngle)
            let myPIFloat = CGFloat(2*M_PI)
            let angleRadians = myCGFloat*myPIFloat / 360
            let eyeAngle = CGAffineTransformRotate(eyeDimensions, -angleRadians)
            
            
            transformFilter.setValue(eyeballImage, forKey: "inputImage")
            transformFilter.setValue(NSValue(CGAffineTransform: eyeAngle), forKey: "inputTransform")
            
            let transformResult = transformFilter.valueForKey("outputImage") as! CIImage
            
            compositingFilter.setValue(backgroundImage, forKey: kCIInputBackgroundImageKey)
            compositingFilter.setValue(transformResult, forKey: kCIInputImageKey)
            
            return  compositingFilter.valueForKey("outputImage") as! CIImage
            
        }*/
        //else {
            return backgroundImage
        //}
    }
    
    func noneImage(cameraImage: CIImage, backgroundImage: CIImage, features : [CIFeature])->CIImage {
        
        var image1 = CIImage()
        
        let compositingFilter = CIFilter(name: "CISourceAtopCompositing")!
        let compositingFilter1 = CIFilter(name: "CISourceAtopCompositing")!
        let transformFilter = CIFilter(name: "CIAffineTransform")!
        let transformFilter1 = CIFilter(name: "CIAffineTransform")!
        
        
        if(isEyes){
            
            let halfEyeWidth = eyeballImage.extent.width / 2
            let halfEyeHeight = eyeballImage.extent.height / 2
            for feature in features{
                let newFeature = feature as? CIFaceFeature
                
                let rightEyePosition = CGAffineTransformMakeTranslation(newFeature!.rightEyePosition.x - halfEyeWidth, newFeature!.rightEyePosition.y - halfEyeHeight)
                
                
                
                transformFilter.setValue(eyeballImage, forKey: "inputImage")
                transformFilter.setValue(NSValue(CGAffineTransform: rightEyePosition), forKey: "inputTransform")
                
                let leftEyePosition = CGAffineTransformMakeTranslation(newFeature!.leftEyePosition.x - halfEyeWidth, newFeature!.leftEyePosition.y - halfEyeHeight)
                
            
                transformFilter1.setValue(eyeballImage, forKey: "inputImage")
                transformFilter1.setValue(NSValue(CGAffineTransform: leftEyePosition), forKey: "inputTransform")
                
                let transformResult = transformFilter.valueForKey("outputImage") as! CIImage
                let transformResult1 = transformFilter1.valueForKey("outputImage") as! CIImage

                
                compositingFilter.setValue(backgroundImage, forKey: kCIInputBackgroundImageKey)
                compositingFilter.setValue(transformResult, forKey: kCIInputImageKey)
                
                image1 = compositingFilter.valueForKey("outputImage") as! CIImage
                
                
                compositingFilter1.setValue(image1, forKey: kCIInputBackgroundImageKey)
                compositingFilter.setValue(transformResult1, forKey: kCIInputImageKey)
                
                 image1 = compositingFilter1.valueForKey("outputImage") as! CIImage
                
 
                
                
            }
        }else{
        
        
            image1 = backgroundImage
        }

        return image1

    
    }
    /*
    
    func hatImage(cameraImage: CIImage, backgroundImage: CIImage, hat: Bool) -> CIImage {
        
        let compositingFilter = CIFilter(name: "CISourceAtopCompositing")!
        let transformFilter = CIFilter(name: "CIAffineTransform")!
        
        let halfMouthWidth = hatBallImage.extent.width
        //let halfMouthHeight = hatBallImage.extent.height
        
        if let features = detector.featuresInImage(cameraImage).first as? CIFaceFeature {
            if (features.hasFaceAngle) {
                
                let mouthPosition = CGAffineTransformMakeTranslation(
                    features.bounds.width - halfMouthWidth,
                    features.bounds.maxY)
                
                let hatDimensions = CGAffineTransformScale(mouthPosition, 2, 2)
                let myCGFloat = CGFloat(features.faceAngle)
                let myPIFloat = CGFloat(2*M_PI)
                let angleRadians = myCGFloat*myPIFloat / 360
                let hatAngle = CGAffineTransformRotate(hatDimensions, -angleRadians)
                
                
                transformFilter.setValue(hatBallImage, forKey: "inputImage")
                transformFilter.setValue(NSValue(CGAffineTransform: hatAngle), forKey: "inputTransform")
                let transformResult = transformFilter.valueForKey("outputImage") as! CIImage
                
                compositingFilter.setValue(backgroundImage, forKey: kCIInputBackgroundImageKey)
                compositingFilter.setValue(transformResult, forKey: kCIInputImageKey)
                
                return  compositingFilter.valueForKey("outputImage") as! CIImage
                
            } else {
                return backgroundImage
            }
        }
        return backgroundImage
    }
    
    func mouthImage(cameraImage: CIImage, backgroundImage: CIImage, mouth: Bool) -> CIImage {
        
        let compositingFilter = CIFilter(name: "CISourceAtopCompositing")!
        let transformFilter = CIFilter(name: "CIAffineTransform")!
        
        let halfMouthWidth = mouthballImage.extent.width / 2
        let halfMouthHeight = mouthballImage.extent.height / 2
        
        if let features = detector.featuresInImage(cameraImage).first as? CIFaceFeature {
            if (features.hasMouthPosition) {
                
                let mouthPosition = CGAffineTransformMakeTranslation(
                    features.hasMouthPosition ? features.mouthPosition.x - halfMouthWidth : features.mouthPosition.x - halfMouthWidth,
                    features.hasMouthPosition ? features.mouthPosition.y - halfMouthHeight : features.mouthPosition.y - halfMouthHeight)
                
                let mouthDimensions = CGAffineTransformScale(mouthPosition, 1, 1)
                let myCGFloat = CGFloat(features.faceAngle)
                let myPIFloat = CGFloat(2*M_PI)
                let angleRadians = myCGFloat*myPIFloat / 360
                let mouthAngle = CGAffineTransformRotate(mouthDimensions, -angleRadians)
                
                transformFilter.setValue(mouthballImage, forKey: "inputImage")
                transformFilter.setValue(NSValue(CGAffineTransform: mouthAngle), forKey: "inputTransform")
                let transformResult = transformFilter.valueForKey("outputImage") as! CIImage
                
                compositingFilter.setValue(backgroundImage, forKey: kCIInputBackgroundImageKey)
                compositingFilter.setValue(transformResult, forKey: kCIInputImageKey)
                
                return  compositingFilter.valueForKey("outputImage") as! CIImage
                
            } else {
                
                return backgroundImage
            }
        }
        
        return backgroundImage
    }
 */
    
    override func viewDidLayoutSubviews() {
        imageView.frame = view.bounds
    }
}


extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        

        connection.videoMirrored = true
        
        connection.videoOrientation = AVCaptureVideoOrientation(rawValue: UIApplication.sharedApplication().statusBarOrientation.rawValue)!
        
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        cameraImage = CIImage(CVPixelBuffer: pixelBuffer!)
        
        dispatch_async(dispatch_get_main_queue()) {
            self.imageView.setNeedsDisplay()
        }
    }
}

extension ViewController: GLKViewDelegate {
    
    
    
    func glkView(view: GLKView, drawInRect rect: CGRect) {
        
        guard let cameraImage = cameraImage else {
            return
        }
        
        let features : [CIFeature] = detectFaces(cameraImage)
        
        print("%d",features.count)
        print(isEyes)
        
        let noImage = noneImage(cameraImage, backgroundImage: cameraImage, features: features)
        
        ciContext.drawImage(noImage,
                            inRect: CGRect(x: 0, y: 0,
                                width: imageView.drawableWidth,
                                height: imageView.drawableHeight),
                            fromRect: noImage.extent)
        
        /*
      
        switch enumNull {
            
        case Enum.EnumFace:
            
            let noImage = noneImage(cameraImage, backgroundImage: cameraImage, mouth: true)
            
            ciContext.drawImage(noImage,
                                inRect: CGRect(x: 0, y: 0,
                                    width: imageView.drawableWidth,
                                    height: imageView.drawableHeight),
                                fromRect: noImage.extent)
        case Enum.EnumEyes:
            
            let leftEyeImage = eyeImage(cameraImage, backgroundImage: cameraImage, leftEye: true)
            let rightEyeImage = eyeImage(cameraImage, backgroundImage: leftEyeImage, leftEye: false)
            
            ciContext.drawImage(rightEyeImage,
                                inRect: CGRect(x: 0, y: 0,
                                    width: imageView.drawableWidth,
                                    height: imageView.drawableHeight),
                                fromRect: rightEyeImage.extent)
            
        case Enum.EnumMouth:
            
            
            let mImage = mouthImage(cameraImage, backgroundImage: cameraImage, mouth: true)
            
            ciContext.drawImage(mImage,
                                inRect: CGRect(x: 0, y: 0,
                                    width: imageView.drawableWidth,
                                    height: imageView.drawableHeight),
                                fromRect: mImage.extent)
            
        case Enum.EnumHat:
            
            let hattImage = hatImage(cameraImage, backgroundImage: cameraImage, hat: true)
            
            ciContext.drawImage(hattImage,
                                inRect: CGRect(x: 0, y: 0,
                                    width: imageView.drawableWidth,
                                    height: imageView.drawableHeight),
                                fromRect: hattImage.extent)
        }
 */
    }
}




