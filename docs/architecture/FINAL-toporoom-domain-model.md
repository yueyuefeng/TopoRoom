# 拓间 TopoRoom — FINAL 领域模型（Domain 层）

> **状态**：FINAL（多专家合成）  
> **日期**：2026-09-16（Asia/Shanghai）  
> **UL 真源**：`toporoom-industry-ubiquitous-language.md`  
> **需求/架构对齐**：`FINAL-toporoom-hw-sw-requirements.md`、`FINAL-toporoom-software-architecture.md`  
> **专家输入**：`debate-domain/01`…`04`  
> **原则**：中文行业词为主；代码标识保留英文 CamelCase + 中文 gloss；瘦 P0；细化既有模型非推倒重来。

---

## 0. 合成决议一览（冲突已裁决）

| ID | 议题 | 最终决议 |
|----|------|----------|
| D1 | Opening | **`Opening` + 必填 `OpeningKind ∈ {door, window, archway}`**；UI 称门洞/窗洞/垭口；工厂 Spec 可细分 |
| D2 | 层高 vs 净高 | **`Storey.height` = 层高**；**`Room.clearHeightMm?` = 净高**（additive）；禁混用 |
| D3 | Document 名 | 代码 `FloorPlanDocument`；对外 **方案 / 户型文档**；SceneIR = 序列化 Published Language |
| D4 | 梁柱烟道 | Domain **有** HostedKind；**不阻断** P0 验收 |
| D5 | Opening.width | P0 = **净宽意图**（门洞净宽/窗宽） |
| D6 | Survey | 无独立持久 Survey AR；**CaptureSession = 量房会话** |
| D7 | 图种 | P0 导出 = **户型图**；平面布置图 → P1 软装 |
| D8 | SceneIR | **0.2 additive**，0.1 可读升级 |
| D9 | 面层口径 | P0 `faceDatum` 文档/会话级；墙饰面厚拆分 P1 |
| D10 | 墙高联动 | 改层高默认跟随墙高，允许单墙覆写 |

---

## 1. Ubiquitous Language 子集（Domain P0）

> 仅列 **应进入 Domain 层** 的 P0 词；完整行业表见 UL。Adapter/会话词见 §6。

### 1.1 方案与楼层

| 中文 | 代码 | 定义要点 |
|------|------|----------|
| 方案 / 户型文档 | `FloorPlanDocument` | 可编辑真相；单位 mm |
| 户型 | （文档内语义） | 墙房洞层分隔；≠ 平面布置图 |
| 楼层 | `Storey` | 同标高墙/房/洞集合 |
| 层高 | `StoreyHeight` / `Storey.height` | 结构面→上层结构面 |
| 室内净高 | `ClearHeight` / `Room.clearHeightMm` | 完成地→顶；可空 |
| 标高 | `elevation` | 相对 ±0.000 |
| 房间 | `Room` | 闭合墙环 + 名称 |
| 空间类型 | `SpaceType` | interior / balcony / … |
| 现状 / 原始户型 | As-built 话术 / meta | 量房默认写入 |

### 1.2 墙与构件

| 中文 | 代码 |
|------|------|
| 墙 / 墙段 | `Wall` |
| 墙中线 | centerline |
| 墙厚 / 墙高 | thickness / height |
| 墙属性 | `WallKind`（masonry / shearWall / partition / …） |
| 梁 / 柱 / 烟道 | `HostedComponent.kind` = beam / column / flue |
| 打断墙 | `WallSplit`（服务动作） |

### 1.3 洞口（必须细分）

| 中文 | 代码 |
|------|------|
| 洞口（基类） | `Opening` |
| 门洞 | `OpeningKind.door` |
| 窗洞 | `OpeningKind.window` |
| 垭口 | `OpeningKind.archway` |
| 门洞净宽 / 净高 | width / height（door） |
| 窗台高 | `sill` |

### 1.4 尺寸

| 中文 | 代码 |
|------|------|
| 尺寸来源 | `MeasureSource`：laser / typed / depth_fit |
| 关键尺寸 | 门洞净宽、约定轴长、层高 |
| 面层口径 | `FaceDatum`：structural / architectural / finished |
| 正交/边长约束 | Ortho + EdgeLength（P0） |

