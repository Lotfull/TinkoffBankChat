//
//  ChatsListViewController.swift
//  TinkoffChat
//
//  Created by Kam Lotfull on 05.10.17.
//  Copyright © 2017 Kam Lotfull. All rights reserved.
//

import UIKit
import CoreData

protocol IChatsListDelegate: class {
    func pushVC(_ viewController: UIViewController)
}

class ChatsListViewController: UIViewController, IChatsListDelegate {
    @IBOutlet weak var tableView: UITableView!
    
    private var model: IChatsListModel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    static func initWith(model: IChatsListModel) -> ChatsListViewController {
        let chatsListVC = UIStoryboard(name: "ChatsList", bundle: nil).instantiateViewController(withIdentifier: "ChatsListViewController") as! ChatsListViewController
        chatsListVC.model = model
        model.delegate = chatsListVC
        return chatsListVC
    }
    
    let chatsTableViewCellName = "ChatCell"
    let chatsTableViewCellID = "ChatCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        let nib = UINib(nibName: chatsTableViewCellName, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: chatsTableViewCellID)
        model.setup(tableView)
        navigationItem.rightBarButtonItem?.tintColor = UIColor(white: 0.5, alpha: 1)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print(#function)
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    @IBAction func presentProfile(_ sender: Any) {
        let profileVC = ProfileAssembly().profileViewController()
        let navigationController = UINavigationController.init(rootViewController: profileVC)
        self.present(navigationController, animated: true, completion: nil)
    }
    
    private func updateChatsList() {
        tableView.reloadData()
    }
    
    func pushVC(_ viewController: UIViewController) {
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    private let sectionName = ["Online", "History"]
    
    
    
    
}

