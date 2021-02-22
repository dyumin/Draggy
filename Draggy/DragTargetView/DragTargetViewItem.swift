//
//  DragTargetViewItem.swift
//  Draggy
//
//  Created by El D on 21.02.2021.
//

import Cocoa

class DragTargetViewItem: NSCollectionViewItem {
    
    @IBOutlet weak var icon: NSImageView!
    {
        didSet
        {
            icon.unregisterDraggedTypes() // https://stackoverflow.com/questions/5892464/cocoa-nsview-subview-blocking-drag-drop
        }
    }

    override var highlightState: NSCollectionViewItem.HighlightState
    {
        didSet
        {
            if (highlightState != oldValue)
            {
                let backgroundColor = { () ->  CGColor? in
                if #available(OSX 10.14, *) {
                    return (highlightState == .asDropTarget) ? NSColor.controlAccentColor.cgColor.copy(alpha: 0.30) : nil
                } else {
                    return (highlightState == .asDropTarget) ? NSColor.systemBlue.cgColor.copy(alpha: 0.30) : nil
                } }()
            
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
    
    var bundle: Bundle?
    {
        didSet
        {
            if let bundle = bundle
            {
                icon.image = NSWorkspace.shared.icon(forFile: bundle.bundlePath)

                if let bundleDisplayName = bundle.infoDictionary?["CFBundleDisplayName"] as? String
                {
                    localizedName.stringValue = bundleDisplayName
                } else if let bundleName = bundle.infoDictionary?[kCFBundleNameKey as String] as? String
                {
                    localizedName.stringValue = bundleName
                }
            }
            else
            {
                prepareForReuse()
            }
        }
    }
    
    var runningApplication: NSRunningApplication?
    {
        didSet
        {
            if let runningApplication = runningApplication
            {
                icon.image = runningApplication.icon
                localizedName.stringValue = runningApplication.localizedName ?? ""
            }
            else
            {
                prepareForReuse()
            }
        }
    }

    override func prepareForReuse() {
        icon.image = nil
        localizedName.stringValue = ""
    }
}
