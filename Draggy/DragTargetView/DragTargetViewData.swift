//
//  DragTargetViewData.swift
//  Draggy
//
//  Created by El D on 20.02.2021.
//

import Cocoa

private enum Sections: Int {
    case RecentApps = 0
    case SuggestedApps = 1
    case RunningApplications = 2
    case SectionsCount
}

class DragTargetViewData: NSObject, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout {
    var runningApplications: [NSRunningApplication]
    var runningApplicationsObservation: NSKeyValueObservation?

    var suggestedApps: [Bundle]
    var suggestedAppsObservation: NSKeyValueObservation?

    var recentlyUsedApps: [Bundle]
    var recentlyUsedAppsObservation: NSKeyValueObservation?

    weak var collectionView: NSCollectionView! {
        didSet {
            collectionView.register(NSNib(nibNamed: SectionHeader.Identifier.rawValue, bundle: nil), forSupplementaryViewOfKind: NSCollectionView.SupplementaryElementKind.init("UICollectionElementKindSectionHeader"), withIdentifier: SectionHeader.Identifier)

            collectionView.registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
            collectionView.reloadData()
        }
    }

    override init() {
        runningApplications = []
        suggestedApps = []
        recentlyUsedApps = []
        super.init()
        runningApplicationsObservation = NSWorkspace.shared.observe(\.runningApplications, options: [.new, .initial, .old]) { [weak self] (workspace, keyValueObservedChange) in

            guard let self = self else {
                return
            }

            if (keyValueObservedChange.kind == .insertion) {
                self.runningApplications.insert(keyValueObservedChange.newValue!.first!, at: 0)
                self.collectionView.performBatchUpdates {
                    self.collectionView.animator().insertItems(at: [IndexPath(item: 0, section: Sections.RunningApplications.rawValue)])
                }

                return
            }

            if (keyValueObservedChange.kind == .removal) {
                let index = self.runningApplications.firstIndex(of: keyValueObservedChange.oldValue!.first!)!
                self.runningApplications.remove(at: index)

                self.collectionView.performBatchUpdates {
                    self.collectionView.animator().deleteItems(at: [IndexPath(item: index, section: Sections.RunningApplications.rawValue)])
                }
                return
            }


            if (keyValueObservedChange.kind == .setting) {
                self.runningApplications = keyValueObservedChange.newValue?.reversed() ?? []
                if let collectionView = self.collectionView {
                    collectionView.reloadSections([Sections.RunningApplications.rawValue])
                }
                return
            }
        }

        // async because of dispatch_once reenter
        DispatchQueue.main.async {
            self.suggestedAppsObservation = DragSessionManager.shared.observe(\.current, options: [.new]) { [weak self] (dragSessionManager, keyValueObservedChange) in
                // clear previous recent apps
//                self?.recentlyUsedApps = []
//                self?.collectionView.reloadSections([Sections.RecentApps.rawValue])
                if let newValueOptional = keyValueObservedChange.newValue, let newValue = newValueOptional /* wtf swift */ {
                    DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive).async {
                        guard let self = self else {
                            return
                        }

                        let suggestedApps = LSCopyApplicationURLsForURL(newValue as CFURL, LSRolesMask.all)?.takeRetainedValue() as? [URL] // TODO: what if drop file already changed and another request already finished?

                        DispatchQueue.main.async {
                            self.suggestedApps.removeAll()
                            if let suggestedApps = suggestedApps {
                                for url in suggestedApps {
                                    self.suggestedApps.append(Bundle(url: url)!)
                                }
                            }
                            self.collectionView.reloadSections([Sections.SuggestedApps.rawValue])
                        }
                    }

                    DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive).async {
                        let recentApps = RecentAppsManager.shared.recentApps(for: newValue, .PerType)
                        DispatchQueue.main.async {
                            guard let self = self else {
                                return
                            }
                            self.recentlyUsedApps = recentApps // TODO: what if drop file already changed
                            self.collectionView.reloadSections([Sections.RecentApps.rawValue])
                        }
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

        guard let targetApplication = { () -> URL? in
            if (indexPath.section == Sections.RecentApps.rawValue) {
                return indexPath.item < recentlyUsedApps.count ? recentlyUsedApps[indexPath.item].bundleURL : nil // sometimes collectionView accepts drops on nonexistent items at the end if items count just changed and numberOfItemsInSection already returned new value
            } else if (indexPath.section == Sections.SuggestedApps.rawValue) {
                return indexPath.item < suggestedApps.count ? suggestedApps[indexPath.item].bundleURL : nil // sometimes collectionView accepts drops on nonexistent items at the end if items count just changed and numberOfItemsInSection already returned new value
            } else if (indexPath.section == Sections.RunningApplications.rawValue) {
                return indexPath.item < runningApplications.count ? runningApplications[indexPath.item].bundleURL! : nil // sometimes collectionView accepts drops on nonexistent items at the end if items count just changed and numberOfItemsInSection already returned new value
            }
            return nil
        }() else {

            return false
        }

        let pb = draggingInfo.draggingPasteboard
        let classes = [NSURL.self]
        guard let urls = pb.readObjects(forClasses: classes, options: nil) as? [URL] else {
            return false
        }

        RecentAppsManager.shared.didOpen(urls.first!, with: Bundle(url: targetApplication)!)
        DispatchQueue.main.async {
            collectionView.reloadSections([Sections.RecentApps.rawValue]) // todo: do it better
        }

        let result = DragTargetViewData.open(urls, with: targetApplication)
        if (result) {
            DragSessionManager.shared.closeWindow()
        }

        return result
    }

    @discardableResult
    public class func open(_ urls: [URL], with application: URL) -> Bool {
        if #available(OSX 10.15, *) {
            var error: Error?
            let dispatchGroup = DispatchGroup()

            dispatchGroup.enter()
            NSWorkspace.shared.open(urls, withApplicationAt: application, configuration: NSWorkspace.OpenConfiguration()) { (runningApplication, inError) in
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
                try NSWorkspace.shared.open(urls, withApplicationAt: application, options: [NSWorkspace.LaunchOptions.async], configuration: [:])
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

    func ClearRecent() {
        if let current = DragSessionManager.shared.current {
            RecentAppsManager.shared.clearRecent(for: current, .PerType)
            recentlyUsedApps = []
            collectionView.reloadSections([Sections.RecentApps.rawValue])
        }
    }

    func clearRecent(_ app: Bundle, _ type: RecentType) {
        if let current = DragSessionManager.shared.current {
            RecentAppsManager.shared.clearRecent(app, for: current, .PerType)
            let index = recentlyUsedApps.firstIndex(of: app)!
            recentlyUsedApps.remove(at: index)
            collectionView.performBatchUpdates {
                collectionView.animator().deleteItems(at: [IndexPath(item: index, section: Sections.RecentApps.rawValue)])
            }
        }
    }

    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        Sections.SectionsCount.rawValue
    }

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {

        if (section == Sections.RecentApps.rawValue) {
            return recentlyUsedApps.count
        } else if (section == Sections.SuggestedApps.rawValue) {
            return suggestedApps.count
        } else if (section == Sections.RunningApplications.rawValue) {
            return runningApplications.count
        }

        return 0
    }

    func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) -> NSView {

        let headerView = collectionView.makeSupplementaryView(ofKind: kind, withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SectionHeader"), for: indexPath) as! SectionHeader

        if (indexPath.section == Sections.RecentApps.rawValue) {
            headerView.stringValue = NSLocalizedString("recent_apps_section_header_title", comment: "")
            headerView.clear.isHidden = false
            headerView.clear.title = NSLocalizedString("recent_apps_section_header_clear_button_title", comment: "")
            headerView.dragTargetViewData = self
        } else if (indexPath.section == Sections.SuggestedApps.rawValue) {
            headerView.stringValue = NSLocalizedString("suggested_apps_section_header_title", comment: "")

        } else if (indexPath.section == Sections.RunningApplications.rawValue) {
            headerView.stringValue = NSLocalizedString("running_applications_section_header_title", comment: "")
        }

        return headerView
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DragTargetViewItem"), for: indexPath) as? DragTargetViewItem

        if (indexPath.section == Sections.RecentApps.rawValue) {
            item?.bundle = recentlyUsedApps[indexPath.item]
            item?.removeButton.isHidden = false
            item?.dataSource = self
        } else if (indexPath.section == Sections.SuggestedApps.rawValue) {
            item?.bundle = suggestedApps[indexPath.item]

        } else if (indexPath.section == Sections.RunningApplications.rawValue) {
            item?.runningApplication = runningApplications[indexPath.item]
        }

        return item ?? NSCollectionViewItem()
    }

    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> NSSize {
        NSSize(width: collectionView.frame.size.width, height: 15)
    }
}
