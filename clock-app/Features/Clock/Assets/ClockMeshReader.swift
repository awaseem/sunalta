import Foundation

struct ClockMeshReader {
    let bytes: UnsafeRawBufferPointer
    var offset: Int

    func require(_ count: Int) throws {
        guard count <= bytes.count - offset else { throw CocoaError(.fileReadCorruptFile) }
    }

    mutating func uint32() throws -> UInt32 {
        try require(4)
        defer { offset += 4 }
        return UInt32(littleEndian: bytes.loadUnaligned(fromByteOffset: offset, as: UInt32.self))
    }

    mutating func float() throws -> Float {
        let value = Float(bitPattern: try uint32())
        guard value.isFinite else { throw CocoaError(.fileReadCorruptFile) }
        return value
    }

    mutating func vectors3(count: Int) throws -> [SIMD3<Float>] {
        try require(count * 12)
        return try (0..<count).map { _ in SIMD3(try float(), try float(), try float()) }
    }

}
