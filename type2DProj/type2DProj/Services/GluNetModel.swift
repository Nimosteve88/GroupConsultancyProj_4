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
    private let glucoseMean: Float = 100.0   // mg/dL
    private let glucoseStd: Float = 12.0    // mg/dL
    private let carbMean: Float =  0.0       // grams (now zero for fasting scenario)
    private let carbStd: Float =  50.0       // grams
    private let insulinMean: Float = 0.0     // arbitrary units (now zero for fasting scenario)
    private let insulinStd: Float = 1.0      // arbitrary units

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
    print("[GluNetModel] Normalized values:")
    print("[GluNetModel] Glucose: \(gNorm)")
    print("[GluNetModel] Carbs: \(cNorm)")
    print("[GluNetModel] Insulin: \(iNorm)")
    print("[GluNetModel] Times: \(tNorm)")

    // Build input tensor [1,16,4]
    var input = [Float](); input.reserveCapacity(64)
    for i in 0..<16 {
      input += [ gNorm[i], cNorm[i], iNorm[i], tNorm[i] ]
    }
    let inputData = input.withUnsafeBufferPointer { Data(buffer: $0) }

    do {
      try interpreter.copy(inputData, toInputAt: 0)
      try interpreter.invoke()
      
      // Get all outputs for debugging
//        let outputCount = interpreter.outputTensorCount
//      print("[GluNetModel] Model has \(outputCount) output tensors")
//      
//      // Print each output tensor
//      for i in 0..<outputCount {
//        let output = try interpreter.output(at: i)
//        let shape = output.shape
//        print("[GluNetModel] Output tensor \(i) shape: \(shape)")
//        
//        // Convert to Float array
//        let outputArray = output.data.toArray(type: Float.self)
//        print("[GluNetModel] Output tensor \(i) values (first 10): \(outputArray.prefix(10))")
//        
//        // If this is the 256x1 output, print it formatted
//        if shape.dimensions == [256, 1] {
//          print("[GluNetModel] 256x1 Output tensor values:")
//          for (index, value) in outputArray.enumerated() {
//            print("[\(index)]: \(value)")
//          }
//        }
//      }
      
      // Get the primary prediction output (assuming it's at index 0)
      let output = try interpreter.output(at: 0)
      let outputData = output.data
        let outputValue = outputData.withUnsafeBytes {
            $0.load(as: Float.self)
        }
      print("Output Value: \(outputValue)")
        
      print("Model Output Values: \(output)")
      let raw = ((output.data.toArray(type: Float.self).first ?? 0) - 128) * 0.1
      
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
