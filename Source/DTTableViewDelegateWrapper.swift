//
//  File.swift
//  DTTableViewManager
//
//  Created by Denys Telezhkin on 13.08.17.
//  Copyright © 2017 Denys Telezhkin. All rights reserved.
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

import UIKit
import DTModelStorage

open class DTTableViewDelegateWrapper : NSObject {
    weak var delegate: AnyObject?
    weak var tableView: UITableView? { return manager.tableView }
    var viewFactory: TableViewFactory { return manager.viewFactory }
    var storage: Storage { return manager.storage }
    var configuration: TableViewConfiguration { return manager.configuration }
    var viewFactoryErrorHandler: ((DTTableViewFactoryError) -> Void)? { return manager.viewFactoryErrorHandler }
    private unowned let manager: DTTableViewManager
    
    init(delegate: AnyObject?, tableViewManager: DTTableViewManager) {
        self.delegate = delegate
        manager = tableViewManager
    }
    
    /// Array of `UITableViewDataSource` reactions for `DTTableViewDataSource`
    /// - SeeAlso: `EventReaction`.
    final var tableViewEventReactions = ContiguousArray<EventReaction>()  {
        didSet {
            delegateWasReset()
        }
    }
    
    func delegateWasReset() {
        // Subclasses need to override this method, resetting `UITableView` delegate or datasource.
        // Resetting delegate is needed, because UITableView caches results of `respondsToSelector` call, and never calls it again until `setDelegate` method is called.
        // We force UITableView to flush that cache and query us again, because with new event we might have new delegate or datasource method to respond to.
    }
    
    /// Returns header model for section at `index`, or nil if it is not found.
    ///
    /// If `TableViewConfiguration` `displayHeaderOnEmptySection` is false, this method also returns nil.
    final func headerModel(forSection index: Int) -> Any?
    {
        guard storage.sections.count > index else { return nil }
        
        if storage.sections[index].numberOfItems == 0 && !configuration.displayHeaderOnEmptySection
        {
            return nil
        }
        return (self.storage as? HeaderFooterStorage)?.headerModel(forSection: index)
    }
    
    /// Returns footer model for section at `index`, or nil if it is not found.
    ///
    /// If `TableViewConfiguration` `displayFooterOnEmptySection` is false, this method also returns nil.
    final func footerModel(forSection index: Int) -> Any?
    {
        guard storage.sections.count > index else { return nil }
        
        if storage.sections[index].numberOfItems == 0 && !configuration.displayFooterOnEmptySection
        {
            return nil
        }
        return (storage as? HeaderFooterStorage)?.footerModel(forSection: index)
    }
    
    final internal func appendReaction<T,U>(for cellClass: T.Type, signature: EventMethodSignature, closure: @escaping (T,T.ModelType, IndexPath) -> U) where T: ModelTransfer, T:UITableViewCell
    {
        let reaction = EventReaction(signature: signature.rawValue, viewType: .cell, viewClass: T.self)
        reaction.makeReaction(closure)
        tableViewEventReactions.append(reaction)
    }
    
    final internal func append4ArgumentsReaction<CellClass,Argument,ReturnValue>
        (for cellClass: CellClass.Type,
         signature: EventMethodSignature,
         closure: @escaping (Argument, CellClass, CellClass.ModelType, IndexPath) -> ReturnValue)
        where CellClass: ModelTransfer, CellClass: UITableViewCell
    {
        let reaction = FourArgumentsEventReaction(signature: signature.rawValue,
                                                  viewType: .cell,
                                                  viewClass: CellClass.self)
        reaction.make4ArgumentsReaction(closure)
        tableViewEventReactions.append(reaction)
    }
    
    final internal func append5ArgumentsReaction<CellClass, ArgumentOne, ArgumentTwo, ReturnValue>
        (for cellClass: CellClass.Type,
         signature: EventMethodSignature,
         closure: @escaping (ArgumentOne, ArgumentTwo, CellClass, CellClass.ModelType, IndexPath) -> ReturnValue)
        where CellClass: ModelTransfer, CellClass: UITableViewCell
    {
        let reaction = FiveArgumentsEventReaction(signature: signature.rawValue,
                                                  viewType: .cell,
                                                  viewClass: CellClass.self)
        reaction.make5ArgumentsReaction(closure)
        tableViewEventReactions.append(reaction)
    }
    
    final internal func appendReaction<T,U>(for modelClass: T.Type, signature: EventMethodSignature, closure: @escaping (T, IndexPath) -> U)
    {
        let reaction = EventReaction(signature: signature.rawValue, viewType: .cell, modelType: T.self)
        reaction.makeReaction(closure)
        tableViewEventReactions.append(reaction)
    }
    
    final func appendReaction<T,U>(forSupplementaryKind kind: String, supplementaryClass: T.Type, signature: EventMethodSignature, closure: @escaping (T, T.ModelType, Int) -> U) where T: ModelTransfer, T: UIView {
        let reaction = EventReaction(signature: signature.rawValue, viewType: .supplementaryView(kind: kind), viewClass: T.self)
        let indexPathBlock : (T, T.ModelType, IndexPath) -> U = { cell, model, indexPath in
            return closure(cell, model, indexPath.section)
        }
        reaction.makeReaction(indexPathBlock)
        tableViewEventReactions.append(reaction)
    }
    
