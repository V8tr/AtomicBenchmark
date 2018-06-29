//
//  GetterSetterBenchmark.swift
//  AtomicBenchmark
//
//  Created by Vadym Bulavin on 6/29/18.
//  Copyright © 2018 Vadim Bulavin. All rights reserved.
//

import Foundation

struct GetterSetterBenchmark {
	struct Settings {
		let attemptsPerIteration: Int
		let iterationsPerSample: [Int]
	}

	let settings: Settings

	func measure(sample: Sample) -> Result {
		var sample = sample

		let getterMeasurements = settings.iterationsPerSample.map {
			self.makeMeasurement(operation: "Getter", numberOfIterations: $0) { _ in
				_ = sample.foo
			}
		}

		let setterMeasurements = settings.iterationsPerSample.map {
			self.makeMeasurement(operation: "Setter", numberOfIterations: $0) { i in
				sample.foo = i
			}
		}

		return Result(measurements: getterMeasurements + setterMeasurements, title: sample.title)
	}

	private func makeMeasurement(operation: String, numberOfIterations: Int, block: (Int) -> Void) -> Measurement {
		let duration = averageBenchmark(iterations: numberOfIterations, numberOfAttempts: settings.attemptsPerIteration, block: block)
		return Measurement(iterations: numberOfIterations, duration: duration, operation: operation)
	}
}


