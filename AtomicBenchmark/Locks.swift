//
//  Locks.swift
//  AtomicBenchmark
//
//  Created by Vadym Bulavin on 6/29/18.
//  Copyright © 2018 Vadim Bulavin. All rights reserved.
//

import Foundation

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
