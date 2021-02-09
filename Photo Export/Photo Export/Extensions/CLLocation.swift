//
//  CLLocation.swift
//  Photo Export
//
//  Created by Jason Barrie Morley on 09/02/2021.
//

import CoreLocation
import Foundation

extension CLLocation {

    var iso6809Representation: String {
        String(format: "%+08.4f%+09.4f/", coordinate.latitude, coordinate.longitude)
    }

}
