//
//  Array.swift
//  AtomStudies
//
//  Created by Adithiya Venkatakrishnan on 8/2/2025.
//

import SwiftUI

extension Array {
    func getSubarray(start: Int) -> [Element] {
        var array: [Element] = []
        for i in stride(from: start, to: count, by: 1) {
            array.append(self[i])
        }
        return array
    }

    func getSubarray(start: Int, end: Int) -> [Element] {
        var array: [Element] = []
        for i in stride(from: start, to: end, by: 1) {
            array.append(self[i])
        }
        return array
    }

    func getSubarray(start: Int, by: Int) -> [Element] {
        var array: [Element] = []
        for i in stride(from: start, to: count, by: by) {
            array.append(self[i])
        }
        return array
    }

    func getSubarray(by: Int) -> [Element] {
        var array: [Element] = []
        for i in stride(from: 0, to: count, by: by) {
            array.append(self[i])
        }
        return array
    }
}

extension Array where Element == Int {
    func sum() -> Int {
        var sum = 0
        for i in self { sum += i }
        return sum
    }
}
