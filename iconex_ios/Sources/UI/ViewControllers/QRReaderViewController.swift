//
//  QRReaderViewController.swift
//  iconex_ios
//
//  Copyright © 2018 ICON Foundation. All rights reserved.
//

import UIKit
import AVFoundation
import RxSwift
import RxCocoa

enum ReaderMode {
    case address(ActionMode)
    case privateKey
    
    enum ActionMode {
        case add
        case send
    }
}

class QRReaderViewController: UIViewController {
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var captureView: UIView!
    @IBOutlet weak var indicatorView: UIView!
    @IBOutlet weak var indicatorLabel: UILabel!
    
    var mode: ReaderMode = .address(.add)
    var type: COINTYPE = .icx
    
    var handler: ((String) -> Void)?
    
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initialize()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setCaptureSession()
        
        captureSession.startRunning()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    func initialize() {
        titleLabel.text = "Transfer.QR".localized
        
        captureView.border(3, UIColor.white)
        
        indicatorView.corner(4)
        indicatorLabel.text = ""
        indicatorView.isHidden = true
        
        closeButton.rx.controlEvent(UIControl.Event.touchUpInside)
            .subscribe(onNext: { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            }).disposed(by: disposeBag)
    }
    
}

extension QRReaderViewController: AVCaptureMetadataOutputObjectsDelegate {
    func setCaptureSession() {
        
        
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back)
        
        guard let captureDevice = deviceDiscoverySession.devices.first else {
            return
        }
        
        do {
            captureSession = AVCaptureSession()
            
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            captureSession.addInput(input)
            
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(captureMetadataOutput)
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
        } catch {
            let alert = Alert.Basic(message: "Alert.Permission.Camera".localized)
            alert.handler = {
                self.dismiss(animated: true, completion: nil)
            }
            alert.show(self)
            Log.Error("\(error)")
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = view.layer.bounds
        videoView.layer.addSublayer(previewLayer!)
        
        view.bringSubviewToFront(captureView)
        
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if metadataObjects.count == 0 {
            return
        }
        
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if metadataObj.type == .qr {
            let barcodeObject = previewLayer?.transformedMetadataObject(for: metadataObj)
            
            if captureView.frame.contains(barcodeObject!.bounds) {
            
                guard let code = metadataObj.stringValue else {
                    return
                }
                
                switch self.mode {
                case .address(let action):
                    switch action {
                    case .add:
                        if self.type == .icx {
                            guard Validator.validateICXAddress(address: code) || Validator.validateIRCAddress(address: code) else {
                                captureView.border(2, UIColor.red)
                                indicatorView.isHidden = false
                                indicatorLabel.text = "Error.Address.ICX.Invalid".localized
                                return
                            }
                            captureSession.stopRunning()
                            
                            captureView.border(2, UIColor.green)
                            indicatorView.isHidden = true
                            if let completions = self.handler {
                                completions(code)
                            }
                            dismiss(animated: true, completion: nil)
                        } else if self.type == .eth {
                            guard Validator.validateETHAddress(address: code) else {
                                captureView.border(2, UIColor.red)
                                indicatorView.isHidden = false
                                indicatorLabel.text = "Error.Address.ETH.Invalid".localized
                                return
                            }
                            captureSession.stopRunning()
                            
                            captureView.border(2, UIColor.green)
                            indicatorView.isHidden = true
                            if let completions = self.handler {
                                completions(code)
                            }
                            dismiss(animated: true, completion: nil)
                        } else if self.type == .irc {
                            guard Validator.validateIRCAddress(address: code) else {
                                captureView.border(2, UIColor.red)
                                indicatorView.isHidden = false
                                indicatorLabel.text = "Error.Address.IRC.Invalid".localized
                                return
                            }
                            captureSession.stopRunning()
                            
                            captureView.border(2, UIColor.green)
                            indicatorView.isHidden = true
                            if let completions = self.handler {
                                completions(code)
                            }
                            dismiss(animated: true, completion: nil)
                        }
                        
                    case .send:
                        if self.type == .icx {
                            guard Validator.validateICXAddress(address: code) || Validator.validateIRCAddress(address: code) else {
                                captureView.border(2, UIColor.red)
                                indicatorView.isHidden = false
                                indicatorLabel.text = "Error.Address.ICX.Invalid".localized
                                return
                            }
                            captureSession.stopRunning()
                            
                            captureView.border(2, UIColor.green)
                            indicatorView.isHidden = true
                            if let completions = self.handler {
                                completions(code)
                            }
                            dismiss(animated: true, completion: nil)
                        } else if self.type == .eth {
                            guard Validator.validateETHAddress(address: code) else {
                                captureView.border(2, UIColor.red)
                                indicatorView.isHidden = false
                                indicatorLabel.text = "Error.Address.ETH.Invalid".localized
                                return
                            }
                            captureSession.stopRunning()
                            
                            captureView.border(2, UIColor.green)
                            indicatorView.isHidden = true
                            if let completions = self.handler {
                                completions(code)
                            }
                            dismiss(animated: true, completion: nil)
                        } else if self.type == .irc {
                            guard Validator.validateIRCAddress(address: code) else {
                                captureView.border(2, UIColor.red)
                                indicatorView.isHidden = false
                                indicatorLabel.text = "Error.Address.IRC.Invalid".localized
                                return
                            }
                            captureSession.stopRunning()
                            
                            captureView.border(2, UIColor.green)
                            indicatorView.isHidden = true
                            if let completions = self.handler {
                                completions(code)
                            }
                            dismiss(animated: true, completion: nil)
                        }
                    }
                    
                case .privateKey:
                    if code.hexToData() != nil && code.length == 64 {
                        captureSession.stopRunning()
                        
                        captureView.border(2, UIColor.green)
                        indicatorView.isHidden = true
                        if let completions = self.handler {
                            completions(code)
                        }
                        dismiss(animated: true, completion: nil)
                    } else {
                        captureView.border(2, UIColor.red)
                        indicatorView.isHidden = false
                        indicatorLabel.text = "Error.QRReader.PrivateKey".localized
                    }
                }
                
                Log.Debug(code)
            }
        }
    }
}
