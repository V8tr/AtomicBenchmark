//
//  main.swift
//  AtomicBenchmark
//
//  Created by Vadym Bulavin on 6/29/18.
//  Copyright © 2018 Vadim Bulavin. All rights reserved.
//

import Foundation

// MARK: - Settings

let numberOfAttempts = 100
let iterations = [1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, /*4096, 8192, 16_384, 32_768, 65_536, 131_072, 262_144, 524_288, 1_048_576, 2_097_152, 4_194_304*/]

// MARK: - Locks

final class SpinLock {
	private var unfairLock = os_unfair_lock_s()

	func lock() {
		os_unfair_lock_lock(&unfairLock)
	}

	func unlock() {
		os_unfair_lock_unlock(&unfairLock)
	}
}

final class Mutex {
	private var mutex: pthread_mutex_t = {
		var mutex = pthread_mutex_t()
		pthread_mutex_init(&mutex, nil)
		return mutex
	}()

	func lock() {
		pthread_mutex_lock(&mutex)
	}

	func unlock() {
		pthread_mutex_unlock(&mutex)
	}
}

final class ReadWriteLock {
	private var rwlock: pthread_rwlock_t = {
		var rwlock = pthread_rwlock_t()
		pthread_rwlock_init(&rwlock, nil)
		return rwlock
	}()

	func lock() {
		pthread_rwlock_wrlock(&rwlock)
	}

	func unlock() {
		pthread_rwlock_unlock(&rwlock)
	}
}

// MARK: - SUT

class LockSample {
	private let lock: () -> Void
	private let unlock: () -> Void

	init(lock: @escaping () -> Void, unlock: @escaping () -> Void) {
		self.lock = lock
		self.unlock = unlock
	}

	private var underlyingFoo = 0

	var foo: Int {
		get {
			lock()
			let value = underlyingFoo
			unlock()
			return value
		}
		set {
			lock()
			underlyingFoo = newValue
			unlock()
		}
	}
}

// MARK: - Benchmark

struct Result {
	let iterations: Int
	let duration: TimeInterval
}

func benchmark(_ block: () -> Void) -> TimeInterval {
	let startTime = CFAbsoluteTimeGetCurrent()
	block()
	let endTime = CFAbsoluteTimeGetCurrent()
	let totalTime = endTime - startTime
	return totalTime
}

func averageBenchmark(iterations: Int, numberOfAttempts: Int, _ block: (Int) -> Void) -> Result {
	var accumulatedResult: TimeInterval = 0

	for _ in 0..<numberOfAttempts {
		let result = benchmark {
			for i in 0..<iterations {
				block(i)
			}
		}
		accumulatedResult += result
	}

	return Result(iterations: iterations, duration: accumulatedResult / TimeInterval(numberOfAttempts))
}

// MARK: - Calculations

func printResults(_ results: [Result], identifier: String) {
	print("**** \(identifier) benchmark results ****")
	for result in results {
		print("Iterations: \(result.iterations) - \(result.duration)s")
	}
}

var getterResults: [Result] = []
var setterResults: [Result] = []

// MARK: - Lock

let lock = NSLock()
let nsLockSample = LockSample(lock: lock.lock, unlock: lock.unlock)

getterResults = iterations.map {
	averageBenchmark(iterations: $0, numberOfAttempts: numberOfAttempts) { _ in
		_ = nsLockSample.foo
	}
}

setterResults = iterations.map {
	averageBenchmark(iterations: $0, numberOfAttempts: numberOfAttempts) {
		nsLockSample.foo = $0
	}
}

print("**** Lock ****")
printResults(getterResults, identifier: "Getter")
printResults(setterResults, identifier: "Setter")

// MARK: - Mutex

let mutex = Mutex()
let mutexSample = LockSample(lock: mutex.lock, unlock: mutex.unlock)

getterResults = iterations.map {
	averageBenchmark(iterations: $0, numberOfAttempts: numberOfAttempts) { _ in
		_ = mutexSample.foo
	}
}

setterResults = iterations.map {
	averageBenchmark(iterations: $0, numberOfAttempts: numberOfAttempts) {
		mutexSample.foo = $0
	}
}

print("**** Mutex ****")
printResults(getterResults, identifier: "Getter")
printResults(setterResults, identifier: "Setter")

// MARK: - SpinLock

let spinLock = SpinLock()
let spinLockSample = LockSample(lock: spinLock.lock, unlock: spinLock.unlock)

getterResults = iterations.map {
	averageBenchmark(iterations: $0, numberOfAttempts: numberOfAttempts) { _ in
		_ = spinLockSample.foo
	}
}

setterResults = iterations.map {
	averageBenchmark(iterations: $0, numberOfAttempts: numberOfAttempts) {
		spinLockSample.foo = $0
	}
}

print("**** SpinLock ****")
printResults(getterResults, identifier: "Getter")
printResults(setterResults, identifier: "Setter")

// MARK: - Read Write Lock

let rwLock = ReadWriteLock()
let rwLockSample = LockSample(lock: rwLock.lock, unlock: rwLock.unlock)

getterResults = iterations.map {
	averageBenchmark(iterations: $0, numberOfAttempts: numberOfAttempts) { _ in
		_ = rwLockSample.foo
	}
}

setterResults = iterations.map {
	averageBenchmark(iterations: $0, numberOfAttempts: numberOfAttempts) {
		rwLockSample.foo = $0
	}
}

print("**** Read Write Lock ****")
printResults(getterResults, identifier: "Getter")
printResults(setterResults, identifier: "Setter")

// MARK: - Dispatch Queue

class DispatchQueueSample {
	private let queue = DispatchQueue(label: "com.vadimbulavin.DispatchQueueSample")
	private var underlyingFoo = 0

	var foo: Int {
		get {
			return queue.sync { underlyingFoo }
		}
		set {
			queue.sync {
				self.underlyingFoo = newValue
			}
		}
	}
}

let dispatchQueueSample = DispatchQueueSample()

getterResults = iterations.map {
	averageBenchmark(iterations: $0, numberOfAttempts: numberOfAttempts) { _ in
		_ = dispatchQueueSample.foo
	}
}

setterResults = iterations.map {
	return averageBenchmark(iterations: $0, numberOfAttempts: numberOfAttempts) {
		dispatchQueueSample.foo = $0
	}
}

print("**** Dispatch Queue ****")
printResults(getterResults, identifier: "Getter")
printResults(setterResults, identifier: "Setter")

// MARK: - Operations Queue

class OperationsQueueSample {
	private let queue = OperationQueue()
	private var underlyingFoo = 0

	var foo: Int {
		get {
			var foo: Int!
			execute(on: queue) { [underlyingFoo] in
				foo = underlyingFoo
			}
			return foo
		}
		set {
			execute(on: queue) {
				self.underlyingFoo = newValue
			}
		}
	}

	private func execute(on q: OperationQueue, block: @escaping () -> Void) {
		let op = BlockOperation(block: block)
		q.addOperation(op)
		op.waitUntilFinished()
	}
}

let operationsQueueSample = OperationsQueueSample()

getterResults = iterations.map {
	return averageBenchmark(iterations: $0, numberOfAttempts: numberOfAttempts) { _ in
		_ = operationsQueueSample.foo
	}
}

setterResults = iterations.map {
	return averageBenchmark(iterations: $0, numberOfAttempts: numberOfAttempts) {
		operationsQueueSample.foo = $0
	}
}

print("**** Operations Queue ****")
printResults(getterResults, identifier: "Getter")
printResults(setterResults, identifier: "Setter")

