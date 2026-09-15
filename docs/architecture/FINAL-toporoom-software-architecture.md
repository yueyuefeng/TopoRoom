# 拓间（TopoRoom）最终软件架构

> **状态**：FINAL（Go-with-changes 合成）  
> **日期**：2026-09-15  
> **配套**：`FINAL-toporoom-hw-sw-requirements.md`  
> **图示**：全文 **ASCII only**（无 mermaid）  
> **冲突裁决**：(1) SceneIR 唯一真相 (2) 瘦 P0 (3) 激光关键尺寸 (4) Godot 只读 (5) 禁 GS/写回 (6) Android 白名单 + 外购 Type-C

---

## 0. 架构原则与不变量

| # | 原则 / 不变量 |
|---|---------------|
| I1 | **SceneIR / FloorPlanDocument 是唯一可编辑真相源**；Mesh / MeshGL / 点云 / 3DGS / Godot Node 皆派生 |
| I2 | **manifold 仅出现在 GeometryKernel ACL 之后**；聚合/事件/DocumentStore 永不含 `Manifold`/`CrossSection`/`MeshGL` 原生类型 |
| I3 | **gotbot 只贡献 Application 模式**（ToolRegistry / ParamGatheringFSM / EventPipeline / Ports）；不是 CAD 内核 |
| I4 | **每 documentId 串行写队列**（修正 gotbot 无锁竞态）；rebuild 可用 `rebuildGeneration` 抢占 |
| I5 | **Capture 只发 Command/Event**，持久化落回同一 FloorPlanDocument；禁止第二真相源 |
| I6 | **导出结构固体必须 Status==NoError**；Fault 可见，禁止静默坏网 |
| I7 | **Godot = glTF Conformist 只读宿主**；编辑在 TopoRoom |
| I8 | **VisualizationDerivative 禁止写回尺寸** |
| I9 | **激光尺寸经 Command 写入语义 + source**；不得只写在 Evidence 里假装已量 |
| I10 | 依赖方向：**UI → Application → Domain ← Adapters**；Ports 在内，Adapters 在外 |

---

## 1. 上下文 / BC 全景 ASCII

```
                         ┌──────────────────────┐
                         │   InteractionShell   │
                         │  (gotbot patterns)   │
                         └──────────┬───────────┘
              Command/Intent        │        Partnership
         ┌────────────┬─────────────┼──────────────┐
         v            v             v              v
 ┌───────────────┐ ┌─────────┐ ┌──────────┐  ┌─────────────┐
 │ CaptureDevice │ │ Capture │ │ FloorPlan│  │Visualization│
 │ +Calibration  │→│ Session │→│ Modeling │←→│  (瘦 P0)    │
 │   <<OHS>>     │ │ <<CS>>  │ │ <<CORE>> │  └──────▲──────┘
 └───────────────┘ └────┬────┘ └────┬─────┘         │
                        │           │               │ MeshProjection
                        v           │ PL SceneIR    │ / Snapshot
               ┌────────────────┐   │               │
               │ObservationStore│   │               │
               │  <<OHS 只读>>  │   │               │
               └────────┬───────┘   │               │
                        ┆可选约束    v               │
                        ┆    ┌──────────────┐       │
                        └───→│GeometryKernel│───────┘
                             │ <<ACL→mfld>> │
                             └──────┬───────┘
                                    │ Status + Mesh
                                    v
                             ┌──────────────┐     glTF PL
                             │ Deliverables │──────────────→ [Godot 只读]
                             │ DXF/PDF/glb  │
                             └──────────────┘

P1+（虚线，战略保留）：
  FloorPlan --OHS--> Furnishing
  FloorPlan --CS/OHS--> MEP
  FloorPlan/FU/MEP --events--> TakeoffQuote
  ProjectCollab <--Partnership--> FloorPlan
  VisualizationDerivative <-Conformist- SceneIR   (禁止写回尺寸)
```

### 1.1 BC 职责与关系表

