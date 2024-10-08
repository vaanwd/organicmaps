enum ActivityWidgetDeeplinkSource: String, CaseIterable {
  case liveActivityWidget = "live-activity-widget"
}

extension TrackRecordingAction {

  static private let kTrackRecordingDeeplinkPath = "track-recording"

  func buildDeeplink(for source: ActivityWidgetDeeplinkSource) -> URL {
    return URL(string: "om://" + source.rawValue + "/" + Self.kTrackRecordingDeeplinkPath + "/" + self.rawValue)!
  }

  static func parseFromDeeplink(_ deeplink: String) -> TrackRecordingAction? {
    let components = deeplink.components(separatedBy: "/")
    if components.contains(kTrackRecordingDeeplinkPath) {
      return TrackRecordingAction(rawValue: components.last ?? "")
    }
    return nil
  }
}
