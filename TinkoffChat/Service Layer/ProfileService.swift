//
//  ProfileService.swift
//  TinkoffChat
//
//  Created by Kam Lotfull on 31.10.17.
//  Copyright © 2017 Kam Lotfull. All rights reserved.
//

import UIKit
import CoreData

protocol DataManager {
    func loadProfile(completion: @escaping (Profile?, Error?) -> Void)
    func saveProfile(_ profile: Profile, completion: @escaping (Bool, Error?) -> Void)
}

enum CoreDataError: Error {
    case loadError
    case saveError
}

class ProfileService: DataManager {
    
    func loadProfile(completion: @escaping (Profile?, Error?) -> Void) {
        if let appUser = CoreDataManager.getAppUser(),
            let user = appUser.currentUser {
            let image = user.image != nil ? UIImage(data: user.image!) : #imageLiteral(resourceName: "placeholder-user")
            let myProfile = Profile(name: user.name ?? "Unnamed User",
                                    info: user.info ?? "No info",
                                    image: image)
            completion(myProfile, nil)
        } else {
            print("Core data error")
            completion(nil, CoreDataError.loadError)
        }
    }
    
    func saveProfile(_ profile: Profile, completion: @escaping (Bool, Error?) -> Void) {
        CoreDataManager.saveProfile(profile, completion: completion)
    }
}
