# ModernSwiftConcurrency-iOS

## Modern Concurrency in Swift with Examples

In WWDC2021 Apple came up with its new alternative approach in handling **Swift Concurrency**. The motive of this project is to explain all the latest stuff introduced in Swift Concurrency in one place. We will be covering the following [topics](#topics) with **less theoretical but in more practical way** with coding examples. You can get the codes directly from [ViewController.swift](https://github.com/MahiAlJawad/ModernSwiftConcurrency-iOS/blob/main/ModernSwiftConcurrency-iOS/ViewController.swift) file.

## Topics
1. [Error-handling with `try-do-catch-throw-throws` and `Result<T, E>`](#1-error-handling)
2. [`async-await` and old approach](#2-async-await)
3. How to adopt `async-await` from scratch or from existing APIs (Continuation)
4. `Task` and `TaskGroups`
5. Async-sequence
6. `actor` and old approach

## 1. Error-handling

This topic is not at all related to the Swift Concurrency. But as we are gonna see the coding example from `ViewController.swift` in our project, so it is important to understand the basic `try-catch` thing in Swift. If you are familiar well with this topic, you can skip this section surely.

### When to use `try`
If there's function whose declaration or signature has `throws` that means the function can throw error. To use the fuction in your code you need the keyword `try`.

Example:

```
func foo() throws -> Int {
// ... dummy throwing function
}

let result = try foo()
```

### When to use `do-catch`
If you use some function where you had to use `try` because the original function `throws` error, Then you should (not mandatory) use `catch` block to grab the error thrown from the function and handle it.

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

**You cannot make this way**. You'll get an *error*. Because you are using some other functions which can throw but you are not making any way to return any error. In this situation you have to use `throws`. The correct version is as follows.


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
    // You can also return your custom made error
  }
}
```
If you don't use `do-catch` here, as it is optional still you need to use `throws`- it's mandatory. In that case the errors which is throwsn from `foo()` or `poo()` function will be automatically thrown from `yourFunction()`.

### Use of `Result<T, E>`
There's also an alternative in fact it is the latest alternative of combining error and result altogether. If you have got the result succesfully just send usng `.success(result)` otherwise `.failure(error)`. 

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
// How to handle result
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

Well let's see what happens if we want to download 3 photos serially (one after another).

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

In fact I did 3 errors without any error from the compiller. 

```
guard let photo else { 
   return
}
```

Each time I have been checking if the photo is not nil, if we found the photo is nil we were supposed to handle this way:

```
guard let photo else { 
   completion(nil)
   return
}
```

So that the caller may know that something wrong has happened.

### Async-Await - The latest approach