### 1.5 量房（Domain 可感知部分）

| 中文 | 代码 | 注 |
|------|------|-----|
| 量房会话 | `CaptureSession` | 在 domain-capture；非几何真相 |
| 引导步骤 | `GuidedStep` | 会话内 |
| 量测样本 | `MeasureSample` | 经端口入；确认后写语义+source |

### 1.6 交付（业务闸门语言）

| 中文 | 代码 |
|------|------|
| 交付物 / 出图 | `Deliverable` / `ExportJob` |
| 户型平面 / CAD / PDF / 三维浏览件 | DXF/PDF/glb 产物类型 |

**UI 来源话术（强制）**：激光实测 / 手工录入 / 深度辅助拟合。

---

## 2. Bounded Contexts（ASCII）

```
                         ┌──────────────────────┐
                         │  InteractionShell    │
                         │  交互编排 (Application)│
                         └──────────┬───────────┘
              Command/Intent        │
         ┌────────────┬─────────────┼──────────────┐
         v            v             v              v
 ┌───────────────┐ ┌─────────┐ ┌──────────┐  ┌─────────────┐
 │ CaptureDevice │ │ 量房会话 │ │ 户型建模 │  │ 视图预览    │
 │ 采集配件      │→│ Capture │→│FloorPlan │←→│Visualization│
 │   <<OHS>>     │ │ Session │ │ <<CORE>> │  └──────▲──────┘
 └───────────────┘ └────┬────┘ └────┬─────┘         │
                        │           │ PL 方案/SceneIR│
                        v           v               │
               ┌────────────────┐ ┌──────────────┐  │
               │ Observation    │ │ GeometryKernel│──┘
               │ 观测证据(可空) │ │ 几何ACL→mfld │
               └────────────────┘ └──────┬───────┘
                                         v
                                  ┌──────────────┐   glTF PL
                                  │ Deliverables │────────→ [Godot 只读]
                                  │ 出图交付     │
                                  └──────────────┘

P1+：Furnishing 软装 | MEP 水电管综 | TakeoffQuote 算量 | ProjectCollab 项目
     VisualizationDerivative（禁写回尺寸）
```

| BC | 行业别名 | P0 |
|----|----------|-----|
| FloorPlanModeling | 户型建模 | 核心 |
| CaptureSession | 量房会话 | 是 |
| CaptureDevice | 采集配件 | 是 |
| ObservationStore | 观测证据 | 可空 |
| GeometryKernel | 几何编译 ACL | 是 |
| Deliverables | 出图交付 | 是 |
| Visualization | 视图预览 | 瘦 |
| InteractionShell | 交互编排 | 应用 |

---

## 3. Aggregates / Entities / VOs / Domain Services / Events

### 3.1 户型建模（domain-floorplan）

#### Aggregate Roots

| AR | Gloss | 边界 |
|----|-------|------|
| `FloorPlanDocument` | 方案 / 户型文档 | 单位、snapMm、version、format、storeys、faceDatum?、meta |
| `Storey` | 楼层 | **主编辑 AR**：Wall / Opening / Room / HostedComponent 同事务 |

#### Entities

| Entity | Gloss | 关键属性 |
|--------|-------|-----------|
| `Wall` | 墙段 | id, centerline, thickness, height, WallKind |
| `Opening` | 洞口 | id, hostWallId, **OpeningKind**, width, height, sill, offset, measureSources? |
| `Room` | 房间 | id, name, SpaceType, boundaryWallIds, clearHeightMm?, areaCache? |
| `HostedComponent` | 梁柱烟道等 | id, kind(beam\|column\|flue\|…), params |

#### Value Objects（P0）

`LengthMm`、`WallKind`、`SpaceType`、`OpeningKind`、`MeasureSource`、`FaceDatum`、`Polyline2D`、`Point2D`、`ClearHeight`（可选包装）

#### Domain Services

