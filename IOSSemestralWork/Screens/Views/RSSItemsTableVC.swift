//
//  RSSFeedTableVC.swift
//  IOSSemestralWork
//
//  Created by Petr Budík on 12/07/2019.
//  Copyright © 2019 Petr Budík. All rights reserved.
//

import Foundation
import UIKit

final class RSSItemsTableVC: BaseViewController {
    private let viewModel: IRSSItemsTableVM
    private weak var tableView: UITableView!
    lazy var refresher = RefreshControl()
    
//    var flowDelegate: ItemTableVCFlowDelegate?
    
    init(_ viewModel: IRSSItemsTableVM) {
        self.viewModel = viewModel
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        view.backgroundColor = .white
        
        let tableView = UITableView(frame: self.view.bounds, style: UITableView.Style.plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 120
        tableView.rowHeight = UITableView.automaticDimension
        
        // Initialize PullToRefresh
        tableView.refreshControl = refresher
        refresher.delegate = self
        
        tableView.register(RssItemCell.self, forCellReuseIdentifier: "RssItemCell")
        view.addSubview(tableView)
        self.tableView = tableView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBindings()
        
        navigationItem.title = viewModel.selectedItem.title
//        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addBarButtonTapped(_:)))
    }
    
    private func setupBindings() {
        
    }
}

// MARK: UITableView delegate and data source
//FIXME: Implement
extension RSSItemsTableVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.shownItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RssItemCell", for: indexPath) as! RssItemCell
        
        cell.setData(using: viewModel.shownItems[indexPath.row])
        
        return cell
    }
    
    
}

// MARK: Refresher

extension RSSItemsTableVC: RefreshControlDelegate {
    
    /**
     Checks beginning of the PullToRefresh and updates its label.
     */
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        var offset: CGFloat = 0
        if let frame = self.navigationController?.navigationBar.frame {
            offset = frame.minY + frame.size.height
        }
        
        if (-scrollView.contentOffset.y >= offset ) {
            refresher.refreshView.updateLabelText()
        }
    }
    
    func update() {
        print("requesting data")
        
        refresher.refreshView.startUpdating()
        viewModel.updateAllFeeds()
    }
}
