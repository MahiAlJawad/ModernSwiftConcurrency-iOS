# ModernSwiftConcurrency-iOS

## Modern Concurrency in Swift with Examples

In WWDC2021 Apple came up with its new alternative approach in handling **Swift Concurrency**. The motive of this project is to explain all the latest stuff introduced in Swift Concurrency in one place. We will be covering the following [topics](#topics) with **less theretical but in more practical way** with coding examples. You can get the codes directly from [ViewController.swift](https://github.com/MahiAlJawad/ModernSwiftConcurrency-iOS/blob/main/ModernSwiftConcurrency-iOS/ViewController.swift) file.

## Topics
1. [Error-handling with `try-do-catch-throw-throws` and `Result<T, E>`](#error-handling)
2. `async-await` and old approach
3. How to adopt `async-await` from scratch or from existing APIs (Continuation)
4. `Task` and `TaskGroups`
5. Async-sequence
6. `actor` and old approach

## Error-handling

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
