//
//  ProgressView.swift
//  Draggy
//
//  Created by El D on 16.03.2021.
//

import Cocoa

class DownloadView: NSCollectionViewItem {


    @IBOutlet weak var icon: NSImageView! {
        didSet {
            icon.unregisterDraggedTypes() // https://stackoverflow.com/questions/5892464/cocoa-nsview-subview-blocking-drag-drop
        }
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

                guard view.layer!.backgroundColor != backgroundColor else {
                    return
                }

//                print(self, highlightState.rawValue)
                let colourAnim = CABasicAnimation(keyPath: "backgroundColor")
                colourAnim.fromValue = view.layer!.backgroundColor
                colourAnim.toValue = backgroundColor
                view.layer!.backgroundColor = backgroundColor // TODO: fails to animate in (out is ok)
                view.layer!.add(colourAnim, forKey: "colourAnimation")
            }
        }
    }
    
    override func viewDidLoad() {
        view.wantsLayer = true
        view.layer!.cornerRadius = 3
        view.layer!.masksToBounds = true
    }
    
    override func prepareForReuse() {
        view.layer?.backgroundColor = nil // sometimes highlightState doest work as expected, leaving highlight color (why?) // copied from DragTargetViewItem
    }
}
