//
//  VoiceConversationDatabaseManager.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 26/05/25.
//

import CoreData

enum VoiceConversationDatabaseVersion {
  static let containerName = "VoiceConversation"
}

final class VoiceConversationDatabaseManager {
  
  // MARK: - Properties
  
  static let shared = VoiceConversationDatabaseManager()
  
  /// Container init
  public var container: NSPersistentContainer = {
    /// Loading model from package resources
    let bundle = Bundle.module
    let modelURL = bundle.url(forResource: VoiceConversationDatabaseVersion.containerName, withExtension: "mom")!
    let model = NSManagedObjectModel(contentsOf: modelURL)!
    let container = NSPersistentContainer(name: VoiceConversationDatabaseVersion.containerName, managedObjectModel: model)
    
    /// Setting notification tracking
    let description = container.persistentStoreDescriptions.first!
    description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
    description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
    /// Loading of persistent stores
    container.loadPersistentStores { (storeDescription, error) in
      if let error {
        fatalError("Failed to load store: \(error)")
      }
    }
    /// Configure the viewContext (main context)
    container.viewContext.automaticallyMergesChangesFromParent = true
    container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    return container
  }()
  
  /// Background context for heavy database operations
  public lazy var backgroundContext: NSManagedObjectContext = {
    newTaskContext()
  }()
  
  private var notificationToken: NSObjectProtocol?
  /// A peristent history token used for fetching transactions from the store.
  /// Thread-safe storage: tokens are archived to Data for thread-safe access
  /// NSPersistentHistoryToken objects are not thread-safe and must be archived/unarchived
  private var _lastTokenData: Data?
  private let tokenQueue = DispatchQueue(label: "com.ekavoice.persistentHistoryToken")
  
  /// Thread-safe getter: unarchives token from Data
  /// NSPersistentHistoryToken must be archived/unarchived for thread-safe access
  private func getLastToken() -> NSPersistentHistoryToken? {
    return tokenQueue.sync {
      guard let data = _lastTokenData else { return nil }
      // Use NSKeyedUnarchiver for thread-safe token retrieval
      // This ensures the token is valid on the thread where it's unarchived
      guard let unarchiver = try? NSKeyedUnarchiver(forReadingFrom: data) else {
        return nil
      }
      unarchiver.requiresSecureCoding = true
      defer { unarchiver.finishDecoding() }
      return unarchiver.decodeObject(of: NSPersistentHistoryToken.self, forKey: NSKeyedArchiveRootObjectKey)
    }
  }
  
  /// Thread-safe setter: archives token to Data
  /// NSPersistentHistoryToken must be archived for thread-safe storage
  private func setLastToken(_ token: NSPersistentHistoryToken?) {
    tokenQueue.sync {
      if let token = token {
        // Use NSKeyedArchiver for thread-safe token storage
        // This ensures the token can be safely passed between threads
        let archiver = NSKeyedArchiver(requiringSecureCoding: true)
        archiver.encode(token, forKey: NSKeyedArchiveRootObjectKey)
        archiver.finishEncoding()
        _lastTokenData = archiver.encodedData
      } else {
        _lastTokenData = nil
      }
    }
  }
  /// Flag to prevent concurrent persistent history fetches (thread-safe)
  private var _isFetchingHistory = false
  private let historyFetchQueue = DispatchQueue(label: "com.ekavoice.persistentHistoryFetch")
  private var isFetchingHistory: Bool {
    get {
      return historyFetchQueue.sync { _isFetchingHistory }
    }
    set {
      historyFetchQueue.sync { _isFetchingHistory = newValue }
    }
  }
  /// To get upload completion callbacks
  private var uploadCompletionCallbacks: [UUID: () -> Void] = [:]
  /// Session ids which are being listened to for is file uploaded changes
  private var watchedSessionIDs: Set<UUID> = []
    
  // MARK: - Init
  
  private init() {
    /// Observe Core Data remote change notifications on the queue where the changes were made.
    notificationToken = NotificationCenter.default.addObserver(forName: .NSPersistentStoreRemoteChange, object: nil, queue: nil) { [weak self] _ in
      guard let self else { return }
   //   Task { [weak self] in
   //     guard let self else { return }
   //     fetchPersistentHistory()
   //   }
    }
    
    NotificationCenter.default.addObserver(forName: .NSManagedObjectContextObjectsDidChange, object: nil, queue: nil) { [weak self] notification in
      guard let self else { return }
      
      for sessionID in watchedSessionIDs {
        checkUploadStatus(for: sessionID)
      }
    }
  }
  
  deinit {
    if let observer = notificationToken {
      NotificationCenter.default.removeObserver(observer)
    }
    NotificationCenter.default.removeObserver(self, name: .NSManagedObjectContextObjectsDidChange, object: nil)
  }
}

