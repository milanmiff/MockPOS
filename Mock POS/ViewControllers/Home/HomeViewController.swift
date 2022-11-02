//
//  HomeViewController.swift
//  Mock POS
//
//  Created by Milan Djordjevic on 26/10/2022.
//

import UIKit

protocol HomeViewControllerDelegating: AnyObject {
    func updateField( with text: String)
}

final class HomeViewController: UIViewController, HomeViewControllerDelegating {
    @IBOutlet weak var payloadField: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    
    private var viewModel: HomeViewModeling
    
    init(viewModel: HomeViewModeling) {
        self.viewModel = viewModel
        super.init(nibName: "HomeViewController", bundle: Bundle(for: type(of: self)))
        self.viewModel.viewDelegate = self
    }
    
    required init?(coder: NSCoder) {
        return nil
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func updateField( with text: String) {
        
    }
    
    @IBAction func handleSendTapp(_ sender: Any) {
    }
    
    @IBAction func handleTapDevice(_ sender: Any) {
        viewModel.gotoDevice()
    }
    
}
