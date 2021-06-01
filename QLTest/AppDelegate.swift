//
//  AppDelegate.swift
//  QLTest
//
//  Created by Work on 5/7/21.
//

import Cocoa
import Quartz
//import NIO
//import NIOHTTP1
//import Vapor

//class SimpleHTTPServer: ChannelInboundHandler {
//    typealias InboundIn = HTTPServerRequestPart
//    typealias OutboundOut = HTTPServerResponsePart
//
//    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
//        switch unwrapInboundIn(data) {
//
//        case .head(let req):
//            let replyString = "Hi!"
//            print("=> head \(req)")
//            var head = HTTPResponseHead(version: req.version, status: .ok)
//            head.headers.add(name: "Content-Length", value: "\(replyString.utf8.count)")
//            head.headers.add(name: "Connection", value: "close")
//            let r = HTTPServerResponsePart.head(head)
//            context.write(self.wrapOutboundOut(r), promise: nil)
//            var b = context.channel.allocator.buffer(capacity: replyString.count)
//            b.writeString(replyString)
//
//            let outbound = HTTPServerResponsePart.body(.byteBuffer(b))
//            context.write(self.wrapOutboundOut(outbound))
//            context.write(self.wrapOutboundOut(.end(nil))).recover { error in
//                fatalError("unexpected error \(error)")
//            }.whenComplete { (_: Result<Void, Error>) in
////                self.sentEnd = true
//                context.close().whenFailure { error in
//                    fatalError("close failed \(error)")
//                }
//            }
//        case .body(let body):
//            print("=> body \(body)")
//        case .end(let headers):
//            print("=> end? \(headers)")
//        }
//    }
//}
//
//class Server {
//
//    let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
//
//    init() {
//        let bootstrap = ServerBootstrap(group: group).childChannelInitializer { channel in
//            channel.pipeline.configureHTTPServerPipeline().flatMap {
//                channel.pipeline.addHandler(SimpleHTTPServer())
//            }
//        }
//
//        let serverChannel = try! bootstrap.bind(host: "0.0.0.0", port: 0).wait()
//        print("bound to addr \(serverChannel.localAddress)")
//    }
//}
//
//class Server {
//    var app: Application!
//    init() {
//        app = try! Application(.detect())
//        
//        app.get("foo.html") { req in
//            req.fileio.streamFile(at: Bundle.main.path(forResource: "foo", ofType: "html")!)
//        }
//        app.get("remapped_turtle.bag") { req in
//            req.fileio.streamFile(at: Bundle.main.path(forResource: "remapped_turtle", ofType: "bag")!)
//        }
//        
//        app.http.server.configuration.port = 11122
//        try! app.start()
//        
//        print("Listening on \(app.http.server.shared.localAddress)")
//    }
//    deinit {
//        app.shutdown()
//    }
//}

class MyView: NSView {
    
    override func registerForDraggedTypes(_ newTypes: [NSPasteboard.PasteboardType]) {
        print("register",newTypes)
        super.registerForDraggedTypes(newTypes)
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }
    
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        print("prepare")
        return true
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        print("Available types:",sender.draggingPasteboard.availableType(from: [.fileURL]))
        let str = sender.draggingPasteboard.string(forType: .fileURL)!
//        print("File:",)
        (NSApp.delegate as! AppDelegate).url = URL(string: str)!
        (NSApp.delegate as! AppDelegate).buttonClicked(self)
        return true
    }
}

@main
class AppDelegate: NSObject, NSApplicationDelegate, QLPreviewPanelDataSource, NSDraggingDestination {
    

    @IBOutlet var window: NSWindow!
    
    var url: URL?
//    var server: Server?


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        window.contentView!.registerForDraggedTypes([.fileURL])
        
//        server = Server()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @IBAction func buttonClicked(_ sender: Any) {
        QLPreviewPanel.shared().makeKeyAndOrderFront(self)
    }
    
    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        1
    }
    
    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        return NSURL(fileURLWithPath: "/Users/work/Documents/bags/remapped_turtle.bag")
    }
    
    override func acceptsPreviewPanelControl(_ panel: QLPreviewPanel!) -> Bool {
        print("Accepts control")
        return true
    }
    
    override func beginPreviewPanelControl(_ panel: QLPreviewPanel!) {
        print("Begin control")
        panel.dataSource = self
        panel.delegate = self
    }
    
    override func endPreviewPanelControl(_ panel: QLPreviewPanel!) {
        print("End control")
    }
}

