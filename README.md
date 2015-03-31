# objcJSON
Simple [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON) written in pure Objective C

Basic main functions are there : subscript notation, type inference.

Usage like 
```objective-c
JSONresponse[@"data"][@"weather"][0][@"weatherIconUrl"][0][@"value"]
```
is valid without crashing and multiple checking at each layer of response object.

## Installation
Add JSON.h+m into your project.

## Usage
Example

```objective-c
#import "JSON.h"

[... success:^(AFHTTPRequestOperation *operation, id responseObject) {
    JSON * JSONresponse = [[JSON alloc] initWithJSONobject:responseObject];
    NSLog(@"%@",JSONresponse.description);
} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    NSLog(@"Error: %@", error);
}];
```
