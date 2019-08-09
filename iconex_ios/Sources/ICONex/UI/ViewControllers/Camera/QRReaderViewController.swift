//
//  QRReaderViewController.swift
//  iconex_ios
//
//  Created by a1ahn on 08/08/2019.
//  Copyright © 2019 ICON Foundation. All rights reserved.
//

import UIKit
import AVFoundation
import RxSwift
import RxCocoa

enum QRReaderMode {
    case prvKey, icx, eth, irc
}

private let INITIAL_HEIGHT: CGFloat = 260
private let MAX_HEIGHT: CGFloat = 340
private let MIN_HEIGHT: CGFloat = 240

class QRReaderViewController: BaseViewController {
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var qrImage: UIImageView!
    @IBOutlet weak var captureView: UIView!
    @IBOutlet weak var bottomDesc: UILabel!
    @IBOutlet weak var height: NSLayoutConstraint!
    
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    private var readerMode: QRReaderMode = .prvKey
    
    private var handler: ((String) -> Void)?
    
    private var standingBy = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        showQR()
    }
    
    override func initializeComponents() {
        super.initializeComponents()
        
        bottomDesc.size14(text: "QRReader.Desc".localized, color: .white, weight: .light, align: .center)
        qrImage.alpha = 0.0
        bottomDesc.alpha = 0.0
        captureView.alpha = 0.0
        height.constant = MAX_HEIGHT
        
        makeEdge()
        
        closeButton.rx.tap.subscribe(onNext: { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }).disposed(by: disposeBag)
    }
    
    override func refresh() {
        super.refresh()
        
        backgroundView.backgroundColor = UIColor(0, 0, 0, 0.8)
        
        setCaptureSession()
        captureSession.startRunning()
    }
    
    func showQR() {
        UIView.animate(withDuration: 0.1, animations: {
            self.qrImage.alpha = 1.0
        }, completion: { _ in
            self.showRect()
        })
    }
    
    func showRect() {
        self.height.constant = MIN_HEIGHT
        UIView.animate(withDuration: 0.25, animations: {
            self.captureView.alpha = 1.0
            self.bottomDesc.alpha = 1.0
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.hideDesc()
        })
    }
    
    func hideDesc() {

        UIView.animate(withDuration: 0.2, delay: 2.0, animations: {
            self.qrImage.alpha = 0.0
            self.bottomDesc.alpha = 0.0
        }, completion: { _ in
            self.height.constant = MAX_HEIGHT
            
            UIView.animate(withDuration: 0.2, animations: {
                self.backgroundView.backgroundColor = UIColor(0, 0, 0, 0.4)
                self.view.layoutIfNeeded()
            }, completion: { _ in
                self.standingBy = true
            })
        })
    }
    
    func set(mode: QRReaderMode, handler: @escaping ((String) -> Void)) {
        self.readerMode = mode
        self.handler = handler
    }
}

extension QRReaderViewController: AVCaptureMetadataOutputObjectsDelegate {
    private func setCaptureSession() {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back)
        
        guard let captureDevice = deviceDiscoverySession.devices.first else { return }
        
        do {
            captureSession = AVCaptureSession()
            let input = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(input)
            
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(captureMetadataOutput)
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
        } catch {
            
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.layer.bounds
        view.layer.addSublayer(previewLayer)
        view.bringSubviewToFront(backgroundView)
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard standingBy == true else { return }
        guard metadataObjects.count > 0 else { return }
        
        guard let meta = metadataObjects[0] as? AVMetadataMachineReadableCodeObject else { return }
        
        guard meta.type == .qr else { return }
        guard let barcodeObject = previewLayer.transformedMetadataObject(for: meta) else { return }
        
        let rect = captureView.convert(UIScreen.main.bounds, to: self.view)
        
        guard rect.contains(barcodeObject.bounds), let code = meta.stringValue else { return }
        
        switch readerMode {
        case .prvKey:
            if code.hexToData() != nil && code.count == 64 {
                captureSession.stopRunning()
                Log("Code - \(code)")
                if let handle = handler {
                    handle(code)
                }
                self.dismiss(animated: true, completion: nil)
            } else {
                
            }
            
        case .icx:
            break
            
        case .eth:
            break
            
        case .irc:
            break
        }
    }
}

