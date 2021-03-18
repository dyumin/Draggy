//
//  DragTargetViewData.swift
//  Draggy
//
//  Created by El D on 20.02.2021.
//

import Cocoa

private enum Sections: Int, Comparable {
    static func <(lhs: Sections, rhs: Sections) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    case RecentApps
    case SuggestedApps
    case RunningApplications
    case Youtube
}

class DragTargetViewData: NSObject, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout {
    private var runningApplications: [NSRunningApplication]
    private var runningApplicationsObservation: NSKeyValueObservation?

    private var suggestedApps: [Bundle]
    private var suggestedAppsObservation: NSKeyValueObservation?

    private var recentlyUsedApps: [SimpleBundle]
    private var recentlyUsedAppsObservation: NSKeyValueObservation?

    private var sections: OrderedSet<Sections>

    var currentPasteboardItem = PasteboardItem.empty

    weak var collectionView: NSCollectionView! {
        didSet {
            collectionView.register(NSNib(nibNamed: SectionHeader.Identifier.rawValue, bundle: nil), forSupplementaryViewOfKind: NSCollectionView.SupplementaryElementKind.init("UICollectionElementKindSectionHeader"), withIdentifier: SectionHeader.Identifier)

            collectionView.registerForDraggedTypes([.fileURL, .string])
            collectionView.reloadData()
        }
    }

    override init() {
        runningApplications = []
        suggestedApps = []
        recentlyUsedApps = []
        sections = []
        super.init()
        runningApplicationsObservation = NSWorkspace.shared.observe(\.runningApplications, options: [.new, .initial, .old]) { [weak self] (workspace, keyValueObservedChange) in

            guard let self = self else {
                return
            }

            if (keyValueObservedChange.kind == .insertion) {
                self.runningApplications.insert(keyValueObservedChange.newValue!.first!, at: 0)
                if let runningApplications = self.sections.firstIndex(of: .RunningApplications) {
                    self.collectionView.performBatchUpdates {
                        self.collectionView.animator().insertItems(at: [IndexPath(item: 0, section: runningApplications)])
                    }
                }

                return
            }

            if (keyValueObservedChange.kind == .removal) {
                let index = self.runningApplications.firstIndex(of: keyValueObservedChange.oldValue!.first!)!
                self.runningApplications.remove(at: index)
                if let runningApplications = self.sections.firstIndex(of: .RunningApplications) {
                    self.collectionView.performBatchUpdates {
                        self.collectionView.animator().deleteItems(at: [IndexPath(item: index, section: runningApplications)])
                    }
                }
                return
            }


            if (keyValueObservedChange.kind == .setting) {
                self.runningApplications = keyValueObservedChange.newValue?.reversed() ?? []
                if let collectionView = self.collectionView, let runningApplications = self.sections.firstIndex(of: .RunningApplications) {
                    collectionView.reloadSections([runningApplications])
                }
                return
            }
        }

        suggestedAppsObservation = DragSessionManager.shared.observe(\.currentPasteboardURL, options: [.new]) { [weak self] (dragSessionManager, _) in

            guard let self = self else {
                return
            }

            self.currentPasteboardItem = dragSessionManager.currentPasteboardItem

            switch (dragSessionManager.currentPasteboardItem) {
            case .file(let url):
                self.onFileDragged(url)
            case .empty:
                return
            case .url(let url):
                self.onURLDragged(url)
            }
        }
    }
    
    private func onURLDragged(_ url: URL) {
        sections = [.Youtube]
        collectionView.reloadData()
    }

