package Lodestone.server

import std.env.getStdIn
import std.collection.ArrayQueue
import std.sync.AtomicInt64

import Lodestone.utils.exceptions.SingletonConflictionException
import Lodestone.utils.properties.ServerPropertiesLoader

public struct PendingServerCommand {
    let command: String

    public init(command: String) {
        this.command = command
    }
}

public class ServerNetworkIo {
    public init() {}

    public func tick() {}
}

public class MinecraftServer {
    public static var thisx: ?MinecraftServer = Option.None

    private let serverPropertiesLoader: ServerPropertiesLoader
    private let networkIo: ServerNetworkIo

    private var stopped: Bool = false
    private var running: Bool = false

    private var ticks = AtomicInt64(0)

    private let commandQueue = ArrayQueue<PendingServerCommand>()

    public init(serverPropertiesLoader: ServerPropertiesLoader) {
        this.serverPropertiesLoader = serverPropertiesLoader
        this.networkIo = ServerNetworkIo()

        if (thisx.isNone()) {
            thisx = Option.Some(this)
        } else {
            throw SingletonConflictionException("Multiple MinecraftServer instance")
        }
    }

    public func setupServer() {
        let consoleHandler = spawn {
            let bufferedReader = getStdIn()

            var command: ?String
            while (!((thisx?.stopped) ?? false) && ((thisx?.running) ?? false)) {
                command = bufferedReader.readln()
                if (command.isSome()) {
                    thisx?.enqueueCommand(command ?? "")
                }
            }
        }

        this.running = true
    }

    public func runServer() {
        while (thisx?.running ?? false) {
            thisx?.tick()
        }
    }

    public func tick() {
        thisx?.ticks.fetchAdd(1)
        thisx?.executeQueuedCommands()
    }

    public func executeQueuedCommands() {
        while (!this.commandQueue.isEmpty()) {
            let command = this.commandQueue.remove()
            println("Received command: ${command?.command}")
        }
    }

    public func enqueueCommand(command: String): Unit {
        this.commandQueue.add(PendingServerCommand(command))
    }

    public func tickNetworkIo() {
        this.getNetworkIo().tick()
    }
    
    public func getNetworkIo(): ServerNetworkIo {
        return this.networkIo
    }

    public static func get() {
        return thisx
    }
}
