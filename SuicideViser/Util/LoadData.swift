//
//  LoadJSON.swift
//  SuicideViser
//
//  Created by Choi Wai Lap on 23/3/2024.
//

import Foundation
import SwiftyJSON

func parseJSON(for filename: String) -> JSON? {
    if let bundlePath = Bundle.main.path(forResource: filename, ofType: "json"),
       let jsonData: Data = try? String(contentsOfFile: bundlePath).data(using: .utf8),
       let json: JSON = try? JSON(data: jsonData) {
        return json
    }
    return nil
}

func parseCSV(for filename: String) -> [String] {
    guard let filepath = Bundle.main.path(forResource: filename, ofType: "csv") else {
        fatalError()
    }
    guard let data = try? String(contentsOfFile: filepath) else {
        fatalError()
    }
    var rows = data.components(separatedBy: "\n")
    rows.removeFirst()
    return rows.filter({ !$0.isEmpty })
}
