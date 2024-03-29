//
//  RSSFeedTableVC.swift
//  IOSSemestralWork
//
//  Created by Petr Budík on 12/07/2019.
//  Copyright © 2019 Petr Budík. All rights reserved.
//

import Foundation
import UIKit
import Resources
import Data
import RealmSwift
import Common

protocol RSSItemsTableVCFlowDelegate {
    func select(_ rssItem: MyRSSItem, otherRssItems rssItems: Results<MyRSSItem>)
}

/**
VC for displaying `MyRSSItem`s.
*/
final class RSSItemsTableVC: BaseViewController {
    private let viewModel: IRSSItemsTableVM
    private weak var tableView: UITableView!
    private lazy var refresher = RefreshControl(delegate: self)
    
    private let flowDelegate: RSSItemsTableVCFlowDelegate
        
    init(_ viewModel: IRSSItemsTableVM, delegate: RSSItemsTableVCFlowDelegate) {
        self.viewModel = viewModel
        self.flowDelegate = delegate
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    
    override func loadView() {
        super.loadView()
        view.backgroundColor = .white
        
        let tableView = UITableView(frame: self.view.bounds, style: UITableView.Style.plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 120
        tableView.rowHeight = UITableView.automaticDimension
        tableView.accessibilityIdentifier = "RSSItemsTableVC_TableView"
        
        // Initialize PullToRefresh
        tableView.refreshControl = refresher
        
        tableView.register(RssItemCell.self, forCellReuseIdentifier: "RssItemCell")
        view.addSubview(tableView)
        self.tableView = tableView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBindings()
        
        navigationItem.title = viewModel.title
    }
    
    private func setupBindings() {
        viewModel.downloadStatus.producer.startWithValues { [weak self] status in
            print("End refreshing")
            self?.refresher.refreshView.stopUpdating()
            self?.refresher.endRefreshing()
            
            if let status = status {
                self?.checkStatus(status)
            }
            
            self?.tableView.reloadData()
        }
    }
}

// MARK: UITableView delegate and data source
extension RSSItemsTableVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.shownItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RssItemCell", for: indexPath) as! RssItemCell
        
        cell.setData(using: viewModel.shownItems[indexPath.row])
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //TODO: Should we update repository here or in AppFlowCoordinator?
        let selectedItem = viewModel.shownItems[indexPath.row]
        viewModel.select(selectedItem)
        flowDelegate.select(selectedItem, otherRssItems: viewModel.shownItems)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: Refresher

extension RSSItemsTableVC: RefreshControlDelegate {
    func lastUpdateDate() -> NSDate {
        return viewModel.lastUpdateDate()
    }
    
    /**
     Checks beginning of the PullToRefresh and updates its label.
     */
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        var offset: CGFloat = 0
        if let frame = self.navigationController?.navigationBar.frame {
            offset = frame.minY + frame.size.height
        }
        
        if (-scrollView.contentOffset.y >= offset ) {
            refresher.refreshView.updateLabelText(date: lastUpdateDate())
        }
    }
    
    func update() {
        print("requesting data")
        
        refresher.refreshView.startUpdating()
        viewModel.updateAllFeeds()
    }
    
    private func checkStatus(_ status: DownloadStatus) {
        if status == DownloadStatus.unreachable {
            // Internet is unreachable
            print("Internet is unreachable")
            self.view.makeToast(L10n.Error.internetUnreachable)
            
        }
    }
}
