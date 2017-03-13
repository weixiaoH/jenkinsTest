//  JPEngine.m
//  JSPatch
//
//  Created by bang on 15/4/30.
//  Copyright (c) 2015 bang. All rights reserved.
//

#import "CTEngine.h"
#import <objc/runtime.h>
#import <objc/message.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIApplication.h>
#endif

@implementation JPXXXBoxing

#define JPBOXING_GEN(_name, _prop, _type) \
+ (instancetype)_name:(_type)obj  \
{   \
    JPXXXBoxing *boxing = [[JPXXXBoxing alloc] init]; \
    boxing._prop = obj;   \
    return boxing;  \
}

JPBOXING_GEN(boxObj, obj, id)
JPBOXING_GEN(boxPointer, pointer, void *)
JPBOXING_GEN(boxClass, cls, Class)
JPBOXING_GEN(boxWeakObj, weakObj, id)
JPBOXING_GEN(boxAssignObj, assignObj, id)

- (id)unbox
{
    if (self.obj) return self.obj;
    if (self.weakObj) return self.weakObj;
    if (self.assignObj) return self.assignObj;
    if (self.cls) return self.cls;
    return self;
}
- (void *)unboxPointer
{
    return self.pointer;
}
- (Class)unboxClass
{
    return self.cls;
}
@end

#pragma mark - Fix iOS7 NSInvocation fatal error
// A fatal error of NSInvocation on iOS7.0.
// A invocation return 0 when the return type is double/float.
// http://stackoverflow.com/questions/19874502/nsinvocation-getreturnvalue-with-double-value-produces-0-unexpectedly

typedef struct {double d;} JPXXXDouble;
typedef struct {float f;} JPXXXFloat;

static NSMethodSignature *fixXXXSignature(NSMethodSignature *signature)
{
#if TARGET_OS_IPHONE
#ifdef __LP64__
    if (!signature) {
        return nil;
    }
    
    if ([[UIDevice currentDevice].systemVersion floatValue] < 7.09) {
        BOOL isReturnDouble = (strcmp([signature methodReturnType], "d") == 0);
        BOOL isReturnFloat = (strcmp([signature methodReturnType], "f") == 0);

        if (isReturnDouble || isReturnFloat) {
            NSMutableString *types = [NSMutableString stringWithFormat:@"%s@:", isReturnDouble ? @encode(JPXXXDouble) : @encode(JPXXXFloat)];
            for (int i = 2; i < signature.numberOfArguments; i++) {
                const char *argType = [signature getArgumentTypeAtIndex:i];
                [types appendFormat:@"%s", argType];
            }
            signature = [NSMethodSignature signatureWithObjCTypes:[types UTF8String]];
        }
    }
#endif
#endif
    return signature;
}

@interface NSObject (JPXXXFix)
- (NSMethodSignature *)jp_methodSignatureForSelector:(SEL)aSelector;
+ (void)jp_fixMethodSignature;
@end

@implementation NSObject (JPXXXFix)
const static void *JPFixedXXXFlagKey = &JPFixedXXXFlagKey;
- (NSMethodSignature *)jp_methodSignatureForSelector:(SEL)aSelector
{
    NSMethodSignature *signature = [self jp_methodSignatureForSelector:aSelector];
    return fixXXXSignature(signature);
}
+ (void)jp_fixMethodSignature
{
#if TARGET_OS_IPHONE
#ifdef __LP64__
    if ([[UIDevice currentDevice].systemVersion floatValue] < 7.1) {
        NSNumber *flag = objc_getAssociatedObject(self, JPFixedXXXFlagKey);
        if (!flag.boolValue) {
            SEL originalSelector = @selector(methodSignatureForSelector:);
            SEL swizzledSelector = @selector(jp_methodSignatureForSelector:);
            Method originalMethod = class_getInstanceMethod(self, originalSelector);
            Method swizzledMethod = class_getInstanceMethod(self, swizzledSelector);
            BOOL didAddMethod = class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
            if (didAddMethod) {
                class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
            } else {
                method_exchangeImplementations(originalMethod, swizzledMethod);
            }
            objc_setAssociatedObject(self, JPFixedXXXFlagKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
#endif
#endif
}
@end

#pragma mark -

static JSContext *_XXXcontext;
static NSString *_XXXregexStr = @"(?<!\\\\)\\.\\s*(\\w+)\\s*\\(";
static NSString *_XXXreplaceStr = @".__c(\"$1\")(";
static NSRegularExpression* _XXXregex;
static NSObject *_XXXnullObj;
static NSObject *_XXXnilObj;
static NSMutableDictionary *_XXXregisteredStruct;
static NSMutableDictionary *_XXXcurrInvokeSuperClsName;
static char *XXXkPropAssociatedObjectKey;
static BOOL _XXXautoConvert;
static BOOL _XXXconvertOCNumberToString;
static NSString *_XXXscriptRootDir;
static NSMutableSet *_XXXrunnedScript;

static NSMutableDictionary *_XXXJSOverideMethods;
static NSMutableDictionary *_XXXTMPMemoryPool;
static NSMutableDictionary *_XXXpropKeys;
static NSMutableDictionary *_XXXJSMethodSignatureCache;
static NSLock              *_XXXJSMethodSignatureLock;
static NSRecursiveLock     *_XXXJSMethodForwardCallLock;
static NSMutableDictionary *_XXXprotocolTypeEncodeDict;
static NSMutableArray      *_XXXpointersToRelease;

#ifdef DEBUG
static NSArray *_XXXJSLastCallStack;
#endif

static void (^_XXXexceptionBlock)(NSString *log) = ^void(NSString *log) {
    NSCAssert(NO, log);
};

@implementation CTXXXEngine

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

#pragma mark - APIS

+ (void)startXXXEngine
{
    if (![JSContext class] || _XXXcontext) {
        return;
    }
    
    JSContext *context = [[JSContext alloc] init];
    
#ifdef DEBUG
    context[@"po"] = ^JSValue*(JSValue *obj) {
        id ocObject = formatXXXJSToOC(obj);
        return [JSValue valueWithObject:[ocObject description] inContext:_XXXcontext];
    };

    context[@"bt"] = ^JSValue*() {
        return [JSValue valueWithObject:_XXXJSLastCallStack inContext:_XXXcontext];
    };
#endif

    context[@"_OC_XXXdefineClass"] = ^(NSString *classDeclaration, JSValue *instanceMethods, JSValue *classMethods) {
        return defineXXXClass(classDeclaration, instanceMethods, classMethods);
    };

    context[@"_OC_XXXdefineProtocol"] = ^(NSString *protocolDeclaration, JSValue *instProtocol, JSValue *clsProtocol) {
        return defineXXXProtocol(protocolDeclaration, instProtocol,clsProtocol);
    };
    
    context[@"_OC_XXXcallI"] = ^id(JSValue *obj, NSString *selectorName, JSValue *arguments, BOOL isSuper) {
        return callXXXSelector(nil, selectorName, arguments, obj, isSuper);
    };
    context[@"_OC_XXXcallC"] = ^id(NSString *className, NSString *selectorName, JSValue *arguments) {
        return callXXXSelector(className, selectorName, arguments, nil, NO);
    };
    context[@"_OC_XXXformatJSToOC"] = ^id(JSValue *obj) {
        return formatXXXJSToOC(obj);
    };
    
    context[@"_OC_XXXformatOCToJS"] = ^id(JSValue *obj) {
        return formatOCToXXXJS([obj toObject]);
    };
    
    context[@"_OC_XXXgetCustomProps"] = ^id(JSValue *obj) {
        id realObj = formatXXXJSToOC(obj);
        return objc_getAssociatedObject(realObj, XXXkPropAssociatedObjectKey);
    };
    
    context[@"_OC_XXXsetCustomProps"] = ^(JSValue *obj, JSValue *val) {
        id realObj = formatXXXJSToOC(obj);
        objc_setAssociatedObject(realObj, XXXkPropAssociatedObjectKey, val, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    };
    
    context[@"__weak"] = ^id(JSValue *jsval) {
        id obj = formatXXXJSToOC(jsval);
        return [[JSContext currentContext][@"_formatXXXOCToJS"] callWithArguments:@[formatOCToXXXJS([JPXXXBoxing boxWeakObj:obj])]];
    };

    context[@"__strong"] = ^id(JSValue *jsval) {
        id obj = formatXXXJSToOC(jsval);
        return [[JSContext currentContext][@"_formatXXXOCToJS"] callWithArguments:@[formatOCToXXXJS(obj)]];
    };
    
    context[@"_OC_XXXsuperClsName"] = ^(NSString *clsName) {
        Class cls = NSClassFromString(clsName);
        return NSStringFromClass([cls superclass]);
    };
    
    context[@"autoConvertOCType"] = ^(BOOL autoConvert) {
        _XXXautoConvert = autoConvert;
    };

    context[@"convertOCNumberToString"] = ^(BOOL convertOCNumberToString) {
        _XXXconvertOCNumberToString = convertOCNumberToString;
    };
    
    context[@"include"] = ^(NSString *filePath) {
        NSString *absolutePath = [_XXXscriptRootDir stringByAppendingPathComponent:filePath];
        if (!_XXXrunnedScript) {
            _XXXrunnedScript = [[NSMutableSet alloc] init];
        }
        if (absolutePath && ![_XXXrunnedScript containsObject:absolutePath]) {
            [CTXXXEngine _evaluateXXXScriptWithPath:absolutePath];
            [_XXXrunnedScript addObject:absolutePath];
        }
    };
    
    context[@"resourcePath"] = ^(NSString *filePath) {
        return [_XXXscriptRootDir stringByAppendingPathComponent:filePath];
    };

    context[@"dispatch_after"] = ^(double time, JSValue *func) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [func callWithArguments:nil];
        });
    };
    
    context[@"dispatch_async_main"] = ^(JSValue *func) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [func callWithArguments:nil];
        });
    };
    
    context[@"dispatch_sync_main"] = ^(JSValue *func) {
        if ([NSThread currentThread].isMainThread) {
            [func callWithArguments:nil];
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [func callWithArguments:nil];
            });
        }
    };
    
    context[@"dispatch_async_global_queue"] = ^(JSValue *func) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [func callWithArguments:nil];
        });
    };
    
    context[@"releaseTmpObj"] = ^void(JSValue *jsVal) {
        if ([[jsVal toObject] isKindOfClass:[NSDictionary class]]) {
            void *pointer =  [(JPXXXBoxing *)([jsVal toObject][@"__obj"]) unboxPointer];
            id obj = *((__unsafe_unretained id *)pointer);
            @synchronized(_XXXTMPMemoryPool) {
                [_XXXTMPMemoryPool removeObjectForKey:[NSNumber numberWithInteger:[(NSObject*)obj hash]]];
            }
        }
    };
    
    context[@"_OC_XXXlog"] = ^() {
        NSArray *args = [JSContext currentArguments];
        for (JSValue *jsVal in args) {
            id obj = formatXXXJSToOC(jsVal);
            NSLog(@"CTPatch.log: %@", obj == _XXXnilObj ? nil : (obj == _XXXnullObj ? [NSNull null]: obj));
        }
    };
    
    context[@"_OC_XXXcatch"] = ^(JSValue *msg, JSValue *stack) {
        _XXXexceptionBlock([NSString stringWithFormat:@"js exception, \nmsg: %@, \nstack: \n %@", [msg toObject], [stack toObject]]);
    };
    
    context.exceptionHandler = ^(JSContext *con, JSValue *exception) {
        NSLog(@"%@", exception);
        _XXXexceptionBlock([NSString stringWithFormat:@"js exception: %@", exception]);
    };
    
    _XXXnullObj = [[NSObject alloc] init];
    context[@"_OC_XXXnull"] = formatOCToXXXJS(_XXXnullObj);
    
    _XXXcontext = context;
    
    _XXXnilObj = [[NSObject alloc] init];
    _XXXJSMethodSignatureLock = [[NSLock alloc] init];
    _XXXJSMethodForwardCallLock = [[NSRecursiveLock alloc] init];
    _XXXregisteredStruct = [[NSMutableDictionary alloc] init];
    _XXXcurrInvokeSuperClsName = [[NSMutableDictionary alloc] init];
    
