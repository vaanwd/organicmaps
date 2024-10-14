enum TrackEditingMode {
  struct StopRecordingConfiguration {
    let groupId: MWMMarkGroupID
    let name: String
    let color: UIColor
    let onStopCompletion: (TrackRecordingManager.StopOption) -> Void
  }

  struct EditingConfiguration {
    let trackId: MWMTrackID
    let onFinishEditingCompletion: (Bool) -> Void
  }

  case edit(EditingConfiguration)
  case stopRecording(StopRecordingConfiguration)
}

final class EditTrackViewController: MWMTableViewController {

  private enum Sections: Int, CaseIterable {
    case info
    case `continue`
    case delete
  }
  
  private enum InfoSectionRows: Int, CaseIterable {
    case title
    case color
    case bookmarkGroup
  }

  private let mode: TrackEditingMode
  private let bookmarksManager = BookmarksManager.shared()

  private var trackTitle: String?
  private var trackGroupTitle: String?
  private var trackGroupId = FrameworkHelper.invalidCategoryId()
  private var trackColor: UIColor

  init(editingMode: TrackEditingMode) {
    self.mode = editingMode

    switch editingMode {
    case .edit(let configuration):
      trackGroupId = bookmarksManager.category(forTrackId: configuration.trackId).categoryId
      let track = bookmarksManager.track(withId: configuration.trackId)
      trackTitle = track.trackName
      trackColor = track.trackColor
    case .stopRecording(let configuration):
      trackGroupId = configuration.groupId
      trackTitle = configuration.name
      trackColor = configuration.color
    }
    trackGroupTitle = bookmarksManager.category(withId: trackGroupId).title

    super.init(style: .grouped)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    updateTrackIfNeeded()
  }

  deinit {
    removeFromBookmarksManagerObserverList()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    switch mode {
    case .edit:
      title = L("track_title")
    case .stopRecording:
      // TODO: localize and remove previous string
      title = L("Save Track Recording?")
    }
    navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save,
                                                        target: self,
                                                        action: #selector(onSave))

    tableView.registerNib(cell: BookmarkTitleCell.self)
    tableView.registerNib(cell: MWMButtonCell.self)

    addToBookmarksManagerObserverList()
  }
    
