//
//  RemoveButton.swift
//  Draggy
//
//  Created by El D on 24.02.2021.
//

import Cocoa

class RemoveButton: NSButton {

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.isEnabled = false
        self.wantsLayer = true
        self.layer!.opacity = 0

        self.unregisterDraggedTypes()

        let labelTrackingArea = NSTrackingArea(rect: self.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.cursorUpdate, NSTrackingArea.Options.activeInKeyWindow], owner: self, userInfo: nil)
        self.addTrackingArea(labelTrackingArea)
    }

    weak var controller: DragTargetViewItem!

    override func mouseEntered(with event: NSEvent) {
        guard !isHidden else { // generally mouse events arent sent anyway if hidden
            return
        }

        if (!DragSessionManager.shared().willCloseWindow && controller?.highlightState != .asDropTarget) {
            self.isEnabled = true
            self.layer!.opacity = 1
        }
    }

    override func mouseExited(with event: NSEvent) {
        guard !isHidden else { // generally mouse events arent sent anyway if hidden
            return
        }
        self.isEnabled = false
        self.layer!.opacity = 0
    }
}
