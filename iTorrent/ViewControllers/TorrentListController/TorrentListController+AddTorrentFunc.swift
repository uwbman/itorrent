//
//  TorrentListController+AddTorrentFunc.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 03.04.2020.
//  Copyright © 2020  XITRIX. All rights reserved.
//

import ITorrentFramework
import UIKit

extension TorrentListController {
    func addUrl() {
        Dialog.withTextField(self,
                             title: "Add from URL",
                             message: "Please enter the existing torrent's URL below",
                             textFieldConfiguration: { textField in
                                 textField.placeholder = "https://"

                                 if #available(iOS 10.0, *),
                                     UIPasteboard.general.hasStrings,
                                     let text = UIPasteboard.general.string,
                                     text.starts(with: "https://") ||
                                     text.starts(with: "http://") {
                                     textField.text = UIPasteboard.general.string
                                 }
        }) { textField in
            Core.shared.addFromUrl(textField.text!, presenter: self)
        }
    }
    
    func addMagnet() {
        Dialog.withTextField(self,
                             title: "Add from magnet",
                             message: "Please enter the magnet link below",
                             textFieldConfiguration: { textField in
                                 textField.placeholder = "magnet:"

                                 if #available(iOS 10.0, *),
                                     UIPasteboard.general.hasStrings,
                                     UIPasteboard.general.string?.starts(with: "magnet:") ?? false {
                                     textField.text = UIPasteboard.general.string
                                 }
        }) { textField in
            Utils.checkFolderExist(path: Core.configFolder)
            if let hash = TorrentSdk.getMagnetHash(magnetUrl: textField.text!),
                Core.shared.torrents[hash] != nil {
                Dialog.show(self, title: "This torrent already exists",
                            message: "\("Torrent with hash:".localized) \"\(hash)\" \("already exists in download queue".localized)")
            }

            Core.shared.addMagnet(textField.text!)
        }
    }
    
    @available(iOS 11.0, *)
    func addFile() {
        self.present(FilesBrowserController(), animated: true)
    }
    
    @available(iOS 13.0, *)
    func createMenu() -> UIMenu {
        UIMenu(title: "Add from...".localized, children: [
            UIAction(title: "Files".localized, image: UIImage(systemName: "doc.fill.badge.plus"), handler: {_ in self.addFile()}),
            UIAction(title: "Magnet", image: UIImage(systemName: "link.badge.plus"), handler: {_ in self.addMagnet()}),
            UIAction(title: "URL", image: UIImage(systemName: "link.badge.plus"), handler: {_ in self.addUrl()}),
        ])
    }
    
    @objc func addTorrent(_ sender: UIBarButtonItem) {
        let addController = ThemedUIAlertController(title: nil, message: "Add from...".localized, preferredStyle: .actionSheet)

        let addURL = UIAlertAction(title: "URL", style: .default) { _ in
            self.addUrl()
        }
        let addMagnet = UIAlertAction(title: "Magnet", style: .default) { _ in
            self.addMagnet()
        }
        let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)

        addController.addAction(addMagnet)
        addController.addAction(addURL)

//        let webview = UIAlertAction(title: "Web", style: .default) { _ in
//            let webviewAlert = ThemedUIAlertController(title: Localize.get("Open in Web View"),
//                                                       message: nil,
//                                                       preferredStyle: .alert)
//
//            webviewAlert.addTextField(configurationHandler: { textField in
//                textField.placeholder = "https://google.com/"
//                let theme = Themes.current
//                textField.keyboardAppearance = theme.keyboardAppearence
//            })
//
//            let ok = UIAlertAction(title: "OK", style: .default) { _ in
//                let textField = webviewAlert.textFields![0]
//                if !textField.text!.isEmpty {
//                    if let url = URL(string: textField.text!),
//                        UIApplication.shared.canOpenURL(url) {
//                        WebViewController.present(in: self.splitViewController!, with: url)
//                    } else {
//                        WebViewController.present(in: self.splitViewController!, with: URL(string: "http://google.com/search?q=\(textField.text!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")!)
//                    }
//                } else {
//                    WebViewController.present(in: self.splitViewController!, with: URL(string: "http://google.com/")!)
//                }
//            }
//
//            webviewAlert.addAction(ok)
//            webviewAlert.addAction(UIAlertAction(title: Localize.get("Cancel"), style: .cancel))
//
//            self.present(webviewAlert, animated: true)
//        }
        // addController.addAction(webview)

        if #available(iOS 11.0, *) {
            let files = UIAlertAction(title: NSLocalizedString("Files", comment: ""), style: .default) { _ in
                self.addFile()
            }
            addController.addAction(files)
        }

        addController.addAction(cancel)

        addController.popoverPresentationController?.barButtonItem = sender
        addController.popoverPresentationController?.permittedArrowDirections = .down

        present(addController, animated: true)
    }
}