| BC | 代号 | 核心/支撑 | P0? | 职责 | 关键关系 |
|----|------|-----------|-----|------|----------|
| 交互编排 | InteractionShell | Application | P0 | Tool/FSM/串行队列；引导采集 Tool | Customer→各业务 BC |
| 采集设备 | CaptureDevice | 支撑 | P0 | AccessoryProfile、Calibration；Depth/IMU/Laser 适配入口 | OHS→CaptureSession |
| 采集会话 | CaptureSession | 支撑 | P0 | GuidedStep、轨迹轻量、会话状态；**不持网格** | CS→FloorPlan；→Observation |
| 户型语义 | FloorPlanModeling | **核心** | P0 | FloorPlanDocument / Storey / Wall/Room/Opening | PL SceneIR 出站 |
| 观测证据 | ObservationStore | 支撑 | P0 可空 | EvidencePack 外置 | OHS 只读；非真相 |
| 几何内核 | GeometryKernel | 通用+ACL | P0 | GeometryPort；无业务 AR | ACL→manifold |
| 出图交付 | Deliverables | 支撑 | P0 | ExportJob；DXF/PDF/glTF；Status 闸门 | PL→Godot |
| 可视化 | Visualization | 支撑 | P0 瘦 | ViewSession；2D/3D 校验 | Partnership↔Shell |
| 软装 | Furnishing | 支撑 | P1+ | 布局/铺贴 | OHS 于 FloorPlan ID |
| 管综 | MEP | 支撑 | P1+ | 点位/回路 | CS/OHS |
| 算量报价 | TakeoffQuote | 支撑 | P1+ | 面积/报价策略 | events |
| 项目协作 | ProjectCollab | 支撑 | P1+ | 云版本 | Partnership |
| 衍生可视化 | VisualizationDerivative | 支撑可选 | P1+ | 视频/GS 漫游 | Conformist；**禁写回** |

### 1.2 合并/降级决策（相对旧文）

| 原稿 | 决策 |
|------|------|
| SemanticScene 独立 BC | **≡ FloorPlanModeling** |
| ReconstructionCompiler 独立 BC | **拆分**：几何→GeometryKernel；装配导出→Deliverables |
| GodotRuntimeAdapter 独立 BC | **降为适配器**（Deliverables/Visualization） |
| DeviceFirmware / Calibration | **并入 CaptureDevice** |
| Furnishing/MEP/Takeoff/Collab | 战略保留，**P0 不实现** |

---

## 2. 静态组件图（boxes + lines）ASCII

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Presentation / UI                               │
│  GuidedCaptureUI │ FloorPlanCanvas2D │ MeshPreview3D │ ExportDialog     │
└───────────────┬─────────────────┬──────────────────┬────────────────────┘
                │                 │                  │
                v                 v                  v
┌─────────────────────────────────────────────────────────────────────────┐
│ InteractionShell (Application)                                          │
│  ToolRegistry │ ParamGatheringFSM │ SessionIsolate(documentId queue)   │
│  EditorSession │ EventPipeline │ NotifyPort                             │
└───────┬─────────────────┬──────────────────┬────────────────────────────┘
        │                 │                  │
        v                 v                  v
┌───────────────┐ ┌───────────────┐ ┌──────────────────────────────────────┐
│CaptureSession │ │FloorPlan      │ │ Deliverables AppService               │
│ Application   │ │ Application   │ │  ExportJob │ StatusGate │ Exporters   │
└───────┬───────┘ └───────┬───────┘ └──────────────────┬───────────────────┘
        │                 │                            │
        │                 v                            │
        │         ┌───────────────┐                    │
        │         │ FloorPlan     │                    │
        │         │ Domain        │                    │
        │         │ Document/     │                    │
        │         │ Storey AR     │                    │
        │         └───────┬───────┘                    │
        │                 │ BuildRequest               │
        │                 v                            │
        │         ┌───────────────┐                    │
        │         │ GeometryPort  │◄───────────────────┘
        │         └───────┬───────┘
        │                 │
        v                 v