#if TARGET_OS_IPHONE
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMemoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
#endif
    
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"CTEngine" ofType:@"js"];
    if (!path) _XXXexceptionBlock(@"can't find CTEngine.js");
    NSString *jsCore = [[NSString alloc] initWithData:[[NSFileManager defaultManager] contentsAtPath:path] encoding:NSUTF8StringEncoding];
    
    if ([_XXXcontext respondsToSelector:@selector(evaluateScript:withSourceURL:)]) {
        [_XXXcontext evaluateScript:jsCore withSourceURL:[NSURL URLWithString:@"CTEngine"]];
    } else {
        [_XXXcontext evaluateScript:jsCore];
    }
}

+ (JSValue *)evaluateXXXScript:(NSString *)script
{
    return [self _evaluateXXXScript:script withSourceURL:[NSURL URLWithString:@"main.js"]];
}

+ (JSValue *)evaluateXXXScriptWithXXXPath:(NSString *)filePath
{
    _XXXscriptRootDir = [filePath stringByDeletingLastPathComponent];
    return [self _evaluateXXXScriptWithPath:filePath];
}

+ (JSValue *)_evaluateXXXScriptWithPath:(NSString *)filePath
{
    NSString *script = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    return [self _evaluateXXXScript:script withSourceURL:[NSURL URLWithString:[filePath lastPathComponent]]];
}

+ (JSValue *)_evaluateXXXScript:(NSString *)script withSourceURL:(NSURL *)resourceURL
{
    if (!script || ![JSContext class]) {
        _XXXexceptionBlock(@"script is nil");
        return nil;
    }
    [self startXXXEngine];
    
    if (!_XXXregex) {
        _XXXregex = [NSRegularExpression regularExpressionWithPattern:_XXXregexStr options:0 error:nil];
    }
    NSString *formatedScript = [NSString stringWithFormat:@";(function(){try{\n%@\n}catch(e){_OC_XXXcatch(e.message, e.stack)}})();", [_XXXregex stringByReplacingMatchesInString:script options:0 range:NSMakeRange(0, script.length) withTemplate:_XXXreplaceStr]];
    @try {
        if ([_XXXcontext respondsToSelector:@selector(evaluateScript:withSourceURL:)]) {
            return [_XXXcontext evaluateScript:formatedScript withSourceURL:resourceURL];
        } else {
            return [_XXXcontext evaluateScript:formatedScript];
        }
    }
    @catch (NSException *exception) {
        _XXXexceptionBlock([NSString stringWithFormat:@"%@", exception]);
    }
    return nil;
}

+ (JSContext *)contextXXX
{
    return _XXXcontext;
}

+ (void)addXXXExtensions:(NSArray *)extensions
{
    if (![JSContext class]) {
        return;
    }
    if (!_XXXcontext) _XXXexceptionBlock(@"please call [CTXXXEngine startXXXEngine]");
    for (NSString *className in extensions) {
        Class extCls = NSClassFromString(className);
        [extCls mainXXX:_XXXcontext];
    }
}

+ (void)defineXXXStruct:(NSDictionary *)defineDict
{
    @synchronized (_XXXcontext) {
        [_XXXregisteredStruct setObject:defineDict forKey:defineDict[@"name"]];
    }
}

+ (void)handleMemoryWarning {
    [_XXXJSMethodSignatureLock lock];
    _XXXJSMethodSignatureCache = nil;
    [_XXXJSMethodSignatureLock unlock];
}

+ (void)handleXXXException:(void (^)(NSString *msg))exceptionBlock
{
    _XXXexceptionBlock = [exceptionBlock copy];
}

#pragma mark - Implements

