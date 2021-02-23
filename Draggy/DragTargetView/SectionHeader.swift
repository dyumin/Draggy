//
//  SectionHeader.swift
//  Draggy
//
//  Created by El D on 22.02.2021.
//

import Cocoa
import AppKit
import Foundation

class SectionHeader: NSView {

    static let Identifier = NSUserInterfaceItemIdentifier(rawValue: "SectionHeader")

    @IBOutlet weak var header: NSTextField!
    @IBOutlet weak var clear: NSButton!

    weak var dragTargetViewData: DragTargetViewData!

    var stringValue: String = "" {
        didSet {
            header!.stringValue = stringValue
        }
    }

    @IBAction func onClearPressed(_ sender: Any) {
        dragTargetViewData?.ClearRecent()
    }

    override func prepareForReuse() {
        clear.isHidden = true
    }
}