    private func onFileDragged(_ file: URL) {
        let (sectionsToRemove, insertRunningApplications) = { () -> (IndexSet, Bool) in
            var insertRunningApplications = true
            var indexSet = IndexSet()
            var i = 0
            for section in self.sections {
                if section != .RunningApplications {
                    indexSet.insert(i)
                } else {
                    insertRunningApplications = false
                }
                i += 1
            }
            return (indexSet, insertRunningApplications)
        }()

        sections = [.RunningApplications]
        collectionView.performBatchUpdates {
            collectionView.animator().deleteSections(sectionsToRemove)
            if insertRunningApplications {
                collectionView.animator().insertSections([sections.firstIndex(of: .RunningApplications)!])
            }
        }

        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
            let recentApps = RecentAppsManager.shared.recentApps(for: file, .PerType)
            if !recentApps.isEmpty {
                DispatchQueue.main.async { [self] in
                    recentlyUsedApps = recentApps // TODO: what if drop file already changed
                    collectionView.insertSections([sections.append(.RecentApps)])
                }
            }
        }

        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
            // binds symbols on first call
            let suggestedApps = LSCopyApplicationURLsForURL(file as CFURL, LSRolesMask.all)?.takeRetainedValue() as? [URL] // TODO: what if drop file already changed and another request already finished?
            if let suggestedAppsURLs = suggestedApps {
                var suggestedApps = [Bundle]()
                for url in suggestedAppsURLs {
                    if let bundle = Bundle(url: url) { // May fail if bundle isnt accessible (sandbox for example)
                        // Todo: display as simple path
                        // Fun fact: you can still get this bundle from NSWorkspace.shared.runningApplications if it is running
                        suggestedApps.append(bundle)
                    }
                }

                if !suggestedApps.isEmpty {
                    DispatchQueue.main.async {
                        self.suggestedApps = suggestedApps
                        self.collectionView.insertSections([self.sections.append(.SuggestedApps)])
                    }
                }
            }
        }
    }

    func collectionView(_ collectionView: NSCollectionView, validateDrop draggingInfo: NSDraggingInfo, proposedIndexPath proposedDropIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath>, dropOperation proposedDropOperation: UnsafeMutablePointer<NSCollectionView.DropOperation>) -> NSDragOperation {

        if (draggingInfo.draggingPasteboard.pasteboardItems?.count != 1) { // multiple items support currently disabled
            return [] // NSDragOperationNone
        }

        proposedDropOperation.pointee = NSCollectionView.DropOperation.on

        return .generic
    }

    func collectionView(_ collectionView: NSCollectionView, acceptDrop draggingInfo: NSDraggingInfo, indexPath: IndexPath, dropOperation: NSCollectionView.DropOperation) -> Bool {

        switch sections[indexPath.section] {
        case .RecentApps, .SuggestedApps, .RunningApplications: do {
            guard let targetApplicationUrl = { () -> URL? in
                guard sections.count > indexPath.section else { // collectionView accepts drops on hidden sections
                    return nil
                }
                switch sections[indexPath.section] {
                case .RecentApps:
                    return indexPath.item < recentlyUsedApps.count ? recentlyUsedApps[indexPath.item].bundleURL : nil // sometimes collectionView accepts drops on nonexistent items at the end if items count just changed and numberOfItemsInSection already returned new value
                case .SuggestedApps:
                    return indexPath.item < suggestedApps.count ? suggestedApps[indexPath.item].bundleURL : nil // sometimes collectionView accepts drops on nonexistent items at the end if items count just changed and numberOfItemsInSection already returned new value
                case .RunningApplications:
                    return indexPath.item < runningApplications.count ? runningApplications[indexPath.item].bundleURL! : nil // sometimes collectionView accepts drops on nonexistent items at the end if items count just changed and numberOfItemsInSection already returned new value
                default:
                    fatalError()
                }
            }() else {
                return false
            }
            let targetApplication = SimpleBundle(targetApplicationUrl)

            guard case .file(let url) = currentPasteboardItem else {
                return false
            }

            RecentAppsManager.shared.didOpen(url, with: targetApplication)

            let result = DragTargetViewData.open([url], with: targetApplication)
            if (result) {
                DragSessionManager.shared.closeWindow()
            }

            return result
        }
        case .Youtube:
            guard case .url(let url) = currentPasteboardItem else {
                return false
            }
            DragSessionManager.shared.closeWindow()
            Youtube.shared.download(url)
            return true
        }
    }

    @discardableResult
    public class func open(_ urls: [URL], with application: SimpleBundle) -> Bool {
        if #available(OSX 10.15, *) {
            var error: Error?
            let dispatchGroup = DispatchGroup()

            dispatchGroup.enter()
            NSWorkspace.shared.open(urls, withApplicationAt: application.bundleURL, configuration: NSWorkspace.OpenConfiguration()) { (runningApplication, inError) in
                /* Queue : com.apple.launchservices.open-queue (serial), non-main */

                if let inError = inError {
                    error = inError
                    dispatchGroup.leave()
                    DispatchQueue.main.async {
                        let alert = NSAlert.init(error: inError)
                        alert.runModal()
                    }
                    return
                }

                dispatchGroup.leave()
            }

            dispatchGroup.wait()

            if (error == nil) {
                return true
            }
        } else {
            do {
                try NSWorkspace.shared.open(urls, withApplicationAt: application.bundleURL, options: [NSWorkspace.LaunchOptions.async], configuration: [:])
                return true
            } catch {
                DispatchQueue.main.async {
                    let alert = NSAlert.init(error: error)
                    alert.runModal()
                }
                return false
            }
        }

        return false
    }

    public func ClearRecent() {
        if case .file(let current) = DragSessionManager.shared.currentPasteboardItem {
            RecentAppsManager.shared.clearRecent(for: current, .PerType)
            recentlyUsedApps = []
            collectionView.reloadSections([sections.firstIndex(of: .RecentApps)!])
        }
    }

    public func clearRecent(_ app: SimpleBundle, _ type: RecentType) {
        if case .file(let current) = DragSessionManager.shared.currentPasteboardItem {
            RecentAppsManager.shared.clearRecent(app, for: current, .PerType)
            let index = recentlyUsedApps.firstIndex(of: app)!
            recentlyUsedApps.remove(at: index)
            collectionView.performBatchUpdates {
                collectionView.animator().deleteItems(at: [IndexPath(item: index, section: sections.firstIndex(of: .RecentApps)!)])
            }
        }
    }

    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        sections.count
    }

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        switch sections[section] {
        case .RecentApps:
            return recentlyUsedApps.count
        case .SuggestedApps:
            return suggestedApps.count
        case .RunningApplications:
            return runningApplications.count
        case .Youtube:
            return 1
        }
    }

    func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) -> NSView {

        let headerView = collectionView.makeSupplementaryView(ofKind: kind, withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SectionHeader"), for: indexPath) as! SectionHeader

        switch sections[indexPath.section] {
        case .RecentApps:
            headerView.stringValue = NSLocalizedString("recent_apps_section_header_title", comment: "")
            headerView.clear.isHidden = false
            headerView.clear.title = NSLocalizedString("recent_apps_section_header_clear_button_title", comment: "")
            headerView.dragTargetViewData = self
        case .SuggestedApps:
            headerView.stringValue = NSLocalizedString("suggested_apps_section_header_title", comment: "")
        case .RunningApplications:
            headerView.stringValue = NSLocalizedString("running_applications_section_header_title", comment: "")
        case .Youtube:
            headerView.stringValue = NSLocalizedString("youtube_section_header_title", comment: "")
        }

        return headerView
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        switch sections[indexPath.section] {
        case .RecentApps:
            let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DragTargetViewItem"), for: indexPath) as! DragTargetViewItem
            item.bundle = recentlyUsedApps[indexPath.item]
            item.removeButton.isHidden = false
            item.dataSource = self
            return item
        case .SuggestedApps:
            let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DragTargetViewItem"), for: indexPath) as! DragTargetViewItem
            item.bundle = SimpleBundle(suggestedApps[indexPath.item])
            return item
        case .RunningApplications:
            let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DragTargetViewItem"), for: indexPath) as! DragTargetViewItem
            item.runningApplication = runningApplications[indexPath.item]
            return item
        case .Youtube:
            let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DownloadView"), for: indexPath) as! DownloadView
            return item
        }
    }

    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> NSSize {
        NSSize(width: collectionView.frame.size.width, height: 15)
    }
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        switch sections[indexPath.section] {
        case .RecentApps, .SuggestedApps, .RunningApplications, .Youtube:
            return NSSize.init(width: 125, height: 125)
        }
    }
}
