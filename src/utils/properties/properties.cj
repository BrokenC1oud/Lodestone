public package Lodestone.utils.properties

import std.collection.HashMap
import std.collection.HashMapIterator
import std.convert.Parsable
import std.fs.File
import std.fs.FSException
import std.fs.OpenMode
import std.fs.Path
import std.io.InputStream
import std.io.OutputStream
import std.io.StringReader
import std.io.StringWriter
import std.unicode.UnicodeStringExtension

// TODO: Naive implementation, handle escapes, concurrent safety
public class Properties <: Equatable<Properties> & ToString {
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

        stringWriter.flush()
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

    public func iterator(): HashMapIterator<String, String> {
        return HashMapIterator<String, String>(this.map)
    }

    public func toString(): String {
        return "Properties{${this.map.toString()}}"
    }
}

public abstract class AbstractPropertiesHandler {
    protected let properties: Properties

    public init(properties: Properties) {
        this.properties = properties
    }

    public static func loadFromFile(path: Path): Properties {
        let properties = Properties()
        try {
            properties.load(StringReader(File(path, OpenMode.Read)))
        } catch (e: FSException) {
            // Just return an empty properties
        }

        return properties
    }

    public func save(output: Path): Unit {
        this.properties.save(StringWriter(File(output, OpenMode.Write)), comment: "Minecraft server properties")
    }

    protected func get<T>(key: String, deserializer: (String) -> ?T, serializer: (T) -> String, default: T): T {
        let value = this.properties.getProperty(key)
        let object = match (value) {
            case Some(v) => deserializer(v) ?? default
            case None => default
        }
        this.properties.setProperty(key, serializer(object))

        return object
    }

    protected func get<T>(key: String, deserializer: (String) -> ?T, default: T): T where T <: ToString {
        this.get(key, deserializer, { v: ToString => v.toString() }, default)
    }

    protected func get(key: String, default: Bool): Bool {
        this.get(key, Bool.tryParse, default)
    }

    protected func get(key: String, default: Int64): Int64 {
        this.get(key, Int64.tryParse, default)
    }

    protected func get(key: String, default: String): String {
        this.get(key, { s => s }, default)
    }
}

public class ServerPropertiesHandler <: AbstractPropertiesHandler {
    public init(properties: Properties) {
        super(properties)

        // register config entries here for christ's sake
        this.serverPort()
    }

    public static func load(path: Path): ServerPropertiesHandler {
        return ServerPropertiesHandler(loadFromFile(path))
    }

    public func serverPort(): Int64 {
        return this.get("server-port", 25565)
    }
}

public class ServerPropertiesLoader {
    private let path: Path
    private let propertiesHandler: ServerPropertiesHandler

    public init(path: Path) {
        this.path = path
        this.propertiesHandler = ServerPropertiesHandler.load(path)
    }

    public func save() {
        this.propertiesHandler.save(this.path)
    }

    public func getServerPropertiesHandler() {
        return this.propertiesHandler
    }
}
