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
  private var lastToken: NSPersistentHistoryToken?
  /// To get upload completion callbacks
  private var uploadCompletionCallbacks: [UUID: () -> Void] = [:]
  /// Session ids which are being listened to for is file uploaded changes
  private var watchedSessionIDs: Set<UUID> = []
    
  // MARK: - Init
  
  private init() {
    /// Observe Core Data remote change notifications on the queue where the changes were made.
    notificationToken = NotificationCenter.default.addObserver(forName: .NSPersistentStoreRemoteChange, object: nil, queue: nil) { [weak self] note in
      guard let self else { return }
      debugPrint("Received a persistent store remote change notification.")
      Task { [weak self] in
        guard let self else { return }
        await self.fetchPersistentHistory()
      }
    }
    
    NotificationCenter.default.addObserver(forName: .NSManagedObjectContextObjectsDidChange, object: nil, queue: nil) { [weak self] notification in
      guard let self else { return }
      Task {
        for sessionID in self.watchedSessionIDs {
          await self.checkUploadStatus(for: sessionID)
        }
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
  
  /// Used to fetch persistent history changes from the store.
  func fetchPersistentHistory() async {
    do {
      try await fetchPersistentHistoryTransactionsAndChanges()
    } catch {
      debugPrint("\(error.localizedDescription)")
    }
  }
  
  /// Fetches persistent history transactions and merges them into the view context.
  func fetchPersistentHistoryTransactionsAndChanges() async throws {
    backgroundContext.name = "persistentHistoryContext"
    debugPrint("Start fetching persistent history changes from the store...")
    try await backgroundContext.perform { [weak self] in
      guard let self else { return }
      // Execute the persistent history change since the last transaction.
      /// - Tag: fetchHistory
      let changeRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: self.lastToken)
      let historyResult = try backgroundContext.execute(changeRequest) as? NSPersistentHistoryResult
      if let history = historyResult?.result as? [NSPersistentHistoryTransaction],
         !history.isEmpty {
        self.mergePersistentHistoryChanges(from: history)
        return
      }
    }
    debugPrint("Finished merging history changes.")
  }
  
  /// Helper function to merge persistent history changes into the view context.
  /// - Parameter history: An array of `NSPersistentHistoryTransaction` objects representing the changes.
  private func mergePersistentHistoryChanges(from history: [NSPersistentHistoryTransaction]) {
    debugPrint("Received \(history.count) persistent history transactions.")
    // Update view context with objectIDs from history change request.
    /// - Tag: mergeChanges
    let viewContext = container.viewContext
    viewContext.perform {
      for transaction in history {
        viewContext.mergeChanges(fromContextDidSave: transaction.objectIDNotification())
        self.lastToken = transaction.token
      }
    }
  }
  
  func observeUploadStatus(for sessionID: UUID, completion: @escaping () -> Void) {
    uploadCompletionCallbacks[sessionID] = completion
    watchedSessionIDs.insert(sessionID)
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
      return voice
    } catch {
      print("Failed to save voice conversation: \(error.localizedDescription)")
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
    } catch {
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
    let fetchRequest = QueryHelper.fetchRequest(for: sessionID)
    guard let voice = try? container.viewContext.fetch(fetchRequest).first else {
      return
    }
    // Check if chunk with given fileName already exists
    if let existingChunks = voice.toVoiceChunkInfo as? Set<VoiceChunkInfo>,
       let existingChunk = existingChunks.first(where: { $0.fileName == chunkArguement.fileName }) {
      existingChunk.update(from: chunkArguement)
    } else {
      let newChunk = VoiceChunkInfo(context: container.viewContext)
      newChunk.update(from: chunkArguement)
      voice.addToToVoiceChunkInfo(newChunk)
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

// MARK: - Check upload status

extension VoiceConversationDatabaseManager {
  func checkUploadStatus(for sessionID: UUID) {
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      let context = container.viewContext
      let fetchRequest = QueryHelper.fetchRequest(for: sessionID)
      guard let voice = try? context.fetch(fetchRequest).first,
            let chunks = voice.toVoiceChunkInfo as? Set<VoiceChunkInfo> else { return }
      
      let isFileUploadStatus = chunks.compactMap { $0.isFileUploaded }
      print("File upload status of files -> \(isFileUploadStatus)")
      if chunks.allSatisfy({$0.isFileUploaded}),
         let callback = self.uploadCompletionCallbacks.removeValue(forKey: sessionID) {
        callback()
      }
    }
  }
}
