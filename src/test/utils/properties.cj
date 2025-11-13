package Lodestone.test.utils

import std.unittest.*
import std.unittest.testmacro.Assert
import std.unittest.testmacro.Test
import std.unittest.testmacro.TestCase

import std.io.ByteBuffer
import std.io.StringReader
import std.io.StringWriter

import Lodestone.utils.properties.Properties


@Test
class PropertiesTest {
    @TestCase
    func properties_load() {
        let properties = Properties()
        properties.setProperty("test1", "2")
        properties.setProperty("test2", "1")
        let byte_buffer = ByteBuffer()
        let string_writer = StringWriter(byte_buffer)
        properties.save(string_writer)
        let properties_1 = Properties()
        let string_reader = StringReader(byte_buffer)
        properties_1.load(string_reader)
        @Assert(properties, properties_1)
    }
}
