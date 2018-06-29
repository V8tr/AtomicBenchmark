//
//  Benchmark.swift
//  AtomicBenchmark
//
//  Created by Vadym Bulavin on 6/29/18.
//  Copyright © 2018 Vadim Bulavin. All rights reserved.
//

import Cocoa

func benchmark(block: () -> Void) -> TimeInterval {
	let startTime = CFAbsoluteTimeGetCurrent()
	block()
	let endTime = CFAbsoluteTimeGetCurrent()
	let totalTime = endTime - startTime
	return totalTime
}

func averageBenchmark(iterations: Int, numberOfAttempts: Int, block: (Int) -> Void) -> TimeInterval {
	var accumulatedResult: TimeInterval = 0

	for _ in 0..<numberOfAttempts {
		let result = benchmark {
			for i in 0..<iterations {
				block(i)
			}
		}
		accumulatedResult += result
	}

	return accumulatedResult / TimeInterval(numberOfAttempts)
}
