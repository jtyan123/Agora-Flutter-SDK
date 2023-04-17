#ifndef VideoViewController_h
#define VideoViewController_h

#if TARGET_OS_IPHONE
#import <Flutter/Flutter.h>
#else
#import <FlutterMacOS/FlutterMacOS.h>
#endif

extern void (^externalFrameCallback)(CVPixelBufferRef);
extern int64_t outputTextureId;

@interface VideoViewController : NSObject

- (instancetype)initWith:(NSObject<FlutterTextureRegistry> *)textureRegistry
               messenger:(NSObject<FlutterBinaryMessenger> *)messenger;

- (int64_t)createPlatformRender;

- (BOOL)destroyPlatformRender:(int64_t)platformRenderId;

- (int64_t)createTextureRender:(intptr_t)videoFrameBufferManagerIntPtr
                           uid:(NSNumber *)uid
                     channelId:(NSString *)channelId
               videoSourceType:(NSNumber *)videoSourceType;

- (BOOL)destroyTextureRender:(int64_t)textureId;

- (void)regExternalFrame:(void (^)(CVPixelBufferRef))callback;

- (void)setOutputTextureId:(int64_t)textureId;
@end

#endif /* VideoViewController_h */
