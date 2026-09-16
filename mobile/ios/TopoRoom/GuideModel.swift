import Foundation
import SwiftUI

@MainActor
final class GuideModel: ObservableObject {
  @Published var phase: String = "host_check"
  @Published var blocking: String = ""
  @Published var log: String = ""
  @Published var canExport: Bool = false
  @Published var typedMm: String = "4000"
  @Published var lastExportDir: String = ""

  private var core: TopoRoomCore?

  init() {
    restart()
  }

  func restart() {
    core = TopoRoomCore(documentId: "doc_ios")
    core?.markHostOk(true)
    refresh("software host — P0: depth capture Android-first")
  }

  func addRectangle() {
    guard let core else { return }
    let storey = core.firstStoreyId
    do {
      try core.addWall(storeyId: storey, wallId: "wall_n", x0: 0, y0: 3000, x1: 4000, y1: 3000)
      try core.addWall(storeyId: storey, wallId: "wall_e", x0: 4000, y0: 3000, x1: 4000, y1: 0)
      try core.addWall(storeyId: storey, wallId: "wall_s", x0: 4000, y0: 0, x1: 0, y1: 0)
      try core.addWall(storeyId: storey, wallId: "wall_w", x0: 0, y0: 0, x1: 0, y1: 3000)
      refresh("drew 4 walls")
    } catch {
      refresh("wall error: \(error.localizedDescription)")
    }
  }

  func measureTyped() {
    guard let core else { return }
    let value = Double(typedMm) ?? 4000
    do {
      try core.setMeasurement(id: "m_key_\(UUID().uuidString.prefix(8))", valueMm: value,
                              source: "typed", betweenCsv: "wall_s")
      refresh("typed \(value) mm")
    } catch {
      refresh("measure error: \(error.localizedDescription)")
    }
  }

  func addDoor() {
    guard let core else { return }
    do {
      try core.addOpening(
        storeyId: core.firstStoreyId, wallId: "wall_s", openingId: "op_door", widthMm: 900,
        heightMm: 2100, offsetMm: 800)
      refresh("placed door")
    } catch {
      refresh("opening error: \(error.localizedDescription)")
    }
  }

  func exportAll() {
    guard let core else { return }
    let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("export")
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    do {
      try core.closeRoom(
        storeyId: core.firstStoreyId, roomId: "room_1", wallIdsCsv: "wall_n,wall_e,wall_s,wall_w")
      try core.export(format: "glb", to: dir.appendingPathComponent("room.glb").path)
      try core.export(format: "dxf", to: dir.appendingPathComponent("room.dxf").path)
      try core.export(format: "pdf", to: dir.appendingPathComponent("room.pdf").path)
      lastExportDir = dir.path
      refresh("exported glb/dxf/pdf")
    } catch {
      refresh("export error: \(error.localizedDescription)")
    }
  }

  func runFakeLoop() {
    restart()
    guard let core else { return }
    let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("export")
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    do {
      try core.runFakeOneRoom(to: dir.path)
      lastExportDir = dir.path
      refresh("fake one-room (software; no external depth)")
    } catch {
      refresh("fake loop error: \(error.localizedDescription)")
    }
  }

  func attachEvidence() {
    core?.attachEvidence(id: "p0_empty", kind: "note")
    refresh("evidence sidecar attached (still optional / empty OK)")
  }

  private func refresh(_ line: String) {
    phase = core?.phase ?? "host_check"
    blocking = core?.blockingReason ?? ""
    canExport = core?.canExport ?? false
    log = log.isEmpty ? line : log + "\n" + line
  }
}
