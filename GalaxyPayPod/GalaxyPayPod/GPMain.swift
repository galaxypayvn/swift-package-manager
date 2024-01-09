//
//  GPMain.swift
//  GalaxyPayPod
//
//  Created by Nguyen Nhat Kiem on 09/01/2024.
//

import Foundation

//#if targetEnvironment(simulator)
//#else
import TestTrueID
//#endif

public class GPMain: NSObject {
    private static var instance: GPMain? = nil
    public static var shared: GPMain {
        if Self.instance == nil {
            Self.instance = GPMain()
        }
        return Self.instance!
    }
    
    public func testPod() {
        MainTrueIDSDK.shared.showMainVC()
//        print("Test Pod")
    }
    
    public func callTestTrueId() {
        MainTrueIDSDK.shared.testSDK()
    }
}
