import GalaxyPaySDK

public struct GPayPackage {
    public private(set) var text = "Hello, World!"

    public init() {
    }
    
    public func showGPWallet(_ userInfo: [String: String], callback: @escaping (Bool,Int,Bool,Bool,Bool)->Void) {
        GPay.shared.showGPWallet(userInfo, callback: { isInValidData, transactionStatus, isBackFromHomePage, isFlowComplete, isTokenExpired in
            callback(isInValidData, transactionStatus, isBackFromHomePage, isFlowComplete, isTokenExpired)
        })
    }
}
