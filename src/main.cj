public package Lodestone

import std.fs.Path

import Lodestone.utils.properties.ServerPropertiesLoader

main(): Int64 {
    let path = Path("server.properties")
    let serverPropertiesLoader = ServerPropertiesLoader(path)
    serverPropertiesLoader.save()

    return 0
}