//
//  Executer.swift
//  AtomicBenchmark
//
//  Created by Vadym Bulavin on 6/29/18.
//  Copyright © 2018 Vadim Bulavin. All rights reserved.
//

import Cocoa

struct Measurement {
	let iterations: Int
	let duration: TimeInterval
	let operation: String
}

struct Result {
	let measurements: [Measurement]
	let title: String
}

struct Report {
	var results: [Result]

	mutating func add(measurements: [Measurement], title: String) {
		let result = Result(measurements: measurements, title: title)
		results.append(result)
	}
}
