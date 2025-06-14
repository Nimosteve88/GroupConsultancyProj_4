//
//  GluNetModel.swift
//  type2DProj
//
//  Created by Nimo, Steve on 13/06/2025.
//


import Foundation
import TensorFlowLite
import Accelerate

/// Encapsulates loading, preprocessing, and inference for the GluNet TFLite model.
final class GluNetModel {
  private var interpreter: Interpreter

  // Normalization parameters (from model training)
  private let glucoseMean: Float = 100.0
  private let glucoseStd: Float = 50.0
  private let carbMean: Float =  50.0
  private let carbStd: Float =  50.0
  private let insulinMean: Float = 1.0
  private let insulinStd: Float = 1.0

  /// Initialize interpreter with the bundled `glunet.tflite` model.
  init?() {
    print("[GluNetModel] Initializing interpreter...")
    guard let path = Bundle.main.path(forResource: "glunet", ofType: "tflite") else {
      print("[GluNetModel] ERROR: glunet.tflite not found")
      return nil
    }
    do {
      interpreter = try Interpreter(modelPath: path)
      try interpreter.allocateTensors()
      print("[GluNetModel] Interpreter allocated successfully")
    } catch {
      print("[GluNetModel] ERROR creating Interpreter: \(error)")
      return nil
    }
  }

  /// Standardizes array to zero-mean, unit-variance.
  private func normalize(_ values: [Float], mean: Float, std: Float) -> [Float] {
    return values.map { ($0 - mean) / std }
  }

  /// Denormalizes single value from zero-mean, unit-variance back.
  private func denormalize(_ value: Float, mean: Float, std: Float) -> Float {
    return value * std + mean
  }

  /// Linear interpolation of `values` to `outputLength` points.
  private func interpolate(_ values: [Float], to outputLength: Int) -> [Float] {
    let n = values.count
    guard n > 1, outputLength > 1 else { return values }
    var out = [Float](repeating: 0, count: outputLength)
    for i in 0..<outputLength {
      let t = Float(i) * Float(n - 1) / Float(outputLength - 1)
      let idx = Int(t), nxt = min(idx + 1, n - 1)
      let frac = t - Float(idx)
      out[i] = values[idx] * (1 - frac) + values[nxt] * frac
    }
    return out
  }

  /// Normalizes time to 0-1 range where 0 is 00:00 and 1 is 23:59
  private func normalizeTime(_ date: Date) -> Float {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.hour, .minute], from: date)
    let totalMinutes = Float(components.hour! * 60 + components.minute!)
    return totalMinutes / (24 * 60) // Normalize to 0-1 range
  }

  /// Predicts 30-min CGM ahead from 16-step window.
  func predict(
    glucose: [Float],
    carbs: [Float],
    insulin: [Float],
    times: [Date]
  ) -> Float? {
    // Validate lengths
    guard glucose.count == 16, times.count == 16 else { return nil }

    // Interpolate carb & insulin curves
    let carb16 = interpolate(carbs, to: 16)
    let ins16  = interpolate(insulin, to: 16)

    // Normalize each channel
    let gNorm = normalize(glucose, mean: glucoseMean, std: glucoseStd)
    let cNorm = normalize(carb16, mean: carbMean, std: carbStd)
    let iNorm = normalize(ins16, mean: insulinMean, std: insulinStd)
    let tNorm = times.map { normalizeTime($0) }

    // Build input tensor [1,16,4]
    var input = [Float](); input.reserveCapacity(64)
    for i in 0..<16 {
      input += [ gNorm[i], cNorm[i], iNorm[i], tNorm[i] ]
    }
    let inputData = input.withUnsafeBufferPointer { Data(buffer: $0) }

    do {
      try interpreter.copy(inputData, toInputAt: 0)
      try interpreter.invoke()
      let output = try interpreter.output(at: 0)
      let raw = output.data.toArray(type: Float.self).first ?? 0
      // De-normalize prediction back to mg/dL
      let denorm = denormalize(raw, mean: glucoseMean, std: glucoseStd)
      print("[GluNetModel] raw pred=\(raw), denorm=\(denorm)")
      return denorm
    } catch {
      print("[GluNetModel] Inference error: \(error)")
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
