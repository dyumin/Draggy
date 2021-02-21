//
//  DragTargetViewItem.swift
//  Draggy
//
//  Created by El D on 21.02.2021.
//

import Cocoa

class DragTargetViewItem: NSCollectionViewItem {
    
    @IBOutlet weak var icon: NSImageView!
    @IBOutlet weak var localizedName: NSTextField!
    
    var runningApplication: NSRunningApplication?
    {
        didSet
        {
            icon.image = runningApplication?.icon
            localizedName.stringValue = runningApplication?.localizedName ?? ""
        }
    }

    // 1 false load on app start
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
//        view.registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
//        icon.registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
        
        
        
        // Do view setup here.
    }
    
    override func becomeFirstResponder() -> Bool {
        false
    }
    
    override func validateProposedFirstResponder(_ responder: NSResponder, for event: NSEvent?) -> Bool {
        false
    }
    
    func collectionView(_ collectionView: NSCollectionView, validateDrop draggingInfo: NSDraggingInfo, proposedIndexPath proposedDropIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath>, dropOperation proposedDropOperation: UnsafeMutablePointer<NSCollectionView.DropOperation>) -> NSDragOperation {
        
        proposedDropOperation.pointee = NSCollectionView.DropOperation.on
        
        return .generic
    }

    func collectionView(_ collectionView: NSCollectionView, acceptDrop draggingInfo: NSDraggingInfo, indexPath: IndexPath, dropOperation: NSCollectionView.DropOperation) -> Bool {
        return true
    }
    
    
    override func validRequestor(forSendType sendType: NSPasteboard.PasteboardType?, returnType: NSPasteboard.PasteboardType?) -> Any? {
        nil
    }
    
    override func prepareForReuse() {
        icon.image = nil
        localizedName.stringValue = ""
    }
}
