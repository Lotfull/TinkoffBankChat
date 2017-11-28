//
//  ChatModel.swift
//  TinkoffChat
//
//  Created by Kam Lotfull on 31.10.17.
//  Copyright © 2017 Kam Lotfull. All rights reserved.
//

import CoreData
import UIKit

protocol IChatModel: class {
    weak var delegate: IChatModelDelegate? { get set }
    var isOnline: Bool { get }
    var name: String { get }
    func sendMessage(text: String, completionHandler: ((Bool, Error?) -> Void)?)
    func markChatAsRead()
    func setup(_ tableView: UITableView)
}

protocol IChatModelDelegate: class {
    func userBecameOnline(online: Bool)
}

class ChatModel: NSObject, IChatModel, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate {
    
    weak var delegate: IChatModelDelegate?
    
    let communicationService: ICommunicationService
    let chatDataService: IChatDataService
    let chatID: String
    
    let name: String
    
    var isOnline: Bool {
        return chatDataService.isOnlineChat(withID: chatID)
    }
    
    private let fetchedResultsController: NSFetchedResultsController<Message>
    private var tableView: UITableView!

    init(communicationService: ICommunicationService,
        chatDataService: IChatDataService,
        chat: Chat) {
        
        self.communicationService = communicationService
        self.chatDataService = chatDataService
        self.chatID = chat.id ?? "chatID\(arc4random_uniform(1000))"
        self.name = "name"//chatDataService.getUserNameForChat(withID: self.chatID)
        
        let mainContext = chatDataService.mainContext//.mainContext
        guard let model = mainContext.persistentStoreCoordinator?.managedObjectModel else {
            preconditionFailure("Model is not available in context")
        }
        
        
        let fetchRequest: NSFetchRequest<Message> = Message.fetchRequestMessageByChatID(ID: chatID, model: model)!
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Message.text), ascending: true)]
        self.fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: mainContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        super.init()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(managedObjectContextDidSave(_:)),
                                               name: .NSManagedObjectContextDidSave,
                                               object: mainContext)
    }
    
    @objc func managedObjectContextDidSave(_ notification: NSNotification) {
        delegate?.userBecameOnline(online: chatDataService.isOnlineChat(withID: chatID))
    }
    func markChatAsRead() {
        chatDataService.makeReadChat(withID: chatID)
    }
    
    func setup(_ tableView: UITableView) {
        self.tableView = tableView
        self.tableView.delegate = self
        self.tableView.dataSource = self
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Error fetching: \(error)")
        }
        do {
            try self.fetchedResultsController.performFetch()
        } catch {
            print("Error fetching: \(error)")
        }
    }
    func sendMessage(text: String, completionHandler: ((Bool, Error?) -> Void)?) {
        communicationService.sendMessage(text: text, to: chatID, completionHandler: completionHandler)
    }
    
    private var shouldScrollToBottom = false
}

// MARK: - UITableViewDataSource

extension ChatModel {
    func numberOfSections(in tableView: UITableView) -> Int {
        guard let sectionsCount = fetchedResultsController.sections?.count else {
            preconditionFailure("no sections in fetchedResultsController")
        }
        return sectionsCount
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = fetchedResultsController.sections else {
            preconditionFailure("no sections in fetchedResultsController")
        }
        let sectionInfo = sections[section]
        return sectionInfo.numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = fetchedResultsController.object(at: indexPath)
        let messageCellIdentifier = message.type == inbox ? MessageCellID.inbox.rawValue : MessageCellID.outbox.rawValue
        let cell = tableView.dequeueReusableCell(withIdentifier: messageCellIdentifier, for: indexPath)
        guard let messageCell = cell as? MessageCellConfiguration & UITableViewCell else {
            assertionFailure("Wrong cell type")
            return cell
        }
        messageCell.messageText = message.text
        return messageCell
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            let adjustedTableViewFrameSize = self.tableView.frame.height - self.tableView.contentInset.bottom
            let contentExceedsTableViewFrame = self.tableView.contentSize.height > adjustedTableViewFrameSize
            if self.shouldScrollToBottom && contentExceedsTableViewFrame {
                let offset = CGPoint(x: 0, y: self.tableView.contentSize.height - adjustedTableViewFrameSize)
                self.tableView.setContentOffset(offset, animated: true)
            }
            self.shouldScrollToBottom = false
        }
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
        CATransaction.commit()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .delete:
            deleteRowsInTableAtIndexPath(indexPath)
        case .insert:
            self.shouldScrollToBottom = true
            insertRowsInTableAtIndexPath(newIndexPath)
        default:
            break
        }
    }
    
    private func deleteRowsInTableAtIndexPath(_ indexPath: IndexPath?) {
        if let indexPath = indexPath {
            tableView.deleteRows(at: [indexPath], with: .none)
        }
    }
    
    private func insertRowsInTableAtIndexPath(_ indexPath: IndexPath?) {
        if let indexPath = indexPath {
            tableView.insertRows(at: [indexPath], with: .none)
        }
    }
}

// MARK: - UITableViewDelegate

extension ChatModel {
//    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        guard let messageCell = cell as? MessageCellConfiguration & UITableViewCell else {
//            assertionFailure("Wrong cell type")
//            return
//        }
//        let message = fetchedResultsController.object(at: indexPath)
//        cell.layoutIfNeeded()
////        let messageCellIdentifier = message.type == inbox ?
////            MessageCellID.inbox.rawValue :
////            MessageCellID.outbox.rawValue
//    }
}
