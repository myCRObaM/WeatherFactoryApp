//
//  SearchViewController.swift
//  WheatherAppFactory
//
//  Created by Matej Hetzel on 12/09/2019.
//  Copyright © 2019 Matej Hetzel. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

class SearchViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource  {
    
    let viewModel: SearchViewModel!
    let searchBar: UISearchBar!
    var cancelButtonPressed: hideKeyboard!
    var keyboardHeight: CGFloat!
    var bottomConstraint: NSLayoutConstraint?
    let disposeBag = DisposeBag()
    var selectedLocationButton: ChangeLocationBasedOnSelection!
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if viewModel.locationData.count != 0 {
            return viewModel.locationData[0].postalcodes.count
        }
        else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dataForCellSetup = viewModel.locationData[0].postalcodes[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cellID", for: indexPath) as? LocationTableViewCell else {
            fatalError("nije settano")
            
        }
        cell.setupCell(data: dataForCellSetup)
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let data = viewModel.locationData[0].postalcodes[indexPath.row]
        searchBar.endEditing(true)
        self.dismiss(animated: false, completion: nil)
        cancelButtonPressed.hideViewController()
        selectedLocationButton.didSelectLocation(long: data.lat, lat: data.lng, location: data.placeName)
    }
    
    let searchView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let tableView: UITableView = {
        let view = UITableView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let blurryBackground: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = true
        return view
    }()
    
    let cancelButton: UIButton = {
        let imageView = UIButton()
        imageView.setImage(UIImage(named: "cancel_icon"), for: .normal)
        imageView.contentMode = .scaleToFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    init(model: SearchViewModel, searchBar: UISearchBar) {
        self.viewModel = model
        self.searchBar = searchBar
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewWillAppear(_ animated: Bool) {

        super.viewWillAppear(animated)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        prepareForViewModel()
        bindTextFieldWithRx()
        
        setupView()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        
      NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillHideNotification, object: nil)
        self.searchBar.becomeFirstResponder()
    }
    func setupView(){
        tableView.register(LocationTableViewCell.self, forCellReuseIdentifier: "cellID")
        
        let tap = UILongPressGestureRecognizer(target: self, action: #selector(screenPressed))
        tap.minimumPressDuration = 0
        view.addSubview(blurryBackground)
        view.addSubview(searchBar)
        view.addSubview(tableView)
        view.addSubview(cancelButton)
        
        blurryBackground.addGestureRecognizer(tap)
        cancelButton.addTarget(self, action: #selector(screenPressed), for: .touchUpInside)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        
        setupConstraints()
        
        
    }
    func setupConstraints(){
        NSLayoutConstraint.activate([
            blurryBackground.topAnchor.constraint(equalTo: view.topAnchor),
            blurryBackground.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            blurryBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurryBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
        bottomConstraint = NSLayoutConstraint(item: searchBar!, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: -20)
        
        NSLayoutConstraint.activate([
            searchBar.heightAnchor.constraint(equalToConstant: 70),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
        view.addConstraint(bottomConstraint!)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: searchBar.topAnchor, constant: -20)
            ])
        NSLayoutConstraint.activate([
            cancelButton.topAnchor.constraint(equalTo: tableView.topAnchor, constant: view.bounds.width/25),
            cancelButton.trailingAnchor.constraint(equalTo: tableView.trailingAnchor, constant: -view.bounds.width/25)
            ])
        
    }
    @objc func screenPressed(gesture: UITapGestureRecognizer){
        if gesture.state == .began {
            searchBar.endEditing(true)
            self.dismiss(animated: false, completion: nil)
            cancelButtonPressed.hideViewController()
        }
    }
    @objc func keyboardWillShow(notification: NSNotification){
        UIView.setAnimationsEnabled(true)
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            keyboardHeight = keyboardFrame.cgRectValue.height
            
            let isKeyboardShown = notification.name == UIResponder.keyboardWillShowNotification
            
            UIView.animate(withDuration: 1) {
                self.bottomConstraint?.constant = isKeyboardShown ? -self.keyboardHeight : -20
                self.view.layoutIfNeeded()
            }
        }
    }
    func prepareForViewModel(){
        viewModel.getData(subject: viewModel.getLocationSubject).disposed(by: disposeBag)
        reloadTableViewData(subject: viewModel.dataDoneSubject).disposed(by: disposeBag)
    }
    
    func bindTextFieldWithRx(){
        @discardableResult let _ = searchBar.rx.text.orEmpty
            .distinctUntilChanged()
            .enumerated()
            .skipWhile({ (index, value) -> Bool in
                return index == 0
            })
            .map({ (index, value) -> String in
                return value
            })
            .debounce(.milliseconds(300), scheduler: ConcurrentDispatchQueueScheduler(qos: .background))
            .bind(to: viewModel.getLocationSubject)
    }
    
    func reloadTableViewData(subject: PublishSubject<Bool>) -> Disposable{
        return subject
            .observeOn(MainScheduler.instance)
            .subscribeOn(viewModel.scheduler)
            .subscribe(onNext: {[unowned self]  article in
                self.tableView.reloadData()
            })
    }
    
}
