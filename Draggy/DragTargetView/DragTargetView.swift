//
//  DragTargetView.swift
//  Draggy
//
//  Created by El D on 20.02.2021.
//

import Cocoa
import LaunchAtLogin

class DragTargetView: NSViewController {

    @IBOutlet weak var collectionView: NSCollectionView!
    let dataSource = DragTargetViewData()

    var _menu: NSMenu? = nil
    override var menu: NSMenu? {
        set {
            _menu = newValue
            if let autostartItem = _menu?.item(withTag: 0) {
                autostartItem.state = LaunchAtLogin.isEnabled ? .on : .off
                autostartItem.title = NSLocalizedString("menu_autostart", comment: "")
            }

            if let exitItem = _menu?.item(withTag: 1) {
                exitItem.title = NSLocalizedString("menu_exit", comment: "")
            }
        }
        get {
            _menu
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.dataSource = dataSource
        collectionView.delegate = dataSource
        dataSource.collectionView = collectionView

        // Do view setup here.
    }

    @objc func onMenuButtonPressed() {
        menu?.popUp(positioning: nil, at: App.shared.currentEvent!.locationInWindow, in: self.view)
    }

    @IBAction func onExitPressed(_ sender: Any) {
        App.shared.terminate(sender)
    }

    @IBAction func onAutostartPressed(_ sender: NSMenuItem) {
        LaunchAtLogin.isEnabled = (sender.state == .off)
        sender.state = LaunchAtLogin.isEnabled ? .on : .off
    }
}
