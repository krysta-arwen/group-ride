//
//  Profile+CoreDataProperties.swift
//  
//
//  Created by Krysta Deluca on 6/11/18.
//
//

import Foundation
import CoreData


extension Profile {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Profile> {
        return NSFetchRequest<Profile>(entityName: "Profile")
    }

    @NSManaged public var bike: String?
    @NSManaged public var name: String?
    @NSManaged public var profileDescription: String?
    @NSManaged public var ride: String?
    @NSManaged public var username: String?

}
