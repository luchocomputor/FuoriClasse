//
//  Extensions.swift
//  Fuoriclasse
//
//  Created by Louis Almairac on 14/03/2025.
//
import SwiftUI
import SceneKit
import ModelIO

extension SCNGeometry {
    static func from(mdlMesh: MDLMesh) -> SCNGeometry? {
        var geometrySources: [SCNGeometrySource] = []
        var geometryElements: [SCNGeometryElement] = []

        // 🔥 Extraire les vertices
        guard let vertexBuffer = mdlMesh.vertexBuffers.first else {
            print("❌ Impossible de charger les vertices")
            return nil
        }

        let vertexData = Data(bytes: vertexBuffer.map().bytes, count: vertexBuffer.length)
        let vertexSource = SCNGeometrySource(data: vertexData,
                                             semantic: .vertex,
                                             vectorCount: mdlMesh.vertexCount,
                                             usesFloatComponents: true,
                                             componentsPerVector: 3,
                                             bytesPerComponent: MemoryLayout<Float>.size,
                                             dataOffset: 0,
                                             dataStride: MemoryLayout<SIMD3<Float>>.size)
        geometrySources.append(vertexSource)

        // 🔥 Extraire les indices
        if let submeshes = mdlMesh.submeshes as? [MDLSubmesh] {
            for submesh in submeshes {
                let indexData = Data(bytes: submesh.indexBuffer.map().bytes, count: submesh.indexBuffer.length)
                let geometryElement = SCNGeometryElement(data: indexData,
                                                         primitiveType: .triangles,
                                                         primitiveCount: submesh.indexCount / 3,
                                                         bytesPerIndex: submesh.indexType == MDLIndexBitDepth.uInt16 ? 2 : 4)
                geometryElements.append(geometryElement)
            }
        }

        return SCNGeometry(sources: geometrySources, elements: geometryElements)
    }
}
