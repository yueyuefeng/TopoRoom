#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TRCore : NSObject

+ (NSString*)version;
+ (nullable instancetype)documentWithId:(NSString*)documentId;

- (BOOL)addWallOnStorey:(NSString*)storeyId
                 wallId:(NSString*)wallId
                     x0:(double)x0
                     y0:(double)y0
                     x1:(double)x1
                     y1:(double)y1
           thicknessMm:(double)thicknessMm
              heightMm:(double)heightMm
                  error:(NSError* _Nullable* _Nullable)error;

- (nullable NSString*)sceneIRJSON;

@end

NS_ASSUME_NONNULL_END
