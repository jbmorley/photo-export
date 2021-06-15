//
//  PhotoLibrary.swift
//  Photo Export
//
//  Created by Jason Barrie Morley on 02/02/2021.
//

import Combine
import Foundation
import SQLite3

let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)


enum PhotoLibraryError: Error {
    case notFound
    case sqlError(message: String)
}

class PhotoLibrary {

    let url: URL

    init(url: URL) {
        // TODO: Check that the schema version is supported.
        self.url = url.appendingPathComponent("database/Photos.sqlite")
    }

    func metadata(for id: String) throws -> Metadata {

        guard FileManager.default.fileExists(atPath: self.url.path) else {
            throw PhotoLibraryError.notFound
        }

        var db: OpaquePointer?
        guard sqlite3_open(url.path, &db) == SQLITE_OK else {
            print("error opening database")
            let errorMessage = String(cString: sqlite3_errmsg(db)!)
            sqlite3_close(db)
            db = nil
            throw PhotoLibraryError.sqlError(message: errorMessage)
        }

        defer {
            print("closing the database")
            if sqlite3_close(db) != SQLITE_OK {
                print("error closing database")
            }
            db = nil
        }

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, """
            SELECT
                *
            FROM
                ZASSET
                JOIN
                    ZADDITIONALASSETATTRIBUTES
                ON ZADDITIONALASSETATTRIBUTES.ZASSET = ZASSET.Z_PK
                LEFT OUTER JOIN
                    ZASSETDESCRIPTION
                ON
                   ZADDITIONALASSETATTRIBUTES.ZASSETDESCRIPTION = ZASSETDESCRIPTION.Z_PK
            WHERE
                ZUUID = ?
""", -1, &statement, nil) != SQLITE_OK {
            let errorMessage = String(cString: sqlite3_errmsg(db)!)
            throw PhotoLibraryError.sqlError(message: errorMessage)
        }

        if sqlite3_bind_text(statement, 1, id, -1, SQLITE_TRANSIENT) != SQLITE_OK {
            let errorMessage = String(cString: sqlite3_errmsg(db)!)
            throw PhotoLibraryError.sqlError(message: errorMessage)
        }

        defer {
            print("finalizing the statement")
            if sqlite3_finalize(statement) != SQLITE_OK {
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                print("error finalizing prepared statement: \(errmsg)")
            }
            statement = nil
        }

        // TODO: This expects just one row, so we should be able to guard this better
        var row: [String: String] = [:]
        while sqlite3_step(statement) == SQLITE_ROW {
            for i in 0..<sqlite3_column_count(statement) {
                if let columnTableName = sqlite3_column_table_name(statement, i),
                   let columnName = sqlite3_column_name(statement, i),
                   let value = sqlite3_column_text(statement, i) {
                    row["\(String(cString: columnTableName)).\(String(cString: columnName))"] = String(cString: value)
                }
            }
        }

        return Metadata(title: row["ZADDITIONALASSETATTRIBUTES.ZTITLE"],
                        caption: row["ZASSETDESCRIPTION.ZLONGDESCRIPTION"],
                        timeZone: row["ZADDITIONALASSETATTRIBUTES.ZTIMEZONENAME"])
    }

}
