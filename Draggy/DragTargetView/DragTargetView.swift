//
//  DragTargetView.swift
//  Draggy
//
//  Created by El D on 20.02.2021.
//

import Cocoa

class DragTargetView: NSViewController {

    @IBOutlet weak var collectionView: NSCollectionView!
    let dataSource = DragTargetViewData()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dataSource = dataSource
        collectionView.delegate = dataSource
        dataSource.collectionView = collectionView

        // Do view setup here.
    }
}
