enum TrackRecordingState: Equatable {
  case inactive
  case active
  case error(TrackRecordingError)
}

enum TrackRecordingAction {
  case start
  case stop
}

enum TrackRecordingError: Error {
  case locationIsProhibited
}

typealias TrackRecordingStateHandler = (TrackRecordingState) -> Void

@objcMembers
final class TrackRecordingManager: NSObject {

  typealias CompletionHandler = () -> Void

  enum StopOption {
    case `continue`
    case stopWithoutSaving
    case saveWith(categoryId: MWMMarkGroupID, name: String?, color: UIColor)
  }

  fileprivate struct Observation {
    weak var observer: AnyObject?
    var recordingStateDidChangeHandler: TrackRecordingStateHandler?
  }

  static let shared: TrackRecordingManager = TrackRecordingManager(trackRecorder: FrameworkHelper.self)

  private let trackRecorder: TrackRecorder.Type
  private var observations: [Observation] = []
  private(set) var recordingState: TrackRecordingState = .inactive {
    didSet {
      notifyObservers()
    }
  }

  private init(trackRecorder: TrackRecorder.Type) {
    self.trackRecorder = trackRecorder
    super.init()
    self.recordingState = getCurrentRecordingState()
  }

  func processAction(_ action: TrackRecordingAction, completion: (CompletionHandler)? = nil) {
    switch action {
    case .start:
      start(completion: completion)
    case .stop:
      stop(completion: completion)
    }
  }

  func addObserver(_ observer: AnyObject, recordingStateDidChangeHandler: @escaping TrackRecordingStateHandler) {
    let observation = Observation(observer: observer, recordingStateDidChangeHandler: recordingStateDidChangeHandler)
    observations.append(observation)
    recordingStateDidChangeHandler(recordingState)
  }

  func removeObserver(_ observer: AnyObject) {
    observations.removeAll { $0.observer === observer }
  }

  private func notifyObservers() {
    observations = observations.filter { $0.observer != nil }
    observations.forEach { $0.recordingStateDidChangeHandler?(recordingState) }
  }

  private func handleError(_ error: TrackRecordingError, completion: (CompletionHandler)? = nil) {
    switch error {
    case .locationIsProhibited:
      // Show alert to enable location
      LocationManager.checkLocationStatus()
    }
    stopRecording(.stopWithoutSaving, completion: completion)
  }

  private func getCurrentRecordingState() -> TrackRecordingState {
    guard !LocationManager.isLocationProhibited() else {
      return .error(.locationIsProhibited)
    }
    return trackRecorder.isTrackRecordingEnabled() ? .active : .inactive
  }

  private func start(completion: (CompletionHandler)? = nil) {
    let state = getCurrentRecordingState()
    switch state {
    case .inactive:
      trackRecorder.startTrackRecording()
      recordingState = .active
      completion?()
    case .active:
      completion?()
    case .error(let trackRecordingError):
      handleError(trackRecordingError, completion: completion)
    }
  }

  private func stop(completion: (CompletionHandler)? = nil) {
    guard !trackRecorder.isTrackRecordingEmpty() else {
      Toast.toast(withText: L("track_recording_toast_nothing_to_save")).show()
      stopRecording(.stopWithoutSaving, completion: completion)
      return
    }

    let configuration = TrackEditingMode.StopRecordingConfiguration(
      groupId: trackRecorder.getTrackRecordingCategory(),
      name: trackRecorder.generateTrackRecordingName(),
      color: trackRecorder.generateTrackRecordingColor(),
      onStopCompletion: { [weak self] stopOption in
        self?.stopRecording(stopOption, completion: completion)
    })
    let editTrackViewController = EditTrackViewController(editingMode: .stopRecording(configuration))
    let navigationController = MWMNavigationController(rootViewController: editTrackViewController)
    editTrackViewController.modalPresentationStyle = .pageSheet
    UIViewController.topViewController().present(navigationController, animated: true)
  }

  private func stopRecording(_ option: StopOption, completion: (CompletionHandler)? = nil) {
    switch option {
    case .continue:
      break
    case .stopWithoutSaving:
      trackRecorder.stopTrackRecording()
      recordingState = .inactive
    case .saveWith(let categoryId, let name, let color):
      trackRecorder.stopTrackRecording()
      trackRecorder.saveTrackRecording(withCategoryId: categoryId, name: name, color: color)
      recordingState = .inactive
    }
    completion?()
  }
}
