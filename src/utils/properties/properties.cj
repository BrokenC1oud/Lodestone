public package Lodestone.utils.properties

import std.collection.HashMap
import std.io.InputStream
import std.io.OutputStream
import std.io.StringReader
import std.io.StringWriter
import std.unicode.UnicodeStringExtension

// TODO: Naive implementation, handle escapes, concurrent safety
public class Properties <: Equatable<Properties> {
    private let map: HashMap<String, String>
    private let defaults: ?Properties
    private let comment: ?String

    public init() {
        this.map = HashMap<String, String>()
        this.defaults = Option<Properties>.None
        this.comment = Option<String>.None
    }

    public init(defaults: Properties) {
        this.map = HashMap<String, String>()
        this.defaults = defaults
        this.comment = Option<String>.None
    }

    public init(initialCapacity: Int64) {
        this.map = HashMap<String, String>(initialCapacity)
        this.defaults = Option<Properties>.None
        this.comment = Option<String>.None
    }

    public init(initialCapacity: Int64, defaults: Properties) {
        this.map = HashMap<String, String>(initialCapacity)
        this.defaults = defaults
        this.comment = Option<String>.None
    }

    public func setProperty(key: String, value: String): Unit {
        this.map.add(key, value)
    }

    public func getProperty(key: String): ?String {
        return this.map.get(key)
    }

    public func load<T>(stringReader: StringReader<T>): Unit where T <: InputStream {
        for (line in stringReader.lines()) {
            let sep = line.indexOf('=') ?? -1
            let comment = line.indexOf('#') ?? line.size

            if (sep == -1) {
                continue
            }

            let key = line[0..sep].trim()
            let value = line[sep + 1..comment].trim()

            this.setProperty(key, value)
        }
    }

    public func save<T>(stringWriter: StringWriter<T>, comment!: ?String = Option<String>.None): Unit where T <: OutputStream {
        if (comment.isSome()) {
            this.writeComments<T>(stringWriter, comment ?? "")
        }

        for ((key, value) in this.map) {
            stringWriter.writeln("${key}=${value}")
        }
    }

    private func writeComments<T>(stringWriter: StringWriter<T>, comments: String): Unit where T <: OutputStream {
        let lines = comments.split('\n')
        for (line in lines) {
            stringWriter.writeln("# ${line}")
        }
    }

    public operator func ==(rhs: Properties): Bool {
        return this.map == rhs.map
    }
}
