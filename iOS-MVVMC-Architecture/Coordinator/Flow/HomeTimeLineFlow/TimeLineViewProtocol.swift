//
//  TimeLineViewProtocol.swift
//  iOS-MVVMC-Architecture
//
//  Created by Nishinobu.Takahiro on 2017/05/12.
//  Copyright © 2017年 hachinobu. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

protocol TimeLineViewProtocol {
    var selectedItem: Observable<String> { get }
    var reachedBottom: ControlEvent<Void> { get }
}
