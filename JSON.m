//
//  JSON.m
//  objcJSON
//
//  Created by Duy Pham on 31/3/15.
//  Copyright (c) 2015 Duy Pham. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "JSON.h"

@interface NSNumber (Bool)

- (BOOL)isBool;

@end
/**
 *  Error
 */
#define JSONErrorDomain @"JSONErrorDomain"
typedef enum {
    JSONErrorUnsupportedType,
    JSONErrorWrongType,
    JSONErrorIndexOutOfBounds,
    JSONErrorKeyNotExist
}JSONError;

/**
 *  private interface
 */
@interface JSON () {
    id _object;
    JSONtype _type;
    NSError * _error;
}
@end

/**
 *  implementation
 */
@implementation JSON
@synthesize object = _object;
@synthesize type   = _type;
@synthesize error  = _error;

- (instancetype)init {
    return [self initWithJSONobject:[NSNull null]];
}

+ (instancetype)nullJSON {
    return [[self alloc] initWithJSONobject:[NSNull null]];
}

- (instancetype)initWithData:(NSData *)data {
    return [self initWithData:data options:NSJSONReadingAllowFragments error:nil];
}

- (instancetype)initWithData:(NSData *)data options:(NSJSONReadingOptions)opt error:(NSError *__autoreleasing *)error {
    id object = [NSJSONSerialization JSONObjectWithData:data options:opt error:error];
    if (object != nil) {
        return [self initWithJSONobject:object];
    }
    else {
        return [self initWithJSONobject:[NSNull null]];
    }
}

- (instancetype)initWithJSONobject:(id)object {
    self = [super init];
    if (self != nil) {
        if (object != nil) {
            _object = object;
            if ([object isKindOfClass:[NSDictionary class]]) {
                _type = JSONtypeDictionary;
            }
            else if ([object isKindOfClass:[NSArray class]]) {
                _type = JSONtypeArray;
            }
            else if ([object isKindOfClass:[NSNumber class]]) {
                // check if is Bool
                if ([(NSNumber *)object isBool]) {
                    _type = JSONtypeBool;
                }
                else {
                    _type = JSONtypeNumber;
                }
            }
            else if ([object isKindOfClass:[NSString class]]) {
                _type = JSONtypeString;
            }
            else if ([object isKindOfClass:[NSNull class]]) {
                _type = JSONtypeNull;
            }
            else {
                _type = JSONtypeUnknown;
                _object = [NSNull null];
                _error = [NSError errorWithDomain:JSONErrorDomain code:JSONErrorUnsupportedType userInfo:@{NSLocalizedDescriptionKey: @"Unsupported type"}];
            }
        }
        else {
            _type = JSONtypeNull;
            _object = [NSNull null];
        }
    }
    return self;
}
/**
 *  subscripting
 */
/**
 *  if type is array
 *
 *  @return array[idx] as JSON, or nullJSON otherwise
 */
- (id)objectAtIndexedSubscript:(NSUInteger)idx {
    if (_type == JSONtypeArray) {
        NSArray * arr = _object;
        if (idx < [arr count]) {
            return [[JSON alloc] initWithJSONobject:[arr objectAtIndex:idx]];
        }
        else {
            JSON * ret = [JSON nullJSON];
            ret.error = [NSError errorWithDomain:JSONErrorDomain code:JSONErrorIndexOutOfBounds userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Index %lu out of bounds", (unsigned long)idx]}];
            return ret;
        }
    }
    else {
        JSON * ret = [JSON nullJSON];
        ret.error = [NSError errorWithDomain:JSONErrorDomain code:JSONErrorWrongType userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"JSON is not an array to return object at index %lu", (unsigned long)idx]}];
        return ret;
    }
}
/**
 *  if type is dictionary
 *
 *  @return dictionary[key] as JSON, or nullJSON otherwise
 */
- (id)objectForKeyedSubscript:(id)key {
    if (_type == JSONtypeDictionary) {
        NSDictionary * dict = self.object;
        id object = [dict objectForKey:key];
        if (object != nil) {
            return [[JSON alloc] initWithJSONobject:object];
        }
        else {
            JSON * ret = [JSON nullJSON];
            ret.error = [NSError errorWithDomain:JSONErrorDomain code:JSONErrorKeyNotExist userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Dictionary does not contains key %@", key]}];
            return ret;
        }
    }
    else {
        JSON * ret = [JSON nullJSON];
        ret.error = [NSError errorWithDomain:JSONErrorDomain code:JSONErrorWrongType userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"JSON is not an dictionary to return object for key %@", key]}];
        return ret;
    }
}
/**
 *  @return dictionary of original key and JSON object value, or nil
 */
- (NSDictionary *)dictionary {
    if (_type == JSONtypeDictionary) {
        NSDictionary * dict = _object;
        NSMutableDictionary * ret = [[NSMutableDictionary alloc] initWithCapacity:[dict count]];
        [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [ret setObject:[[JSON alloc] initWithJSONobject:obj] forKey:key];
        }];
        return [NSDictionary dictionaryWithDictionary:ret];
    }
    return nil;
}
/**
 *  @return array of JSON object or nil
 */
- (NSArray *)array {
    if (_type == JSONtypeArray) {
        NSArray * arr = _object;
        NSMutableArray * ret = [[NSMutableArray alloc] initWithCapacity:[arr count]];
        [arr enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [ret addObject:[[JSON alloc] initWithJSONobject:obj]];
        }];
        return [NSArray arrayWithArray:ret];
    }
    return nil;
}

- (NSString *)string {
    if (_type == JSONtypeString) {
        return _object;
    }
    return nil;
}
- (NSNumber *)number {
    if (_type == JSONtypeNumber) {
        return _object;
    }
    return nil;
}

- (NSNumber *)boolNumber {
    if (_type == JSONtypeBool) {
        return _object;
    }
    return false;
}

/**
 *  Description
 */
- (NSString *)description {
    NSString * description = @"Unknown";
    switch (_type) {
        case JSONtypeDictionary:
        case JSONtypeArray:
        {
            NSData * data = [NSJSONSerialization dataWithJSONObject:_object options:NSJSONWritingPrettyPrinted error:nil];
            description = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
            break;
        case JSONtypeString:
            description = _object;
            break;
        case JSONtypeNumber:
            description = [(NSNumber *)_object stringValue];
            break;
        case JSONtypeBool:
        {
            description = (BOOL)_object ? @"true" : @"false";
        }
            break;
        case JSONtypeNull:
            description = @"Null";
            break;
        default:
            break;
    }
    return description;
}

- (NSString *)debugDescription {
    return [self description];
}
@end

/**
 *  NSNumber Bool
 */
@implementation NSNumber (Bool)

- (BOOL)isBool {
    static NSNumber * trueNumber = nil;
    static NSNumber * falseNumber = nil;
    static NSString * trueObjCType = nil;
    static NSString * falseObjCType = nil;
    
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        trueNumber = [NSNumber numberWithBool:true];
        falseNumber = [NSNumber numberWithBool:false];
        trueObjCType = [NSString stringWithCString:trueNumber.objCType encoding:NSUTF8StringEncoding];
        falseObjCType = [NSString stringWithCString:falseNumber.objCType encoding:NSUTF8StringEncoding];
    });
    
    NSString * objCType = [NSString stringWithCString:self.objCType encoding:NSUTF8StringEncoding];
    if (([self compare:trueNumber] == NSOrderedSame &&  [objCType isEqualToString:trueObjCType]) ||
        ([self compare:falseNumber] == NSOrderedSame &&  [objCType isEqualToString:falseObjCType])) {
        return true;
    }
    else {
        return false;
    }
}

@end