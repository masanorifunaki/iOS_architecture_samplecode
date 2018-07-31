//
//  SearchUsersViewController.swift
//  FluxExample
//
//  Created by marty-suzuki on 2018/07/31.
//  Copyright © 2018年 marty-suzuki. All rights reserved.
//

import UIKit

final class SearchUsersViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var searchBar: UISearchBar!

    private let userStore: GithubUserStore
    private let actionCreator: ActionCreator
    private let dataSource: SearchUsersDataSource

    private var showUserSubscription: Subscription?
    private lazy var reloadSubscription: Subscription = {
        return userStore.addListener { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.reloadSections(IndexSet(integer: 0) , with: .fade)
                self?.refrectEditing()
            }
        }
    }()

    init(userStore: GithubUserStore = .shared,
         actionCreator: ActionCreator = .init()) {
        self.userStore = userStore
        self.actionCreator = actionCreator
        self.dataSource = SearchUsersDataSource(userStore: userStore,
                                                actionCreator: actionCreator)
        super.init(nibName: "SearchUsersViewController", bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Search Users"

        dataSource.configure(tableView)
        searchBar.delegate = self

        subscribeStore()

        _ = reloadSubscription
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        subscribeStore()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)

        unsubscribeStore()
    }

    private func unsubscribeStore() {
        if let subscription = showUserSubscription {
            userStore.removeListener(subscription)
            showUserSubscription = nil
        }
    }

    private func subscribeStore() {
        guard showUserSubscription == nil else {
            return
        }

        showUserSubscription = userStore.addListener { [weak self] in
            DispatchQueue.main.async {
                self?.showUserRepositories()
            }
        }
    }

    private func showUserRepositories() {
        if userStore.selectedUser == nil {
            return
        }
        let vc = UserRepositoriesViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    private func refrectEditing() {
        UIView.animate(withDuration: 0.3) {
            if self.userStore.isSeachUsersFieldEditing {
                self.view.backgroundColor = .black
                self.tableView.isUserInteractionEnabled = false
                self.tableView.alpha = 0.5
                self.searchBar.setShowsCancelButton(true, animated: true)
            } else {
                self.searchBar.resignFirstResponder()
                self.view.backgroundColor = .white
                self.tableView.isUserInteractionEnabled = true
                self.tableView.alpha = 1
                self.searchBar.setShowsCancelButton(false, animated: true)
            }
        }
    }
}

extension SearchUsersViewController: UISearchBarDelegate {
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        actionCreator.setIsSearchUsersFieldEditing(true)
        return true
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        actionCreator.setIsSearchUsersFieldEditing(false)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let text = searchBar.text, !text.isEmpty {
            actionCreator.searchUsers(query: text)
            actionCreator.setIsSearchUsersFieldEditing(false)
        }
    }
}