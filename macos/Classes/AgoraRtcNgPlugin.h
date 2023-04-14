#import <FlutterMacOS/FlutterMacOS.h>

@interface AgoraRtcNgPlugin : NSObject<FlutterPlugin>
- (void) regOnFrame:(void (^)(CVPixelBufferRef))callback;
@end
