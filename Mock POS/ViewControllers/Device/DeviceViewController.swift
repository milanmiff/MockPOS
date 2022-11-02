//
//  DeviceViewController.swift
//  Mock POS
//
//  Created by Milan Djordjevic on 02/11/2022.
//

import UIKit

protocol DeviceViewControllerDelegating: AnyObject {
}

final class DeviceViewController: UIViewController, DeviceViewControllerDelegating {
    @IBOutlet weak var textViewMessage: UITextView!
    private var viewModel: DeviceViewModeling
    
    init(viewModel: DeviceViewModeling) {
        self.viewModel = viewModel
        super.init(nibName: "DeviceViewController", bundle: Bundle(for: type(of: self)))
        self.viewModel.viewDelegate = self
    }
    
    required init?(coder: NSCoder) {
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func handleSendButton(_ sender: Any) {
        viewModel.textToSend = textViewMessage.text ?? "Default"
        viewModel.sendData()
    }
}
