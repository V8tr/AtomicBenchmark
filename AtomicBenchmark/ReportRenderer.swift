//
//  ReportRenderer.swift
//  AtomicBenchmark
//
//  Created by Vadym Bulavin on 6/29/18.
//  Copyright © 2018 Vadim Bulavin. All rights reserved.
//

import Foundation

struct ReportRenderer {
	let report: Report

	func render() {
		for result in report.results {
			print("***** \(result.title) *****")
			for measurement in result.measurements {
				print("\(measurement.operation): \(measurement.iterations) iterations completed in \(measurement.duration)s")
			}
			print("\n")
		}
	}
}

struct CSVReportRenderer {
	let report: Report
	let fileName: String

	func render() {
		guard let path = FileManager.default.urls(for: .desktopDirectory, in: .allDomainsMask).first?.appendingPathComponent(fileName) else {
			fatalError()
		}

		var content = ""
		content += "Operation,Number of iterations,Duration in seconds\n"

		for result in report.results {
			content += "\(result.title)\n"
			for measurement in result.measurements {
				content += "\(measurement.operation),\(measurement.iterations),\(measurement.duration)\n"
			}
			content += "\n"
		}

		try! content.write(to: path, atomically: true, encoding: .utf8)
	}
}