┌───────────────┐ ┌───────────────────────────────────────────────────────┐
│ CaptureDevice │ │ Infrastructure Adapters                               │
│ Ports:        │ │  ManifoldWasmAdapter │ ManifoldNativeAdapter          │
│  DepthStream  │ │  VendorSdkDepth │ UvcDepth │ BtLaser │ PhoneImu       │
│  LaserRange   │ │  DocumentStore(IndexedDB) │ GlbExporter │ DxfExporter │
│  Imu          │ │  GodotRuntimeLoader(外部进程)                         │
└───────────────┘ └───────────────────────────────────────────────────────┘
```

---

## 3. 各核心组件内部架构 ASCII

### 3.1 InteractionShell

```
┌────────────────────── InteractionShell ──────────────────────┐
│                                                              │
│  ┌─────────────┐    ┌──────────────────┐    ┌─────────────┐ │
│  │ ToolRegistry│───→│ ParamGatheringFSM│───→│ CommandBus  │ │
│  │ DrawWall    │    │ (collect params) │    │ (serial Q)  │ │
│  │ CutOpening  │    └──────────────────┘    └──────┬──────┘ │
│  │ LaserMeasure│                                   │        │
│  │ GuidedCapture                                    v        │
│  │ Export…     │                    ┌──────────────────────┐│
│  └─────────────┘                    │ SessionIsolate       ││
│                                     │ key = documentId     ││
│  ┌─────────────┐                    │ queue: cmds+rebuild ││
│  │EditorSession│◄──HUD/pick────────→│ Visualization bridge ││
│  └─────────────┘                    └──────────────────────┘│
│                                                              │
│  gotbot 映射: ToolHandler←CommandHandler; FSM←commandContext │
│               Ports←ReplySender; SessionIsolate←chats map    │
│  **必须改**: 无锁并发 → 每 documentId 串行                     │
└──────────────────────────────────────────────────────────────┘
```

### 3.2 CaptureSession

```
┌────────────────────── CaptureSession ────────────────────────┐
│ Aggregate: CaptureSession                                    │
│  id, documentId, state, GuidedStep[], CalibrationState,      │
│  TrajectoryLite, accessoryRefs, evidencePackId?              │
│                                                              │
│  ┌────────────┐   ports    ┌─────────────────────────────┐  │
│  │ Guided FSM │←──────────│ Depth / Laser / Imu  samples │  │
│  │ Calibrate  │            └─────────────────────────────┘  │
│  │ OuterWall  │                                             │
│  │ Height     │   sync Commands                              │
│  │ Openings   │──────────────────────────────────→ FloorPlan │
│  └────────────┘   AddWall / CutOpening / SetStoreyHeight     │
│                                                              │
│  可选 ──Append*──→ ObservationStore (EvidenceId only)        │
│                                                              │
│  不变量: 不持深度视频/网格; 完成≠几何 OK; 断连可保存语义        │
└──────────────────────────────────────────────────────────────┘
```

### 3.3 FloorPlanModeling

```
┌────────────────── FloorPlanModeling (CORE) ──────────────────┐
│                                                              │
│  FloorPlanDocument (AR)                                      │
│   units=mm │ snap │ version │ format │ storeys[]             │
│        │                                                     │
│        └── Storey (主编辑 AR)                                │
│              Wall[] ── Opening[] / HostedComponent           │
│              Room[]  (闭合服务派生，同事务)                    │
│              height / elevation                              │
│                                                              │
│  Domain Services: RoomClosure │ OpeningPlacement │           │
│                   OrthoEdgeConstraint (P0)                   │
│                                                              │
│  Events: WallAdded │ OpeningAdded │ RoomClosed │             │
│          StoreyHeightChanged │ FloorPlanSemanticsChanged     │
│                                                              │
│  序列化投影 = SceneIR 0.1  (Published Language)              │
│  禁止: Manifold/MeshGL 字段; 第二套 CaptureDocument           │
└──────────────────────────────────────────────────────────────┘
```

### 3.4 GeometryKernel

```
┌────────────────── GeometryKernel (ACL) ──────────────────────┐
│                                                              │
│  Domain/App 可见:                                            │
│  ┌─────────────────────────────────────────────────────────┐│
│  │ GeometryPort                                            ││
│  │  rebuild(BuildRequest) → RebuildResult                  ││
│  │  ensureBuilt(documentRev, scope?) → RebuildResult       ││
│  │  status(solidId|storeyId) → GeometryStatus              ││
│  │  clearCache(keys?)                                      ││
│  └─────────────────────────────────────────────────────────┘│
│                          │                                   │
│                          v  仅 Adapter 内                    │
│  ┌─────────────────────────────────────────────────────────┐│
│  │ ManifoldAdapter (Wasm | Native)                         ││
│  │  CrossSection → Extrude → Boolean(Subtract openings)    ││
│  │  GetMeshGL → MeshProjection + nodeHints                 ││
│  │  Status → GeometryFault 映射                            ││
│  │  CacheKey = hash(SceneIR slice + compileOptions)        ││
│  └─────────────────────────────────────────────────────────┘│
│                                                              │
│  P0 不做: Smooth/Refine/MinGap/LevelSet/Hull/importRepair    │
│  软装默认不进 Boolean                                        │
└──────────────────────────────────────────────────────────────┘
```

### 3.5 Deliverables

```
┌────────────────────── Deliverables ──────────────────────────┐
│ Aggregate: ExportJob                                         │
│  format │ layerSet │ documentRev │ status                    │
│                                                              │
│  ExportAppService                                            │
│    1. ensureBuilt + status gate                              │
│    2a. Fault → ExportRejected (不改 Storey)                  │
│    2b. OK:                                                   │
│         ┌──────────────┐  ┌──────────────┐  ┌─────────────┐ │
│         │ DxfExporter  │  │ PdfExporter  │  │ GlbExporter │ │
│         │ 语义中线/尺寸 │  │ 平面         │  │ 节点树装配  │ │
│         └──────────────┘  └──────────────┘  └──────┬──────┘ │
│                                                    │        │
│                                            GodotRuntime     │
│                                            Adapter (只读)   │
│                                                              │
│  策略待确认(Q3): Fault 时语义 DXF 中线层是否放行               │
└──────────────────────────────────────────────────────────────┘
```

---

## 4. 组件交互序列 ASCII

### 4.1 序列 A：引导采集写语义

```
User      UI/Shell      CaptureDevice     CaptureSession      FloorPlan       Observation
 │          │                │                  │                 │                │
 │ insert   │                │                  │                 │                │
 │─────────→│ discover/open  │                  │                 │                │
 │          │───────────────→│                  │                 │                │
 │          │←────frames─────│                  │                 │                │
 │ start    │                │                  │                 │                │
 │ guided   │──GuidedCaptureTool+FSM───────────→│                 │                │
 │          │                │                  │                 │                │
 │ calibrate│                │   Imu/Depth      │                 │                │
 │─────────→│────────────────┼─────────────────→│ CalibrationOK   │                │
 │          │                │                  │                 │                │
 │ wall pts │                │ Depth fit hint   │                 │                │
 │─────────→│────────────────┼─────────────────→│ AddWallCommand  │                │
 │          │                │                  │────────────────→│ WallAdded      │
 │          │                │                  │  optional───────┼───────────────→│ Append
 │          │←────HUD refresh (semantics)───────┤                 │                │
 │          │                │                  │                 │                │
 │ (repeat openings / height…)                                    │                │
 │          │                │                  │                 │──SemanticsChanged
 │          │                │                  │                 │→ RebuildPolicy │