extension QRReaderViewController {
    func makeEdge() {
        let leftTop = UIBezierPath()
        leftTop.move(to: .zero)
        leftTop.addLine(to: CGPoint(x: 30, y: 0))
        leftTop.addLine(to: CGPoint(x: 30, y: 6))
        leftTop.addLine(to: CGPoint(x: 6, y: 6))
        leftTop.addLine(to: CGPoint(x: 6, y: 30))
        leftTop.addLine(to: CGPoint(x: 0, y: 30))
        leftTop.addLine(to: .zero)
        
        let leftTopView = makeMasked(path: leftTop.cgPath, resizingMask: [.flexibleRightMargin, .flexibleBottomMargin])
        leftTopView.translatesAutoresizingMaskIntoConstraints = false
        captureView.addSubview(leftTopView)
        leftTopView.topAnchor.constraint(equalTo: captureView.topAnchor).isActive = true
        leftTopView.leadingAnchor.constraint(equalTo: captureView.leadingAnchor).isActive = true
        leftTopView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        leftTopView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        let rightTop = UIBezierPath()
        rightTop.move(to: .zero)
        rightTop.addLine(to: CGPoint(x: 30, y: 0))
        rightTop.addLine(to: CGPoint(x: 30, y: 30))
        rightTop.addLine(to: CGPoint(x: 24, y: 30))
        rightTop.addLine(to: CGPoint(x: 24, y: 6))
        rightTop.addLine(to: CGPoint(x: 0, y: 6))
        rightTop.addLine(to: .zero)
        
        let rightTopView = makeMasked(path: rightTop.cgPath, resizingMask: [.flexibleLeftMargin, .flexibleBottomMargin])
        rightTopView.translatesAutoresizingMaskIntoConstraints = false
        captureView.addSubview(rightTopView)
        rightTopView.topAnchor.constraint(equalTo: captureView.topAnchor).isActive = true
        rightTopView.trailingAnchor.constraint(equalTo: captureView.trailingAnchor).isActive = true
        rightTopView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        rightTopView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        let leftBottom = UIBezierPath()
        leftBottom.move(to: .zero)
        leftBottom.addLine(to: CGPoint(x: 6, y: 0))
        leftBottom.addLine(to: CGPoint(x: 6, y: 24))
        leftBottom.addLine(to: CGPoint(x: 30, y: 24))
        leftBottom.addLine(to: CGPoint(x: 30, y: 30))
        leftBottom.addLine(to: CGPoint(x: 0, y: 30))
        leftBottom.addLine(to: .zero)
        
        let leftBottomView = makeMasked(path: leftBottom.cgPath, resizingMask: [.flexibleRightMargin, .flexibleTopMargin])
        leftBottomView.translatesAutoresizingMaskIntoConstraints = false
        captureView.addSubview(leftBottomView)
        leftBottomView.bottomAnchor.constraint(equalTo: captureView.bottomAnchor).isActive = true
        leftBottomView.leadingAnchor.constraint(equalTo: captureView.leadingAnchor).isActive = true
        leftBottomView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        leftBottomView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        let rightBottom = UIBezierPath()
        rightBottom.move(to: CGPoint(x: 24, y: 0))
        rightBottom.addLine(to: CGPoint(x: 30, y: 0))
        rightBottom.addLine(to: CGPoint(x: 30, y: 30))
        rightBottom.addLine(to: CGPoint(x: 0, y: 30))
        rightBottom.addLine(to: CGPoint(x: 0, y: 24))
        rightBottom.addLine(to: CGPoint(x: 24, y: 24))
        rightBottom.addLine(to: CGPoint(x: 24, y: 0))
        
        let rightBottomView = makeMasked(path: rightBottom.cgPath, resizingMask: [.flexibleTopMargin, .flexibleLeftMargin])
        rightBottomView.translatesAutoresizingMaskIntoConstraints = false
        captureView.addSubview(rightBottomView)
        rightBottomView.bottomAnchor.constraint(equalTo: captureView.bottomAnchor).isActive = true
        rightBottomView.trailingAnchor.constraint(equalTo: captureView.trailingAnchor).isActive = true
        rightBottomView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        rightBottomView.heightAnchor.constraint(equalToConstant: 30).isActive = true
    }
    
    func makeMasked(path: CGPath, resizingMask: UIView.AutoresizingMask) -> UIView {
        
        let shape = CAShapeLayer()
        shape.path = path
        
        shape.fillRule = .evenOdd
        shape.fillColor = UIColor.white.cgColor
        shape.borderWidth = 1.0
        shape.borderColor = UIColor.gray77.cgColor
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        view.backgroundColor = UIColor(255, 255, 255, 0.4)
        view.layer.mask = shape
        view.autoresizingMask = resizingMask
        
        return view
    }
}