| Service | Gloss |
|---------|-------|
| `RoomClosureService` | 成房 / 闭合检测 |
| `OpeningPlacementService` | 洞口边距/门垛/越界校验 |
| `WallJoinService` | 共墙、打断 |
| `OrthoEdgeConstraintService` | P0 正交+边长约束 |

#### Domain Events（户型）

`WallAdded` / `WallGeometryChanged` / `WallRemoved`  
`OpeningAdded` / `OpeningChanged` / `OpeningRemoved`（**含 kind**）  
`RoomClosed` / `RoomOpened` / `RoomAttributesChanged`  
`StoreyHeightChanged`  
`HostedComponentPlaced` / `HostedComponentRemoved`  
`FloorPlanSemanticsChanged`  
`CriticalDimensionConfirmed`（可选）

### 3.2 量房会话（domain-capture）

| 类型 | 名称 | Gloss |
|------|------|-------|
| AR | `CaptureSession` | 量房会话 |
| VO/态 | `GuidedStep`, `CalibrationState`, `TrajectoryLite` | 引导步、校准、轻轨迹 |
| 引用 | `documentId`, `evidencePackId?`, `accessoryRefs` | |

**不变量**：不持深度视频/网格/Manifold；完成≠几何 OK。

事件：`CalibrationAccepted`、`SurveySessionStarted`/`Completed`（可与现有 Capture* 事件双名）。

### 3.3 出图 / 几何（业务侧可见，非几何库类型）

| 对象 | 归属 | 说明 |
|------|------|------|
| `ExportJob` | Deliverables | 格式、图层、闸门结果 |
| `GeometryFault` / Status | 经 Port 回传 | 拒固体导出 |

---

## 4. 不变量（Domain）

| # | 不变量 |
|---|--------|
| I1 | **FloorPlanDocument / SceneIR 唯一可编辑真相**；Mesh/点云/glTF/Godot Node 非真相 |
| I2 | 聚合内 **无** Manifold / CrossSection / MeshGL / Godot 类型 |
| I3 | `Opening.kind` 必填；UI 禁用裸 Opening |
| I4 | `Storey.height` 语义 = **层高**；不得当净高展示 |
| I5 | 关键尺寸 source∈{laser,typed} 优先；`depth_fit` 不得静默覆盖 laser |
| I6 | Room 未闭合不计面积、不作为「完整房间体」充分条件 |
| I7 | Opening 从属于 Wall；删墙级联洞口；环失效处理明确 |
| I8 | 单位 mm；Document 级冻结 |
| I9 | 每 documentId 写命令串行（应用层保障，领域假定单线程一致性） |
| I10 | 结构固体导出须几何 Status OK；Fault 可达用户 |
| I11 | CaptureSession 不持久第二套户型 Document |
| I12 | 垭口 kind=archway，禁止用「door 无扇」偷偷表示 |

---

## 5. 映射：旧代码名 → 行业名

| 旧 / 技术名 | 行业名（UI/文档） | Domain 处理 |
|-------------|-------------------|-------------|
| `FloorPlanDocument` | 方案 / 户型文档 | 类名保留 |
| `SceneIR` | 户型语义方案（对内 SceneIR） | 序列化形态 |
| `Storey` | 楼层 | 保留；文案楼层 |
| `Storey.height` | **层高** | 注释+UI |
| （缺失）净高 | **室内净高** | 增 `clearHeightMm?` |
| `Opening` 统称 | 门洞/窗洞/垭口 | **OpeningKind** |
| `Opening.type=door\|window` | 门洞/窗洞 | 增 `archway` |
| `Opening.width` | 门洞净宽 / 窗宽 | 文档定义=净宽意图 |
| `Opening.sill` | 窗台高 | 保留 |
| `HostedComponent` | 梁/柱/烟道… | kind 枚举；UI 具体名 |
| `CaptureSession` | 量房会话 / 本次量房 | 类名保留 |
| `MeasureSource.laser` | 激光实测 | UI 映射 |
| `typed` | 手工录入 | |
| `depth_fit` | 深度辅助拟合 | |
| `FloorPlan` 混用 | 户型 vs 平面布置 | 文案拆分 |
| `Floor` 歧义 | 楼层用 Storey；地面 FloorSurface | 禁混 |
| `Space` 无类型 | 空间 + SpaceType/名称 | 强制 |
| `MEP` | 水电管综（P1） | BC 名可留 |
| `Takeoff` | 算量（P1） | |
| `TraceOverlay` | 临摹底图（P1） | |
| Mesh / Boolean / Extrude | 改墙改洞 / 挖门洞 / 生成墙体三维 | 仅 Adapter 话术 |

