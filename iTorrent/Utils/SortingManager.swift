//
//  SortingManager.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 17.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import ITorrentFramework
import Foundation
import UIKit

public enum SortingTypes: Int, Codable {
    case name = 0
    case dateAdded = 1
    case dateCreated = 2
    case size = 3
}

class SortingManager {
    
    @available(iOS 14, *)
    public static func createSortingMenu(applyChanges: (() -> ())? = nil) -> UIMenu {
        func setSort(_ sortingType: SortingTypes) {
            UserPreferences.sortingType = sortingType
            applyChanges?()
        }
        
        func iconFor(_ sortingType: SortingTypes) -> UIImage? {
            UserPreferences.sortingType == sortingType ? UIImage(systemName: "chevron.down") : nil
        }
        
        let alphabetAction = UIAction(title: "Name".localized, image: iconFor(.name), handler: { _ in setSort(.name)})
        let dateAddedAction = UIAction(title: "Date Added".localized, image: iconFor(.dateAdded), handler: { _ in setSort(.dateAdded)})
        let dateCreatedAction = UIAction(title: "Date Created".localized, image: iconFor(.dateCreated), handler: { _ in setSort(.dateCreated)})
        let sizeAction = UIAction(title: "Size".localized, image: iconFor(.size), handler: { _ in setSort(.size)})

        let sections = UserPreferences.sortingSections
        let name = (sections ? "Disable state sections" : "Enable state sections").localized
        let icon = sections ? UIImage(systemName: "checkmark") : nil
        let sectionsAction = UIAction(title: name, image: icon) { _ in
            UserPreferences.sortingSections = !sections
            applyChanges?()
        }

        return UIMenu(title: "", children: [
            UIMenu(title: "", options: .displayInline, children: [alphabetAction, dateAddedAction, dateCreatedAction, sizeAction]),
            UIMenu(title: "", options: .displayInline, children: [sectionsAction])
        ])
    }

    public static func createSortingController(buttonItem: UIBarButtonItem? = nil, applyChanges: @escaping () -> Void = {}) -> ThemedUIAlertController {
        let alphabetAction = createAlertButton(NSLocalizedString("Name", comment: ""), SortingTypes.name, applyChanges)
        let dateAddedAction = createAlertButton(NSLocalizedString("Date Added", comment: ""), SortingTypes.dateAdded, applyChanges)
        let dateCreatedAction = createAlertButton(NSLocalizedString("Date Created", comment: ""), SortingTypes.dateCreated, applyChanges)
        let sizeAction = createAlertButton(NSLocalizedString("Size", comment: ""), SortingTypes.size, applyChanges)

        let sectionsAction = createSectionsAlertButton(applyChanges)

        let cancel = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: UIAlertAction.Style.cancel, handler: nil)

        var sortAlertController = ThemedUIAlertController(title: NSLocalizedString("Sort Torrents By:", comment: ""), message: nil, preferredStyle: .actionSheet)

        var message = NSLocalizedString("Currently sorted by ", comment: "")
        checkConditionToAddButtonToList(&sortAlertController, &message, alphabetAction, SortingTypes.name)
        checkConditionToAddButtonToList(&sortAlertController, &message, dateAddedAction, SortingTypes.dateAdded)
        checkConditionToAddButtonToList(&sortAlertController, &message, dateCreatedAction, SortingTypes.dateCreated)
        checkConditionToAddButtonToList(&sortAlertController, &message, sizeAction, SortingTypes.size)

        sortAlertController.addAction(sectionsAction)
        sortAlertController.addAction(cancel)

        sortAlertController.message = message

        if sortAlertController.popoverPresentationController != nil, buttonItem != nil {
            sortAlertController.popoverPresentationController?.barButtonItem = buttonItem
        }

        return sortAlertController
    }

    private static func createAlertButton(_ buttonName: String, _ sortingType: SortingTypes, _ applyChanges: @escaping () -> Void = {}) -> UIAlertAction {
        UIAlertAction(title: buttonName, style: .default) { _ in
            UserPreferences.sortingType = sortingType
            applyChanges()
        }
    }

    private static func createSectionsAlertButton(_ applyChanges: @escaping () -> Void = {}) -> UIAlertAction {
        let sections = UserPreferences.sortingSections
        let name = sections ? NSLocalizedString("Disable state sections", comment: "") : NSLocalizedString("Enable state sections", comment: "")
        return UIAlertAction(title: name, style: sections ? .destructive : .default) { _ in
            UserPreferences.sortingSections = !sections
            applyChanges()
        }
    }

    private static func checkConditionToAddButtonToList(_ sortAlertController: inout ThemedUIAlertController, _ message: inout String, _ alertAction: UIAlertAction, _ sortingType: SortingTypes) {
        if UserPreferences.sortingType != sortingType {
            sortAlertController.addAction(alertAction)
        } else {
            message.append(alertAction.title!)
        }
    }

    public static func sort(managers: [TorrentModel]) -> [SectionModel<TorrentModel>] {
        var res = [SectionModel<TorrentModel>]()

        if UserPreferences.sortingSections {
            let dict = Dictionary(grouping: managers, by: { $0.displayState })
            let sortingOrder = UserPreferences.sectionsSortingOrder
            for id in sortingOrder {
                let state = TorrentState(id: id)!
                if var items = dict[state] {
                    simpleSort(&items)
                    let section = SectionModel(title: state.rawValue, items: items)
                    res.append(section)
                }
            }
        } else {
            var items = managers
            simpleSort(&items)
            let section = SectionModel(title: "", items: items)
            res.append(section)
        }

        return res
    }

    private static func simpleSort(_ list: inout [TorrentModel]) {
        switch UserPreferences.sortingType {
        case SortingTypes.name:
            list.sort { (t1, t2) -> Bool in
                t1.title < t2.title
            }
        case SortingTypes.dateAdded:
            list.sort { (t1, t2) -> Bool in
                t1.addedDate! > t2.addedDate!
            }
        case SortingTypes.dateCreated:
            list.sort { (t1, t2) -> Bool in
                t1.creationDate! > t2.creationDate!
            }
        case SortingTypes.size:
            list.sort { (t1, t2) -> Bool in
                t1.totalWanted > t2.totalWanted
            }
        }
    }
}
