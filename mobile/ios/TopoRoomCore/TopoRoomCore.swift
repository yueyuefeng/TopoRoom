import Foundation

/// Swift face of the shared C++ core. SceneIR / FloorPlanDocument is the only
/// editable truth. Godot must never write dimensions back.
public final class TopoRoomCore {
  private let impl: TRCore

  public static var version: String { TRCore.version() }
  public static var iosExternalDepthInP0: Bool { TRCore.iosExternalDepthInP0() }

  public init?(documentId: String) {
    guard let impl = TRCore(documentWithId: documentId) else { return nil }
    self.impl = impl
  }

  public var firstStoreyId: String { impl.firstStoreyId() }
  public var phase: String { impl.phase }
  public var canExport: Bool { impl.canExport }
  public var blockingReason: String { impl.blockingReason }
  public var evidenceEmpty: Bool { impl.evidenceEmpty() }

  public func markHostOk(_ ok: Bool) { impl.markHostOk(ok) }

  public func addWall(
    storeyId: String, wallId: String, x0: Double, y0: Double, x1: Double, y1: Double,
    thicknessMm: Double = 200, heightMm: Double = 2800
  ) throws {
    try impl.addWall(
      onStorey: storeyId, wallId: wallId, x0: x0, y0: y0, x1: x1, y1: y1,
      thicknessMm: thicknessMm, heightMm: heightMm)
  }

  public func addOpening(
    storeyId: String, wallId: String, openingId: String, kind: String = "door",
    widthMm: Double, heightMm: Double, offsetMm: Double, sillMm: Double = 0
  ) throws {
    try impl.addOpening(
      onStorey: storeyId, wallId: wallId, openingId: openingId, kind: kind, widthMm: widthMm,
      heightMm: heightMm, offsetMm: offsetMm, sillMm: sillMm)
  }

  public func setMeasurement(
    id: String, valueMm: Double, source: String, instrumentId: String? = nil,
    betweenCsv: String? = nil
  ) throws {
    try impl.setMeasurement(
      id, valueMm: valueMm, source: source, instrumentId: instrumentId, betweenCsv: betweenCsv)
  }

  public func closeRoom(storeyId: String, roomId: String, wallIdsCsv: String) throws {
    try impl.closeRoom(onStorey: storeyId, roomId: roomId, wallIdsCsv: wallIdsCsv)
  }

  public func export(format: String, to path: String) throws {
    try impl.exportFormat(format, toPath: path)
  }

  public func sceneIRJSON() -> String? { impl.sceneIRJSON() }

  public func runFakeOneRoom(to directory: String) throws {
    try impl.runFakeOneRoom(toDirectory: directory)
  }

  public func attachEvidence(id: String, kind: String, uri: String = "") {
    _ = impl.attachEvidenceId(id, kind: kind, uri: uri)
  }
}