// MARK: - Notification changes

extension VoiceConversationDatabaseManager {
  /// Creates and configures a private queue context.
  func newTaskContext() -> NSManagedObjectContext  {
    // Create a private queue context.
    let taskContext = container.newBackgroundContext()
    taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    // Set unused undoManager to nil for macOS (it is nil by default on iOS)
    // to reduce resource requirements.
    taskContext.undoManager = nil
    return taskContext
  }
  
  func fetchPersistentHistory() {
    historyFetchQueue.async { [weak self] in
      guard let self else { return }
      
      guard !_isFetchingHistory else {
        return
      }
      
      _isFetchingHistory = true
      defer {
        _isFetchingHistory = false
      }
      
      fetchPersistentHistoryTransactionsAndChanges()
    }
  }
  
  func fetchPersistentHistoryTransactionsAndChanges() {
    backgroundContext.perform { [weak self] in
      guard let self else { return }
      
      // Get token on the background context's thread - unarchived from thread-safe storage
      let token = getLastToken()
      
      // Create the change request with the token
      // The token is now valid on this thread since we unarchived it here
      let changeRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: token)
      
//      do {
//        let historyResult = try backgroundContext.execute(changeRequest) as? NSPersistentHistoryResult
//        if let history = historyResult?.result as? [NSPersistentHistoryTransaction],
//           !history.isEmpty {
//          mergePersistentHistoryChanges(from: history)
//        }
//      } catch {
//        print("⚠️ Persistent history fetch failed: \(error)")
//      }
    }
  }
  
  /// Helper function to merge persistent history changes into the view context.
  /// - Parameter history: An array of `NSPersistentHistoryTransaction` objects representing the changes.
  private func mergePersistentHistoryChanges(from history: [NSPersistentHistoryTransaction]) {
    // Update view context with objectIDs from history change request.
    /// - Tag: mergeChanges
    container.viewContext.perform { [weak self] in
      guard let self else { return }
      
      // Get the last transaction token to update atomically
      guard let lastTransaction = history.last else { return }
      
      for transaction in history {
        container.viewContext.mergeChanges(fromContextDidSave: transaction.objectIDNotification())
      }
      
      // Update token once with the last transaction's token (thread-safe via archiving)
      // The token is valid on this thread, we archive it for thread-safe storage
      setLastToken(lastTransaction.token)
    }
  }
  
  func observeUploadStatus(for sessionID: UUID, completion: @escaping () -> Void) {
    uploadCompletionCallbacks[sessionID] = completion
    watchedSessionIDs.insert(sessionID)
    checkUploadStatus(for: sessionID)
  }
}

// MARK: - Create

extension VoiceConversationDatabaseManager {
  /// Used to add a new voice conversation to the database.
  /// - Parameter conversationArguement: model containing the arguments for the database.
  func addVoiceConversation(
    conversationArguement: VoiceConversationArguementModel
  ) async -> VoiceConversation? {
    let voice = VoiceConversation(context: container.viewContext)
    voice.sessionID = UUID()
    voice.update(from: conversationArguement)
    do {
      try container.viewContext.save()
      logAddVoiceEvent(sessionID: voice.sessionID, status: .success)
      return voice
    } catch {
      logAddVoiceEvent(sessionID: voice.sessionID, status: .failure, message: "Failed to save voice conversation: \(error.localizedDescription)")
      debugPrint("Failed to save voice conversation: \(error.localizedDescription)")
      return nil
    }
  }
}

// MARK: - Update

extension VoiceConversationDatabaseManager {
  /// This is to be used to update the voice conversation in the database.
  /// - Parameters:
  ///   - sessionID: Session ID of the voice conversation to update.
  ///   - conversationArguement: Model containing the arguments for the update.
  func updateVoiceConversation(
    sessionID: UUID,
    conversationArguement: VoiceConversationArguementModel
  ) {
    let fetchRequest = QueryHelper.fetchRequest(for: sessionID)
    guard let voice = try? container.viewContext.fetch(fetchRequest).first else {
      return
    }
    voice.update(from: conversationArguement)
    do {
      try container.viewContext.save()
      logUpdateConversationEvent(sessionID: sessionID, status: .success)
    } catch {
      logUpdateConversationEvent(sessionID: sessionID, status: .failure, message: "Failed to update voice conversation: \(error.localizedDescription)")
      print("Failed to update voice conversation: \(error.localizedDescription)")
    }
  }
  
