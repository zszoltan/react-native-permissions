#import "RNPermissionHandlerLocalNetwork.h"
#include <dns_sd.h>

@implementation RNPermissionHandlerLocalNetwork{
    NSTimer* timer;
    DNSServiceRef browseRef;
}

+ (NSArray<NSString *> * _Nonnull)usageDescriptionKeys {
  return @[@"NSCameraUsageDescription"];
}

+ (NSString * _Nonnull)handlerUniqueId {
  return @"ios.permission.LOCAL_NETWORK";
}

- (void)checkWithResolver:(void (^ _Nonnull)(RNPermissionStatus))resolve
                 rejecter:(void (__unused ^ _Nonnull)(NSError * _Nonnull)) reject {
    self->_resolve = resolve;
    if (@available(iOS 14, *)){
         if(self->timer!=nil){
             [self resolvePromise:RNPermissionStatusNotDetermined];
             return;
        }
        if(self->browseRef!=nil){
            DNSServiceRefDeallocate(self->browseRef);
            self->browseRef = nil;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self->timer = [NSTimer scheduledTimerWithTimeInterval: 1.0
                                                           target: self
                                                         selector:@selector(onTimeOut:)                                                    userInfo: nil
                                                          repeats:NO];
            DNSServiceErrorType error = kDNSServiceErr_NoError;
            error = DNSServiceBrowse(&(self->browseRef), 0, 0,  @"_http._tcp".UTF8String, NULL, browseCallback, (__bridge void *)(self));
            if (error != kDNSServiceErr_NoError)
            {
                NSLog(@"ERROR DNSServiceBrowse error code: %d", error);
                [self resolvePromise:RNPermissionStatusNotDetermined];
                return;
            }
            error = DNSServiceSetDispatchQueue(self->browseRef, dispatch_get_main_queue());
            if (error != kDNSServiceErr_NoError)
            {
                
                NSLog(@"ERROR DNSServiceSetDispatchQueue error code: %d", error);
                [self resolvePromise:RNPermissionStatusNotDetermined];
                return;
            }
        });
    }else{
        [self resolvePromise:RNPermissionStatusNotAvailable];
    }
  
}


- (void)requestWithResolver:(void (^ _Nonnull)(RNPermissionStatus))resolve
                   rejecter:(void (^ _Nonnull)(NSError * _Nonnull))reject {
                      [self checkWithResolver:resolve rejecter:reject]; 
}

-(void)resolvePromise:(RNPermissionStatus) status {
    [self cleanup];
    if(self->_resolve !=nil){
        NSLog(@"-------------------------------------------local network--- resolvePromise");
        self->_resolve(status);
        self->_resolve = nil;
    }
}
-(void)onTimeOut:(NSTimer *)timer {
    [self cleanup];
    [self resolvePromise:RNPermissionStatusAuthorized];
}
-(void)cleanup {
    if(self->timer){
       [self->timer invalidate];
        self->timer = nil;
    }
    if(self->browseRef != nil){
        DNSServiceRefDeallocate(self->browseRef);
        self->browseRef = nil;
    }
}

static void browseCallback(DNSServiceRef sdRef, DNSServiceFlags flags, uint32_t interfaceIndex,
                           DNSServiceErrorType errorCode, const char *serviceName,
                           const char *regtype, const char *replyDomain, void *context) {
    if (errorCode == kDNSServiceErr_PolicyDenied) {
        if(context!=nil){
            RNPermissionHandlerLocalNetwork* this = (__bridge RNPermissionHandlerLocalNetwork *)(context);
            [this resolvePromise:RNPermissionStatusDenied];
        }
    }
}
@end
