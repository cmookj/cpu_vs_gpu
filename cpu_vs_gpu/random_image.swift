//
//  random_image.swift
//  AddCompute
//
//  Created by Changmook Chun on 11/28/21.
//

import Foundation

//                                                 Generation of random images
// -----------------------------------------------------------------------------
func randomSubImage(_ subImage: UnsafeMutablePointer<Float>,
                    from b: Int,
                    to e: Int) {
    for i in b..<e {
        subImage[i] = abs(Float(arc4random_uniform(256)))
    }
}

func randomImage(_ image: UnsafeMutablePointer<Float>, from b: Int, inParallelWith countThreads: Int) {
    let countRowsInSubImage = height / countThreads
    let groupImageGeneration = DispatchGroup()
    for index in 0..<countThreads {
        DispatchQueue.global().async(group: groupImageGeneration) {
            randomSubImage(image,
                           from: b + width * countRowsInSubImage * index,
                           to: b + width * countRowsInSubImage * (index + 1))
        }
    }
    groupImageGeneration.wait()
}

func randomImages(_ head: UnsafeMutablePointer<Float>,
                  width w: Int,
                  height h: Int,
                  count c: Int,
                  inParallelWith countThreads: Int) {
    for i in 0..<c {
        let firstElementInImage = w * h * i
        randomImage(head, from: firstElementInImage, inParallelWith: countThreads)
    }
}

func randomImages(_ head: UnsafeMutablePointer<Float>, width w: Int, height h: Int, count c: Int) {
    for i in 0..<w*h*c {
        head[i] = abs(Float(arc4random_uniform(256)))
    }
}