```

### 4.2 序列 B：激光写入关键边

```
User     Shell/FSM      LaserRangefinderPort     CaptureSession/尺寸Tool      Storey
 │          │                    │                        │                     │
 │ 选关键边 │                    │                        │                     │
 │ (门洞净宽)│                    │                        │                     │
 │─────────→│ 提示「激光或键入」  │                        │                     │
 │          │──readLengthMm()───→│                        │                     │
 │  瞄准触发│                    │                        │                     │
 │          │←─MeasureSample─────│                        │                     │
 │          │   valueMm, source=laser, instrumentId       │                     │
 │          │────────────────────┼───────────────────────→│                     │
 │          │                    │     SetOpeningWidth /  │                     │
 │          │                    │     SetEdgeLength      │                     │
 │          │                    │     + measurement      │────────────────────→│
 │          │                    │     source=laser       │  不变量+约束         │
 │          │                    │                        │  OpeningUpdated      │
 │          │←──UI 显示来源徽章「laser」────────────────────┤                     │
 │          │                    │                        │                     │
 │ 若断连   │                    │                        │                     │
 │          │──降级 typed 键盘───┤                        │ source=typed       │
 │          │                    │                        │────────────────────→│
 │          │                    │                        │                     │
 ※ 深度点选草测若与 laser 冲突: UI 以 laser 为准并记冲突; 不得覆盖 laser 字段
