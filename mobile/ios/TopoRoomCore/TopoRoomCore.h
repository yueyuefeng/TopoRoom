#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TRCore : NSObject

@property (nonatomic, readonly) NSString* phase;
@property (nonatomic, readonly) BOOL canExport;
@property (nonatomic, readonly) NSString* blockingReason;

+ (NSString*)version;
+ (BOOL)iosExternalDepthInP0;
+ (nullable instancetype)documentWithId:(NSString*)documentId;

- (NSString*)firstStoreyId;

- (BOOL)addWallOnStorey:(NSString*)storeyId
                 wallId:(NSString*)wallId
                     x0:(double)x0
                     y0:(double)y0
                     x1:(double)x1
                     y1:(double)y1
            thicknessMm:(double)thicknessMm
               heightMm:(double)heightMm
                  error:(NSError* _Nullable* _Nullable)error;

- (BOOL)addOpeningOnStorey:(NSString*)storeyId
                    wallId:(NSString*)wallId
                 openingId:(NSString*)openingId
                      kind:(NSString*)kind
                   widthMm:(double)widthMm
                  heightMm:(double)heightMm
                  offsetMm:(double)offsetMm
                    sillMm:(double)sillMm
                     error:(NSError* _Nullable* _Nullable)error;

- (BOOL)setMeasurement:(NSString*)measurementId
               valueMm:(double)valueMm
                source:(NSString*)source
          instrumentId:(nullable NSString*)instrumentId
           betweenCsv:(nullable NSString*)betweenCsv
                 error:(NSError* _Nullable* _Nullable)error;

- (BOOL)closeRoomOnStorey:(NSString*)storeyId
                   roomId:(NSString*)roomId
              wallIdsCsv:(NSString*)wallIdsCsv
                    error:(NSError* _Nullable* _Nullable)error;

- (BOOL)exportFormat:(NSString*)format
              toPath:(NSString*)path
               error:(NSError* _Nullable* _Nullable)error;

- (nullable NSString*)sceneIRJSON;

- (void)markHostOk:(BOOL)ok;
- (void)noteWall;
- (void)noteOpening;
- (void)noteKeyMeasurement:(NSString*)source typedExplicit:(BOOL)typedExplicit;
- (void)noteRebuild:(BOOL)ok;

- (BOOL)runFakeOneRoomToDirectory:(NSString*)directory
                            error:(NSError* _Nullable* _Nullable)error;

- (BOOL)attachEvidenceId:(NSString*)itemId
                    kind:(NSString*)kind
                     uri:(NSString*)uri;
- (BOOL)evidenceEmpty;

@end

NS_ASSUME_NONNULL_END