  // MARK: - Table view data source
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    Sections.allCases.count
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch Sections(rawValue: section) {
    case .info:
      InfoSectionRows.allCases.count
    case .continue:
      switch mode {
      case .edit:
        0
      case .stopRecording:
        1
      }
    case .delete:
      1
    default:
      fatalError()
    }
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    switch Sections(rawValue: indexPath.section) {
    case .info:
      switch InfoSectionRows(rawValue: indexPath.row) {
      case .title:
        let cell = tableView.dequeueReusableCell(cell: BookmarkTitleCell.self, indexPath: indexPath)
        cell.configure(name: trackTitle ?? "", delegate: self, hint: L("placepage_track_name_hint"))
        return cell
      case .color:
        let cell = tableView.dequeueDefaultCell(for: indexPath)
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.text = L("change_color")
        cell.imageView?.image = circleImageForColor(trackColor, frameSize: 28, diameter: 22)
        return cell
      case .bookmarkGroup:
        let cell = tableView.dequeueDefaultCell(for: indexPath)
        cell.textLabel?.text = trackGroupTitle
        cell.imageView?.image = UIImage(named: "ic_folder")
        cell.imageView?.styleName = "MWMBlack";
        cell.accessoryType = .disclosureIndicator;
        return cell;
      default:
        fatalError()
      }
    case .continue:
      let cell = tableView.dequeueReusableCell(cell: MWMButtonCell.self, indexPath: indexPath)
      cell.configure(withTitle: L("continue_recording"), styleName: "BookmarksCategoryContinueButton", action: { [self] in
        close { [self] in
          switch mode {
          case .stopRecording(let configuration):
            configuration.onStopCompletion(.continue)
          default:
            fatalError("Continue is available only in stopRecording mode")
          }
        }
      })
      return cell
    case .delete:
      let cell = tableView.dequeueReusableCell(cell: MWMButtonCell.self, indexPath: indexPath)
      switch mode {
      case .edit(let configuration):
        cell.configure(withTitle: L("placepage_delete_track_button"), styleName: "BookmarksCategoryDeleteButton") { [weak self] in
          guard let self else { return }
          self.close({ self.bookmarksManager.deleteTrack(configuration.trackId) })
        }
      case .stopRecording(let configuration):
        cell.configure(withTitle: L("stop_without_saving"), styleName: "BookmarksCategoryDeleteButton") { [weak self] in
          guard let self else { return }
          self.close({ configuration.onStopCompletion(.stopWithoutSaving) })
        }
      }
      return cell
    default:
      fatalError()
    }
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    switch InfoSectionRows(rawValue: indexPath.row) {
    case .color:
      openColorPicker()
    case .bookmarkGroup:
      openGroupPicker()
    default:
      break
    }
  }
  
  // MARK: - Private

  private func updateTrackIfNeeded() {
    // TODO: Update the track content on the Edit screen instead of closing it when the track gets updated from cloud.
    if case .edit(let configuration) = mode, !bookmarksManager.hasTrack(configuration.trackId) {
      close()
    }
  }

  private func addToBookmarksManagerObserverList() {
    bookmarksManager.add(self)
  }

  private func removeFromBookmarksManagerObserverList() {
    bookmarksManager.remove(self)
  }

  @objc private func onSave() {
    view.endEditing(true)
    close { [self] in
      switch mode {
      case .edit(let configuration):
        bookmarksManager.updateTrack(configuration.trackId, setGroupId: trackGroupId, color: trackColor, title: trackTitle ?? "")
        configuration.onFinishEditingCompletion(true)
      case .stopRecording(let configuration):
        configuration.onStopCompletion(.saveWith(categoryId: trackGroupId, name: trackTitle, color: trackColor))
      }
    }
  }

  private func updateColor(_ color: UIColor) {
    trackColor = color
    tableView.reloadRows(at: [IndexPath(row: InfoSectionRows.color.rawValue, section: Sections.info.rawValue)],
                         with: .none)
  }

  @objc private func openColorPicker() {
    ColorPicker.shared.present(from: self, pickerType: .defaultColorPicker(trackColor), completionHandler: { [weak self] color in
      self?.updateColor(color)
    })
  }

  private func openGroupPicker() {
    let groupViewController = SelectBookmarkGroupViewController(groupName: trackGroupTitle ?? "", groupId: trackGroupId)
    groupViewController.delegate = self
    let navigationController = UINavigationController(rootViewController: groupViewController)
    present(navigationController, animated: true, completion: nil)
  }

  private func close(_ completion: (() -> Void)? = nil) {
    if (presentingViewController != nil) {
      dismiss(animated: true, completion: completion)
    } else {
      goBack()
      completion?()
    }
  }
}

extension EditTrackViewController: BookmarkTitleCellDelegate {
  func didFinishEditingTitle(_ title: String) {
    trackTitle = title
  }
}

// MARK: - BookmarkColorViewControllerDelegate
extension EditTrackViewController: BookmarkColorViewControllerDelegate {
  func bookmarkColorViewController(_ viewController: BookmarkColorViewController, didSelect bookmarkColor: BookmarkColor) {
    viewController.dismiss(animated: true)
    updateColor(bookmarkColor.color)
  }
}

// MARK: - SelectBookmarkGroupViewControllerDelegate
extension EditTrackViewController: SelectBookmarkGroupViewControllerDelegate {
  func bookmarkGroupViewController(_ viewController: SelectBookmarkGroupViewController,
                                   didSelect groupTitle: String,
                                   groupId: MWMMarkGroupID) {
    viewController.dismiss(animated: true)
    trackGroupTitle = groupTitle
    trackGroupId = groupId
    tableView.reloadRows(at: [IndexPath(row: InfoSectionRows.bookmarkGroup.rawValue, section: Sections.info.rawValue)],
                         with: .none)
  }
}

// MARK: - BookmarksObserver
extension EditTrackViewController: BookmarksObserver {
  func onBookmarksLoadFinished() {
    updateTrackIfNeeded()
  }

  func onBookmarksCategoryDeleted(_ groupId: MWMMarkGroupID) {
    if trackGroupId == groupId {
      close()
    }
  }
}
