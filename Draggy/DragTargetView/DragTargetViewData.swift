//
//  DragTargetViewData.swift
//  Draggy
//
//  Created by El D on 20.02.2021.
//

import Cocoa

class DragTargetViewData: NSObject, NSCollectionViewDataSource, NSCollectionViewDelegate {
    var runningApplications: [NSRunningApplication]
    var runningApplicationsObservation: NSKeyValueObservation?

    weak var collectionView: NSCollectionView! {
        didSet {
            collectionView.registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
            collectionView.reloadData()
        }
    }

    override init() {
        runningApplications = []
        super.init()
        runningApplicationsObservation = NSWorkspace.shared.observe(\.runningApplications, options: [.new, .initial, .old]) { [weak self] (workspace, keyValueObservedChange) in

            guard let self = self else {
                return
            }

            if (keyValueObservedChange.kind == .insertion) {
                self.runningApplications.insert(keyValueObservedChange.newValue!.first!, at: 0)
                self.collectionView.performBatchUpdates {

                    self.collectionView.animator().insertItems(at: [IndexPath(item: 0, section: 0)])

                } completionHandler: { animationsFinished in

                }

                return
            }

            if (keyValueObservedChange.kind == .removal) {
                let index = self.runningApplications.firstIndex(of: keyValueObservedChange.oldValue!.first!)!
                self.runningApplications.remove(at: index)

                self.collectionView.performBatchUpdates {

                    self.collectionView.animator().deleteItems(at: [IndexPath(item: index, section: 0)])

                } completionHandler: { animationsFinished in

                }

                return
            }


            if (keyValueObservedChange.kind == .setting) {
                self.runningApplications = keyValueObservedChange.newValue?.reversed() ?? []
                if let collectionView = self.collectionView {
                    collectionView.reloadData()
                }
                return
            }
        }
    }

    func collectionView(_ collectionView: NSCollectionView, validateDrop draggingInfo: NSDraggingInfo, proposedIndexPath proposedDropIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath>, dropOperation proposedDropOperation: UnsafeMutablePointer<NSCollectionView.DropOperation>) -> NSDragOperation {

        proposedDropOperation.pointee = NSCollectionView.DropOperation.on

        return .generic
    }

    func collectionView(_ collectionView: NSCollectionView, acceptDrop draggingInfo: NSDraggingInfo, indexPath: IndexPath, dropOperation: NSCollectionView.DropOperation) -> Bool {
        let targetApplication = runningApplications[indexPath.item]

//        targetApplication.bundleURL

        let pb = draggingInfo.draggingPasteboard
        let classes = [NSURL.self]
        guard let urls = pb.readObjects(forClasses: classes, options: nil) as? [URL] else {
            return false
        }

        if #available(OSX 10.15, *) {
            var error: Error?
            let dispatchGroup = DispatchGroup()
            
            dispatchGroup.enter()
            NSWorkspace.shared.open(urls, withApplicationAt: targetApplication.bundleURL!, configuration: NSWorkspace.OpenConfiguration()) { (runningApplication, inError) in
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
                try NSWorkspace.shared.open(urls, withApplicationAt: targetApplication.bundleURL!, options: [NSWorkspace.LaunchOptions.async], configuration: [:])
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

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return runningApplications.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DragTargetViewItem"), for: indexPath) as? DragTargetViewItem

        item?.runningApplication = runningApplications[indexPath.item]

        return item ?? NSCollectionViewItem()
    }
}
