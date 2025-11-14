import Foundation

struct Session: Codable {
    var schema: String
    var transport: Transport
    var tracks: [Track]
    struct Transport: Codable { var bpm: Double; var meter: String }
    struct Track: Codable { var id: String; var instrument: [String: CodableValue]; var clips: [Clip]? }
    struct Clip: Codable { var id: String; var start: Double; var length: Double; var notes: [Note]? }
    struct Note: Codable { var time: Double; var pitch: Int; var velocity: Int?; var length: Double? }
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

@main
enum LabRunnerMain {
    static func main() throws {
        let args = CommandLine.arguments
        func arg(_ name: String) -> String? { if let i = args.firstIndex(of: name), i+1 < args.count { return args[i+1] } else { return nil } }
        guard let sessionFile = arg("--session-file"), let outDir = arg("--out") else {
            fputs("usage: lab-runner --session-file <path> --out <dir>\n", stderr)
            exit(2)
        }
        let outURL = URL(fileURLWithPath: outDir, isDirectory: true)
        try? FileManager.default.createDirectory(at: outURL, withIntermediateDirectories: true)
        let data = try Data(contentsOf: URL(fileURLWithPath: sessionFile))
        let sess = try JSONDecoder().decode(Session.self, from: data)
        let bpm = sess.transport.bpm
        let secPerBeat = 60.0 / bpm
        var events: [[String: Any]] = []
        for t in sess.tracks {
            for c in t.clips ?? [] {
                for n in c.notes ?? [] {
                    let ts = (c.start + n.time) * secPerBeat
                    events.append(["ts": ts, "type": "note.on", "pitch": n.pitch, "track": t.id])
                    if let len = n.length { events.append(["ts": ts + len*secPerBeat, "type": "note.off", "pitch": n.pitch, "track": t.id]) }
                }
            }
        }
        events.sort { (a,b) -> Bool in
            (a["ts"] as? Double ?? 0) < (b["ts"] as? Double ?? 0)
        }
        // Write NDJSON logs
        let evURL = outURL.appendingPathComponent("events.ndjson")
        var ev = ""
        for e in events { if let d = try? JSONSerialization.data(withJSONObject: e), let s = String(data: d, encoding: .utf8) { ev.append(s + "\n") } }
        try ev.data(using: .utf8)?.write(to: evURL)
        // Simple UMP snapshot placeholder
        let umpURL = outURL.appendingPathComponent("ump.ndjson")
        try "[]\n".data(using: .utf8)?.write(to: umpURL)
        // Runner log
        let logURL = outURL.appendingPathComponent("run.log")
        try "lab-runner ok\n".data(using: .utf8)?.write(to: logURL)
        print("ok")
    }
}