```

### 4.3 序列 C：编译导出 glTF → Godot

```
User     Shell      FloorPlan      GeometryPort/Adapter      Deliverables      Godot
 │         │            │                   │                     │              │
 │ Export  │            │                   │                     │              │
 │────────→│ ExportRequested                │                     │              │
 │         │────────────┼───────────────────┼────────────────────→│              │
 │         │            │    ensureBuilt    │                     │              │
 │         │            │ buildRequest from │                     │              │
 │         │            │ SceneIR dirty     │                     │              │
 │         │            │──────────────────→│                     │              │
 │         │            │                   │ CrossSection        │              │
 │         │            │                   │ →Extrude→Boolean    │              │
 │         │            │                   │ →MeshProjection     │              │
 │         │            │←──RebuildResult───│                     │              │
 │         │            │                   │                     │              │
 │         │            │              status?                    │              │
 │         │            │                   │          gate       │              │
 │         │            │                   │      ┌──Fault?──ExportRejected     │
 │         │←──Notify───┼───────────────────┼──────┤  (高亮 entityIds)           │
 │         │            │                   │      └──NoError──写 .glb/.gltf     │
 │         │            │                   │         节点 Storey_/Wall_/Room_   │
 │         │            │                   │         extras.toporoomId          │
 │         │            │                   │         mm→m                       │
 │         │←──ExportCompleted (path)───────┼─────────────────────┤              │
 │ 打开glb │            │                   │                     │   load       │
 │─────────┼────────────┼───────────────────┼─────────────────────┼─────────────→│
 │         │            │                   │                     │  只读漫游     │
 │         │            │                   │                     │  无写回       │
```

---

## 5. 集成关系 ASCII（端口/适配器）

```
                    ┌──────────── Domain / Application ────────────┐
                    │                                              │
  DepthStreamPort   │   LaserRangefinderPort   ImuPort             │
        ▲           │           ▲                 ▲                │
        │           │           │                 │                │
        │           │    GeometryPort             │                │
        │           │         ▲                   │                │
        │           │         │                   │                │
────────┼───────────┼─────────┼───────────────────┼────────────────┼──
        │           │         │                   │   Hexagon      │
────────┼───────────┼─────────┼───────────────────┼────────────────┼──
        │           │         │                   │                │
 ┌──────┴──────┐ ┌──┴───┐ ┌───┴────────────┐ ┌───┴─────┐          │
 │VendorSdk    │ │BtLaser│ │ManifoldWasm   │ │PhoneImu │          │
 │DepthAdapter │ │Adapter│ │Adapter        │ │Adapter  │          │
 ├─────────────┤ ├───────┤ ├───────────────┤ └─────────┘          │
 │UvcDepth     │ │Typed  │ │ManifoldNative │                      │
 │Adapter      │ │Adapter│ │Adapter        │                      │
 └─────────────┘ └───────┘ └───────────────┘                      │
                                                                  │
 DocumentStorePort ← IndexedDbAdapter / FileAdapter               │
 GodotExportPort   ← GlbFile + 外部 Godot 进程（Conformist）       │
 NotifyPort        ← UI Toast / FaultHighlighter                  │
```

**规则**：Domain 包禁止 import 厂商 SDK / manifold；CI 门禁（NFR-015）。

---

## 6. 部署关系 ASCII

```
┌─────────────────────── PhoneHost (Android 白名单) ───────────────────────┐
│  TopoRoom App                                                            │
│   ┌─────────────┐  ┌──────────────┐  ┌────────────┐  ┌───────────────┐ │
│   │ UI + Shell  │  │ Capture*     │  │ FloorPlan  │  │ WASM Worker   │ │
│   │             │  │ Sessions     │  │ Document   │  │ ManifoldWasm  │ │
│   └─────────────┘  └──────────────┘  └────────────┘  └───────────────┘ │
│         │ USB Host              │ BT                  │ local files     │
└─────────┼───────────────────────┼─────────────────────┼─────────────────┘
          │                       │                     │
          v                       v                     │
   ┌──────────────┐       ┌──────────────┐              │
   │ Type-C Depth │       │ Bluetooth    │              │
   │ Module       │       │ Laser Meter  │              │
   │ (+Power Hub?)│       └──────────────┘              │
   └──────────────┘                                     │
                                                        │
              ┌─────────────────────────────────────────┘
              │ .glb / SceneIR / DXF
              v
┌─────────────────────┐     optional      ┌──────────────────────────┐
│ Godot 4 (只读)      │◄──────────────────│ Desktop Compiler         │
│ 加载 .glb 漫游检查  │   same .glb       │ Native Manifold + CI     │
└─────────────────────┘                   │ 大户型 ensureBuilt       │
                                          └──────────────────────────┘

