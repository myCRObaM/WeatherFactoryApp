//
//  SearchViewModelTest.swift
//  WheatherAppFactoryTests
//
//  Created by Matej Hetzel on 12/09/2019.
//  Copyright © 2019 Matej Hetzel. All rights reserved.
//

import XCTest
import RxTest
import RxSwift
import Nimble
import Quick
import Cuckoo
@testable import WheatherAppFactory


class SearchViewModelTest: QuickSpec {
    override func spec() {
        describe("load local test json"){
            var weatherData: [LocationDataClass]!
            let mockedWeatherRepository = MockLocationRepository()
            var testScheduler: TestScheduler!
            var searchViewModel: SearchViewModel!
            let disposeBag = DisposeBag()
            beforeSuite {
                Cuckoo.stub(mockedWeatherRepository){ mock in
                    let testBundle = Bundle(for: SearchViewModelTest.self)
                    guard let path = testBundle.url(forResource: "LocationJSON", withExtension: "json") else {return}
                    let dataFromLocation = try! Data(contentsOf: path)
                    let weather = try! JSONDecoder().decode(LocationDataClass.self, from: dataFromLocation)
                    
                    when(mock.alamofireRequest(any())).thenReturn(Observable.just(weather))
                    weatherData = [weather]
                }
            }
            context("Initialize viewModel"){
                var dataReadySubject: TestableObserver<Bool>!
                beforeEach {
                    testScheduler = TestScheduler(initialClock: 0)
                    searchViewModel = SearchViewModel(repository: mockedWeatherRepository, scheduler: testScheduler)
                    searchViewModel.getData(subject: searchViewModel.getLocationSubject).disposed(by: disposeBag)
                    
                    dataReadySubject = testScheduler.createObserver(Bool.self)
                    
                    searchViewModel.dataDoneSubject.subscribe(dataReadySubject).disposed(by: disposeBag)
                }
                it("check if data is triggering the event on a subject"){
                    testScheduler.start()
                    searchViewModel.getLocationSubject.onNext("virovitica")
                    
                    expect(dataReadySubject.events.count).to(equal(1))
                    expect(dataReadySubject.events[0].value.element).to(equal(true))
                }
                it("Check if data is loaded into the viewModel"){
                    testScheduler.start()
                    searchViewModel.getLocationSubject.onNext("searchViewModel")
                
                }
            }
        }
    }
}