    final func appendReaction<T,U>(forSupplementaryKind kind: String, modelClass: T.Type, signature: EventMethodSignature, closure: @escaping (T, Int) -> U) {
        let reaction = EventReaction(signature: signature.rawValue, viewType: .supplementaryView(kind: kind), modelType: T.self)
        let indexPathBlock : (T, IndexPath) -> U = { model, indexPath in
            return closure(model, indexPath.section)
        }
        reaction.makeReaction(indexPathBlock)
        tableViewEventReactions.append(reaction)
    }
    
    final func performCellReaction(_ signature: EventMethodSignature, location: IndexPath, provideCell: Bool) -> Any? {
        var cell : UITableViewCell?
        if provideCell { cell = tableView?.cellForRow(at: location) }
        guard let model = storage.item(at: location) else { return nil }
        return tableViewEventReactions.performReaction(of: .cell, signature: signature.rawValue, view: cell, model: model, location: location)
    }
    
    final func perform4ArgumentsCellReaction(_ signature: EventMethodSignature, argument: Any, location: IndexPath, provideCell: Bool) -> Any? {
        var cell : UITableViewCell?
        if provideCell { cell = tableView?.cellForRow(at: location) }
        guard let model = storage.item(at: location) else { return nil }
        return tableViewEventReactions.perform4ArgumentsReaction(of: .cell,
                                                                 signature: signature.rawValue,
                                                                 argument: argument,
                                                                 view: cell,
                                                                 model: model,
                                                                 location: location)
    }
    
    final func perform5ArgumentsCellReaction(_ signature: EventMethodSignature,
                                             argumentOne: Any,
                                             argumentTwo: Any,
                                             location: IndexPath,
                                             provideCell: Bool) -> Any? {
        var cell : UITableViewCell?
        if provideCell { cell = tableView?.cellForRow(at: location) }
        guard let model = storage.item(at: location) else { return nil }
        return tableViewEventReactions.perform5ArgumentsReaction(of: .cell,
                                                                 signature: signature.rawValue,
                                                                 firstArgument: argumentOne,
                                                                 secondArgument: argumentTwo,
                                                                 view: cell,
                                                                 model: model,
                                                                 location: location)
    }
    
    final func performNillableCellReaction(_ reaction: EventReaction, location: IndexPath, provideCell: Bool) -> Any? {
        var cell : UITableViewCell?
        if provideCell { cell = tableView?.cellForRow(at: location) }
        guard let model = storage.item(at: location) else { return nil }
        return reaction.performWithArguments((cell as Any,model,location))
    }
    
    final func cellReaction(_ signature: EventMethodSignature, location: IndexPath) -> EventReaction? {
        guard let model = storage.item(at: location) else { return nil }
        return tableViewEventReactions.reaction(of: .cell, signature: signature.rawValue, forModel: model, view: nil)
    }
    
    final func performHeaderReaction(_ signature: EventMethodSignature, location: Int, provideView: Bool) -> Any? {
        var view : UIView?
        if provideView {
            view = tableView?.headerView(forSection: location)
        }
        guard let model = (storage as? HeaderFooterStorage)?.headerModel(forSection: location) else { return nil}
        return tableViewEventReactions.performReaction(of: .supplementaryView(kind: DTTableViewElementSectionHeader), signature: signature.rawValue, view: view, model: model, location: IndexPath(item: 0, section: location))
    }
    
    final func performFooterReaction(_ signature: EventMethodSignature, location: Int, provideView: Bool) -> Any? {
        var view : UIView?
        if provideView {
            view = tableView?.footerView(forSection: location)
        }
        guard let model = (storage as? HeaderFooterStorage)?.footerModel(forSection: location) else { return nil}
        return tableViewEventReactions.performReaction(of: .supplementaryView(kind: DTTableViewElementSectionFooter), signature: signature.rawValue, view: view, model: model, location: IndexPath(item: 0, section: location))
    }
    
    /// Calls `viewFactoryErrorHandler` with `error`. If it's nil, prints error into console and asserts.
    @nonobjc func handleTableViewFactoryError(_ error: DTTableViewFactoryError) {
        if let handler = viewFactoryErrorHandler {
            handler(error)
        } else {
            print((error as NSError).description)
            assertionFailure(error.description)
        }
    }
    
    // MARK: - Target Forwarding
    
    /// Forwards `aSelector`, that is not implemented by `DTTableViewManager` to delegate, if it implements it.
    ///
    /// - Returns: `DTTableViewManager` delegate
    override open func forwardingTarget(for aSelector: Selector) -> Any? {
        return delegate
    }
    
    /// Returns true, if `DTTableViewManageable` implements `aSelector`, or `DTTableViewManager` has an event, associated with this selector.
    ///
    /// - SeeAlso: `EventMethodSignature`
    override open func responds(to aSelector: Selector) -> Bool {
        if delegate?.responds(to: aSelector) ?? false {
            return true
        }
        if super.responds(to: aSelector) {
            if let eventSelector = EventMethodSignature(rawValue: String(describing: aSelector)) {
                return tableViewEventReactions.contains(where: { $0.methodSignature == eventSelector.rawValue })
            }
            return true
        }
        return false
    }
}
