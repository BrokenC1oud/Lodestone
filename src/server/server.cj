package Lodestone.server

import std.env.getStdIn
import std.collection.ArrayList
import std.collection.ArrayQueue
import std.net.IPSocketAddress
import std.net.IPv4Address
import std.net.SocketAddress
import std.net.TcpServerSocket
import std.net.TcpSocket
import std.sync.AtomicInt64

import Lodestone.utils.properties.ServerPropertiesLoader

public struct PendingServerCommand {
    let command: String

    public init(command: String) {
        this.command = command
    }
}

public class ClientConnection {
    let connection: TcpSocket
    public init(socket: TcpSocket) {
        this.connection = socket
    }

    public func tick() {}
}

public class ServerNetworkIo {
    var server: ?MinecraftServer
    let listenerHandles: ArrayList<Future<Unit>>
    let connections: ArrayList<ClientConnection>

    public init() {
        this.server = None
        this.listenerHandles = ArrayList()
        this.connections = ArrayList()
    }

    public func attachServer(server: MinecraftServer) {
        this.server = server
    }

    public func bind(address: SocketAddress) {
        listenerHandles.add(spawn { this.listenerLoop(address) })
    }

    private func listenerLoop(address: SocketAddress) {
        try(tcpServerSocket = TcpServerSocket(bindAt: address)) {
            tcpServerSocket.bind()

            println("Listening on ${tcpServerSocket.localAddress}")

            while (true) {
                let incoming = tcpServerSocket.accept()
                let clientConnection = ClientConnection(incoming)
                this.connections.add(clientConnection)
            }
        }
    }

    public func tick() {
        for (connection in this.connections) {
            connection.tick()
        }
    }

    public func stop() {
        for (listener in this.listenerHandles) {
            listener.cancel()
        }
    }
}

public class MinecraftServer {
    private let serverPropertiesLoader: ServerPropertiesLoader
    private let networkIo: ServerNetworkIo

    private var stopped: Bool = false
    private var running: Bool = false

    private var ticks = AtomicInt64(0)

    private let commandQueue = ArrayQueue<PendingServerCommand>()
    private var consoleHandler: ?Future<Unit> = Option.None

    public init(serverPropertiesLoader: ServerPropertiesLoader) {
        this.serverPropertiesLoader = serverPropertiesLoader
        this.networkIo = ServerNetworkIo()
        this.networkIo.attachServer(this)
    }

    public func setupServer() {
        this.consoleHandler = spawn {
            let bufferedReader = getStdIn()

            var command: ?String
            while (!(this.stopped && this.running)) {
                command = bufferedReader.readln()
                if (command.isSome()) {
                    this.enqueueCommand(command ?? "")
                }
            }
        }

        this.networkIo.bind(IPSocketAddress(
            IPv4Address.unspecified, 
            UInt16(this.serverPropertiesLoader.getServerPropertiesHandler().serverPort())
        ))

        this.running = true
    }

    public func runServer() {
        while (this.running) {
            this.tick()
        }

        this.networkIo.stop()
        this.consoleHandler?.cancel()
    }

    public func tick() {
        this.ticks.fetchAdd(1)
        this.networkIo.tick()
        this.executeQueuedCommands()
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

    public func get() {
        return this
    }
}
