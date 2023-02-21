//
//  ViewController.swift
//  ModernSwiftConcurrency-iOS
//
//  Created by Mahi Al Jawad on 19/2/23.
//

import UIKit

class ViewController: UIViewController {

    // MARK: Uncomment each function calling in viewDidLoad to start and check examples
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MARK: Each of the Task { } block is Unstructured Concurrency
        
        // MARK: Async-await example with SERIAL execution
//        Task {
//            try await getPhotosInSerialExecution()
//        }
        
        // MARK: Async-await example with PARALLEL execution
//        Task {
//            try await getPhotosInParallelExecution()
//        }
        
        // MARK: TaskGroup example
        // Also we can set priority in each task
        Task(priority: .high) {
            do {
                try await getPhotosWithTaskGroupExecution(numberOfPhotos: 5)
            } catch{
                // If any of the child task is failed
                // then the whole parent task will be canceled
                // and an error will be thrown
                print("Error in parent-task: \(error)")
                throw error
            }
        }
    }
}

// MARK: Async-await example with SERIAL EXECUTION
extension ViewController {
    func getPhotosInSerialExecution() async throws -> [UIImage] {
        // The flow of execution is done IN SERIAL
        // i.e. When the image1 is downloading due to the `await` keyword
        // THE THREAD IS RELEASED for other job. image2 download will not
        // start until the image1 download is not completed
        // Same goes for the image3 download will not start until the image2
        // download is done
        
        let image1 = try await downloadPhoto(with: 1)
        let image2 = try await downloadPhoto(with: 2)
        let image3 = try await downloadPhoto(with: 3)
        print("Done downloading all 3 photos")
        return [image1, image2, image3]
    }
}

// MARK: Async-await example with PARALLEL EXECUTION
extension ViewController {
    func getPhotosInParallelExecution() async throws -> [UIImage] {
        async let image1 = downloadPhoto(with: 1)
        async let image2 = downloadPhoto(with: 2)
        async let image3 = downloadPhoto(with: 3)
        // All three downloading tasks will start now
        // All three tasks will execute in parallel
        // After all 3 images are donwloaded completely
        // then the function will return
        // During the execution of each download in parallel the current
        // thread may be released as this tasks are marked as `await`
        return try await [image1, image2, image3]
    }
}

// MARK: TaskGroup
extension ViewController {
    // When we have dynamic number of async tasks
    // to execute then TaskGroup is the approach we need.
    func getPhotosWithTaskGroupExecution(numberOfPhotos: Int) async throws -> [UIImage] {
        // We will write the return type of each task in the first argument
        // That's why we used UIImage.self as each task gives UIImage in return
        return try await withThrowingTaskGroup(of: UIImage?.self) { [weak self] taskGroup -> [UIImage] in
            guard let self else { return [] }

            for i in 1...numberOfPhotos {
                // We can also separately add priorities to the each task
                taskGroup.addTask {
                    // MARK: Task Cancellation checking example
                    // Also some other APIs available under Task
                    // e.g. Task.isCancelled which returns Bool
                    do {
                        try Task.checkCancellation()
                        return try await self.downloadPhoto(with: i)
                    } catch {
                        print("Error in a child-task: \(error)")
                        // Let's say we don't want to throw error
                        // if any downloading fails
                        // rather we want to return nil
                        return nil
                    }
                }
            }
            
            // MARK: To check download failure case cancel the task here
            // It's just a dummy way to check any task failure
            //taskGroup.cancelAll()

            // MARK: AsyncSequence
            // Till this point all the tasks will start execute IN PARALLEL
            // We just collected all tasks together to
            // collect their result output i.e. [UIImage] in this case
            
            // This for-await-in also known as ASYNC-SEQUENCE. We are just
            // iterating over the asynchronous tasks
            var images = [UIImage]()
            for try await image in taskGroup {
                if let image = image {
                    images.append(image)
                } else {
                    // MARK: TaskGroup Cancel example
                    // Let's say If any of the child-task result was failed(found nil)
                    // Then we want to cancel the whole parent task i.e. taskGroup
                    taskGroup.cancelAll()
                    throw DownloadError.taskCancelled
                }
                
                
            }
            return images
        }
    }
}


// MARK: Dummy time-consuming long running task e.g. Network call
extension ViewController {
    func downloadPhoto(with photoID: Int) async throws -> UIImage {
        print("Starting downloading with photoID: \(photoID)")
        try await Task.sleep(until: .now + .seconds(2), clock: .continuous)
        print("Finished downloading with photoID: \(photoID)")
        return UIImage()
    }
}

enum DownloadError: Error {
    case taskCancelled
}
