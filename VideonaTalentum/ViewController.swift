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

//Somos unos muñones con GIT


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

    var cameraFront = true
    var cameraBack = false
    
    let eaglContext = EAGLContext(API: .OpenGLES2)
    let captureSession = AVCaptureSession()
    
    let imageView = GLKView()
    
    
    //var enumNull = Enum.EnumFace
    
    let comicEffect = CIFilter(name: "CIComicEffect")!
    let eyeballImage = CIImage(image: UIImage(named: "eyeball.png")!)!
    let mouthballImage = CIImage(image: UIImage(named: "boca.png")!)!
    let hatBallImage = CIImage(image: UIImage(named:"sombrero.png")!)!
    let moustacheImage2 = CIImage(image: UIImage(named:"bigotes.png")!)!
    
    var previewLayer : AVCaptureVideoPreviewLayer?
    
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
        
        view.addSubview(imageView)
        imageView.context = eaglContext
        imageView.delegate = self
 
        
        initialiseCaptureSession()
        
        
        
        let eyesImage = UIImage(named: "eyes_icon.png")!
        let moustacheImage = UIImage(named: "moustache_icon.png")!
        let hatImage = UIImage(named: "hat_icon.png")!
        let mouthImage = UIImage(named: "mouth_icon.png")!
        
        
        let eyes = ActionButtonItem(title: "Eyes", image: eyesImage)
        eyes.action = { item in print("Ojitos...")
        
            if(self.isEyes){
                self.isEyes=false
            }else{
                self.isEyes=true
            }
            
            
        }
        
        let moustache = ActionButtonItem(title: "Moustache", image: moustacheImage)
        moustache.action = { item in print("Bigotito...")
            if(self.isMoustache){
                self.isMoustache=false
            }else{
                self.isMoustache=true
            }
        }
        
        let hat = ActionButtonItem(title: "Hat", image: hatImage)
        hat.action = { item in print("Sombrerito...")
            if(self.isHat){
                self.isHat=false
            }else{
                self.isHat=true
            }
        }
        
        let mouth = ActionButtonItem(title:"Mouth", image:mouthImage)
        mouth.action = { item in print("Boca...")
            if(self.isMouth){
                self.isMouth=false
            }else{
                self.isMouth=true
            }
        }
        
        actionButton = ActionButton(attachedToView: self.view, items: [hat, eyes, moustache, mouth])
        actionButton.action = { button in button.toggleMenu() }
        actionButton.setTitle("+", forState: .Normal)
        
        actionButton.backgroundColor = UIColor(red: 167.0/255.0, green: 169.0/255.0, blue: 173.0/255.0, alpha:0.8)
        
        
        
        //self.view.bringSubviewToFront(imageView)
        self.view.bringSubviewToFront(Camera)
        self.view.bringSubviewToFront(recordPlay)
        
    }
    
    
    @IBAction func Camera(sender: AnyObject) {
        changeCamera()
    }
    
    
    func initialiseCaptureSession() {
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        
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
        
        
    /*
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.view.layer.addSublayer(previewLayer!)
        previewLayer?.frame=self.view.layer.frame*/
 
        
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
                cameraBack=true
                cameraFront=false
                
                break;
            case .Back:
                videoDevice = ViewController.deviceWithMediaType(.Front)
                cameraFront=true
                cameraBack=false
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
    
    
    func noneImage(cameraImage: CIImage, backgroundImage: CIImage, features : [CIFeature])->CIImage {
        
        var finalImage = backgroundImage
        
        let compositingFilter = CIFilter(name: "CISourceAtopCompositing")!
        let transformFilter = CIFilter(name: "CIAffineTransform")!
        let compositingFilter1 = CIFilter(name: "CISourceAtopCompositing")!
        let transformFilter1 = CIFilter(name: "CIAffineTransform")!
        
        if(features.count == 0)
        {
            return finalImage
        }
        
        for feature in features{
            let newFeature = feature as? CIFaceFeature
        
            if(isEyes){
            
                let halfEyeWidth = eyeballImage.extent.width / 2
                let halfEyeHeight = eyeballImage.extent.height / 2
            
                let scale = newFeature!.bounds.width/(eyeballImage.extent.width*4)
                let scale2 = newFeature!.bounds.height/(eyeballImage.extent.height*4)
                
                
                let rightEyePosition = CGAffineTransformMakeTranslation(newFeature!.rightEyePosition.x - halfEyeWidth, newFeature!.rightEyePosition.y - halfEyeHeight)
                
                let leftEyePosition = CGAffineTransformMakeTranslation(newFeature!.leftEyePosition.x - halfEyeWidth, newFeature!.leftEyePosition.y - halfEyeHeight)
                
                
                let eyerightScaledPosition = CGAffineTransformScale(rightEyePosition, scale,scale2)
                
                let eyeleftScaledPosition = CGAffineTransformScale(leftEyePosition, scale,scale2)
               
                
                transformFilter.setValue(eyeballImage, forKey: "inputImage")
                transformFilter.setValue(NSValue(CGAffineTransform: eyerightScaledPosition), forKey: "inputTransform")
                
                
                transformFilter1.setValue(eyeballImage, forKey: "inputImage")
                transformFilter1.setValue(NSValue(CGAffineTransform: eyeleftScaledPosition), forKey: "inputTransform")
                
                let transformResult = transformFilter.valueForKey("outputImage") as! CIImage
            
                let transformResult1 = transformFilter1.valueForKey("outputImage") as! CIImage
                
                
                compositingFilter.setValue(finalImage, forKey: kCIInputBackgroundImageKey)
                compositingFilter.setValue(transformResult, forKey: kCIInputImageKey)
                
                finalImage = compositingFilter.valueForKey("outputImage") as! CIImage
                

                compositingFilter1.setValue(finalImage, forKey: kCIInputBackgroundImageKey)
                compositingFilter1.setValue(transformResult1, forKey: kCIInputImageKey)
                
                finalImage = compositingFilter1.valueForKey("outputImage") as! CIImage
            
            }
            if(isHat){
                
                let halfHatWidth = hatBallImage.extent.width / 2
                let halfHatHeight = hatBallImage.extent.height / 2
                
                let scale = newFeature!.bounds.width/hatBallImage.extent.width
            
                var offsetY = CGFloat(0)
                var offsetX = CGFloat(0)
                
                let myCGFloat = CGFloat(newFeature!.faceAngle)
                let myPIFloat = CGFloat(2*M_PI)
                let hatAngleRadians = myCGFloat*myPIFloat / 360
                
                let hatAngle = CGAffineTransformMakeRotation(-hatAngleRadians)
                
                if(-hatAngleRadians>0){
                    offsetY = sin(hatAngleRadians) * hatBallImage.extent.height
                    offsetX = sin(hatAngleRadians) * hatBallImage.extent.width
                }else{
                    offsetY = -1 * sin(hatAngleRadians) * hatBallImage.extent.height
                    offsetX = -1 * sin(hatAngleRadians) * hatBallImage.extent.width
                }
                print(offsetY)
                
                print(offsetX)
                
                let hatPosition = CGAffineTransformTranslate(hatAngle, newFeature!.bounds.midX - halfHatWidth + offsetX, newFeature!.bounds.maxY + halfHatHeight + offsetY)
                

                let hatScaledPosition = CGAffineTransformScale(hatPosition, scale,2)
                
                transformFilter.setValue(hatBallImage, forKey: "inputImage")
                transformFilter.setValue(NSValue(CGAffineTransform: hatScaledPosition), forKey: "inputTransform")
                
                
                let transformResult = transformFilter.valueForKey("outputImage") as! CIImage
                
                compositingFilter.setValue(finalImage, forKey: kCIInputBackgroundImageKey)
                compositingFilter.setValue(transformResult, forKey: kCIInputImageKey)
                
                finalImage = compositingFilter.valueForKey("outputImage") as! CIImage
                
                
            }
            if(isMoustache){
                
                
                let halfMoustacheWidth = moustacheImage2.extent.width / 7.5
                let halfMoustacheheight = moustacheImage2.extent.height / 15
                
              
                let moustachePosition = CGAffineTransformMakeTranslation(newFeature!.bounds.midX - halfMoustacheWidth, newFeature!.mouthPosition.y - halfMoustacheheight)
                
                let moustacheScaledPosition = CGAffineTransformScale(moustachePosition, 0.3,0.3)
                
                
                let myCGFloat = CGFloat(newFeature!.faceAngle)
                let myPIFloat = CGFloat(2*M_PI)
                let angleRadians = myCGFloat*myPIFloat / 360
                let moustacheAngle = CGAffineTransformRotate(moustacheScaledPosition, -angleRadians)

                
                transformFilter.setValue(moustacheImage2, forKey: "inputImage")
                transformFilter.setValue(NSValue(CGAffineTransform: moustacheAngle), forKey: "inputTransform")
                
                
                let transformResult = transformFilter.valueForKey("outputImage") as! CIImage
                
                compositingFilter.setValue(finalImage, forKey: kCIInputBackgroundImageKey)
                compositingFilter.setValue(transformResult, forKey: kCIInputImageKey)
                
                finalImage = compositingFilter.valueForKey("outputImage") as! CIImage
            }
            if(isMouth){
                
                
                let halfMouthWidth = mouthballImage.extent.width / 2
                let halfMouthHeight = mouthballImage.extent.height / 2
                
                let scaleWidth = newFeature!.bounds.width/(mouthballImage.extent.width*2)
                let scaleHeight = newFeature!.bounds.height/(mouthballImage.extent.width*2)

                
                
                let mouthPosition = CGAffineTransformMakeTranslation(newFeature!.mouthPosition.x - halfMouthWidth, newFeature!.mouthPosition.y - halfMouthHeight)
                
                let mouthScaledPosition = CGAffineTransformScale(mouthPosition, scaleWidth,scaleHeight)
                
                
                let myCGFloat = CGFloat(newFeature!.faceAngle)
                let myPIFloat = CGFloat(2*M_PI)
                let angleRadians = myCGFloat*myPIFloat / 360
                let mouthAngle = CGAffineTransformRotate(mouthScaledPosition, -angleRadians)
                
                
                
                transformFilter.setValue(mouthballImage, forKey: "inputImage")
                transformFilter.setValue(NSValue(CGAffineTransform: mouthAngle), forKey: "inputTransform")
                
                
                
                let transformResult = transformFilter.valueForKey("outputImage") as! CIImage
                
                compositingFilter.setValue(finalImage, forKey: kCIInputBackgroundImageKey)
                compositingFilter.setValue(transformResult, forKey: kCIInputImageKey)
                
                finalImage = compositingFilter.valueForKey("outputImage") as! CIImage
            }

        }
        return finalImage
    }
    
    func noneImag2(cameraImage: CIImage, backgroundImage: CIImage, features : [CIFeature])->CIImage {
    
        var image = CIImage()
        let compositingFilter = CIFilter(name: "CISourceAtopCompositing")!
        let transformFilter = CIFilter(name: "CIAffineTransform")!
        let alphaFilter = CIFilter(name: "CIColorMatrix")!
        
        let floatArr : [CGFloat] = [0,0,0,0]
        let vector = CIVector(values: floatArr, count: floatArr.count)
        
        alphaFilter.setDefaults()
        alphaFilter.setValue(cameraImage, forKey: kCIInputImageKey)
        
        alphaFilter.setValue(vector, forKey: "inputAVector")
        
        image = alphaFilter.valueForKey("outputImage") as! CIImage
        
        
        for feature in features{
            let newFeature = feature as? CIFaceFeature
        
        
            let halfMoustacheWidth = moustacheImage2.extent.width / 2
            let halfMoustacheHeight = moustacheImage2.extent.height / 2
            
            
            
            let moustachePosition = CGAffineTransformMakeTranslation(newFeature!.bounds.midX - halfMoustacheWidth, newFeature!.bounds.minY - halfMoustacheHeight)
            
             let mouthDimensions = CGAffineTransformScale(moustachePosition, 0.2,0.2)
            
            
        
        transformFilter.setValue(moustacheImage2, forKey: "inputImage")
        transformFilter.setValue(NSValue(CGAffineTransform: mouthDimensions), forKey: "inputTransform")
        
        
        let transformResult = transformFilter.valueForKey("outputImage") as! CIImage
        
        compositingFilter.setValue(image, forKey: kCIInputBackgroundImageKey)
        compositingFilter.setValue(transformResult, forKey: kCIInputImageKey)
        
        return compositingFilter.valueForKey("outputImage") as! CIImage

        }
        return image
        
   /*             let rightEyePosition = CGAffineTransformMakeTranslation(newFeature!.rightEyePosition.x - halfEyeWidth, newFeature!.rightEyePosition.y - halfEyeHeight)
                
                let leftEyePosition = CGAffineTransformMakeTranslation(newFeature!.leftEyePosition.x - halfEyeWidth, newFeature!.leftEyePosition.y - halfEyeHeight)
                
                transformFilter.setValue(eyeballImage, forKey: "inputImage")
                transformFilter.setValue(NSValue(CGAffineTransform: rightEyePosition), forKey: "inputTransform")

                
                let transformResult = transformFilter.valueForKey("outputImage") as! CIImage
                
                let transformResult1 = transformFilter1.valueForKey("outputImage") as! CIImage
                
                
                compositingFilter.setValue(finalImage, forKey: kCIInputBackgroundImageKey)
                compositingFilter.setValue(transformResult, forKey: kCIInputImageKey)
                
                finalImage = compositingFilter.valueForKey("outputImage") as! CIImage
                
                
                compositingFilter1.setValue(finalImage, forKey: kCIInputBackgroundImageKey)
                compositingFilter1.setValue(transformResult1, forKey: kCIInputImageKey)
                
                finalImage = compositingFilter1.valueForKey("outputImage") as! CIImage

        */
        
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
        

        if(cameraFront){
            connection.videoMirrored = true
        }
        else{
            connection.videoMirrored = false
        }
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
        
        let noImage = noneImage(cameraImage, backgroundImage: cameraImage,features: features)
        
        ciContext.drawImage(noImage,
                            inRect: CGRect(x: 0, y: 0,
                                width: imageView.drawableWidth,
                                height: imageView.drawableHeight),
                            fromRect: noImage.extent)
        
    }
}



