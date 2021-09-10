#import "RNPermissions.h"

@interface RNPermissionHandlerLocalNetwork : NSObject<RNPermissionHandler>

@property (nonatomic, strong) void (^resolve)(RNPermissionStatus status);
@property (nonatomic, strong) void (^reject)(NSError *error);

@end
