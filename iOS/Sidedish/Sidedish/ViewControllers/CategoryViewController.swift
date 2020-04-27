//
//  ViewController.swift
//  Sidedish
//
//  Created by kimdo2297 on 2020/04/21.
//  Copyright © 2020 Jason. All rights reserved.
//

import UIKit

final class CategoryViewController: UIViewController {
    private let categoryTableView = CategoryTableView()
    private var categoryTableViewDataSource: CategoryTableViewDataSource!
    private var categoryViewModels: CategoryViewModels!
    private var hasBeenDisplayed = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureMenuTableViewDataSource()
        configureMenuTableView()
        configureObserver()
        configureUsecase()
    }
    
    private func configureMenuTableView() {
        categoryTableView.dataSource = categoryTableViewDataSource
        categoryTableView.delegate = self
        categoryTableView.register(ProductCell.self,
                                   forCellReuseIdentifier: ProductCell.reuseIdentifier)
        categoryTableView.register(CategoryHeaderView.self,
                                   forHeaderFooterViewReuseIdentifier: CategoryHeaderView.reuseIdentifier)
        configureMenuTableViewConstraints()
    }
    
    private func configureMenuTableViewConstraints() {
        view.addSubview(categoryTableView)
        
        let safeArea = view.safeAreaLayoutGuide
        categoryTableView.leadingAnchor.constraint(equalTo:
            safeArea.leadingAnchor).isActive = true
        categoryTableView.topAnchor.constraint(equalTo: safeArea.topAnchor).isActive = true
        categoryTableView.widthAnchor.constraint(equalTo: safeArea.widthAnchor,
                                                 multiplier: 1).isActive = true
        categoryTableView.heightAnchor.constraint(equalTo: safeArea.heightAnchor,
                                                  multiplier: 1).isActive = true
    }
    
    private func configureMenuTableViewDataSource() {
        categoryTableViewDataSource = CategoryTableViewDataSource(
            sectionCountHandler: {
                guard let categoryViewModels = self.categoryViewModels else { return nil }
                return categoryViewModels.count
        },
            rowCountHandler: { section -> Int? in
                guard let categoryViewModels = self.categoryViewModels,
                    let categoryViewModel = categoryViewModels.categoryViewModel(at: section) else { return nil }
                return categoryViewModel.productViewModelsCount
        },
            modelBindingHandler: { section, row -> ProductViewModel? in
                guard let categoryViewModels = self.categoryViewModels,
                    let categoryViewModel = categoryViewModels.categoryViewModel(at: section),
                    let productViewModel = categoryViewModel.productViewModel(at: row) else { return nil }
                return productViewModel
        })
    }
    
    private func configureObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateTableView),
                                               name: CategoryViewModels.Notification.categoryViewModelsDidChange,
                                               object: categoryViewModels)
    }
    
    @objc private func updateTableView(notification: Notification) {
        guard let userInfo = notification.userInfo, let index = userInfo["index"] as? Int else { return }
        DispatchQueue.main.async {
            self.categoryTableView.reloadSections(IndexSet(integer: index), with: .automatic)
        }
    }
    
    private func configureUsecase() {
        CategoryURLsUseCase.requestCategoryURLs(with: MockCategoryURLsSuccessStub()) { urlStrings in
            guard let urlStrings = urlStrings else { return }
            self.initCategoryViewModels(count: urlStrings.count)
            var index = 0
            urlStrings.forEach {
                CategoryUseCase.makeCategory(from: $0,
                                             with: MockCategorySuccessStub())
                { category in
                    guard let category = category else { return }
                    let categoryViewModel = CategoryViewModel(category: category)
                    self.categoryViewModels.insert(at: index,
                                                   categoryViewModel: categoryViewModel)
                }
                index += 1
            }
        }
    }
    
    private func initCategoryViewModels(count: Int) {
        categoryViewModels = CategoryViewModels(count: count)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        presentLoginViewController()
    }
    
    private func presentLoginViewController() {
        if !hasBeenDisplayed {
            guard let loginViewController = storyboard?.instantiateViewController(withIdentifier: LoginViewController.Identifier.storyboardIdentifier) as? LoginViewController else { return }
            loginViewController.modalPresentationStyle = .fullScreen
            present(loginViewController, animated: true)
            hasBeenDisplayed = true
        }
    }
}

extension CategoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let categoryHeaderView = tableView.dequeueReusableHeaderFooterView(withIdentifier: CategoryHeaderView.reuseIdentifier) as? CategoryHeaderView else { return nil }
        guard let categoryViewModels = categoryViewModels,
            let categoryViewModel = categoryViewModels.categoryViewModel(at: section) else { return nil }
        categoryViewModel.performBind { header in
            categoryHeaderView.configureCategory(text: header.name)
            categoryHeaderView.configureTitle(text: header.description)
        }
        return categoryHeaderView
    }
}