P0 无云依赖；P1 可选 ProjectCollab 云端
```

---

## 7. 数据流分层 SceneIR→MeshGL→glTF ASCII

```
 L1  SceneIR / FloorPlanDocument          ←── 唯一可编辑真相
      │  measurements.source
      │  walls / openings / rooms / storeys
      │
      │  GeometryRebuildPolicy / BuildRequest
      v
     GeometryPort.rebuild / ensureBuilt
      │
      │  [ACL 边界]
      v
 L3  MeshGL (Adapter 内) ──→ MeshProjection (跨边界 DTO + nodeHints)
      │  cache: hash(SceneIR + compileOptions)
      │
      │  GlbExporter / 场景装配
      v
 L4  glTF 2.0 (.glb)                      ←── Published Language (引擎)
      │  Storey_ / Wall_ / Room_ / Opening_
      │  extras.toporoomId ; mm→m
      v
     Godot 4 只读

旁路（非主链）:
 L2  Sparse EvidencePack  ··· 可删，弱引用
 L5  点云 / 3DGS / 视频   ··· VisualizationDerivative；禁止写回 L1 尺寸

DXF/PDF ←── 主要读 L1 语义（不依赖三角网）；结构固体 glTF 必须 L3 NoError
```

---

## 8. 组件清单与依赖方向

| 组件 | 层 | 依赖（只允许向下/向内） |
|------|----|------------------------|
| GuidedCaptureUI 等 | Presentation | InteractionShell |
| InteractionShell | Application | FloorPlan App, CaptureSession App, Deliverables, Visualization, Ports |
| CaptureSession App | Application | CaptureDevice Ports, FloorPlan Commands, Observation |
| FloorPlan App/Domain | Application/Domain | GeometryPort（接口）, DocumentStorePort |
| GeometryKernel Port | Domain 契约 | （实现在 Infra） |
| Manifold*Adapter | Infrastructure | manifold-3d / native lib |
| Depth/Laser/Imu Adapters | Infrastructure | 厂商 SDK / UVC / BT |
| Exporters | Infrastructure | MeshProjection + SceneIR 快照 |
| GodotRuntimeAdapter | Infrastructure | 文件系统 .glb |

**禁止依赖**：Domain → manifold；Domain → Godot；CaptureSession → MeshGL；VisualizationDerivative → 写 FloorPlan 尺寸字段。

---

## 9. 端口契约摘要

### 9.1 GeometryPort

```text
rebuild(request: BuildRequest) -> RebuildResult
ensureBuilt(documentRev, solidScope?) -> RebuildResult
status(solidId | storeyId) -> GeometryStatus
clearCache(keys?)

BuildRequest: documentRev, rebuildGeneration, dirty, semantics(FloorPlanSolidSemantics)
RebuildResult: ok+meshes[] | fault(GeometryFault)
FaultCode: NotManifold | InvalidGeometry | TooComplex | Cancelled | Timeout
            | NotClosed | OpeningOutOfBounds
```

P0 流水线：`CrossSection → Extrude → Boolean(Subtract)`；软装不进。

### 9.2 LaserRangefinderPort

```text
discover() -> List<LaserDeviceProfile>
connect(deviceId) -> Handle
readLengthMm() -> MeasureSample
  # valueMm, timestamp, source=laser, instrumentId, rawRssi?(诊断非尺寸)
disconnect()
```

Typed 适配器实现同一 Port，强制 `source=typed`。

### 9.3 DepthStreamPort

```text
discover() -> List<AccessoryProfile>
open(deviceId, options) -> StreamHandle
readFrame(timeout) -> DepthFrameDTO | (DepthFrameDTO, ColorFrameDTO?)
getIntrinsics() -> CameraIntrinsics
getExtrinsicsToImu()? -> Extrinsics
getFirmwareVersion() -> string
close()
```

实现：`VendorSdkAdapter`（主）、`UvcAdapter`（辅）。AccessoryProfile 含 VID/PID、原理标签、供电提示。

### 9.4 ImuPort（摘要）

```text
readSample() -> ImuSampleDTO   # acc + gyro + timestamp
# 可选 subscribe(hz)
```

---

## 10. gotbot 模式映射、manifold ACL

### 10.1 gotbot → InteractionShell

| gotbot | TopoRoom |
|--------|----------|
| CommandHandler / ToolHandler | ToolRegistry + Tool |
| commandContext | ParamGatheringFSM |
| ReplySender | NotifyPort / UI Ports |
| ChatProcessor / Fallback | 工具路由 + 引导 Tool |
| chats map | **SessionIsolate（每 documentId 串行队列）** |

不移植：Telegram 运行时、无锁并行写。

### 10.2 manifold ACL

```
Storey / SceneIR  ──BuildRequest DTO──→  GeometryPort
                                            │
                                            ▼
                                     ManifoldAdapter
                                     (唯一可 import manifold)
                                            │
                                            ▼
                                     MeshProjection DTO
