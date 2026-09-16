#import "TopoRoomCore.h"

#include "toporoom/c_api/toporoom.h"

static BOOL TRFillError(int rc, const char* err, NSError** error) {
  if (rc == 0) return YES;
  if (error) {
    NSString* message = err && err[0] ? @(err) : @"toporoom error";
    *error = [NSError errorWithDomain:@"toporoom" code:rc
                             userInfo:@{NSLocalizedDescriptionKey : message}];
  }
  return NO;
}

@implementation TRCore {
  TopoRoomDocument* _doc;
  TopoRoomGuide* _guide;
  TopoRoomEvidence* _evidence;
}

+ (NSString*)version {
  return @(toporoom_version());
}

+ (BOOL)iosExternalDepthInP0 {
  return toporoom_ios_external_depth_in_p0() != 0;
}

+ (instancetype)documentWithId:(NSString*)documentId {
  TopoRoomDocument* doc = toporoom_document_create(documentId.UTF8String);
  if (!doc) {
    return nil;
  }
  TRCore* core = [[TRCore alloc] init];
  core->_doc = doc;
  core->_guide = toporoom_guide_create();
  core->_evidence = toporoom_evidence_create(documentId.UTF8String);
  return core;
}

- (void)dealloc {
  toporoom_evidence_destroy(_evidence);
  toporoom_guide_destroy(_guide);
  toporoom_document_destroy(_doc);
}

- (NSString*)firstStoreyId {
  char buf[128] = {0};
  if (toporoom_document_first_storey_id(_doc, buf, (int)sizeof(buf)) != 0) {
    return @"storey_1";
  }
  return @(buf);
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
      _doc, storeyId.UTF8String, wallId.UTF8String, x0, y0, x1, y1, thicknessMm, heightMm,
      err, (int)sizeof(err));
  if (rc == 0) {
    toporoom_guide_note_wall(_guide);
  }
  return TRFillError(rc, err, error);
}

- (BOOL)addOpeningOnStorey:(NSString*)storeyId
                    wallId:(NSString*)wallId
                 openingId:(NSString*)openingId
                      kind:(NSString*)kind
                   widthMm:(double)widthMm
                  heightMm:(double)heightMm
                  offsetMm:(double)offsetMm
                    sillMm:(double)sillMm
                     error:(NSError**)error {
  char err[256] = {0};
  const int rc = toporoom_document_add_opening(
      _doc, storeyId.UTF8String, wallId.UTF8String, openingId.UTF8String, kind.UTF8String,
      widthMm, heightMm, offsetMm, sillMm, err, (int)sizeof(err));
  if (rc == 0) {
    toporoom_guide_note_opening(_guide);
  }
  return TRFillError(rc, err, error);
}

- (BOOL)setMeasurement:(NSString*)measurementId
               valueMm:(double)valueMm
                source:(NSString*)source
          instrumentId:(NSString*)instrumentId
           betweenCsv:(NSString*)betweenCsv
                 error:(NSError**)error {
  char err[256] = {0};
  const int rc = toporoom_document_set_measurement(
      _doc, measurementId.UTF8String, valueMm, source.UTF8String,
      instrumentId.UTF8String, betweenCsv.UTF8String, NULL, NULL, NULL, err,
      (int)sizeof(err));
  if (rc == 0) {
    const int explicitTyped = [source isEqualToString:@"typed"] ? 1 : 0;
    toporoom_guide_note_key_measurement(_guide, source.UTF8String, explicitTyped);
  }
  return TRFillError(rc, err, error);
}

- (BOOL)closeRoomOnStorey:(NSString*)storeyId
                   roomId:(NSString*)roomId
              wallIdsCsv:(NSString*)wallIdsCsv
                    error:(NSError**)error {
  char err[256] = {0};
  const int rc = toporoom_document_close_room(
      _doc, storeyId.UTF8String, roomId.UTF8String, wallIdsCsv.UTF8String, err,
      (int)sizeof(err));
  return TRFillError(rc, err, error);
}

- (BOOL)exportFormat:(NSString*)format
              toPath:(NSString*)path
               error:(NSError**)error {
  char err[256] = {0};
  const int rc =
      toporoom_document_export(_doc, format.UTF8String, path.UTF8String, err, (int)sizeof(err));
  if (rc == 0) {
    toporoom_guide_note_rebuild(_guide, 1);
  } else {
    toporoom_guide_note_rebuild(_guide, 0);
  }
  return TRFillError(rc, err, error);
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

- (void)markHostOk:(BOOL)ok {
  toporoom_guide_mark_host_ok(_guide, ok ? 1 : 0);
}

- (void)noteWall {
  toporoom_guide_note_wall(_guide);
}

- (void)noteOpening {
  toporoom_guide_note_opening(_guide);
}

- (void)noteKeyMeasurement:(NSString*)source typedExplicit:(BOOL)typedExplicit {
  toporoom_guide_note_key_measurement(_guide, source.UTF8String, typedExplicit ? 1 : 0);
}

- (void)noteRebuild:(BOOL)ok {
  toporoom_guide_note_rebuild(_guide, ok ? 1 : 0);
}

- (NSString*)phase {
  return @(toporoom_guide_phase(_guide));
}

- (BOOL)canExport {
  return toporoom_guide_can_export(_guide) != 0;
}

- (NSString*)blockingReason {
  return @(toporoom_guide_blocking_reason(_guide));
}

- (BOOL)runFakeOneRoomToDirectory:(NSString*)directory error:(NSError**)error {
  char err[256] = {0};
  const int rc =
      toporoom_debug_fake_one_room(_doc, _guide, directory.UTF8String, err, (int)sizeof(err));
  return TRFillError(rc, err, error);
}

- (BOOL)attachEvidenceId:(NSString*)itemId kind:(NSString*)kind uri:(NSString*)uri {
  return toporoom_evidence_attach(_evidence, itemId.UTF8String, kind.UTF8String,
                                  uri.UTF8String) == 0;
}

- (BOOL)evidenceEmpty {
  return toporoom_evidence_empty(_evidence) != 0;
}

@end
