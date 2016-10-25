import Foundation



// MARK: - ManagedObject Base Class
//
protocol ManagedObject
{
    static var entityName: String { get }
}


// MARK: - Core Data Helpers
//
struct CoreDataHelper<T where T: NSManagedObject, T: ManagedObject>
{
    /// CoreData ManagedObjectContext
    ///
    let context: NSManagedObjectContext


    /// Returns a new FetchRequest for the associated Entity
    ///
    func newFetchRequest() -> NSFetchRequest {
        return NSFetchRequest(entityName: T.entityName)
    }


    /// Returns all of the entities that match with a given predicate.
    ///
    /// - Parameter predicate: Defines the conditions that any given object should meet. Optional.
    ///
    func allObjects(matchingPredicate predicate: NSPredicate? = nil, sortedBy descriptors: [NSSortDescriptor]? = nil)  -> [T] {
        let request = newFetchRequest()
        request.predicate = predicate
        request.sortDescriptors = descriptors

        return loadObjects(withFetchRequest: request)
    }

    /// Returns the number of entities found that match with a given predicate.
    ///
    /// - Parameter predicate: Defines the conditions that any given object should meet. Optional.
    ///
    func countObjects(matchingPredicate predicate: NSPredicate? = nil) -> Int {
        let request = newFetchRequest()
        request.predicate = predicate
        request.includesSubentities = false
        request.predicate = predicate

        var result = 0

        do {
            result = try context.countForFetchRequest(request)
        } catch {
            DDLogSwift.logError("Error counting objects [\(T.entityName)]: \(error)")
            assert(false)
        }

        return result
    }

    /// Deletes the specified Object Instance
    ///
    func deleteObject(object: T) {
        do {
            context.deleteObject(object)
            try context.save()
        } catch {
            DDLogSwift.logError("Error deleting entity [\(T.entityName)]: \(error)")
            assert(false)
        }
    }

    /// Deletes all of the NSMO instances associated to the current kind
    ///
    func deleteAllObjects() {
        let request = newFetchRequest()
        request.includesPropertyValues = false
        request.includesSubentities = false

        do {
            let objects = loadObjects(withFetchRequest: request)
            for object in objects  {
                context.deleteObject(object)
            }

            try context.save()
        } catch {
            DDLogSwift.logError("Error deleting all entities of kind [\(T.entityName)]: \(error)")
            assert(false)
        }
    }

    /// Retrieves the first entity that matches with a given predicate
    ///
    /// - Parameter predicate: Defines the conditions that any given object should meet.
    ///
    func firstObject(matchingPredicate predicate: NSPredicate) -> T? {
        let request = newFetchRequest()
        request.predicate = predicate
        request.fetchLimit = 1

        let objects = loadObjects(withFetchRequest: request)
        return objects.first
    }

    /// Inserts a new Entity. For performance reasons, this helper *DOES NOT* persists the context.
    ///
    func insertNewObject() -> T {
        let name = T.entityName
        let entity = NSEntityDescription.insertNewObjectForEntityForName(name, inManagedObjectContext: context)

        return entity as! T
    }

    /// Loads a single NSManagedObject instance, given its ObjectID, if available.
    ///
    /// - Parameter objectID: Unique Identifier of the entity to retrieve, if available.
    ///
    func loadObject(withObjectID objectID: NSManagedObjectID) -> T? {
        var result: T?

        do {
            result = try context.existingObjectWithID(objectID) as? T
        } catch {
            DDLogSwift.logError("Error loading Object [\(T.entityName)]")
        }

        return result
    }
}


// MARK: - Private Helpers
//
private extension CoreDataHelper
{
    /// Loads the collection of entities that match with a given Fetch Request
    ///
    private func loadObjects(withFetchRequest request: NSFetchRequest) -> [T] {
        var objects: [T]?

        do {
            objects = try context.executeFetchRequest(request) as? [T]
        } catch {
            DDLogSwift.logError("Error loading Objects [\(T.entityName)")
            assert(false)
        }

        return objects ?? []
    }
}
