# ModernSwiftConcurrency-iOS

## Modern Concurrency in Swift with Examples

In WWDC2021 Apple came up with its new alternative approach to handling **Swift Concurrency**. The motive of this project is to explain all the latest stuff introduced in Swift Concurrency in one place. We will be covering the following [topics](#topics) with **less theoretical but more practical** with coding examples. You can get the codes directly from [ViewController.swift](https://github.com/MahiAlJawad/ModernSwiftConcurrency-iOS/blob/main/ModernSwiftConcurrency-iOS/ViewController.swift) file.

## Topics
1. [Error-handling with `try-do-catch-throw-throws` and `Result<T, E>`](#1-error-handling)
2. [`async-await` and old approach](#2-async-await)
3. How to adopt `async-await` from scratch or existing APIs (Continuation)
4. `Task` and `TaskGroups`
5. Async-sequence
6. `actor` and old approach

## 1. Error-handling

This topic is not at all related to Swift Concurrency. But as we are gonna see the coding example from `ViewController.swift` in our project, it is important to understand the basic `try-catch` thing in Swift. If you are familiar well with this topic, you can skip this section surely.

### When to use `try`
If there's a function whose declaration or signature has `throws` that means the function can throw an error. To use the function in your code you need the keyword `try`.

Example:

```
func foo() throws -> Int {
// ... dummy throwing function
}

let result = try foo()
```

### When to use `do-catch`
If you use some function where you had to use `try` because the original function `throws` an error, Then you should (not mandatory) use a `catch` block to grab the error thrown from the function and handle it.

Example:

```
do {
  try result1 = try foo()
  try result2 = try poo()
} catch {
  print("Error: \(error)")
  // Now you can get the possible errors thrown from `foo()` or `poo()` function here and handle as you desire. 
}
```

### When to use `throws-throw`
Let's say the above code block you used in some of your function

```
func yourFunction() -> Int {
  do {
    try result1 = try foo()
    try result2 = try poo()
    return result1 + result2
  } catch {
    print("Error: \(error)")
    // Now you can get the possible errors thrown from `foo()` or `poo()` function here and handle as you desire. 
  }
}
```

**You cannot make this way**. You'll get an *error*. Because you are using some other functions which can throw but you are not making any way to return any error. In this situation, you have to use `throws`. The correct version is as follows.


```
func yourFunction() throws -> Int {
  do {
    try result1 = try foo()
    try result2 = try poo()
    return result1 + result2
  } catch {
    print("Error: \(error)")
    // Now you can get the possible errors thrown from `foo()` or `poo()` function here and handle as you desire. 
    return error 
    // You can also return your custom-made error
  }
}
```
If you don't use `do-catch` here, as it is optional still you need to use `throws`- it's mandatory. In that case, the errors which are thrown from the `foo()` or `poo()` function will be automatically thrown from `yourFunction()`.

### Use of `Result<T, E>`
There's also an alternative it is the latest alternative of combining error and result altogether. If you have got the result successfully just send using `.success(result)` otherwise `.failure(error)`. 

Example:

```
// Custom error
enum CustomError: Error {
case serverError
}

func yourFunction() throws -> Result<Int, CustomError> {
  do {
    try result1 = try foo()
    try result2 = try poo()
    return .success(return1+return2)
  } catch {
    print("Error: \(error)")
    // Now you can get the possible errors thrown from `foo()` or `poo()` function here and handle as you desire. 
    return .failure(.serverError) 
  }
}
```

```
// How to handle the result
let myResult = try yourFunction()

switch myResult {
case .success(let result):
  print("Result is: \(result)
case .failure(let error):
  print("Got error: \(error)
}
```

## 2. Async-Await

### Old Approach
Let's say we want to download a photo using some API. The previous approach was something like this:

```
// Imagine we have this API
func downloadPhoto(with photoID: Int, completion: @escaping (UIImage?) -> ())

// Use of this API

downloadPhoto(with: 1) { photo in
// Now do the task you want to do with this photo
}
```

**What's the problem with this approach?**

Well, let's see what happens if we want to download 3 photos serially (one after another).

```
downloadPhoto(with: 1) { photo1 in
  guard let photo1 else {
    return
  }
  
  downloadPhoto(with: 2) { photo2 in
    guard let photo2 else {
      return
    }
    
    downloadPhoto(with: 3) { photo3 in
      guard let photo3 else { 
        return
      }
      
      // Downloaded all 3 photos
      // Now we'll do whatever task we need to do with these 3 photos
    }
  }
}

```

2 problem happens here:

* Code becomes so long to manage
* Long codes are more error-prone

In fact, I did 3 errors without any error from the compiler. 

```
guard let photo else { 
   return
}
```

Each time I have been checking if the photo is not nil, if we found the photo is nil we were supposed to handle it this way:

```
guard let photo else { 
   completion(nil)
   return
}
```

So that the caller may know that something wrong has happened.

### `Async-Await`- The latest approach

`async` is a keyword if it is used in the function signature then it refers that the function working asynchronously. Generally, it is used in functions that have some task that can make some delay in completion. Such as network calls from APIs. 

- Async function refers that it contains an asynchronous task
- It may do a delay in calculation or fetching the data

For example:

```
func downloadPhoto(with photoID: Int) async throws -> UIImage
```

This is a function that can make a delay in returning the result i.e. UIImage. And also the function works asynchronously. This means during this function executing OS will not block the current thread. Rather the task will be asynchronously managed by the Operating System. Once the task is done this task or function will return the image result.

The `await` keyword is used during the calling of such an `async` function. 

```
let image = try await downloadPhoto(with: 1)
```

`await` indicates that it's a possible suspension point in execution. In simple words code execution might be(not mandatorily) paused when there is an `await` keyword. Code execution will be further resumed once the result from the `downloadPhoto()` function is returned. So when there is an `await` keyword the code execution might be paused and further resumed from that point when the result is returned from the `async` function. 

Let's have a look at the newer version of the previous code of downloading 3 images serially.

```
let image1 = try await downloadPhoto(with: 1)
let image2 = try await downloadPhoto(with: 2)
let image3 = try await downloadPhoto(with: 3)
// Done downloading 3 images one after another
```

We can see we replaced the previous long code with only 3 lines of code. Also, an error will be handled by the `try` approach. We will see how we can make the `async` function. For time being just assume we have the asynchronous `downloadPhoto()` function.

Some points need to mention here until the image1 is downloaded the image2 statement will not be executed. After the first line execution is completed and image1 is returned only then the next line will be executed. Similar goes for the other lines. Because there is an `await` keyword. It will pause and resume according to the OS decisions. Only after the result is returned from the `downloadPhoto()` function then the next line will be started. So the tasks will execute **serially**.

Let us discuss some more possible suspension points. As we said earlier if there's an `await` keyword the function execution might be suspended and paused. But not mandatorily paused. Let's say there's enough core in the CPU to execute the function's task, then it will not pause the execution at all. But if there's a shortage of CPU core then the function execution might take a while so OS will decide by its priority of tasks that when to pause or resume the function execution. 
