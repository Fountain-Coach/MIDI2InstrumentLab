import Foundation
import NIO
import NIOHTTP1

struct Session: Codable {
    var schema: String
    var meta: [String: String]? = nil
    var transport: Transport
    var tracks: [Track]
    struct Transport: Codable { var bpm: Double; var meter: String; var loop: Bool?; var loopStart: Double?; var loopEnd: Double? }
    struct Track: Codable { var id: String; var name: String?; var instrument: [String: CodableValue]; var clips: [Clip]? }
    struct Clip: Codable { var id: String; var start: Double; var length: Double; var notes: [Note]? }
    struct Note: Codable { var time: Double; var pitch: Int; var velocity: Int?; var length: Double? }
}

struct RunStatus: Codable { var id: String; var status: String; var createdAt: String; var finishedAt: String?; var artifacts: [Artifact]
    struct Artifact: Codable { var name: String; var contentType: String?; var size: Int64?; var href: String? }
}

enum CodableValue: Codable { case string(String), number(Double), bool(Bool), obj([String: CodableValue]), arr([CodableValue]), null
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let s = try? c.decode(String.self) { self = .string(s); return }
        if let b = try? c.decode(Bool.self) { self = .bool(b); return }
        if let n = try? c.decode(Double.self) { self = .number(n); return }
        if let o = try? c.decode([String: CodableValue].self) { self = .obj(o); return }
        if let a = try? c.decode([CodableValue].self) { self = .arr(a); return }
        self = .null
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .string(let s): try c.encode(s)
        case .number(let n): try c.encode(n)
        case .bool(let b): try c.encode(b)
        case .obj(let o): try c.encode(o)
        case .arr(let a): try c.encode(a)
        case .null: try c.encodeNil()
        }
    }
}