  /// This updates the voice chunk for the given session ID. If the chunk already exists, it updates the existing chunk; otherwise, it creates a new one.
  /// - Parameters:
  ///   - sessionID: The session ID of the voice conversation to update.
  ///   - chunkArguement: Model containing the arguments for the voice chunk.
  func updateVoiceChunk(
    sessionID: UUID,
    chunkArguement: VoiceChunkInfoArguementModel
  ) {
    // Serialize all Core Data operations to prevent concurrent Set mutations
    // Use performAndWait to ensure thread-safe access to Core Data relationships
    container.viewContext.performAndWait { [weak self] in
      guard let self else { return }
      
      let fetchRequest = QueryHelper.fetchRequest(for: sessionID)
      guard let voice = try? container.viewContext.fetch(fetchRequest).first else {
        return
      }
      
      // Check if chunk with given fileName already exists
      // Create a snapshot of the Set to avoid mutation during enumeration
      // This prevents "Collection was mutated while being enumerated" crashes
      let existingChunksSet = voice.toVoiceChunkInfo as? Set<VoiceChunkInfo> ?? Set<VoiceChunkInfo>()
      let fileNameToFind = chunkArguement.fileName
      
      if let existingChunk = existingChunksSet.first(where: { $0.fileName == fileNameToFind }) {
        existingChunk.update(from: chunkArguement)
      } else {
        let newChunk = VoiceChunkInfo(context: self.container.viewContext)
        newChunk.update(from: chunkArguement)
        voice.addToToVoiceChunkInfo(newChunk)
      }
      
      do {
        try container.viewContext.save()
        self.logUpdateChunkEvent(
          sessionID: sessionID,
          fileName: chunkArguement.fileName,
          status: .success
        )
      } catch {
        self.logUpdateChunkEvent(
          sessionID: sessionID,
          fileName: chunkArguement.fileName,
          status: .failure,
          message: "Failed to update voice conversation: \(error.localizedDescription)"
        )
      }
    }
  }
}

// MARK: - Read

extension VoiceConversationDatabaseManager {
  func getVoice(fetchRequest: NSFetchRequest<VoiceConversation>) -> VoiceConversation? {
    do {
      let results = try container.viewContext.fetch(fetchRequest)
      return results.first
    } catch {
      print("Fetch error: \(error)")
    }
    return nil
  }
}

// MARK: - Delete

extension VoiceConversationDatabaseManager {
  /// Used to delete a single conversation
  /// - Parameter fetchRequest: fetch request of the record to be deleted
  func deleteVoice(fetchRequest: NSFetchRequest<VoiceConversation>) {
    var sessionID: UUID?
    do {
      let results = try container.viewContext.fetch(fetchRequest)
      if let voice = results.first {
        sessionID = voice.sessionID
        container.viewContext.delete(voice)
        try container.viewContext.save()
        logDeleteVoiceEvent(sessionID: voice.sessionID, status: .success)
      }
    } catch {
      logDeleteVoiceEvent(sessionID: sessionID, status: .failure, message: "Delete error: \(error)")
      print("Delete error: \(error)")
    }
  }
  
  /// Delete all the voices data
  func deleteAllVoices() {
    let fetchRequest: NSFetchRequest<NSFetchRequestResult> = VoiceConversation.fetchRequest()
    let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
    
    do {
      try container.viewContext.execute(deleteRequest)
      try container.viewContext.save()
      logDeleteAllVoicesEvent(status: .success)
    } catch {
      logDeleteAllVoicesEvent(status: .failure, message: "Failed to delete all VoiceConversations: \(error)")
      print("Failed to delete all VoiceConversations: \(error)")
    }
  }
}

// MARK: - Check upload status

extension VoiceConversationDatabaseManager {
  func checkUploadStatus(for sessionID: UUID) {
    // Use performAndWait to ensure thread-safe access to Core Data relationships
    container.viewContext.performAndWait { [weak self] in
      guard let self else { return }
      let fetchRequest = QueryHelper.fetchRequest(for: sessionID)
      guard let voice = try? container.viewContext.fetch(fetchRequest).first else { return }
      
      // Create a snapshot of the Set to avoid mutation during enumeration
      let chunks = voice.toVoiceChunkInfo as? Set<VoiceChunkInfo> ?? Set<VoiceChunkInfo>()
      let isFileUploadStatus = chunks.compactMap { $0.isFileUploaded }
      print("File upload status of files for sessionID \(sessionID) -> \(isFileUploadStatus)")
      if chunks.allSatisfy({$0.isFileUploaded}),
         let callback = self.uploadCompletionCallbacks.removeValue(forKey: sessionID) {
        self.watchedSessionIDs.remove(sessionID)
        // Execute callback on main queue since it might update UI
        DispatchQueue.main.async {
          callback()
        }
      }
    }
  }
}

