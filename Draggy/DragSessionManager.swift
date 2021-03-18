//
//  DragSessionManager.swift
//  Draggy
//
//  Created by El D on 15.03.2021.
//

import Foundation

enum PasteboardItem {
    case empty
    case file(URL) // URL.isFileURL == true
    case url(URL) // URL.isFileURL == false
}

open class DragSessionManager : _DragSessionManagerImpl
{
    private override init() {
        super.init()
    }
    
    @objc static let shared = DragSessionManager()
    
    var currentPasteboardItem = PasteboardItem.empty
    @objc internal func setPasteboardItem(_ item: URL, with type:PasteboardItemType)
    {
        switch type {
        case .FileURL:
            assert(item.isFileURL)
            currentPasteboardItem = .file(item)
        case .URL:
            assert(!item.isFileURL)
            currentPasteboardItem = .url(item)
        @unknown default:
            fatalError()
        }
    }
}
