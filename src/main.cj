public package Lodestone

import std.argopt.ArgumentMode
import std.argopt.ArgumentSpec
import std.argopt.parseArguments
import std.fs.Path

import Lodestone.server.MinecraftServer
import Lodestone.utils.properties.ServerPropertiesLoader

main(args: Array<String>): Int64 {
    let argSpec = [
        ArgumentSpec.Long("initSettings", ArgumentMode.NoValue)
    ]

    let arg = parseArguments(args, argSpec)

    let path = Path("server.properties")
    let serverPropertiesLoader = ServerPropertiesLoader(path)
    serverPropertiesLoader.save()

    if (arg.options.get("initSettings").isSome()) {
        println("Initialized server.properties")
        return 0
    }

    let server = MinecraftServer(serverPropertiesLoader)
    server.setupServer()
    server.runServer()

    return 0
}