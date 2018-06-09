//
//  BackwardsCompatibility.swift
//  DTTableViewManager
//
//  Created by Denys Telezhkin on 30.03.2018.
//  Copyright © 2018 Denys Telezhkin. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import UIKit
import DTModelStorage

#if swift(>=4.1)
#else
/// Extension for adding Swift 4.1 methods, to support Swift 4.0 and Swift 3.2/3.3 concurrently.
extension Sequence {
    func compactMap<ElementOfResult>(_ transform: (Self.Element) throws -> ElementOfResult?) rethrows -> [ElementOfResult] {
        return try flatMap(transform)
    }
}
#endif


extension DTTableViewManager {
#if swift(>=4.2)
    @available(*, unavailable, message: "This method was removed, please use editingStyle(forItem:,_:) instead.")
    /// Registers `closure` to be executed, when `UITableViewDelegate.tableView(_:editingStyleForRowAt:)` method is called for `cellClass`.
    open func editingStyle<T: ModelTransfer>(for cellClass:T.Type, _ closure: @escaping (T, T.ModelType, IndexPath) -> UITableViewCell.EditingStyle) where T: UITableViewCell {}
#else
    @available(*, unavailable, message: "This method was removed, please use editingStyle(forItem:,_:) instead.")
    /// Registers `closure` to be executed, when `UITableViewDelegate.tableView(_:editingStyleForRowAt:)` method is called for `cellClass`.
    open func editingStyle<T: ModelTransfer>(for cellClass:T.Type, _ closure: @escaping (T, T.ModelType, IndexPath) -> UITableViewCellEditingStyle) where T: UITableViewCell {}
#endif
    
}
