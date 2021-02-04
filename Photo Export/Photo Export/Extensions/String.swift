//
//  String.swift
//  Photo Export
//
//  Created by Jason Barrie Morley on 04/02/2021.
//

import Foundation

extension String {

    var pathExtension: String { (self as NSString).pathExtension }
    var deletingPathExtension: String { (self as NSString).deletingPathExtension }

}
