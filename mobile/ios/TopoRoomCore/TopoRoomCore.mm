#import "TopoRoomCore.h"

#include "toporoom/c_api/toporoom.h"

@implementation TRCore {
  TopoRoomDocument* _doc;
}

+ (NSString*)version {
  return @(toporoom_version());
}

+ (instancetype)documentWithId:(NSString*)documentId {
  TopoRoomDocument* doc = toporoom_document_create(documentId.UTF8String);
  if (!doc) {
    return nil;
  }
  TRCore* core = [[TRCore alloc] init];
  core->_doc = doc;
  return core;
}

- (void)dealloc {
  toporoom_document_destroy(_doc);
}

- (BOOL)addWallOnStorey:(NSString*)storeyId
                 wallId:(NSString*)wallId
                     x0:(double)x0
                     y0:(double)y0
                     x1:(double)x1
                     y1:(double)y1
           thicknessMm:(double)thicknessMm
              heightMm:(double)heightMm
                  error:(NSError**)error {
  char err[256] = {0};
  const int rc = toporoom_document_add_wall(
      _doc, storeyId.UTF8String, wallId.UTF8String, x0, y0, x1, y1, thicknessMm,
      heightMm, err, (int)sizeof(err));
  if (rc != 0) {
    if (error) {
      *error = [NSError errorWithDomain:@"toporoom" code:rc
                               userInfo:@{NSLocalizedDescriptionKey : @(err)}];
    }
    return NO;
  }
  return YES;
}

- (NSString*)sceneIRJSON {
  char* json = toporoom_document_to_sceneir_json(_doc);
  if (!json) {
    return nil;
  }
  NSString* text = @(json);
  toporoom_string_free(json);
  return text;
}

@end
