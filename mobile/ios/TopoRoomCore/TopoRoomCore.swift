import Foundation

/// Swift face of the shared C++ core. The iOS app UI (later) talks to this type,
/// never to mesh/Godot nodes as editable truth.
public final class TopoRoomCore {
  private let impl: TRCore

  public static var version: String { TRCore.version() }

  public init?(documentId: String) {
    guard let impl = TRCore(documentWithId: documentId) else { return nil }
    self.impl = impl
  }

  public func sceneIRJSON() -> String? {
    impl.sceneIRJSON()
  }
}