---

## 6. 明确留在 Domain 之外

| 类别 | 示例 | 去向 |
|------|------|------|
| 几何库 | Manifold, CrossSection, MeshGL, GeometryCache | GeometryKernel ACL / Infra |
| 引擎 | Godot Node, 场景树 | 适配器；只读 glTF |
| 设备协议 | BLE 帧、UVC、Vendor SDK | CaptureDevice Adapters |
| 证据大对象 | 深度视频、点云、3DGS | ObservationStore / Out |
| 交互态 | ToolHandler, ParamGatheringFSM, 未提交草稿 | InteractionShell |
| P1 业务 | MEP 点位回路、软装实例、报价行、云 Project | 对应 P1 BC |
| 施工流程 | 放线、变更洽商、竣工验收 | Out |

---

## 7. SceneIR 0.2 建议（additive / 向后兼容）

> 目标：0.1 文件可读；新字段可选；读者忽略未知字段。

### 7.1 建议增补 / 澄清

| 路径 | 变更 | 兼容说明 |
|------|------|----------|
| `version` | 允许 `"0.2.0"`；读 0.1 当缺省 | 写新档可 0.2 |
| `storeys[].height` | **文档注释冻结=层高 mm** | 无改字段名 |
| `storeys[].rooms[].clearHeightMm` | **新增可选** 净高 | 缺省=未知 |
| `storeys[].walls[].openings[].type` | 枚举扩展 **`archway`** | 旧 door/window 不变 |
| `openings[].kind` | 可选别名=type | 或仅用 type，二选一写规范 |
| `meta.faceDatum` | `structural`\|`architectural`\|`finished` | 可选 |
| `meta.schemeLabel` / `documentLabel` | 方案显示名 | 可选 |
| `measurements[]` | 强化：`target`（storeyHeight\|openingWidth\|edge…）、`source`、`valueMm` | 0.1 有 source 则保留 |
| `hostedComponents[]` 或 wall/storey 下 | `kind`: beam\|column\|flue | 可选数组 |
| `walls[].kind` | 与 WallKind 对齐文案 | 已有则澄清 shearWall 等 |

### 7.2 不改（避免破坏）

- `units: "mm"`  
- `centerline` 墙中线表达  
- 主存仍语义 JSON；Evidence 外置  

### 7.3 示例片段（示意，非规范冻结稿）

```json
{
  "format": "toporoom.sceneir",
  "version": "0.2.0",
  "units": "mm",
  "meta": { "faceDatum": "structural", "schemeLabel": "现状量房-客厅" },
  "storeys": [{
    "id": "storey_1",
    "name": "1F",
    "elevation": 0,
    "height": 2800,
    "walls": [{
      "id": "wall_1",
      "kind": "masonry",
      "centerline": [[0,0],[4000,0]],
      "thickness": 200,
      "height": 2800,
      "openings": [
        { "id": "op_1", "type": "door", "offset": 800, "width": 900, "height": 2100, "sill": 0 },
        { "id": "op_2", "type": "archway", "offset": 2000, "width": 1200, "height": 2100, "sill": 0 },
        { "id": "op_3", "type": "window", "offset": 500, "width": 1500, "height": 1400, "sill": 900 }
      ]
    }],
    "rooms": [{
      "id": "room_living",
      "label": "客厅",
      "spaceType": "interior",
      "boundaryWallIds": ["wall_1","wall_2","wall_3","wall_4"],
      "clearHeightMm": 2650
    }],
    "hostedComponents": [
      { "id": "hc_beam_1", "kind": "beam", "params": { "zBottomMm": 2400, "depthMm": 400 } }
    ]
  }],
  "measurements": [
    { "id": "m1", "target": "storeyHeight", "storeyId": "storey_1", "valueMm": 2800, "source": "laser" },
    { "id": "m2", "target": "openingWidth", "openingId": "op_1", "valueMm": 900, "source": "laser" }
  ]
}
```

