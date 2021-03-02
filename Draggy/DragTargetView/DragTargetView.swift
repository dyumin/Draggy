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

    // AppKit Release Notes for macOS Big Sur 11
    // https://developer.apple.com/documentation/macos-release-notes/appkit-release-notes-for-macos-11
    // NSScrollView
    //  When linked on macOS Big Sur 11 or later, an NSScrollView with automaticallyAdjustsContentInsets set to true will continue to respect the safe-area insets of the window even when titlebarAppearsTransparent is set to true. For apps linked earlier than macOS Big Sur 11 NSScrollView will ignore the automatic insets when titlebarAppearsTransparent is set to true.
    @IBOutlet weak var collectionViewScrollView: NSScrollView!
    {
        didSet
        {
            collectionViewScrollView.automaticallyAdjustsContentInsets = false
            if let zoomButtonYOrigin = HudWindow.shared.hudWindow.standardWindowButton(NSWindow.ButtonType.zoomButton)?.frame.origin.y {
                collectionViewScrollView.contentInsets.top = zoomButtonYOrigin
            }
        }
    }
    
    
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