```

CI：`domain-*` 不得出现 `from 'manifold-3d'` / `#include <manifold.h>`。

---

## 11. 与硬件的集成点

| 集成点 | 软件侧 | 硬件侧 | 验收注意 |
|--------|--------|--------|----------|
| 深度出流 | DepthStreamPort | Type-C 模组 | 白名单+Hub；热插拔错误码 |
| 激光尺寸 | LaserRangefinderPort | 蓝牙激光仪 | source=laser；禁射频主测 |
| 水平对齐 | ImuPort | 模组/手机 IMU | 降级须提示 |
| 固件/SKU meta | AccessoryProfile → Document meta | 模组固件 | ReleaseTrain 绑定 |
| 证据稀疏块 | ObservationStore | 深度降采样 | 可删 |
| 导出检查 | .glb | — | Godot 只读；非硬件 |

---

## 12. P0 实现包结构建议

```text
packages/
  domain-floorplan/          # FloorPlanDocument, Storey, events, VO(LengthMm…)
  domain-capture/            # CaptureSession AR（无网格）
  app-interaction-shell/     # Tools, FSM, SessionIsolate
  app-capture/               # CaptureSessionApplicationService
  app-floorplan/             # commands handlers, RebuildPolicy
  app-deliverables/          # ExportAppService, StatusGate
  ports/                     # GeometryPort, DepthStreamPort, LaserRangefinderPort,
                             # ImuPort, DocumentStorePort, NotifyPort  (interfaces only)
  adapter-manifold-wasm/
  adapter-manifold-native/
  adapter-depth-vendorsdk/
  adapter-depth-uvc/
  adapter-laser-bt/
  adapter-imu-phone/
  adapter-store-indexeddb/
  adapter-export-gltf/
  adapter-export-dxf/
  app-visualization/         # 瘦预览
  fixtures-sceneir/          # SceneIR 0.1 JSON → glb 金样
  mobile-android/            # UI + 白名单检测 + USB/BT 权限
tools/
  desktop-compiler/          # Native ensureBuilt / CI
docs/
  architecture/              # 以本 FINAL 为准；旧 DDD 文标 superseded
```

**测试金字塔要点**：SceneIR 夹具合同测试；GeometryPort mock；无真机深度回放；Godot 层级断言（Storey_/Wall_/Room_）；domain 包 import 禁令 CI。

---

## 13. 事件编目（P0 摘要）

| 事件 | 生产者 | 消费者 |
|------|--------|--------|
| AccessoryConnected/Lost | CaptureDevice | CaptureSession, UI |
| CalibrationAccepted | CaptureSession | Session 状态 |
| WallAdded / OpeningAdded / RoomClosed / StoreyHeightChanged | FloorPlan | RebuildPolicy, Store, UI |
| FloorPlanSemanticsChanged | FloorPlan | GeometryRebuildPolicy |
| EvidenceAppended | ObservationStore | 质检/P1 拟合 |
| GeometryRebuildSucceeded/Failed | Geometry 包装 | Visualization, Export 闸门 |
| ExportCompleted / ExportRejected | Deliverables | UI |

---

## 14. 反模式（实施红线）

Mesh 进聚合；Manifold 进 Storey；gotbot 当 CAD；无锁并发写文档；GS/点云写回尺寸；点云当主文件；Godot Node 当领域模型；Capture/FloorPlan 双 Document；深度视频进聚合；导出忽略 Status；射频 BLE 当尺子；P0 塞满 MEP/软装/云/报价。

---

## 15. 开放问题（架构侧未决）

与需求文档 §11 对齐：模组 SKU、白名单名单、Fault 时语义 DXF 策略、WASM vs 桌面默认阈值、激光协议清单、P1 云冲突、服务端布尔配额、EXT_mesh_manifold。

---

*文档结束。图示均为 ASCII；实现以 Port 契约与 SceneIR 0.1 冻结稿为准。*