---

## 8. Domain 包 ASCII 草图（仅 Domain）

```
packages/
  domain-floorplan/
  ├── model/
  │   ├── FloorPlanDocument.php|ts   # 方案/户型文档 AR
  │   ├── Storey.ts                  # 楼层 AR
  │   ├── Wall.ts                    # 墙段
  │   ├── Opening.ts                 # 洞口 + OpeningKind
  │   ├── Room.ts                    # 房间 + clearHeight?
  │   ├── HostedComponent.ts         # 梁|柱|烟道…
  │   └── vo/
  │       ├── LengthMm.ts
  │       ├── WallKind.ts
  │       ├── OpeningKind.ts         # door|window|archway
  │       ├── SpaceType.ts
  │       ├── MeasureSource.ts       # laser|typed|depth_fit
  │       └── FaceDatum.ts
  ├── services/
  │   ├── RoomClosureService.ts
  │   ├── OpeningPlacementService.ts
  │   ├── WallJoinService.ts
  │   └── OrthoEdgeConstraintService.ts
  └── events/
      ├── WallEvents.ts
      ├── OpeningEvents.ts
      ├── RoomEvents.ts
      └── StoreyEvents.ts

  domain-capture/
  ├── model/
  │   └── CaptureSession.ts          # 量房会话 AR（无网格）
  ├── vo/
  │   ├── GuidedStep.ts
  │   └── MeasureSample.ts           # 或 ports DTO 确认后写入
  └── events/
      └── SurveySessionEvents.ts

  （禁止）domain-*  → manifold | godot | ble-stack
```

Application / Adapters / ports 包见 FINAL 软件架构 §12；**不属本文 Domain 展开**。

---

## 9. P0 / P1 / Out 落点（Domain 视角）

| 能力 | 分期 |
|------|------|
| 方案文档、单层、层高、直线墙、成房、矩形门/窗/垭口、改净宽、尺寸来源、正交边长约束 | **P0** |
| 梁柱烟道简化放置 | P0 模型有 / 验收不阻断 |
| 房间净高字段 | P0 additive |
| 面层口径 meta | P0 |
| 多层/临摹/立面精放 | P1 |
| 软装→平面布置图、水电、算量报价、云项目 | P1 |
| 真弧墙、完整约束求解、施工图册、GS 写回 | Out / 禁 |

---

## 10. 开放问题（未阻塞 FINAL Domain）

| # | 问题 | 倾向 |
|---|------|------|
| O1 | 改层高是否强制改所有墙高 | 默认跟随，允许覆写（D10） |
| O2 | Fault 时是否仍导出「仅语义线 DXF」 | 交产品书面确认（架构开放问题） |
| O3 | `Opening.kind` vs `type` 双字段 | SceneIR 规范择一主字段，另一弃用或 alias |
| O4 | 套内面积计口径 | P1；标注「口径待确认」 |
| O5 | 门扇/窗扇几何 | P1 Hosted fill |

---

## 11. 追溯

| 来源 | 采用 |
|------|------|
| 专家 01 产品 | P0 UI 必现词、验收对照、话术红线 |
| 专家 02 测绘 | 层高/净高、三来源、faceDatum、as-built |
| 专家 03 硬装 | OpeningKind、墙房层、梁柱烟道、户型图口径 |
| 专家 04 战略 | BC 别名、Context Map、聚合、ACL、D1–D8 决议 |
| FINAL 需求/架构 | 瘦 P0、SceneIR 真相、端口边界 |

---

*文档结束。实现以 Port 契约与 SceneIR 规范冻结稿为准；本稿为 Domain 层统一语言与战术模型。*