final class HTTPHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart
    private var body: ByteBuffer?
    private var method: HTTPMethod = .GET
    private var uri: String = "/"

    private let dataDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Data", isDirectory: true)
    private let artifactsDir: URL
    init() {
        artifactsDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Artifacts", isDirectory: true)
        try? FileManager.default.createDirectory(at: dataDir.appendingPathComponent("sessions", isDirectory: true), withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: dataDir.appendingPathComponent("runs", isDirectory: true), withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: artifactsDir, withIntermediateDirectories: true)
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let part = self.unwrapInboundIn(data)
        switch part {
        case .head(let head):
            method = head.method
            uri = head.uri
            body = context.channel.allocator.buffer(capacity: 0)
        case .body(var buf):
            if var b = body { var buf2 = buf; b.writeBuffer(&buf2); body = b } else { body = buf }
        case .end:
            handle(context: context)
            body = nil
        }
    }

    private func writeJSON(context: ChannelHandlerContext, status: HTTPResponseStatus, obj: Any) {
        let data = (try? JSONSerialization.data(withJSONObject: obj)) ?? Data("{}".utf8)
        var headers = HTTPHeaders()
        headers.add(name: "Content-Type", value: "application/json")
        headers.add(name: "Content-Length", value: String(data.count))
        context.write(wrapOutboundOut(.head(HTTPResponseHead(version: .http1_1, status: status, headers: headers))), promise: nil)
        var buf = context.channel.allocator.buffer(capacity: data.count)
        buf.writeBytes(data)
        context.write(wrapOutboundOut(.body(.byteBuffer(buf))), promise: nil)
        context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
    }
    private func writeText(context: ChannelHandlerContext, status: HTTPResponseStatus, text: String, contentType: String = "text/plain") {
        var headers = HTTPHeaders()
        headers.add(name: "Content-Type", value: contentType)
        headers.add(name: "Content-Length", value: String(text.utf8.count))
        context.write(wrapOutboundOut(.head(HTTPResponseHead(version: .http1_1, status: status, headers: headers))), promise: nil)
        var buf = context.channel.allocator.buffer(capacity: text.utf8.count)
        buf.writeString(text)
        context.write(wrapOutboundOut(.body(.byteBuffer(buf))), promise: nil)
        context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
    }

    private func handle(context: ChannelHandlerContext) {
        let path = uri.split(separator: "?").first.map(String.init) ?? "/"
        if method == .GET && path == "/health" { writeText(context: context, status: .ok, text: "ok\n"); return }

        if method == .POST && path == "/sessions" {
            let data = body.map { Data($0.readableBytesView) }
            guard let data, let _ = try? JSONDecoder().decode(Session.self, from: data) else {
                return writeJSON(context: context, status: .badRequest, obj: problem(400, "invalid session"))
            }
            let id = UUID().uuidString
            let url = dataDir.appendingPathComponent("sessions/") .appendingPathComponent(id + ".json")
            try? data.write(to: url)
            return writeJSON(context: context, status: .created, obj: ["id": id])
        }
        if path.hasPrefix("/sessions/") {
            let id = String(path.dropFirst("/sessions/".count))
            let url = dataDir.appendingPathComponent("sessions/") .appendingPathComponent(id + ".json")
            if method == .GET {
                guard let data = try? Data(contentsOf: url), let obj = try? JSONSerialization.jsonObject(with: data) else {
                    return writeJSON(context: context, status: .notFound, obj: problem(404, "not found"))
                }
                return writeJSON(context: context, status: .ok, obj: obj)
            } else if method == .PUT {
                let data = body.map { Data($0.readableBytesView) }
                guard let data, (try? JSONDecoder().decode(Session.self, from: data)) != nil else {
                    return writeJSON(context: context, status: .badRequest, obj: problem(400, "invalid session"))
                }
                try? data.write(to: url)
                return writeJSON(context: context, status: .noContent, obj: [:])
            } else if method == .DELETE {
                try? FileManager.default.removeItem(at: url)
                return writeJSON(context: context, status: .noContent, obj: [:])
            }
        }

        if method == .POST && path == "/runs" {
            let data = body.map { Data($0.readableBytesView) }
            guard let data, let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return writeJSON(context: context, status: .badRequest, obj: problem(400, "invalid body"))
            }
            var sessData: Data? = nil
            if let sid = root["sessionId"] as? String {
                let url = dataDir.appendingPathComponent("sessions/") .appendingPathComponent(sid + ".json")
                sessData = try? Data(contentsOf: url)
            } else if let s = root["session"] {
                sessData = try? JSONSerialization.data(withJSONObject: s)
            }
            guard let sdata = sessData else { return writeJSON(context: context, status: .badRequest, obj: problem(400, "missing session")) }
            // Create run
            let runId = UUID().uuidString
            let runURL = dataDir.appendingPathComponent("runs/") .appendingPathComponent(runId + ".json")
            let created = ISO8601DateFormatter().string(from: Date())
            let status = RunStatus(id: runId, status: "running", createdAt: created, finishedAt: nil, artifacts: [])
            if let js = try? JSONEncoder().encode(status) { try? js.write(to: runURL) }
            // Write session snapshot into artifacts dir and simulate processing
            let runArtifactsDir = artifactsDir.appendingPathComponent("run-" + runId, isDirectory: true)
            try? FileManager.default.createDirectory(at: runArtifactsDir, withIntermediateDirectories: true)
            try? sdata.write(to: runArtifactsDir.appendingPathComponent("session.snapshot.json"))
            // Launch runner (as subprocess)
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            proc.arguments = ["swift", "run", "-c", "debug", "lab-runner", "--session-file", runArtifactsDir.appendingPathComponent("session.snapshot.json").path, "--out", runArtifactsDir.path]
            let pipe = Pipe(); proc.standardOutput = pipe; proc.standardError = pipe
            try? proc.run()
            proc.terminationHandler = { _ in
                // Update run status
                let finished = ISO8601DateFormatter().string(from: Date())
                var artifacts: [RunStatus.Artifact] = []
                if let items = try? FileManager.default.contentsOfDirectory(at: runArtifactsDir, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) {
                    artifacts = items.map { url in
                        let sz = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map { Int64($0) }
                        return RunStatus.Artifact(name: url.lastPathComponent, contentType: contentTypeFor(url), size: sz, href: "/runs/\(runId)/artifacts/\(url.lastPathComponent)")
                    }
                }
                let fin = RunStatus(id: runId, status: "succeeded", createdAt: created, finishedAt: finished, artifacts: artifacts)
                if let js = try? JSONEncoder().encode(fin) { try? js.write(to: runURL) }
            }
            return writeJSON(context: context, status: .accepted, obj: ["id": runId, "status": "running", "createdAt": created, "artifacts": []])
        }
        if path.hasPrefix("/runs/") {
            let rest = String(path.dropFirst("/runs/".count))
            if rest.contains("/artifacts/") {
                let parts = rest.split(separator: "/", maxSplits: 2).map(String.init)
                if parts.count == 3 && parts[1] == "artifacts" {
                    let runId = parts[0]
                    let name = parts[2]
                    let fileURL = artifactsDir.appendingPathComponent("run-" + runId).appendingPathComponent(name)
                    guard FileManager.default.fileExists(atPath: fileURL.path), let data = try? Data(contentsOf: fileURL) else {
                        return writeJSON(context: context, status: .notFound, obj: problem(404, "not found"))
                    }
                    let ct = contentTypeFor(fileURL) ?? "application/octet-stream"
                    var headers = HTTPHeaders(); headers.add(name: "Content-Type", value: ct); headers.add(name: "Content-Length", value: String(data.count))
                    context.write(wrapOutboundOut(.head(HTTPResponseHead(version: .http1_1, status: .ok, headers: headers))), promise: nil)
                    var buf = context.channel.allocator.buffer(capacity: data.count); buf.writeBytes(data)
                    context.write(wrapOutboundOut(.body(.byteBuffer(buf))), promise: nil)
                    context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
                    return
                }
            } else if rest.hasSuffix("/artifacts") {
                let runId = String(rest.dropLast("/artifacts".count))
                let runArtifactsDir = artifactsDir.appendingPathComponent("run-" + runId)
                guard let items = try? FileManager.default.contentsOfDirectory(at: runArtifactsDir, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) else {
                    return writeJSON(context: context, status: .notFound, obj: problem(404, "not found"))
                }
                let arr: [[String: Any]] = items.map { url in
                    let sz = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map { Int64($0) } ?? 0
                    return ["name": url.lastPathComponent, "size": sz, "href": "/runs/\(runId)/artifacts/\(url.lastPathComponent)"]
                }
                return writeJSON(context: context, status: .ok, obj: ["items": arr])
            } else {
                let runId = rest
                let runURL = dataDir.appendingPathComponent("runs/") .appendingPathComponent(runId + ".json")
                guard let data = try? Data(contentsOf: runURL), let obj = try? JSONSerialization.jsonObject(with: data) else {
                    return writeJSON(context: context, status: .notFound, obj: problem(404, "not found"))
                }
                return writeJSON(context: context, status: .ok, obj: obj)
            }
        }

        if method == .POST && path == "/introspect/au" {
            // Stub: return one fake parameter for now
            return writeJSON(context: context, status: .ok, obj: ["items": [["id": 1, "name": "Gain", "min": 0, "max": 1]]])
        }
        // Mapping generation lives in Tools Factory; Lab does not implement it.

        writeJSON(context: context, status: .notFound, obj: problem(404, "not found"))
    }

    private func problem(_ status: Int, _ title: String) -> [String: Any] {
        return ["title": title, "status": status]
    }
}

private func contentTypeFor(_ url: URL) -> String? {
    switch url.pathExtension.lowercased() {
    case "json", "ndjson": return "application/json"
    case "txt", "log": return "text/plain"
    default: return "application/octet-stream"
    }
}

@main
enum LabServiceMain {
    static func main() throws {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        defer { try? group.syncShutdownGracefully() }
        let bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline().flatMap {
                    channel.pipeline.addHandler(HTTPHandler())
                }
            }
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
            .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
        let port = Int(ProcessInfo.processInfo.environment["LAB_PORT"] ?? "8088") ?? 8088
        let channel = try bootstrap.bind(host: "127.0.0.1", port: port).wait()
        print("lab-service listening on :\(port)")
        try channel.closeFuture.wait()
    }
}
