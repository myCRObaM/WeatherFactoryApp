//
//  ChangeLocationBasedOnSelection.swift
//  WheatherAppFactory
//
//  Created by Matej Hetzel on 12/09/2019.
//  Copyright © 2019 Matej Hetzel. All rights reserved.
//

import Foundation
protocol ChangeLocationBasedOnSelection {
    func didSelectLocation(long: Double, lat: Double, location: String)
}
