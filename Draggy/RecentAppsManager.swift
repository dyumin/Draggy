//
//  RecentAppsManager.swift
//  Draggy
//
//  Created by El D on 22.02.2021.
//

import Cocoa

private struct OpenRecord
{
    let file: String // absolute file path string
    let bundle: String // absolute bundle path string
    let time: Date
}

extension OpenRecord {
    @objc(OpenRecordClass) class OpenRecordClass: NSObject, NSCoding {
        
        let openRecord: OpenRecord
        init(openRecord: OpenRecord) {
            self.openRecord = openRecord
            
            super.init()
        }
        
        func encode(with coder: NSCoder) {
            coder.encode(openRecord.file, forKey:"file")
            coder.encode(openRecord.bundle, forKey:"bundle")
            coder.encode(openRecord.time, forKey:"time")
        }
        
        required init?(coder: NSCoder) {
            guard let file = coder.decodeObject(forKey: "file") as? String else {
                return nil
            }
            guard let bundle = coder.decodeObject(forKey: "bundle") as? String else {
                return nil
            }
            guard let time = coder.decodeObject(forKey: "time") as? Date else {
                return nil
            }
            
            openRecord = OpenRecord(file: file, bundle: bundle, time: time)
            super.init()
        }
    }
}

class RecentAppsManager
{
    public static let shared = RecentAppsManager()
    private init()
    {
        let records = (NSKeyedUnarchiver.unarchiveObject(withFile: "records") as? [OpenRecord.OpenRecordClass])?.map { $0.openRecord }
        self.records = records ?? []
        
        UserDefaults.standard.setValue(Date(), forKey: "Initial")
    }
    
    func applicationWillTerminate() {
        let codableRecords = records.map { OpenRecord.OpenRecordClass(openRecord: $0) }
        NSKeyedArchiver.archiveRootObject(codableRecords, toFile: "records")
    }
    
    deinit // TODO: not called
    {
        let codableRecords = records.map { OpenRecord.OpenRecordClass(openRecord: $0) }
        NSKeyedArchiver.archiveRootObject(codableRecords, toFile: "records")
    }
    
    private var records: [OpenRecord]
    
    func recentApps() -> [Bundle] { // TODO: optimise
        
        var uniqueRecords: [OpenRecord] = []
        for record in records
        {
            if !uniqueRecords.contains(where: { (inRecord) -> Bool in
                inRecord.bundle == record.bundle
            })
            {
                uniqueRecords.append(record)
            }
        }
        
        return uniqueRecords.map { Bundle(path: $0.bundle)! }.reversed() // todo: may fail
    }
    
    func didOpen(_ file: URL, with app: Bundle) {
        print("file.pathExtension = ", file.standardizedFileURL.absoluteString)
        records.append(OpenRecord(file: file.absoluteString, bundle: app.bundlePath, time: Date()))
        
        // TODO: remove after debug
        let codableRecords = records.map { OpenRecord.OpenRecordClass(openRecord: $0) }
        NSKeyedArchiver.archiveRootObject(codableRecords, toFile: "records")
    }
}
