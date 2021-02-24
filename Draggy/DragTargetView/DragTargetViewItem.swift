//
//  DragTargetViewItem.swift
//  Draggy
//
//  Created by El D on 21.02.2021.
//

import Cocoa

class DragTargetViewItem: NSCollectionViewItem {

    @IBOutlet weak var icon: NSImageView! {
        didSet {
            icon.unregisterDraggedTypes() // https://stackoverflow.com/questions/5892464/cocoa-nsview-subview-blocking-drag-drop
        }
    }

    weak var dataSource: DragTargetViewData!

    @IBOutlet weak var removeButton: RemoveButton! {
        didSet {
            removeButton?.controller = self
        }
    }

    @IBAction func removeButtonPressed(_ sender: Any) {
        guard let app = getAppBundleUrl() else {
            return
        }
        dataSource?.clearRecent(Bundle(url: app)!, .PerType)
    }

    override var highlightState: NSCollectionViewItem.HighlightState {
        didSet {
            if (highlightState != oldValue) {
                let backgroundColor = { () -> CGColor? in
                    if #available(OSX 10.14, *) {
                        return (highlightState == .asDropTarget) ? NSColor.controlAccentColor.cgColor.copy(alpha: 0.30) : nil
                    } else {
                        return (highlightState == .asDropTarget) ? NSColor.systemBlue.cgColor.copy(alpha: 0.30) : nil
                    }
                }()

                guard self.view.layer!.backgroundColor != backgroundColor else {
                    return
                }

//                print(self, highlightState.rawValue)
                let colourAnim = CABasicAnimation(keyPath: "backgroundColor")
                colourAnim.fromValue = self.view.layer!.backgroundColor
                colourAnim.toValue = backgroundColor
                self.view.layer!.backgroundColor = backgroundColor // TODO: fails to animate in (out is ok)
                self.view.layer!.add(colourAnim, forKey: "colourAnimation")
            }
        }
    }


    @IBOutlet weak var localizedName: NSTextField!

    override func viewDidLoad() {
        view.wantsLayer = true
        view.layer!.cornerRadius = 3
        view.layer!.masksToBounds = true
    }

    var bundle: Bundle? {
        didSet {
            if let bundle = bundle {
                icon.image = NSWorkspace.shared.icon(forFile: bundle.bundlePath)

                if let bundleDisplayName = bundle.infoDictionary?["CFBundleDisplayName"] as? String {
                    localizedName.stringValue = bundleDisplayName
                } else if let bundleName = bundle.infoDictionary?[kCFBundleNameKey as String] as? String {
                    localizedName.stringValue = bundleName
                }
            }
        }
    }

    var runningApplication: NSRunningApplication? {
        didSet {
            if let runningApplication = runningApplication {
                icon.image = runningApplication.icon
                localizedName.stringValue = runningApplication.localizedName ?? ""
            }
        }
    }

    public func getAppBundleUrl() -> URL? {
        if let bundle = bundle {
            return bundle.bundleURL
        } else if let runningApplication = runningApplication {
            return runningApplication.bundleURL
        }
        return nil
    }

    override func mouseDown(with event: NSEvent) {
        if let current = DragSessionManager.shared().current {
            guard let app = getAppBundleUrl() else {
                return
            }

            if (DragTargetViewData.open([current], with: app)) {
                RecentAppsManager.shared.didOpen(current, with: Bundle(url: app)!)
                DragSessionManager.shared().closeWindow()
            }
        }
    }

    override func prepareForReuse() {
        runningApplication = nil
        bundle = nil

        self.view.layer?.backgroundColor = nil // sometimes highlightState doest work as expected, leaving highlight color (why?)
        removeButton.isHidden = true
        icon.image = nil
        localizedName.stringValue = ""
    }
}