static const void *propXXXKey(NSString *propName) {
    if (!_XXXpropKeys) _XXXpropKeys = [[NSMutableDictionary alloc] init];
    id key = _XXXpropKeys[propName];
    if (!key) {
        key = [propName copy];
        [_XXXpropKeys setObject:key forKey:propName];
    }
    return (__bridge const void *)(key);
}
static id getXXXPropXXXIMP(id slf, SEL selector, NSString *propName) {
    return objc_getAssociatedObject(slf, propXXXKey(propName));
}
static void setXXXPropXXXIMP(id slf, SEL selector, id val, NSString *propName) {
    objc_setAssociatedObject(slf, propXXXKey(propName), val, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static char *methodXXXTypesInXXXProtocol(NSString *protocolName, NSString *selectorName, BOOL isInstanceMethod, BOOL isRequired)
{
    Protocol *protocol = objc_getProtocol([trim(protocolName) cStringUsingEncoding:NSUTF8StringEncoding]);
    unsigned int selCount = 0;
    struct objc_method_description *methods = protocol_copyMethodDescriptionList(protocol, isRequired, isInstanceMethod, &selCount);
    for (int i = 0; i < selCount; i ++) {
        if ([selectorName isEqualToString:NSStringFromSelector(methods[i].name)]) {
            char *types = malloc(strlen(methods[i].types) + 1);
            strcpy(types, methods[i].types);
            free(methods);
            return types;
        }
    }
    free(methods);
    return NULL;
}

static void defineXXXProtocol(NSString *protocolDeclaration, JSValue *instProtocol, JSValue *clsProtocol)
{
    const char *protocolName = [protocolDeclaration UTF8String];
    Protocol* newprotocol = objc_allocateProtocol(protocolName);
    if (newprotocol) {
        addXXXGroupXXXMethodsXXXToProtocol(newprotocol, instProtocol, YES);
        addXXXGroupXXXMethodsXXXToProtocol(newprotocol, clsProtocol, NO);
        objc_registerProtocol(newprotocol);
    }
}

static void addXXXGroupXXXMethodsXXXToProtocol(Protocol* protocol,JSValue *groupMethods,BOOL isInstance)
{
    NSDictionary *groupDic = [groupMethods toDictionary];
    for (NSString *jpSelector in groupDic.allKeys) {
        NSDictionary *methodDict = groupDic[jpSelector];
        NSString *paraString = methodDict[@"paramsType"];
        NSString *returnString = methodDict[@"returnType"] && [methodDict[@"returnType"] length] > 0 ? methodDict[@"returnType"] : @"void";
        NSString *typeEncode = methodDict[@"typeEncode"];
        
        NSArray *argStrArr = [paraString componentsSeparatedByString:@","];
        NSString *selectorName = convertJPXXXSelectorString(jpSelector);
        
        if ([selectorName componentsSeparatedByString:@":"].count - 1 < argStrArr.count) {
            selectorName = [selectorName stringByAppendingString:@":"];
        }

        if (typeEncode) {
            addXXXMethodToXXXProtocol(protocol, selectorName, typeEncode, isInstance);
            
        } else {
            if (!_XXXprotocolTypeEncodeDict) {
                _XXXprotocolTypeEncodeDict = [[NSMutableDictionary alloc] init];
                #define JP_DEFINE_TYPE_ENCODE_CASE(_type) \
                    [_XXXprotocolTypeEncodeDict setObject:[NSString stringWithUTF8String:@encode(_type)] forKey:@#_type];\

                JP_DEFINE_TYPE_ENCODE_CASE(id);
                JP_DEFINE_TYPE_ENCODE_CASE(BOOL);
                JP_DEFINE_TYPE_ENCODE_CASE(int);
                JP_DEFINE_TYPE_ENCODE_CASE(void);
                JP_DEFINE_TYPE_ENCODE_CASE(char);
                JP_DEFINE_TYPE_ENCODE_CASE(short);
                JP_DEFINE_TYPE_ENCODE_CASE(unsigned short);
                JP_DEFINE_TYPE_ENCODE_CASE(unsigned int);
                JP_DEFINE_TYPE_ENCODE_CASE(long);
                JP_DEFINE_TYPE_ENCODE_CASE(unsigned long);
                JP_DEFINE_TYPE_ENCODE_CASE(long long);
                JP_DEFINE_TYPE_ENCODE_CASE(float);
                JP_DEFINE_TYPE_ENCODE_CASE(double);
                JP_DEFINE_TYPE_ENCODE_CASE(CGFloat);
                JP_DEFINE_TYPE_ENCODE_CASE(CGSize);
                JP_DEFINE_TYPE_ENCODE_CASE(CGRect);
                JP_DEFINE_TYPE_ENCODE_CASE(CGPoint);
                JP_DEFINE_TYPE_ENCODE_CASE(CGVector);
                JP_DEFINE_TYPE_ENCODE_CASE(NSRange);
                JP_DEFINE_TYPE_ENCODE_CASE(NSInteger);
                JP_DEFINE_TYPE_ENCODE_CASE(Class);
                JP_DEFINE_TYPE_ENCODE_CASE(SEL);
                JP_DEFINE_TYPE_ENCODE_CASE(void*);
#if TARGET_OS_IPHONE
                JP_DEFINE_TYPE_ENCODE_CASE(UIEdgeInsets);
#else
                JP_DEFINE_TYPE_ENCODE_CASE(NSEdgeInsets);
#endif

                [_XXXprotocolTypeEncodeDict setObject:@"@?" forKey:@"block"];
                [_XXXprotocolTypeEncodeDict setObject:@"^@" forKey:@"id*"];
            }
            
            NSString *returnEncode = _XXXprotocolTypeEncodeDict[returnString];
            if (returnEncode.length > 0) {
                NSMutableString *encode = [returnEncode mutableCopy];
                [encode appendString:@"@:"];
                for (NSInteger i = 0; i < argStrArr.count; i++) {
                    NSString *argStr = trim([argStrArr objectAtIndex:i]);
                    NSString *argEncode = _XXXprotocolTypeEncodeDict[argStr];
                    if (!argEncode) {
                        NSString *argClassName = trim([argStr stringByReplacingOccurrencesOfString:@"*" withString:@""]);
                        if (NSClassFromString(argClassName) != NULL) {
                            argEncode = @"@";
                        } else {
                            _XXXexceptionBlock([NSString stringWithFormat:@"XXXunreconized type %@", argStr]);
                            return;
                        }
                    }
                    [encode appendString:argEncode];
                }
                addXXXMethodToXXXProtocol(protocol, selectorName, encode, isInstance);
            }
        }
    }
}

static void addXXXMethodToXXXProtocol(Protocol* protocol, NSString *selectorName, NSString *typeencoding, BOOL isInstance)
{
    SEL sel = NSSelectorFromString(selectorName);
    const char* type = [typeencoding UTF8String];
    protocol_addMethodDescription(protocol, sel, type, YES, isInstance);
}

static NSDictionary *defineXXXClass(NSString *classDeclaration, JSValue *instanceMethods, JSValue *classMethods)
{
    NSScanner *scanner = [NSScanner scannerWithString:classDeclaration];
    
    NSString *className;
    NSString *superClassName;
    NSString *protocolNames;
    [scanner scanUpToString:@":" intoString:&className];
    if (!scanner.isAtEnd) {
        scanner.scanLocation = scanner.scanLocation + 1;
        [scanner scanUpToString:@"<" intoString:&superClassName];
        if (!scanner.isAtEnd) {
            scanner.scanLocation = scanner.scanLocation + 1;
            [scanner scanUpToString:@">" intoString:&protocolNames];
        }
    }
    
    if (!superClassName) superClassName = @"NSObject";
    className = trim(className);
    superClassName = trim(superClassName);
    
    NSArray *protocols = [protocolNames length] ? [protocolNames componentsSeparatedByString:@","] : nil;
    
    Class cls = NSClassFromString(className);
    if (!cls) {
        Class superCls = NSClassFromString(superClassName);
        if (!superCls) {
            _XXXexceptionBlock([NSString stringWithFormat:@"can't find XXX the super class %@", superClassName]);
            return @{@"cls": className};
        }
        cls = objc_allocateClassPair(superCls, className.UTF8String, 0);
        objc_registerClassPair(cls);
    }
    
    if (protocols.count > 0) {
        for (NSString* protocolName in protocols) {
            Protocol *protocol = objc_getProtocol([trim(protocolName) cStringUsingEncoding:NSUTF8StringEncoding]);
            class_addProtocol (cls, protocol);
        }
    }
    
    for (int i = 0; i < 2; i ++) {
        BOOL isInstance = i == 0;
        JSValue *jsMethods = isInstance ? instanceMethods: classMethods;
        
        Class currCls = isInstance ? cls: objc_getMetaClass(className.UTF8String);
        NSDictionary *methodDict = [jsMethods toDictionary];
        for (NSString *jsMethodName in methodDict.allKeys) {
            JSValue *jsMethodArr = [jsMethods valueForProperty:jsMethodName];
            int numberOfArg = [jsMethodArr[0] toInt32];
            NSString *selectorName = convertJPXXXSelectorString(jsMethodName);
            
            if ([selectorName componentsSeparatedByString:@":"].count - 1 < numberOfArg) {
                selectorName = [selectorName stringByAppendingString:@":"];
            }
            
            JSValue *jsMethod = jsMethodArr[1];
            if (class_respondsToSelector(currCls, NSSelectorFromString(selectorName))) {
                overrideXXXMethod(currCls, selectorName, jsMethod, !isInstance, NULL);
            } else {
                BOOL overrided = NO;
                for (NSString *protocolName in protocols) {
                    char *types = methodXXXTypesInXXXProtocol(protocolName, selectorName, isInstance, YES);
                    if (!types) types = methodXXXTypesInXXXProtocol(protocolName, selectorName, isInstance, NO);
                    if (types) {
                        overrideXXXMethod(currCls, selectorName, jsMethod, !isInstance, types);
                        free(types);
                        overrided = YES;
                        break;
                    }
                }
                if (!overrided) {
                    if (![[jsMethodName substringToIndex:1] isEqualToString:@"_"]) {
                        NSMutableString *typeDescStr = [@"@@:" mutableCopy];
                        for (int i = 0; i < numberOfArg; i ++) {
                            [typeDescStr appendString:@"@"];
                        }
                        overrideXXXMethod(currCls, selectorName, jsMethod, !isInstance, [typeDescStr cStringUsingEncoding:NSUTF8StringEncoding]);
                    }
                }
            }
        }
    }
    
    class_addMethod(cls, @selector(getProp:), (IMP)getXXXPropXXXIMP, "@@:@");
    class_addMethod(cls, @selector(setProp:forKey:), (IMP)setXXXPropXXXIMP, "v@:@@");

    return @{@"cls": className, @"superCls": superClassName};
}

static JSValue *getXXXJSXXXFunctionInObjectHierachy(id slf, NSString *selectorName)
{
    Class cls = object_getClass(slf);
    if (_XXXcurrInvokeSuperClsName[selectorName]) {
        cls = NSClassFromString(_XXXcurrInvokeSuperClsName[selectorName]);
        selectorName = [selectorName stringByReplacingOccurrencesOfString:@"_JPSUPER_" withString:@"_JP"];
    }
    JSValue *func = _XXXJSOverideMethods[cls][selectorName];
    while (!func) {
        cls = class_getSuperclass(cls);
        if (!cls) {
            return nil;
        }
        func = _XXXJSOverideMethods[cls][selectorName];
    }
    return func;
}

static void JPXXXForwardXXXInvocation(__unsafe_unretained id assignSlf, SEL selector, NSInvocation *invocation)
{
#ifdef DEBUG
    _XXXJSLastCallStack = [NSThread callStackSymbols];
#endif
    BOOL deallocFlag = NO;
    id slf = assignSlf;
    NSMethodSignature *methodSignature = [invocation methodSignature];
    NSInteger numberOfArguments = [methodSignature numberOfArguments];
    
    NSString *selectorName = NSStringFromSelector(invocation.selector);
    NSString *JPSelectorName = [NSString stringWithFormat:@"_JP%@", selectorName];
    JSValue *jsFunc = getXXXJSXXXFunctionInObjectHierachy(slf, JPSelectorName);
    if (!jsFunc) {
        JPXXXExecuteORIGForwardXXXInvocation(slf, selector, invocation);
        return;
    }
    
    NSMutableArray *argList = [[NSMutableArray alloc] init];
    if ([slf class] == slf) {
        [argList addObject:[JSValue valueWithObject:@{@"__clsName": NSStringFromClass([slf class])} inContext:_XXXcontext]];
    } else if ([selectorName isEqualToString:@"dealloc"]) {
        [argList addObject:[JPXXXBoxing boxAssignObj:slf]];
        deallocFlag = YES;
    } else {
        [argList addObject:[JPXXXBoxing boxWeakObj:slf]];
    }
    
    for (NSUInteger i = 2; i < numberOfArguments; i++) {
        const char *argumentType = [methodSignature getArgumentTypeAtIndex:i];
        switch(argumentType[0] == 'r' ? argumentType[1] : argumentType[0]) {
        
            #define JP_FWD_ARG_CASE(_typeChar, _type) \
            case _typeChar: {   \
                _type arg;  \
                [invocation getArgument:&arg atIndex:i];    \
                [argList addObject:@(arg)]; \
                break;  \
            }
            JP_FWD_ARG_CASE('c', char)
            JP_FWD_ARG_CASE('C', unsigned char)
            JP_FWD_ARG_CASE('s', short)
            JP_FWD_ARG_CASE('S', unsigned short)
            JP_FWD_ARG_CASE('i', int)
            JP_FWD_ARG_CASE('I', unsigned int)
            JP_FWD_ARG_CASE('l', long)
            JP_FWD_ARG_CASE('L', unsigned long)
            JP_FWD_ARG_CASE('q', long long)
            JP_FWD_ARG_CASE('Q', unsigned long long)
            JP_FWD_ARG_CASE('f', float)
            JP_FWD_ARG_CASE('d', double)
            JP_FWD_ARG_CASE('B', BOOL)
            case '@': {
                __unsafe_unretained id arg;
                [invocation getArgument:&arg atIndex:i];
                if ([arg isKindOfClass:NSClassFromString(@"NSBlock")]) {
                    [argList addObject:(arg ? [arg copy]: _XXXnilObj)];
                } else {
                    [argList addObject:(arg ? arg: _XXXnilObj)];
                }
                break;
            }
            case '{': {
                NSString *typeString = extractXXXStructXXXName([NSString stringWithUTF8String:argumentType]);
                #define JP_FWD_ARG_STRUCT(_type, _transFunc) \
                if ([typeString rangeOfString:@#_type].location != NSNotFound) {    \
                    _type arg; \
                    [invocation getArgument:&arg atIndex:i];    \
                    [argList addObject:[JSValue _transFunc:arg inContext:_XXXcontext]];  \
                    break; \
                }
                JP_FWD_ARG_STRUCT(CGRect, valueWithRect)
                JP_FWD_ARG_STRUCT(CGPoint, valueWithPoint)
                JP_FWD_ARG_STRUCT(CGSize, valueWithSize)
                JP_FWD_ARG_STRUCT(NSRange, valueWithRange)
                
                @synchronized (_XXXcontext) {
                    NSDictionary *structDefine = _XXXregisteredStruct[typeString];
                    if (structDefine) {
                        size_t size = sizeOfXXXStructXXXTypes(structDefine[@"types"]);
                        if (size) {
                            void *ret = malloc(size);
                            [invocation getArgument:ret atIndex:i];
                            NSDictionary *dict = getDictOfXXXStruct(ret, structDefine);
                            [argList addObject:[JSValue valueWithObject:dict inContext:_XXXcontext]];
                            free(ret);
                            break;
                        }
                    }
                }
                
                break;
            }
            case ':': {
                SEL selector;
                [invocation getArgument:&selector atIndex:i];
                NSString *selectorName = NSStringFromSelector(selector);
                [argList addObject:(selectorName ? selectorName: _XXXnilObj)];
                break;
            }
            case '^':
            case '*': {
                void *arg;
                [invocation getArgument:&arg atIndex:i];
                [argList addObject:[JPXXXBoxing boxPointer:arg]];
                break;
            }
            case '#': {
                Class arg;
                [invocation getArgument:&arg atIndex:i];
                [argList addObject:[JPXXXBoxing boxClass:arg]];
                break;
            }
            default: {
                NSLog(@"error type %s", argumentType);
                break;
            }
        }
    }
    
    if (_XXXcurrInvokeSuperClsName[selectorName]) {
        Class cls = NSClassFromString(_XXXcurrInvokeSuperClsName[selectorName]);
        NSString *tmpSelectorName = [[selectorName stringByReplacingOccurrencesOfString:@"_JPSUPER_" withString:@"_JP"] stringByReplacingOccurrencesOfString:@"SUPER_" withString:@"_JP"];
        if (!_XXXJSOverideMethods[cls][tmpSelectorName]) {
            NSString *ORIGSelectorName = [selectorName stringByReplacingOccurrencesOfString:@"SUPER_" withString:@"ORIG"];
            [argList removeObjectAtIndex:0];
            id retObj = callXXXSelector(_XXXcurrInvokeSuperClsName[selectorName], ORIGSelectorName, [JSValue valueWithObject:argList inContext:_XXXcontext], [JSValue valueWithObject:@{@"__obj": slf, @"__realClsName": @""} inContext:_XXXcontext], NO);
            id __autoreleasing ret = formatXXXJSToOC([JSValue valueWithObject:retObj inContext:_XXXcontext]);
            [invocation setReturnValue:&ret];
            return;
        }
    }
    
    NSArray *params = _formatOCToXXXJSList(argList);
    char returnType[255];
    strcpy(returnType, [methodSignature methodReturnType]);
    
    // Restore the return type
    if (strcmp(returnType, @encode(JPXXXDouble)) == 0) {
        strcpy(returnType, @encode(double));
    }
    if (strcmp(returnType, @encode(JPXXXFloat)) == 0) {
        strcpy(returnType, @encode(float));
    }

    switch (returnType[0] == 'r' ? returnType[1] : returnType[0]) {
        #define JP_FWD_RET_CALL_JS \
            JSValue *jsval; \
            [_XXXJSMethodForwardCallLock lock];   \
            jsval = [jsFunc callWithArguments:params]; \
            [_XXXJSMethodForwardCallLock unlock]; \
            while (![jsval isNull] && ![jsval isUndefined] && [jsval hasProperty:@"__isXXXPerformInOC"]) { \
                NSArray *args = nil;  \
                JSValue *cb = jsval[@"cb"]; \
                if ([jsval hasProperty:@"sel"]) {   \
                    id callRet = callXXXSelector(![jsval[@"clsName"] isUndefined] ? [jsval[@"clsName"] toString] : nil, [jsval[@"sel"] toString], jsval[@"args"], ![jsval[@"obj"] isUndefined] ? jsval[@"obj"] : nil, NO);  \
                    args = @[[_XXXcontext[@"_formatXXXOCToJS"] callWithArguments:callRet ? @[callRet] : _formatOCToXXXJSList(@[_XXXnilObj])]];  \
                }   \
                [_XXXJSMethodForwardCallLock lock];    \
                jsval = [cb callWithArguments:args];  \
                [_XXXJSMethodForwardCallLock unlock];  \
            }

        #define JP_FWD_RET_CASE_RET(_typeChar, _type, _retCode)   \
            case _typeChar : { \
                JP_FWD_RET_CALL_JS \
                _retCode \
                [invocation setReturnValue:&ret];\
                break;  \
            }

        #define JP_FWD_RET_CASE(_typeChar, _type, _typeSelector)   \
            JP_FWD_RET_CASE_RET(_typeChar, _type, _type ret = [[jsval toObject] _typeSelector];)   \

        #define JP_FWD_RET_CODE_ID \
            id __autoreleasing ret = formatXXXJSToOC(jsval); \
            if (ret == _XXXnilObj ||   \
                ([ret isKindOfClass:[NSNumber class]] && strcmp([ret objCType], "c") == 0 && ![ret boolValue])) ret = nil;  \

        #define JP_FWD_RET_CODE_POINTER    \
            void *ret; \
            id obj = formatXXXJSToOC(jsval); \
            if ([obj isKindOfClass:[JPXXXBoxing class]]) { \
                ret = [((JPXXXBoxing *)obj) unboxPointer]; \
            }

        #define JP_FWD_RET_CODE_CLASS    \
            Class ret;   \
            ret = formatXXXJSToOC(jsval);


        #define JP_FWD_RET_CODE_SEL    \
            SEL ret;   \
            id obj = formatXXXJSToOC(jsval); \
            if ([obj isKindOfClass:[NSString class]]) { \
                ret = NSSelectorFromString(obj); \
            }

        JP_FWD_RET_CASE_RET('@', id, JP_FWD_RET_CODE_ID)
        JP_FWD_RET_CASE_RET('^', void*, JP_FWD_RET_CODE_POINTER)
        JP_FWD_RET_CASE_RET('*', void*, JP_FWD_RET_CODE_POINTER)
        JP_FWD_RET_CASE_RET('#', Class, JP_FWD_RET_CODE_CLASS)
        JP_FWD_RET_CASE_RET(':', SEL, JP_FWD_RET_CODE_SEL)

        JP_FWD_RET_CASE('c', char, charValue)
        JP_FWD_RET_CASE('C', unsigned char, unsignedCharValue)
        JP_FWD_RET_CASE('s', short, shortValue)
        JP_FWD_RET_CASE('S', unsigned short, unsignedShortValue)
        JP_FWD_RET_CASE('i', int, intValue)
        JP_FWD_RET_CASE('I', unsigned int, unsignedIntValue)
        JP_FWD_RET_CASE('l', long, longValue)
        JP_FWD_RET_CASE('L', unsigned long, unsignedLongValue)
        JP_FWD_RET_CASE('q', long long, longLongValue)
        JP_FWD_RET_CASE('Q', unsigned long long, unsignedLongLongValue)
        JP_FWD_RET_CASE('f', float, floatValue)
        JP_FWD_RET_CASE('d', double, doubleValue)
        JP_FWD_RET_CASE('B', BOOL, boolValue)

        case 'v': {
            JP_FWD_RET_CALL_JS
            break;
        }
        
        case '{': {
            NSString *typeString = extractXXXStructXXXName([NSString stringWithUTF8String:returnType]);
            #define JP_FWD_RET_STRUCT(_type, _funcSuffix) \
            if ([typeString rangeOfString:@#_type].location != NSNotFound) {    \
                JP_FWD_RET_CALL_JS \
                _type ret = [jsval _funcSuffix]; \
                [invocation setReturnValue:&ret];\
                break;  \
            }
            JP_FWD_RET_STRUCT(CGRect, toRect)
            JP_FWD_RET_STRUCT(CGPoint, toPoint)
            JP_FWD_RET_STRUCT(CGSize, toSize)
            JP_FWD_RET_STRUCT(NSRange, toRange)
            
            @synchronized (_XXXcontext) {
                NSDictionary *structDefine = _XXXregisteredStruct[typeString];
                if (structDefine) {
                    size_t size = sizeOfXXXStructXXXTypes( structDefine[@"types"]);
                    JP_FWD_RET_CALL_JS
                    void *ret = malloc(size);
                    NSDictionary *dict = formatXXXJSToOC(jsval);
                    getXXXStructXXXDataWithDict(ret, dict, structDefine);
                    [invocation setReturnValue:ret];
                    free(ret);
                }
            }
            break;
        }
        default: {
            break;
        }
    }
    
    if (_XXXpointersToRelease) {
        for (NSValue *val in _XXXpointersToRelease) {
            void *pointer = NULL;
            [val getValue:&pointer];
            CFRelease(pointer);
        }
        _XXXpointersToRelease = nil;
    }
    
    if (deallocFlag) {
        slf = nil;
        Class instClass = object_getClass(assignSlf);
        Method deallocMethod = class_getInstanceMethod(instClass, NSSelectorFromString(@"ORIGdealloc"));
        void (*originalDealloc)(__unsafe_unretained id, SEL) = (__typeof__(originalDealloc))method_getImplementation(deallocMethod);
        originalDealloc(assignSlf, NSSelectorFromString(@"dealloc"));
    }
}

static void JPXXXExecuteORIGForwardXXXInvocation(id slf, SEL selector, NSInvocation *invocation)
{
    SEL origForwardSelector = @selector(ORIGforwardInvocation:);
    
    if ([slf respondsToSelector:origForwardSelector]) {
        NSMethodSignature *methodSignature = [slf methodSignatureForSelector:origForwardSelector];
        if (!methodSignature) {
            _XXXexceptionBlock([NSString stringWithFormat:@"unrecognized selector -ORIGforwardInvocation: for instance %@", slf]);
            return;
        }
        NSInvocation *forwardInv= [NSInvocation invocationWithMethodSignature:methodSignature];
        [forwardInv setTarget:slf];
        [forwardInv setSelector:origForwardSelector];
        [forwardInv setArgument:&invocation atIndex:2];
        [forwardInv invoke];
    } else {
        Class superCls = [[slf class] superclass];
        Method superForwardMethod = class_getInstanceMethod(superCls, @selector(forwardInvocation:));
        void (*superForwardIMP)(id, SEL, NSInvocation *);
        superForwardIMP = (void (*)(id, SEL, NSInvocation *))method_getImplementation(superForwardMethod);
        superForwardIMP(slf, @selector(forwardInvocation:), invocation);
    }
}

static void _initJPXXXOverideXXXMethods(Class cls) {
    if (!_XXXJSOverideMethods) {
        _XXXJSOverideMethods = [[NSMutableDictionary alloc] init];
    }
    if (!_XXXJSOverideMethods[cls]) {
        _XXXJSOverideMethods[(id<NSCopying>)cls] = [[NSMutableDictionary alloc] init];
    }
}

static void overrideXXXMethod(Class cls, NSString *selectorName, JSValue *function, BOOL isClassMethod, const char *typeDescription)
{
    SEL selector = NSSelectorFromString(selectorName);
    
    if (!typeDescription) {
        Method method = class_getInstanceMethod(cls, selector);
        typeDescription = (char *)method_getTypeEncoding(method);
    }
    
    IMP originalImp = class_respondsToSelector(cls, selector) ? class_getMethodImplementation(cls, selector) : NULL;
    
    IMP msgForwardIMP = _objc_msgForward;
    #if !defined(__arm64__)
        if (typeDescription[0] == '{') {
            //In some cases that returns struct, we should use the '_stret' API:
            //http://sealiesoftware.com/blog/archive/2008/10/30/objc_explain_objc_msgSend_stret.html
            //NSMethodSignature knows the detail but has no API to return, we can only get the info from debugDescription.
            NSMethodSignature *methodSignature = [NSMethodSignature signatureWithObjCTypes:typeDescription];
            if ([methodSignature.debugDescription rangeOfString:@"is special struct return? YES"].location != NSNotFound) {
                msgForwardIMP = (IMP)_objc_msgForward_stret;
            }
        }
    #endif

    if (class_getMethodImplementation(cls, @selector(forwardInvocation:)) != (IMP)JPXXXForwardXXXInvocation) {
        IMP originalForwardImp = class_replaceMethod(cls, @selector(forwardInvocation:), (IMP)JPXXXForwardXXXInvocation, "v@:@");
        if (originalForwardImp) {
            class_addMethod(cls, @selector(ORIGforwardInvocation:), originalForwardImp, "v@:@");
        }
    }

    [cls jp_fixMethodSignature];
    if (class_respondsToSelector(cls, selector)) {
        NSString *originalSelectorName = [NSString stringWithFormat:@"ORIG%@", selectorName];
        SEL originalSelector = NSSelectorFromString(originalSelectorName);
        if(!class_respondsToSelector(cls, originalSelector)) {
            class_addMethod(cls, originalSelector, originalImp, typeDescription);
        }
    }
    
    NSString *JPSelectorName = [NSString stringWithFormat:@"_JP%@", selectorName];
    
    _initJPXXXOverideXXXMethods(cls);
    _XXXJSOverideMethods[cls][JPSelectorName] = function;
    
    // Replace the original selector at last, preventing threading issus when
    // the selector get called during the execution of `overrideMethod`
    class_replaceMethod(cls, selector, msgForwardIMP, typeDescription);
}

#pragma mark -
static id callXXXSelector(NSString *className, NSString *selectorName, JSValue *arguments, JSValue *instance, BOOL isSuper)
{
    NSString *realClsName = [[instance valueForProperty:@"__realClsName"] toString];
   
    if (instance) {
        instance = formatXXXJSToOC(instance);
        if (class_isMetaClass(object_getClass(instance))) {
            className = NSStringFromClass((Class)instance);
            instance = nil;
        } else if (!instance || instance == _XXXnilObj || [instance isKindOfClass:[JPXXXBoxing class]]) {
            return @{@"__isNil": @(YES)};
        }
    }
    id argumentsObj = formatXXXJSToOC(arguments);
    
    if (instance && [selectorName isEqualToString:@"toJS"]) {
        if ([instance isKindOfClass:[NSString class]] || [instance isKindOfClass:[NSDictionary class]] || [instance isKindOfClass:[NSArray class]] || [instance isKindOfClass:[NSDate class]]) {
            return _unboxOCObjectToXXXJS(instance);
        }
    }

    Class cls = instance ? [instance class] : NSClassFromString(className);
    SEL selector = NSSelectorFromString(selectorName);
    
    NSString *superClassName = nil;
    if (isSuper) {
        NSString *superSelectorName = [NSString stringWithFormat:@"SUPER_%@", selectorName];
        SEL superSelector = NSSelectorFromString(superSelectorName);
        
        Class superCls;
        if (realClsName.length) {
            Class defineClass = NSClassFromString(realClsName);
            superCls = defineClass ? [defineClass superclass] : [cls superclass];
        } else {
            superCls = [cls superclass];
        }
        
        Method superMethod = class_getInstanceMethod(superCls, selector);
        IMP superIMP = method_getImplementation(superMethod);
        
        class_addMethod(cls, superSelector, superIMP, method_getTypeEncoding(superMethod));
        
        NSString *JPSelectorName = [NSString stringWithFormat:@"_JP%@", selectorName];
        JSValue *overideFunction = _XXXJSOverideMethods[superCls][JPSelectorName];
        if (overideFunction) {
            overrideXXXMethod(cls, superSelectorName, overideFunction, NO, NULL);
        }
        
        selector = superSelector;
        superClassName = NSStringFromClass(superCls);
    }
    
    
    NSMutableArray *_markArray;
    
    NSInvocation *invocation;
    NSMethodSignature *methodSignature;
    if (!_XXXJSMethodSignatureCache) {
        _XXXJSMethodSignatureCache = [[NSMutableDictionary alloc]init];
    }
    if (instance) {
        [_XXXJSMethodSignatureLock lock];
        if (!_XXXJSMethodSignatureCache[cls]) {
            _XXXJSMethodSignatureCache[(id<NSCopying>)cls] = [[NSMutableDictionary alloc]init];
        }
        methodSignature = _XXXJSMethodSignatureCache[cls][selectorName];
        if (!methodSignature) {
            methodSignature = [cls instanceMethodSignatureForSelector:selector];
            methodSignature = fixXXXSignature(methodSignature);
            _XXXJSMethodSignatureCache[cls][selectorName] = methodSignature;
        }
        [_XXXJSMethodSignatureLock unlock];
        if (!methodSignature) {
            _XXXexceptionBlock([NSString stringWithFormat:@"unrecognized selector %@ for instance %@", selectorName, instance]);
            return nil;
        }
        invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        [invocation setTarget:instance];
    } else {
        methodSignature = [cls methodSignatureForSelector:selector];
        methodSignature = fixXXXSignature(methodSignature);
        if (!methodSignature) {
            _XXXexceptionBlock([NSString stringWithFormat:@"unrecognized selector %@ for class %@", selectorName, className]);
            return nil;
        }
        invocation= [NSInvocation invocationWithMethodSignature:methodSignature];
        [invocation setTarget:cls];
    }
    [invocation setSelector:selector];
    
    NSUInteger numberOfArguments = methodSignature.numberOfArguments;
    NSInteger inputArguments = [(NSArray *)argumentsObj count];
    if (inputArguments > numberOfArguments - 2) {
        // calling variable argument method, only support parameter type `id` and return type `id`
        id sender = instance != nil ? instance : cls;
        id result = invokeXXXVariableParameterXXXMethod(argumentsObj, methodSignature, sender, selector);
        return formatOCToXXXJS(result);
    }
    
    for (NSUInteger i = 2; i < numberOfArguments; i++) {
        const char *argumentType = [methodSignature getArgumentTypeAtIndex:i];
        id valObj = argumentsObj[i-2];
        switch (argumentType[0] == 'r' ? argumentType[1] : argumentType[0]) {
                
                #define JP_CALL_ARG_CASE(_typeString, _type, _selector) \
                case _typeString: {                              \
                    _type value = [valObj _selector];                     \
                    [invocation setArgument:&value atIndex:i];\
                    break; \
                }
                
                JP_CALL_ARG_CASE('c', char, charValue)
                JP_CALL_ARG_CASE('C', unsigned char, unsignedCharValue)
                JP_CALL_ARG_CASE('s', short, shortValue)
                JP_CALL_ARG_CASE('S', unsigned short, unsignedShortValue)
                JP_CALL_ARG_CASE('i', int, intValue)
                JP_CALL_ARG_CASE('I', unsigned int, unsignedIntValue)
                JP_CALL_ARG_CASE('l', long, longValue)
                JP_CALL_ARG_CASE('L', unsigned long, unsignedLongValue)
                JP_CALL_ARG_CASE('q', long long, longLongValue)
                JP_CALL_ARG_CASE('Q', unsigned long long, unsignedLongLongValue)
                JP_CALL_ARG_CASE('f', float, floatValue)
                JP_CALL_ARG_CASE('d', double, doubleValue)
                JP_CALL_ARG_CASE('B', BOOL, boolValue)
                
            case ':': {
                SEL value = nil;
                if (valObj != _XXXnilObj) {
                    value = NSSelectorFromString(valObj);
                }
                [invocation setArgument:&value atIndex:i];
                break;
            }
            case '{': {
                NSString *typeString = extractXXXStructXXXName([NSString stringWithUTF8String:argumentType]);
                JSValue *val = arguments[i-2];
                #define JP_CALL_ARG_STRUCT(_type, _methodName) \
                if ([typeString rangeOfString:@#_type].location != NSNotFound) {    \
                    _type value = [val _methodName];  \
                    [invocation setArgument:&value atIndex:i];  \
                    break; \
                }
                JP_CALL_ARG_STRUCT(CGRect, toRect)
                JP_CALL_ARG_STRUCT(CGPoint, toPoint)
                JP_CALL_ARG_STRUCT(CGSize, toSize)
                JP_CALL_ARG_STRUCT(NSRange, toRange)
                @synchronized (_XXXcontext) {
                    NSDictionary *structDefine = _XXXregisteredStruct[typeString];
                    if (structDefine) {
                        size_t size = sizeOfXXXStructXXXTypes( structDefine[@"types"]);
                        void *ret = malloc(size);
                        getXXXStructXXXDataWithDict(ret, valObj, structDefine);
                        [invocation setArgument:ret atIndex:i];
                        free(ret);
                        break;
                    }
                }
                
                break;
            }
            case '*':
            case '^': {
                if ([valObj isKindOfClass:[JPXXXBoxing class]]) {
                    void *value = [((JPXXXBoxing *)valObj) unboxPointer];
                    
                    if (argumentType[1] == '@') {
                        if (!_XXXTMPMemoryPool) {
                            _XXXTMPMemoryPool = [[NSMutableDictionary alloc] init];
                        }
                        if (!_markArray) {
                            _markArray = [[NSMutableArray alloc] init];
                        }
                        memset(value, 0, sizeof(id));
                        [_markArray addObject:valObj];
                    }
                    
                    [invocation setArgument:&value atIndex:i];
                    break;
                }
            }
            case '#': {
                if ([valObj isKindOfClass:[JPXXXBoxing class]]) {
                    Class value = [((JPXXXBoxing *)valObj) unboxClass];
                    [invocation setArgument:&value atIndex:i];
                    break;
                }
            }
            default: {
                if (valObj == _XXXnullObj) {
                    valObj = [NSNull null];
                    [invocation setArgument:&valObj atIndex:i];
                    break;
                }
                if (valObj == _XXXnilObj ||
                    ([valObj isKindOfClass:[NSNumber class]] && strcmp([valObj objCType], "c") == 0 && ![valObj boolValue])) {
                    valObj = nil;
                    [invocation setArgument:&valObj atIndex:i];
                    break;
                }
                if ([(JSValue *)arguments[i-2] hasProperty:@"__isXXXBlock"]) {
                    JSValue *blkJSVal = arguments[i-2];
                    Class JPBlockClass = NSClassFromString(@"JPXXXBlock");
                    if (JPBlockClass && ![blkJSVal[@"blockObj"] isUndefined]) {
                        __autoreleasing id cb = [JPBlockClass performSelector:@selector(blockWithBlockObj:) withObject:[blkJSVal[@"blockObj"] toObject]];
                        [invocation setArgument:&cb atIndex:i];
                    } else {
                        __autoreleasing id cb = genXXXCallbackBlock(arguments[i-2]);
                        [invocation setArgument:&cb atIndex:i];
                    }
                } else {
                    [invocation setArgument:&valObj atIndex:i];
                }
            }
        }
    }
    
    if (superClassName) _XXXcurrInvokeSuperClsName[selectorName] = superClassName;
    [invocation invoke];
    if (superClassName) [_XXXcurrInvokeSuperClsName removeObjectForKey:selectorName];
    if ([_markArray count] > 0) {
        for (JPXXXBoxing *box in _markArray) {
            void *pointer = [box unboxPointer];
            id obj = *((__unsafe_unretained id *)pointer);
            if (obj) {
                @synchronized(_XXXTMPMemoryPool) {
                    [_XXXTMPMemoryPool setObject:obj forKey:[NSNumber numberWithInteger:[(NSObject*)obj hash]]];
                }
            }
        }
    }
    
    char returnType[255];
    strcpy(returnType, [methodSignature methodReturnType]);
    
    // Restore the return type
    if (strcmp(returnType, @encode(JPXXXDouble)) == 0) {
        strcpy(returnType, @encode(double));
    }
    if (strcmp(returnType, @encode(JPXXXFloat)) == 0) {
        strcpy(returnType, @encode(float));
    }

    id returnValue;
    if (strncmp(returnType, "v", 1) != 0) {
        if (strncmp(returnType, "@", 1) == 0) {
            void *result;
            [invocation getReturnValue:&result];
            
            //For performance, ignore the other methods prefix with alloc/new/copy/mutableCopy
            if ([selectorName isEqualToString:@"alloc"] || [selectorName isEqualToString:@"new"] ||
                [selectorName isEqualToString:@"copy"] || [selectorName isEqualToString:@"mutableCopy"]) {
                returnValue = (__bridge_transfer id)result;
            } else {
                returnValue = (__bridge id)result;
            }
            return formatOCToXXXJS(returnValue);
            
        } else {
            switch (returnType[0] == 'r' ? returnType[1] : returnType[0]) {
                    
                #define JP_CALL_RET_CASE(_typeString, _type) \
                case _typeString: {                              \
                    _type tempResultSet; \
                    [invocation getReturnValue:&tempResultSet];\
                    returnValue = @(tempResultSet); \
                    break; \
                }
                    
                JP_CALL_RET_CASE('c', char)
                JP_CALL_RET_CASE('C', unsigned char)
                JP_CALL_RET_CASE('s', short)
                JP_CALL_RET_CASE('S', unsigned short)
                JP_CALL_RET_CASE('i', int)
                JP_CALL_RET_CASE('I', unsigned int)
                JP_CALL_RET_CASE('l', long)
                JP_CALL_RET_CASE('L', unsigned long)
                JP_CALL_RET_CASE('q', long long)
                JP_CALL_RET_CASE('Q', unsigned long long)
                JP_CALL_RET_CASE('f', float)
                JP_CALL_RET_CASE('d', double)
                JP_CALL_RET_CASE('B', BOOL)

                case '{': {
                    NSString *typeString = extractXXXStructXXXName([NSString stringWithUTF8String:returnType]);
                    #define JP_CALL_RET_STRUCT(_type, _methodName) \
                    if ([typeString rangeOfString:@#_type].location != NSNotFound) {    \
                        _type result;   \
                        [invocation getReturnValue:&result];    \
                        return [JSValue _methodName:result inContext:_XXXcontext];    \
                    }
                    JP_CALL_RET_STRUCT(CGRect, valueWithRect)
                    JP_CALL_RET_STRUCT(CGPoint, valueWithPoint)
                    JP_CALL_RET_STRUCT(CGSize, valueWithSize)
                    JP_CALL_RET_STRUCT(NSRange, valueWithRange)
                    @synchronized (_XXXcontext) {
                        NSDictionary *structDefine = _XXXregisteredStruct[typeString];
                        if (structDefine) {
                            size_t size = sizeOfXXXStructXXXTypes( structDefine[@"types"]);
                            void *ret = malloc(size);
                            [invocation getReturnValue:ret];
                            NSDictionary *dict = getDictOfXXXStruct(ret, structDefine);
                            free(ret);
                            return dict;
                        }
                    }
                    break;
                }
                case '*':
                case '^': {
                    void *result;
                    [invocation getReturnValue:&result];
                    returnValue = formatOCToXXXJS([JPXXXBoxing boxPointer:result]);
                    if (strncmp(returnType, "^{CG", 4) == 0) {
                        if (!_XXXpointersToRelease) {
                            _XXXpointersToRelease = [[NSMutableArray alloc] init];
                        }
                        [_XXXpointersToRelease addObject:[NSValue valueWithPointer:result]];
                        CFRetain(result);
                    }
                    break;
                }
                case '#': {
                    Class result;
                    [invocation getReturnValue:&result];
                    returnValue = formatOCToXXXJS([JPXXXBoxing boxClass:result]);
                    break;
                }
            }
            return returnValue;
        }
    }
    return nil;
}

static id (*new_msgXXXSend1)(id, SEL, id,...) = (id (*)(id, SEL, id,...)) objc_msgSend;
static id (*new_msgXXXSend2)(id, SEL, id, id,...) = (id (*)(id, SEL, id, id,...)) objc_msgSend;
static id (*new_msgXXXSend3)(id, SEL, id, id, id,...) = (id (*)(id, SEL, id, id, id,...)) objc_msgSend;
static id (*new_msgXXXSend4)(id, SEL, id, id, id, id,...) = (id (*)(id, SEL, id, id, id, id,...)) objc_msgSend;
static id (*new_msgXXXSend5)(id, SEL, id, id, id, id, id,...) = (id (*)(id, SEL, id, id, id, id, id,...)) objc_msgSend;
static id (*new_msgXXXSend6)(id, SEL, id, id, id, id, id, id,...) = (id (*)(id, SEL, id, id, id, id, id, id,...)) objc_msgSend;
static id (*new_msgXXXSend7)(id, SEL, id, id, id, id, id, id, id,...) = (id (*)(id, SEL, id, id, id, id, id, id,id,...)) objc_msgSend;
static id (*new_msgXXXSend8)(id, SEL, id, id, id, id, id, id, id, id,...) = (id (*)(id, SEL, id, id, id, id, id, id, id, id,...)) objc_msgSend;
static id (*new_msgXXXSend9)(id, SEL, id, id, id, id, id, id, id, id, id,...) = (id (*)(id, SEL, id, id, id, id, id, id, id, id, id, ...)) objc_msgSend;
static id (*new_msgXXXSend10)(id, SEL, id, id, id, id, id, id, id, id, id, id,...) = (id (*)(id, SEL, id, id, id, id, id, id, id, id, id, id,...)) objc_msgSend;

static id invokeXXXVariableParameterXXXMethod(NSMutableArray *origArgumentsList, NSMethodSignature *methodSignature, id sender, SEL selector) {
    
    NSInteger inputArguments = [(NSArray *)origArgumentsList count];
    NSUInteger numberOfArguments = methodSignature.numberOfArguments;
    
    NSMutableArray *argumentsList = [[NSMutableArray alloc] init];
    for (NSUInteger j = 0; j < inputArguments; j++) {
        NSInteger index = MIN(j + 2, numberOfArguments - 1);
        const char *argumentType = [methodSignature getArgumentTypeAtIndex:index];
        id valObj = origArgumentsList[j];
        char argumentTypeChar = argumentType[0] == 'r' ? argumentType[1] : argumentType[0];
        if (argumentTypeChar == '@') {
            [argumentsList addObject:valObj];
        } else {
            return nil;
        }
    }
    
    id results = nil;
    numberOfArguments = numberOfArguments - 2;
    
    //If you want to debug the macro code below, replace it to the expanded code:
    //https://gist.github.com/bang590/ca3720ae1da594252a2e
    #define JP_G_ARG(_idx) getXXXArgument( argumentsList[_idx])
    #define JP_CALL_MSGSEND_ARG1(_num) results = new_msgXXXSend##_num(sender, selector, JP_G_ARG(0));
    #define JP_CALL_MSGSEND_ARG2(_num) results = new_msgXXXSend##_num(sender, selector, JP_G_ARG(0), JP_G_ARG(1));
    #define JP_CALL_MSGSEND_ARG3(_num) results = new_msgXXXSend##_num(sender, selector, JP_G_ARG(0), JP_G_ARG(1), JP_G_ARG(2));
    #define JP_CALL_MSGSEND_ARG4(_num) results = new_msgXXXSend##_num(sender, selector, JP_G_ARG(0), JP_G_ARG(1), JP_G_ARG(2), JP_G_ARG(3));
    #define JP_CALL_MSGSEND_ARG5(_num) results = new_msgXXXSend##_num(sender, selector, JP_G_ARG(0), JP_G_ARG(1), JP_G_ARG(2), JP_G_ARG(3), JP_G_ARG(4));
    #define JP_CALL_MSGSEND_ARG6(_num) results = new_msgXXXSend##_num(sender, selector, JP_G_ARG(0), JP_G_ARG(1), JP_G_ARG(2), JP_G_ARG(3), JP_G_ARG(4), JP_G_ARG(5));
    #define JP_CALL_MSGSEND_ARG7(_num) results = new_msgXXXSend##_num(sender, selector, JP_G_ARG(0), JP_G_ARG(1), JP_G_ARG(2), JP_G_ARG(3), JP_G_ARG(4), JP_G_ARG(5), JP_G_ARG(6));
    #define JP_CALL_MSGSEND_ARG8(_num) results = new_msgXXXSend##_num(sender, selector, JP_G_ARG(0), JP_G_ARG(1), JP_G_ARG(2), JP_G_ARG(3), JP_G_ARG(4), JP_G_ARG(5), JP_G_ARG(6), JP_G_ARG(7));
    #define JP_CALL_MSGSEND_ARG9(_num) results = new_msgXXXSend##_num(sender, selector, JP_G_ARG(0), JP_G_ARG(1), JP_G_ARG(2), JP_G_ARG(3), JP_G_ARG(4), JP_G_ARG(5), JP_G_ARG(6), JP_G_ARG(7), JP_G_ARG(8));
    #define JP_CALL_MSGSEND_ARG10(_num) results = new_msgXXXSend##_num(sender, selector, JP_G_ARG(0), JP_G_ARG(1), JP_G_ARG(2), JP_G_ARG(3), JP_G_ARG(4), JP_G_ARG(5), JP_G_ARG(6), JP_G_ARG(7), JP_G_ARG(8), JP_G_ARG(9));
    #define JP_CALL_MSGSEND_ARG11(_num) results = new_msgXXXSend##_num(sender, selector, JP_G_ARG(0), JP_G_ARG(1), JP_G_ARG(2), JP_G_ARG(3), JP_G_ARG(4), JP_G_ARG(5), JP_G_ARG(6), JP_G_ARG(7), JP_G_ARG(8), JP_G_ARG(9), JP_G_ARG(10));
        
    #define JP_IF_REAL_ARG_COUNT(_num) if([argumentsList count] == _num)

    #define JP_DEAL_MSGSEND(_realArgCount, _defineArgCount) \
        if(numberOfArguments == _defineArgCount) { \
            JP_CALL_MSGSEND_ARG##_realArgCount(_defineArgCount) \
        }
    
    JP_IF_REAL_ARG_COUNT(1) { JP_CALL_MSGSEND_ARG1(1) }
    JP_IF_REAL_ARG_COUNT(2) { JP_DEAL_MSGSEND(2, 1) JP_DEAL_MSGSEND(2, 2) }
    JP_IF_REAL_ARG_COUNT(3) { JP_DEAL_MSGSEND(3, 1) JP_DEAL_MSGSEND(3, 2) JP_DEAL_MSGSEND(3, 3) }
    JP_IF_REAL_ARG_COUNT(4) { JP_DEAL_MSGSEND(4, 1) JP_DEAL_MSGSEND(4, 2) JP_DEAL_MSGSEND(4, 3) JP_DEAL_MSGSEND(4, 4) }
    JP_IF_REAL_ARG_COUNT(5) { JP_DEAL_MSGSEND(5, 1) JP_DEAL_MSGSEND(5, 2) JP_DEAL_MSGSEND(5, 3) JP_DEAL_MSGSEND(5, 4) JP_DEAL_MSGSEND(5, 5) }
    JP_IF_REAL_ARG_COUNT(6) { JP_DEAL_MSGSEND(6, 1) JP_DEAL_MSGSEND(6, 2) JP_DEAL_MSGSEND(6, 3) JP_DEAL_MSGSEND(6, 4) JP_DEAL_MSGSEND(6, 5) JP_DEAL_MSGSEND(6, 6) }
    JP_IF_REAL_ARG_COUNT(7) { JP_DEAL_MSGSEND(7, 1) JP_DEAL_MSGSEND(7, 2) JP_DEAL_MSGSEND(7, 3) JP_DEAL_MSGSEND(7, 4) JP_DEAL_MSGSEND(7, 5) JP_DEAL_MSGSEND(7, 6) JP_DEAL_MSGSEND(7, 7) }
    JP_IF_REAL_ARG_COUNT(8) { JP_DEAL_MSGSEND(8, 1) JP_DEAL_MSGSEND(8, 2) JP_DEAL_MSGSEND(8, 3) JP_DEAL_MSGSEND(8, 4) JP_DEAL_MSGSEND(8, 5) JP_DEAL_MSGSEND(8, 6) JP_DEAL_MSGSEND(8, 7) JP_DEAL_MSGSEND(8, 8) }
    JP_IF_REAL_ARG_COUNT(9) { JP_DEAL_MSGSEND(9, 1) JP_DEAL_MSGSEND(9, 2) JP_DEAL_MSGSEND(9, 3) JP_DEAL_MSGSEND(9, 4) JP_DEAL_MSGSEND(9, 5) JP_DEAL_MSGSEND(9, 6) JP_DEAL_MSGSEND(9, 7) JP_DEAL_MSGSEND(9, 8) JP_DEAL_MSGSEND(9, 9) }
    JP_IF_REAL_ARG_COUNT(10) { JP_DEAL_MSGSEND(10, 1) JP_DEAL_MSGSEND(10, 2) JP_DEAL_MSGSEND(10, 3) JP_DEAL_MSGSEND(10, 4) JP_DEAL_MSGSEND(10, 5) JP_DEAL_MSGSEND(10, 6) JP_DEAL_MSGSEND(10, 7) JP_DEAL_MSGSEND(10, 8) JP_DEAL_MSGSEND(10, 9) JP_DEAL_MSGSEND(10, 10) }
    
    return results;
}

static id getXXXArgument(id valObj){
    if (valObj == _XXXnilObj ||
        ([valObj isKindOfClass:[NSNumber class]] && strcmp([valObj objCType], "c") == 0 && ![valObj boolValue])) {
        return nil;
    }
    return valObj;
}

#pragma mark -

static id genXXXCallbackBlock(JSValue *jsVal)
{
    #define BLK_TRAITS_ARG(_idx, _paramName) \
    if (_idx < argTypes.count) { \
        NSString *argType = trim(argTypes[_idx]); \
        if (blockXXXTypeIsScalarXXXPointer(argType)) { \
            [list addObject:formatOCToXXXJS([JPXXXBoxing boxPointer:_paramName])]; \
        } else if (blockXXXTypeIsObject(trim(argTypes[_idx]))) {  \
            [list addObject:formatOCToXXXJS((__bridge id)_paramName)]; \
        } else {  \
            [list addObject:formatOCToXXXJS([NSNumber numberWithLongLong:(long long)_paramName])]; \
        }   \
    }

    NSArray *argTypes = [[jsVal[@"args"] toString] componentsSeparatedByString:@","];
    if (argTypes.count > [jsVal[@"argCount"] toInt32]) {
        argTypes = [argTypes subarrayWithRange:NSMakeRange(1, argTypes.count - 1)];
    }
    id cb = ^id(void *p0, void *p1, void *p2, void *p3, void *p4, void *p5) {
        NSMutableArray *list = [[NSMutableArray alloc] init];
        BLK_TRAITS_ARG(0, p0)
        BLK_TRAITS_ARG(1, p1)
        BLK_TRAITS_ARG(2, p2)
        BLK_TRAITS_ARG(3, p3)
        BLK_TRAITS_ARG(4, p4)
        BLK_TRAITS_ARG(5, p5)
        JSValue *ret = [jsVal[@"cb"] callWithArguments:list];
        return formatXXXJSToOC(ret);
    };
    
    return cb;
}

#pragma mark - Struct

static int sizeOfXXXStructXXXTypes(NSString *structTypes)
{
    const char *types = [structTypes cStringUsingEncoding:NSUTF8StringEncoding];
    int index = 0;
    int size = 0;
    while (types[index]) {
        switch (types[index]) {
            #define JP_STRUCT_SIZE_CASE(_typeChar, _type)   \
            case _typeChar: \
                size += sizeof(_type);  \
                break;
                
            JP_STRUCT_SIZE_CASE('c', char)
            JP_STRUCT_SIZE_CASE('C', unsigned char)
            JP_STRUCT_SIZE_CASE('s', short)
            JP_STRUCT_SIZE_CASE('S', unsigned short)
            JP_STRUCT_SIZE_CASE('i', int)
            JP_STRUCT_SIZE_CASE('I', unsigned int)
            JP_STRUCT_SIZE_CASE('l', long)
            JP_STRUCT_SIZE_CASE('L', unsigned long)
            JP_STRUCT_SIZE_CASE('q', long long)
            JP_STRUCT_SIZE_CASE('Q', unsigned long long)
            JP_STRUCT_SIZE_CASE('f', float)
            JP_STRUCT_SIZE_CASE('F', CGFloat)
            JP_STRUCT_SIZE_CASE('N', NSInteger)
            JP_STRUCT_SIZE_CASE('U', NSUInteger)
            JP_STRUCT_SIZE_CASE('d', double)
            JP_STRUCT_SIZE_CASE('B', BOOL)
            JP_STRUCT_SIZE_CASE('*', void *)
            JP_STRUCT_SIZE_CASE('^', void *)
            
            default:
                break;
        }
        index ++;
    }
    return size;
}

static void getXXXStructXXXDataWithDict(void *structData, NSDictionary *dict, NSDictionary *structDefine)
{
    NSArray *itemKeys = structDefine[@"keys"];
    const char *structTypes = [structDefine[@"types"] cStringUsingEncoding:NSUTF8StringEncoding];
    int position = 0;
    for (int i = 0; i < itemKeys.count; i ++) {
        switch(structTypes[i]) {
            #define JP_STRUCT_DATA_CASE(_typeStr, _type, _transMethod) \
            case _typeStr: { \
                int size = sizeof(_type);    \
                _type val = [dict[itemKeys[i]] _transMethod];   \
                memcpy(structData + position, &val, size);  \
                position += size;    \
                break;  \
            }
                
            JP_STRUCT_DATA_CASE('c', char, charValue)
            JP_STRUCT_DATA_CASE('C', unsigned char, unsignedCharValue)
            JP_STRUCT_DATA_CASE('s', short, shortValue)
            JP_STRUCT_DATA_CASE('S', unsigned short, unsignedShortValue)
            JP_STRUCT_DATA_CASE('i', int, intValue)
            JP_STRUCT_DATA_CASE('I', unsigned int, unsignedIntValue)
            JP_STRUCT_DATA_CASE('l', long, longValue)
            JP_STRUCT_DATA_CASE('L', unsigned long, unsignedLongValue)
            JP_STRUCT_DATA_CASE('q', long long, longLongValue)
            JP_STRUCT_DATA_CASE('Q', unsigned long long, unsignedLongLongValue)
            JP_STRUCT_DATA_CASE('f', float, floatValue)
            JP_STRUCT_DATA_CASE('d', double, doubleValue)
            JP_STRUCT_DATA_CASE('B', BOOL, boolValue)
            JP_STRUCT_DATA_CASE('N', NSInteger, integerValue)
            JP_STRUCT_DATA_CASE('U', NSUInteger, unsignedIntegerValue)
            
            case 'F': {
                int size = sizeof(CGFloat);
                CGFloat val;
                #if CGFLOAT_IS_DOUBLE
                val = [dict[itemKeys[i]] doubleValue];
                #else
                val = [dict[itemKeys[i]] floatValue];
                #endif
                memcpy(structData + position, &val, size);
                position += size;
                break;
            }
            
            case '*':
            case '^': {
                int size = sizeof(void *);
                void *val = [(JPXXXBoxing *)dict[itemKeys[i]] unboxPointer];
                memcpy(structData + position, &val, size);
                break;
            }
            
        }
    }
}

static NSDictionary *getDictOfXXXStruct(void *structData, NSDictionary *structDefine)
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    NSArray *itemKeys = structDefine[@"keys"];
    const char *structTypes = [structDefine[@"types"] cStringUsingEncoding:NSUTF8StringEncoding];
    int position = 0;
    
    for (int i = 0; i < itemKeys.count; i ++) {
        switch(structTypes[i]) {
            #define JP_STRUCT_DICT_CASE(_typeName, _type)   \
            case _typeName: { \
                size_t size = sizeof(_type); \
                _type *val = malloc(size);   \
                memcpy(val, structData + position, size);   \
                [dict setObject:@(*val) forKey:itemKeys[i]];    \
                free(val);  \
                position += size;   \
                break;  \
            }
            JP_STRUCT_DICT_CASE('c', char)
            JP_STRUCT_DICT_CASE('C', unsigned char)
            JP_STRUCT_DICT_CASE('s', short)
            JP_STRUCT_DICT_CASE('S', unsigned short)
            JP_STRUCT_DICT_CASE('i', int)
            JP_STRUCT_DICT_CASE('I', unsigned int)
            JP_STRUCT_DICT_CASE('l', long)
            JP_STRUCT_DICT_CASE('L', unsigned long)
            JP_STRUCT_DICT_CASE('q', long long)
            JP_STRUCT_DICT_CASE('Q', unsigned long long)
            JP_STRUCT_DICT_CASE('f', float)
            JP_STRUCT_DICT_CASE('F', CGFloat)
            JP_STRUCT_DICT_CASE('N', NSInteger)
            JP_STRUCT_DICT_CASE('U', NSUInteger)
            JP_STRUCT_DICT_CASE('d', double)
            JP_STRUCT_DICT_CASE('B', BOOL)
            
            case '*':
            case '^': {
                size_t size = sizeof(void *);
                void *val = malloc(size);
                memcpy(val, structData + position, size);
                [dict setObject:[JPXXXBoxing boxPointer:val] forKey:itemKeys[i]];
                position += size;
                break;
            }
            
        }
    }
    return dict;
}

static NSString *extractXXXStructXXXName(NSString *typeEncodeString)
{
    NSArray *array = [typeEncodeString componentsSeparatedByString:@"="];
    NSString *typeString = array[0];
    int firstValidIndex = 0;
    for (int i = 0; i< typeString.length; i++) {
        char c = [typeString characterAtIndex:i];
        if (c == '{' || c=='_') {
            firstValidIndex++;
        }else {
            break;
        }
    }
    return [typeString substringFromIndex:firstValidIndex];
}

#pragma mark - Utils

static NSString *trim(NSString *string)
{
    return [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

static BOOL blockXXXTypeIsObject(NSString *typeString)
{
    return [typeString rangeOfString:@"*"].location != NSNotFound || [typeString isEqualToString:@"id"];
}

static BOOL blockXXXTypeIsScalarXXXPointer(NSString *typeString)
{
    NSUInteger location = [typeString rangeOfString:@"*"].location;
    NSString *typeWithoutAsterisk = trim([typeString stringByReplacingOccurrencesOfString:@"*" withString:@""]);
    
    return (location == typeString.length-1 &&
            !NSClassFromString(typeWithoutAsterisk));
}

static NSString *convertJPXXXSelectorString(NSString *selectorString)
{
    NSString *tmpJSMethodName = [selectorString stringByReplacingOccurrencesOfString:@"__" withString:@"-"];
    NSString *selectorName = [tmpJSMethodName stringByReplacingOccurrencesOfString:@"_" withString:@":"];
    return [selectorName stringByReplacingOccurrencesOfString:@"-" withString:@"_"];
}

#pragma mark - Object format

static id formatOCToXXXJS(id obj)
{
    if ([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSDictionary class]] || [obj isKindOfClass:[NSArray class]] || [obj isKindOfClass:[NSDate class]]) {
        return _XXXautoConvert ? obj: _XXXwrapObj([JPXXXBoxing boxObj:obj]);
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        return _XXXconvertOCNumberToString ? [(NSNumber*)obj stringValue] : obj;
    }
    if ([obj isKindOfClass:NSClassFromString(@"NSBlock")] || [obj isKindOfClass:[JSValue class]]) {
        return obj;
    }
    return _XXXwrapObj(obj);
}

static id formatXXXJSToOC(JSValue *jsval)
{
    id obj = [jsval toObject];
    if (!obj || [obj isKindOfClass:[NSNull class]]) return _XXXnilObj;
    
    if ([obj isKindOfClass:[JPXXXBoxing class]]) return [obj unbox];
    if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray *newArr = [[NSMutableArray alloc] init];
        for (int i = 0; i < [(NSArray*)obj count]; i ++) {
            [newArr addObject:formatXXXJSToOC(jsval[i])];
        }
        return newArr;
    }
    if ([obj isKindOfClass:[NSDictionary class]]) {
        if (obj[@"__obj"]) {
            id ocObj = [obj objectForKey:@"__obj"];
            if ([ocObj isKindOfClass:[JPXXXBoxing class]]) return [ocObj unbox];
            return ocObj;
        } else if (obj[@"__clsName"]) {
            return NSClassFromString(obj[@"__clsName"]);
        }
        if (obj[@"__isXXXBlock"]) {
            Class JPBlockClass = NSClassFromString(@"JPXXXBlock");
            if (JPBlockClass && ![jsval[@"blockObj"] isUndefined]) {
                return [JPBlockClass performSelector:@selector(blockWithBlockObj:) withObject:[jsval[@"blockObj"] toObject]];
            } else {
                return genXXXCallbackBlock(jsval);
            }
        }
        NSMutableDictionary *newDict = [[NSMutableDictionary alloc] init];
        for (NSString *key in [obj allKeys]) {
            [newDict setObject:formatXXXJSToOC(jsval[key]) forKey:key];
        }
        return newDict;
    }
    return obj;
}

static id _formatOCToXXXJSList(NSArray *list)
{
    NSMutableArray *arr = [NSMutableArray new];
    for (id obj in list) {
        [arr addObject:formatOCToXXXJS(obj)];
    }
    return arr;
}

static NSDictionary *_XXXwrapObj(id obj)
{
    if (!obj || obj == _XXXnilObj) {
        return @{@"__isNil": @(YES)};
    }
    return @{@"__obj": obj, @"__clsName": NSStringFromClass([obj isKindOfClass:[JPXXXBoxing class]] ? [[((JPXXXBoxing *)obj) unbox] class]: [obj class])};
}

static id _unboxOCObjectToXXXJS(id obj)
{
    if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray *newArr = [[NSMutableArray alloc] init];
        for (int i = 0; i < [(NSArray*)obj count]; i ++) {
            [newArr addObject:_unboxOCObjectToXXXJS(obj[i])];
        }
        return newArr;
    }
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *newDict = [[NSMutableDictionary alloc] init];
        for (NSString *key in [obj allKeys]) {
            [newDict setObject:_unboxOCObjectToXXXJS(obj[key]) forKey:key];
        }
        return newDict;
    }
    if ([obj isKindOfClass:[NSString class]] ||[obj isKindOfClass:[NSNumber class]] || [obj isKindOfClass:NSClassFromString(@"NSBlock")] || [obj isKindOfClass:[NSDate class]]) {
        return obj;
    }
    return _XXXwrapObj(obj);
}
#pragma clang diagnostic pop
@end


@implementation CTXXXExtension

+ (void)mainXXX:(JSContext *)context{}

+ (void *)formatPointerXXXJSToOC:(JSValue *)val
{
    id obj = [val toObject];
    if ([obj isKindOfClass:[NSDictionary class]]) {
        if (obj[@"__obj"] && [obj[@"__obj"] isKindOfClass:[JPXXXBoxing class]]) {
            return [(JPXXXBoxing *)(obj[@"__obj"]) unboxPointer];
        } else {
            return NULL;
        }
    } else if (![val toBool]) {
        return NULL;
    } else{
        return [((JPXXXBoxing *)[val toObject]) unboxPointer];
    }
}

+ (id)formatRetainedCFTypeOCToJS:(CFTypeRef)CF_CONSUMED type
{
    return formatOCToXXXJS([JPXXXBoxing boxPointer:(void *)type]);
}

+ (id)formatPointerOCToXXXJS:(void *)pointer
{
    return formatOCToXXXJS([JPXXXBoxing boxPointer:pointer]);
}

+ (id)formatXXXJSToOC:(JSValue *)val
{
    if (![val toBool]) {
        return nil;
    }
    return formatXXXJSToOC(val);
}

+ (id)formatOCToXXXJS:(id)obj
{
    JSContext *context = [JSContext currentContext] ? [JSContext currentContext]: _XXXcontext;
    return [context[@"_formatXXXOCToJS"] callWithArguments:@[formatOCToXXXJS(obj)]];
}

+ (int)sizeOfXXXStructTypes:(NSString *)structTypes
{
    return sizeOfXXXStructXXXTypes( structTypes);
}

+ (void)getXXXStructDataWidthDict:(void *)structData dict:(NSDictionary *)dict structDefine:(NSDictionary *)structDefine
{
    return getXXXStructXXXDataWithDict(structData, dict, structDefine);
}

+ (NSDictionary *)getDictOfXXXStruct:(void *)structData structDefine:(NSDictionary *)structDefine
{
    return getDictOfXXXStruct( structData, structDefine);
}

+ (NSMutableDictionary *)registeredXXXStruct
{
    return _XXXregisteredStruct;
}

+ (NSDictionary *)overideXXXMethods
{
    return _XXXJSOverideMethods;
}

+ (NSMutableSet *)includedXXXScriptPaths
{
    return _XXXrunnedScript;
}

@end
