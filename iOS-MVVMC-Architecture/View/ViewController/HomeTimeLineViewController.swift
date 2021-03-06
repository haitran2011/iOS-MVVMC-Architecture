//
//  HomeTimeLineViewController.swift
//  iOS-MVVMC-Architecture
//
//  Created by Nishinobu.Takahiro on 2017/05/12.
//  Copyright © 2017年 hachinobu. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Kingfisher

class HomeTimeLineViewController: UITableViewController, HomeTimeLineViewProtocol {
    
    fileprivate lazy var loadingIndicatorView = LoadingIndicatorView.loadView()
    
    let bag = DisposeBag()
    var viewModel: TimeLineViewModel!
    
    fileprivate var selectedTweetIdObserver = PublishSubject<String>()
    lazy var selectedTweetId: Observable<String> = {
        return self.selectedTweetIdObserver.asObservable()
    }()
    
    fileprivate var selectedUserObserver = PublishSubject<String>()
    lazy var selectedUser: Observable<String> = {
        return self.selectedUserObserver.asObservable()
    }()
    
    lazy var reachedBottom: ControlEvent<Void> = {
        return self.tableView.rx.reachedBottom
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        viewModel.bindRefresh(refresh: tableView.refreshControl!.rx.controlEvent(.valueChanged).asDriver())
        viewModel.bindReachedBottom(reachedBottom: tableView.rx.reachedBottom.asDriver())
        bindAuthStatus()
        bindTimeLineFetch()
        bindTableView()
    }
    
}

extension HomeTimeLineViewController {
    
    fileprivate func setupUI() {
        //TableView Setting
        tableView.dataSource = nil
        tableView.delegate = nil
        tableView.refreshControl = UIRefreshControl()
        tableView.tableFooterView = loadingIndicatorView
        tableView.estimatedRowHeight = 90
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.register(withType: TimeLineTweetCell.self)
    }
    
    fileprivate func bindAuthStatus() {
        viewModel.authStatus
            .drive(onNext: { status in
                print(status)
            }).addDisposableTo(bag)
        
        viewModel.authError
            .filter { $0 != nil }
            .drive(onNext: { authError in
                print(authError!)
            }).addDisposableTo(bag)
    }
    
    fileprivate func bindTimeLineFetch() {
        viewModel.tweets
            .drive(onNext: { tweets in
                print(tweets.count)
            }).addDisposableTo(bag)
        
        viewModel.error
            .drive(onNext: { error in
                print(error)
            }).addDisposableTo(bag)
    }
    
    fileprivate func bindTableView() {
        
        viewModel.tweets
            .map { _ in false }
            .drive(tableView.refreshControl!.rx.isRefreshing.asObserver())
            .addDisposableTo(bag)
        
        viewModel.loadingIndicatorAnimation
            .drive(loadingIndicatorView.indicator.rx.isAnimating)
            .addDisposableTo(bag)
        
        viewModel.loadingIndicatorAnimation.map { !$0 }
            .drive(loadingIndicatorView.indicator.rx.isHidden)
            .addDisposableTo(bag)
        
        //TableViewCellのBind
        viewModel.tweets.drive(tableView.rx.items(cellIdentifier: TimeLineTweetCell.nibName, cellType: TimeLineTweetCell.self)) { [weak self] row, cellViewModel, cell in
            
            guard let strongSelf = self else {
                return
            }
            
            cellViewModel.userName.bind(to: cell.userNameLabel.rx.text).addDisposableTo(cell.bag)
            cellViewModel.screenName.bind(to: cell.screenNameLabel.rx.text).addDisposableTo(cell.bag)
            //observeOn(MainScheduler)とかasDeiverして繋ぐと初回のセル表示時にセルの高さが動的にならない。。
            cellViewModel.body.bind(to: cell.bodyLabel.rx.text).addDisposableTo(cell.bag)
            cellViewModel.profileURL.filter { $0 != nil }.subscribe(onNext: { [weak cell] url in
                let imageURL = url!
                let resource = ImageResource(downloadURL: imageURL, cacheKey: imageURL.absoluteString)
                cell?.iconImageView.kf.indicatorType = .activity
                cell?.iconImageView.kf.setImage(with: resource, placeholder: nil,
                                                options: [.transition(ImageTransition.fade(1.0)), .cacheMemoryOnly],
                                                progressBlock: nil, completionHandler: nil)
            }).addDisposableTo(cell.bag)
            
            cell.iconButton.rx.tap
                .map { cellViewModel.userId.description }
                .bind(to: strongSelf.selectedUserObserver)
                .addDisposableTo(cell.bag)
            
            cellViewModel.retweetCount.bind(to: cell.retweetCountLabel.rx.text).addDisposableTo(cell.bag)
            cellViewModel.likeCount.bind(to: cell.likeCountLabel.rx.text).addDisposableTo(cell.bag)
            
        }.addDisposableTo(bag)
        
        //TableViewCellタップ時に対象のTweetを知らせる
        tableView.rx.modelSelected(TimeLineCellViewModel.self)
            .do(onNext: { [weak self] _ in
                if let selectedIndexPath = self?.tableView.indexPathForSelectedRow {
                    self?.tableView.deselectRow(at: selectedIndexPath, animated: true)
                }
            })
            .map { model -> String in
                return model.id.description
            }
            .bind(to: selectedTweetIdObserver)
            .addDisposableTo(bag)
        
    }
    
    
}

