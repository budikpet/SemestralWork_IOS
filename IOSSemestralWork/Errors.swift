//
//  Errors.swift
//  IOSSemestralWork
//
//  Created by Petr Budík on 02/07/2019.
//  Copyright © 2019 Petr Budík. All rights reserved.
//

import Foundation

enum MyRSSFeedError: Error {
    case exists(MyRSSFeed)
}
