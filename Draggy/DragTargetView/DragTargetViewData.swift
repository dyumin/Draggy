//
//  DragTargetViewData.swift
//  Draggy
//
//  Created by El D on 20.02.2021.
//

import Cocoa

private enum Sections: Int {
    case SuggestedApps = 0
    case RunningApplications = 1
    case SectionsCount
}

class DragTargetViewData: NSObject, NSCollectionViewDataSource, NSCollectionViewDelegate {
    var runningApplications: [NSRunningApplication]
    var runningApplicationsObservation: NSKeyValueObservation?

    var suggestedApps: [Bundle]
    var suggestedAppsObservation: NSKeyValueObservation?

    weak var collectionView: NSCollectionView! {
        didSet {
            collectionView.registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
            collectionView.reloadData()
        }
    }

    override init() {
        runningApplications = []
        suggestedApps = []
        super.init()
        runningApplicationsObservation = NSWorkspace.shared.observe(\.runningApplications, options: [.new, .initial, .old]) { [weak self] (workspace, keyValueObservedChange) in

            guard let self = self else {
                return
            }

            if (keyValueObservedChange.kind == .insertion) {
                self.runningApplications.insert(keyValueObservedChange.newValue!.first!, at: 0)
                self.collectionView.performBatchUpdates {

                    self.collectionView.animator().insertItems(at: [IndexPath(item: 0, section: Sections.RunningApplications.rawValue)])

                } completionHandler: { animationsFinished in

                }

                return
            }

            if (keyValueObservedChange.kind == .removal) {
                let index = self.runningApplications.firstIndex(of: keyValueObservedChange.oldValue!.first!)!
                self.runningApplications.remove(at: index)

                self.collectionView.performBatchUpdates {

                    self.collectionView.animator().deleteItems(at: [IndexPath(item: index, section: Sections.RunningApplications.rawValue)])

                } completionHandler: { animationsFinished in

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
            self.suggestedAppsObservation = DragSessionManager.shared().observe(\.current, options: [.new]) { [weak self] (dragSessionManager, keyValueObservedChange) in
                if let newValue = keyValueObservedChange.newValue {
                    DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive).async {
                        guard let self = self else {
                            return
                        }

                        let suggestedApps = LSCopyApplicationURLsForURL(newValue as CFURL, LSRolesMask.all)
                        self.suggestedApps.removeAll(keepingCapacity: true)

                        for url in suggestedApps!.takeUnretainedValue() as! [URL] {
                            self.suggestedApps.append(Bundle(url: url)!)
                        }

                        DispatchQueue.main.async {
                            self.collectionView.reloadSections([Sections.SuggestedApps.rawValue])
                        }
                    }
                }
            }
        }
    }

    func collectionView(_ collectionView: NSCollectionView, validateDrop draggingInfo: NSDraggingInfo, proposedIndexPath proposedDropIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath>, dropOperation proposedDropOperation: UnsafeMutablePointer<NSCollectionView.DropOperation>) -> NSDragOperation {

        proposedDropOperation.pointee = NSCollectionView.DropOperation.on

        return .generic
    }

    func collectionView(_ collectionView: NSCollectionView, acceptDrop draggingInfo: NSDraggingInfo, indexPath: IndexPath, dropOperation: NSCollectionView.DropOperation) -> Bool {

        guard let targetApplication = { () -> URL? in
            if (indexPath.section == Sections.SuggestedApps.rawValue) {
                return suggestedApps[indexPath.item].bundleURL
            } else if (indexPath.section == Sections.RunningApplications.rawValue) {
                return runningApplications[indexPath.item].bundleURL!
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

        if #available(OSX 10.15, *) {
            var error: Error?
            let dispatchGroup = DispatchGroup()

            dispatchGroup.enter()
            NSWorkspace.shared.open(urls, withApplicationAt: targetApplication, configuration: NSWorkspace.OpenConfiguration()) { (runningApplication, inError) in
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

            if (error != nil) {
                return false
            }
        } else {
            do {
                try NSWorkspace.shared.open(urls, withApplicationAt: targetApplication, options: [NSWorkspace.LaunchOptions.async], configuration: [:])
            } catch {
                DispatchQueue.main.async {
                    let alert = NSAlert.init(error: error)
                    alert.runModal()
                }
                return false
            }
        }

        return true
    }

    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        Sections.SectionsCount.rawValue
    }

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {

        if (section == Sections.SuggestedApps.rawValue) {
            return suggestedApps.count
        } else if (section == Sections.RunningApplications.rawValue) {
            return runningApplications.count
        }

        return 0
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DragTargetViewItem"), for: indexPath) as? DragTargetViewItem

        if (indexPath.section == Sections.SuggestedApps.rawValue) {
            item?.bundle = suggestedApps[indexPath.item]

            return item ?? NSCollectionViewItem()
        }

        if (indexPath.section == Sections.RunningApplications.rawValue) {
            item?.runningApplication = runningApplications[indexPath.item]

            return item ?? NSCollectionViewItem()
        }

        return NSCollectionViewItem()
    }
}
