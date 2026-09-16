import SwiftUI

struct GuideRootView: View {
  @StateObject private var model = GuideModel()

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(alignment: .leading, spacing: 12) {
          Text("P0: depth capture Android-first")
            .font(.subheadline)
            .foregroundColor(.secondary)
          Text("This iOS host edits FloorPlan / SceneIR via the C API. No USB depth path.")
            .font(.footnote)
          Text("phase: \(model.phase)  canExport=\(model.canExport ? "true" : "false")")
          Text(model.blocking.isEmpty ? "ready" : model.blocking)
            .foregroundColor(model.canExport ? .green : .primary)
          Group {
            Button("Draw walls (rectangle)") { model.addRectangle() }
            HStack {
              TextField("typed mm", text: $model.typedMm)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
              Button("Measure typed") { model.measureTyped() }
            }
            Button("Place opening (door)") { model.addDoor() }
            Button("Close room + export glb/dxf/pdf") { model.exportAll() }
            Button("Run Fake one-room loop") { model.runFakeLoop() }
            Button("Attach empty EvidencePack note") { model.attachEvidence() }
          }
          .buttonStyle(.bordered)
          if !model.lastExportDir.isEmpty {
            Text("export dir: \(model.lastExportDir)").font(.caption)
          }
          Text(model.log)
            .font(.system(.footnote, design: .monospaced))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
      }
      .navigationTitle("TopoRoom")
    }
  }
}
