//
//  GluNetModel.swift
//  type2DProj
//
//  Created by Nimo, Steve on 13/06/2025.
//

import Foundation
import TensorFlowLite
import Accelerate

/// Encapsulates loading and inference for the GluNet TFLite model.
final class GluNetModel {
  private var interpreter: Interpreter

  /// Initialize interpreter with the bundled `glunet.tflite` model.
  init?() {
    guard let modelPath = Bundle.main.path(forResource: "glunet", ofType: "tflite") else {
      print("Failed to find glunet.tflite in bundle")
      return nil
    }
    do {
      interpreter = try Interpreter(modelPath: modelPath)
      try interpreter.allocateTensors()
    } catch {
      print("Error creating TensorFlowLite interpreter: \(error)")
      return nil
    }
  }

  /// Linear interpolation of `values` to `outputLength` points.
  private func interpolate(_ values: [Float], to outputLength: Int) -> [Float] {
    let inputCount = values.count
    guard inputCount > 1, outputLength > 1 else {
      return values
    }
    var result = [Float](repeating: 0, count: outputLength)
    for i in 0..<outputLength {
      let t = Float(i) * Float(inputCount - 1) / Float(outputLength - 1)
      let idx = Int(t)
      let frac = t - Float(idx)
      let next = min(idx + 1, inputCount - 1)
      result[i] = values[idx] * (1 - frac) + values[next] * frac
    }
    return result
  }

  /// Run a 16×4 inference: CGM, carbs, insulin, time for last 16 steps.
  func predict(
    glucose: [Float],
    carbs: [Float],
    insulin: [Float],
    times: [Float]
  ) -> Float? {
    // Must have exactly 16 glucose points
    guard glucose.count == 16,
          times.count == 16 else {
      return nil
    }
    // Interpolate carbs & insulin to 16 points
    let carb16 = interpolate(carbs, to: 16)
    let ins16 = interpolate(insulin, to: 16)

    // Build input tensor [1,16,4]
    var inputData = [Float]()
    inputData.reserveCapacity(16 * 4)
    for i in 0..<16 {
      inputData.append(glucose[i])
      inputData.append(carb16[i])
      inputData.append(ins16[i])
      inputData.append(times[i])
    }

    // Convert [Float] to Data
    let data = inputData.withUnsafeBufferPointer { buf in
      Data(buffer: buf)
    }

    do {
      try interpreter.copy(data, toInputAt: 0)
      try interpreter.invoke()
      let outputTensor = try interpreter.output(at: 0)
      let outputFloats: [Float] = outputTensor.data.toArray(type: Float.self)
      return outputFloats.first
    } catch {
      print("TensorFlowLite invocation error: \(error)")
      return nil
    }
  }
}

extension Data {
  /// Convert raw bytes into an array of `T`.
  func toArray<T>(type: T.Type) -> [T] where T: Numeric {
    let count = self.count / MemoryLayout<T>.stride
    return self.withUnsafeBytes { rawBuffer in
      let buffer = rawBuffer.bindMemory(to: T.self)
      return [T](buffer.prefix(count))
    }
  }
}
