import Foundation
import GalaxyPaySDK

import OpenTelemetryApi
import OpenTelemetrySdk
import StdoutExporter
import NIO
import OpenTelemetryProtocolExporterGrpc
import OpenTelemetryProtocolExporterCommon
import GRPC

public class GPayPackage: NSObject {
    public private(set) var text = "Hello, World!"
    
    private static var instance: GPayPackage? = nil
    public static var shared: GPayPackage {
        if Self.instance == nil {
            Self.instance = GPayPackage()
        }
        return Self.instance!
    }
    
    var otlpTraceExporter: OtlpTraceExporter
    
    let tracer = OpenTelemetry.instance.tracerProvider.get(instrumentationName: "OTel Application", instrumentationVersion: "1.0.0")

    public override init() {
        print("init GPayPackage")
        let basicAuth = GPay.shared.getOpenTelemetryAuth()
        print("basicAuth::::\(basicAuth)")
        
        let grpcChannel = ClientConnection(
            configuration: ClientConnection.Configuration.default(
                target: .hostAndPort("https://tempo-us-central1.grafana.net", 443),
                eventLoopGroup: MultiThreadedEventLoopGroup(numberOfThreads: 1)
            )
        )
        
        self.otlpTraceExporter = OtlpTraceExporter(channel: grpcChannel, config: OtlpConfiguration(
            timeout: OtlpConfiguration.DefaultTimeoutInterval,
            headers: [
                ("Authentication", "\(basicAuth)")
            ]
        ))
                                                   
        super.init()
        
//         Initialize the tracer provider. The tracer provider is used to expose major API operations, preprocess spans, and configure custom clocks.
//         Configure the custom rules that are used to generate trace IDs and span IDs and configure custom samplers. You can configure the settings based on your business requirements.
        let spanExporters = MultiSpanExporter(spanExporters: [StdoutExporter(isDebug: true), otlpTraceExporter])
        let spanProcessor = BatchSpanProcessor(spanExporter: spanExporters)
        OpenTelemetry.registerTracerProvider(
            tracerProvider: TracerProviderBuilder().add(spanProcessor: spanProcessor).with(
                resource: Resource(
                    attributes:[
                        ResourceAttributes.serviceName.rawValue: AttributeValue.string("VIETJET_APP_UAT_1.9.1")
                    ]
                )
            )
            .with(idGenerator: SDKLogIdGenerator())
            .build()
        )
//        OpenTelemetry.registerPropagators(textPropagators: [TextMapPropagator], baggagePropagator: <#T##TextMapBaggagePropagator#>)

        // Configure other instrumentation collectors based on your business requirements. The following configuration is used to collect data from the NSUrlSession network library.
//        URLSessionInstrumentation(configuration: URLSessionInstrumentationConfiguration(
//         shouldInstrument: { request in
//         return true
//         })
//        )
    }
    
    public func showGPWallet(_ userInfo: [String: String], callback: @escaping (Bool,Int,Bool,Bool,Bool)->Void) {
        GPay.shared.showGPWallet(userInfo, callback: { isInValidData, transactionStatus, isBackFromHomePage, isFlowComplete, isTokenExpired in
            callback(isInValidData, transactionStatus, isBackFromHomePage, isFlowComplete, isTokenExpired)
        })
        GPay.shared.broadcastLogInfo(callback: { view, sdkVersion, env in
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
                var info = userInfo
                info["view"] = view
                info["SDK_Version"] = sdkVersion
                info["env"] = env
                self.handlerLogging(info)
            }
        })
    }
    
    func handlerLogging(_ userInfo: [String: String]) {
        if let view = userInfo["view"], view.trimmingCharacters(in: .whitespacesAndNewlines) != "",
        let phone = userInfo["phone"], phone.trimmingCharacters(in: .whitespacesAndNewlines) != "",
        let language = userInfo["language"], language.trimmingCharacters(in: .whitespacesAndNewlines) != "",
        let tenant = userInfo["tenantId"], tenant.trimmingCharacters(in: .whitespacesAndNewlines) != "",
        let sdkVersion = userInfo["SDK_Version"], sdkVersion.trimmingCharacters(in: .whitespacesAndNewlines) != "",
        let env = userInfo["env"], env.trimmingCharacters(in: .whitespacesAndNewlines) != ""
        {
            let span = self.tracer.spanBuilder(spanName: view).startSpan()
            span.setAttribute(key: "Phone", value: phone)
            span.setAttribute(key: "Language", value: language)
            span.setAttribute(key: "Tenant", value: tenant)
            span.setAttribute(key: "SDK Version", value: sdkVersion)
            span.setAttribute(key: "Env", value: env)
            span.setAttribute(key: "X-OS", value: "iOS")
            span.end()
            print("handlerLogging:::\(userInfo)")
            print("handlerLogging span:::\(span)")
        }
    }
}

extension String {
    func toDictionary() -> [String: Any]? {
        if let data = self.data(using: .utf8) {
            var jsonObj : Any?
            do {
                jsonObj = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
                return jsonObj as? [String : Any]
            } catch let error as NSError {
                print("Failed to convert to NSDictionary:::\(error)")
                return nil
            }
        }
        
        return nil
    }
}

struct SDKLogIdGenerator: IdGenerator {
    public init() {}

    public func generateSpanId() -> SpanId {
        var id: UInt64
        repeat {
            id = UInt64.random(in: .min ... .max)
        } while id == SpanId.invalidId
        return SpanId(id: id)
    }

    public func generateTraceId() -> TraceId {
        let curentDate = Date().getFormattedDate(format: "yyyyMMddHHmmss")
        var idHi: UInt64
        var idLo: UInt64
        repeat {
            idHi = UInt64.random(in: .min ... .max)
            idLo = UInt64.random(in: .min ... .max)
        } while idHi == TraceId.invalidId && idLo == TraceId.invalidId
        return TraceId(idHi: idHi, idLo: idLo)
    }
}

extension Date {
    func getFormattedDate(format: String) -> String {
         let dateformat = DateFormatter()
         dateformat.dateFormat = format
         return dateformat.string(from: self)
     }
}
