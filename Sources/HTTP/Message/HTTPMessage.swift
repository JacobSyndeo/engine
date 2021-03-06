import Async
import Bits
import Dispatch
import TCP

/// An HTTP message.
/// This is the basis of HTTP request and response,
/// and has the general structure of:
///
///     <status line> HTTP/1.1
///     Content-Lengt: 5
///     Foo: Bar
///
///     hello
///
/// Note: the status line contains information that
/// differentiates requests and responses.
///
/// If the status line contains an HTTP method and URI
/// it is a request.
///
/// If the status line contains an HTTP status code
/// it is a response.
///
/// This protocol is useful for adding methods to both
/// requests and responses, such as the ability to serialize
/// Content to both message types.
///
/// HTTP messages conform to Extendable which allows you
/// to add your own stored properties to requests and responses
/// that can be accessed simply by importing the module that
/// adds them. This is how much of Vapor's functionality is created.
public protocol HTTPMessage: Codable, CustomStringConvertible, CustomDebugStringConvertible {
    /// The HTTP version of this message.
    var version: HTTPVersion { get set }
    /// The HTTP headers.
    var headers: HTTPHeaders { get set }
    /// The message body.
    var body: HTTPBody { get set }
    /// Closure to be called on upgrade
    var onUpgrade: HTTPOnUpgrade? { get set }
}

/// An action that happens when the message is upgraded.
public struct HTTPOnUpgrade: Codable {
    /// Byte source (input)
    public typealias Source = AnyOutputStream<ByteBuffer>

    /// Byte sink (output)
    public typealias Sink = AnyInputStream<ByteBuffer>

    /// Accepts the byte stream underlying the HTTP connection.
    public typealias Closure = (Source, Sink, Worker) throws -> ()

    /// Internal storage
    public let closure: Closure

    /// Create a new OnUpgrade action
    public init(_ closure: @escaping Closure) {
        self.closure = closure
    }

    /// See Encodable.encode
    public func encode(to encoder: Encoder) throws {
        // skip
    }

    /// See Decodable.init
    public init(from decoder: Decoder) throws {
        self.init { _, _, _ in }
    }
}

extension HTTPMessage {
    /// Sets Content-Length / Transfer-Encoding headers.
    internal mutating func updateBodyHeaders() {
        if let count = body.count {
            if count != headers[.contentLength].flatMap(Int.init) {
                headers[.contentLength] = count.description
            }
        } else {
            if headers[.connection] != "close" {
                headers[.transferEncoding] = "chunked"
            }
        }
    }
}

// MARK: Debug string

extension HTTPMessage {
    /// See `CustomStringConvertible.description
    public var description: String {
        var desc: [String] = []
        desc.append("(\(Self.self))")
        desc.append(headers.description)
        desc.append(body.description)
        return desc.joined(separator: "\n")
    }
}

extension HTTPMessage {
    /// See `CustomDebugStringConvertible.debugDescription`
    public var debugDescription: String {
        var desc: [String] = []
        desc.append("(\(Self.self))")
        desc.append(headers.debugDescription)
        desc.append(body.debugDescription)
        return desc.joined(separator: "\n")
    }
}
