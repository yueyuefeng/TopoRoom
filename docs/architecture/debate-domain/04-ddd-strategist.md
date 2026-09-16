# 专家意见 04 — DDD 战略设计（行业语言再 enrichment）

> **角色**：DDD 战略设计师  
> **日期**：2026-09-16（Asia/Shanghai）  
> **输入**：专家 01–03、UL、FINAL 架构 BC 图、toporoom-ddd-architecture、semantic-3d-capture-ddd  
> **原则**：细化既有 TopoRoom BC，不推倒重来；行业话术进 Domain，技术内核留 ACL。

---

## 1. 战略立场

- **核心域**不变：户型语义建模（FloorPlanModeling）≡ SceneIR 真相。  
- **量房**是写入核心域的手段（CaptureSession 支撑域），不是第二真相。  
- BC **英文代号可保留**（包名稳定）；对外/文档别名用行业词（户型建模、量房会话、出图交付…）。  
- P0 实现边界与 FINAL 瘦 P0 对齐；P1 BC 战略保留。

---

## 2. Bounded Contexts — 行业化命名与精炼

| BC 代号（稳定） | 行业别名（文档/对内沟通） | 核心/支撑 | P0 | 精炼说明 |
|-----------------|---------------------------|-----------|-----|----------|
| **FloorPlanModeling** | **户型建模** / 方案语义 | 核心 | 是 | Document=方案/户型文档；Opening 细分门窗垭口；层高≠净高 |
| **CaptureSession** | **量房会话** | 支撑 | 是 | 对外「本次量房」；产出 Command→户型建模 |
| **CaptureDevice** | **采集配件** | 支撑 | 是 | 深度/激光/IMU 端口入口；无业务户型语言 |
| **ObservationStore** | **观测证据** | 支撑 | 可空 | Evidence 非真相 |
| **GeometryKernel** | **几何编译（ACL）** | 通用+ACL | 是 | 无业务 AR；禁污染 Domain |
| **Deliverables** | **出图交付** | 支撑 | 是 | 户型图 DXF/PDF + 浏览用 glb |
| **Visualization** | **视图预览** | 支撑 | 瘦 P0 | 只读快照；写回经 Shell |
| **InteractionShell** | **交互编排** | 应用外壳 | 是 | Tool/FSM；非 Domain 实体 |
| Furnishing | 软装布置 | 支撑 | P1 | 平面布置图能力所在 |
| MEP | 水电管综 | 支撑 | P1 | UI「水电」 |
| TakeoffQuote | 算量报价 | 支撑 | P1 | |
| ProjectCollab | 项目协作 | 支撑 | P1 | 项目≠方案 |
| VisualizationDerivative | 衍生可视化 | 可选 | P1 | 禁写回尺寸 |

**合并确认（继承 FINAL）**

- SemanticScene ≡ FloorPlanModeling  
- ReconstructionCompiler 几何侧 → GeometryKernel；装配导出 → Deliverables  
- Godot → 适配器，非 BC  

---

## 3. Context Map（ASCII）

```
                    <<应用外壳>>
                 InteractionShell
                  交互编排 / Tools
                         |
        Command/Intent   |   Partnership
     +---------+---------+----------+
     v         v         v          v
CaptureDevice 量房会话  户型建模<<CORE>>  视图预览
采集配件----->Capture  FloorPlanModeling  Visualization
   OHS         Session       |               ^
               |             | PL SceneIR    | Snapshot/Mesh
               |             v               |
               |      GeometryKernel --------+
               |      几何编译 ACL→manifold
               v             |
         ObservationStore    v
         观测证据(可空)   Deliverables 出图交付
                              |  glTF PL
                              +----→ [Godot 只读宿主]

P1 虚线:
  户型 --OHS--> 软装Furnishing / 水电MEP
  事件 --> 算量TakeoffQuote
  项目ProjectCollab <-> 户型 Partnership
```

**关系类型（行业解读）**

| 上游 → 下游 | 类型 | 含义 |
|-------------|------|------|
| 量房会话 → 户型建模 | Customer-Supplier | 量房命令写方案语义 |
| 户型 → 几何编译 | Customer-Supplier | 户型定 GeometryPort 契约 |
| 几何 → manifold | **ACL** | 防腐；Domain 无 Manifold 类型 |
| 户型 → 出图 | Customer-Supplier | 语义图层 + Status 闸门 |
| 出图 → Godot | Published Language | glTF；Conformist 只读 |
| 户型 → 软装/MEP | OHS | 宿主 ID 语言 |
| 衍生可视化 → 户型 | Conformist | 禁写回尺寸 |

---

## 4. Aggregate 候选（P0 聚焦）

### 4.1 户型建模 FloorPlanModeling

| AR / 对象 | 行业名 | 职责 |
|-----------|--------|------|
| **FloorPlanDocument** | 方案 / 户型文档 | 单位、snap、版本、多楼层协调、faceDatum |
| **Storey** | 楼层 | **主编辑一致性边界**：墙/洞/房/构件 |
| Wall | 墙段 | 中线+厚高+WallKind |
| Opening | 洞口（门/窗/垭口） | Kind 强制；净宽高等 |
| Room | 房间 | 闭合环+名称+SpaceType+可选净高 |
| HostedComponent | 梁/柱/烟道… | kind 具体化 |
| VO | LengthMm, WallKind, SpaceType, OpeningKind, MeasureSource, FaceDatum, ClearHeight… | |
| Domain Services | RoomClosure、OpeningPlacement、WallJoin、OrthoEdgeConstraint | |
| Factory | StoreyFactory.copy（P1 多层） | |

### 4.2 量房会话 CaptureSession

| AR | 行业名 | 职责 |
|----|--------|------|
| **CaptureSession** | 量房会话 | 状态机、GuidedStep、Calibration、TrajectoryLite、evidenceId；**不持网格** |

### 4.3 其他 P0

| BC | AR / 工作单元 | 备注 |
|----|---------------|------|
| CaptureDevice | AccessoryProfile（偏配置） | 支撑 |
| ObservationStore | EvidencePack | 可空 |
| Deliverables | ExportJob | Status 闸门 |
| GeometryKernel | 无业务 AR；RebuildJob 应用/基建 | ACL |
| InteractionShell | EditorSession（应用态） | 非 Domain 包 |

### 4.4 P1 Aggregates（战略保留）

FurnishingLayout、MEPModel、QuantityTakeoff/Quote、Project…

---

## 5. Domain Events（行业过去式 + 代码名）

| 代码事件 | 行业表述 | 生产者 |
|----------|----------|--------|
| `WallAdded` / `WallGeometryChanged` / `WallRemoved` | 墙已添加/几何已改/已删除 | 户型 |
| `OpeningAdded` / `OpeningChanged` / `OpeningRemoved` | 门洞/窗洞/垭口已…（payload.kind） | 户型 |
| `RoomClosed` / `RoomOpened` / `RoomAttributesChanged` | 房间已闭合/已拆环/属性已改 | 户型 |
| `StoreyHeightChanged` | 层高已变更 | 户型 |
| `HostedComponentPlaced` | 梁/柱/烟道已放置 | 户型 |
| `FloorPlanSemanticsChanged` | 户型语义已变更（粗） | 户型 |
| `CriticalDimensionConfirmed` | 关键尺寸已确认 | 户型/量房应用 |
| `CalibrationAccepted` | 校准确认 | 量房 |
| `SurveySessionCompleted` | 量房采集完成 | 量房 |
| `GeometryRebuildSucceeded/Failed` | 三维重建成功/失败 | 几何包装 |
| `ExportCompleted` / `ExportRejected` | 出图完成/拒绝 | 出图 |

---

## 6. 防腐层（Anti-Corruption）重点

### 6.1 几何 ACL（GeometryKernel）

| Domain 可见 | Adapter 内部 | 禁入 Domain |
|-------------|--------------|-------------|
| `GeometryPort`、`Section2D`、`Solid3D` DTO、`GeometryFault`、`MeshProjection` | Manifold、CrossSection 原生、MeshGL 缓存 | 聚合字段出现 Manifold/MeshGL |
| 业务语言：挖门洞、生成墙体三维、局部更新 | Boolean/Extrude/DirtyRegion | 用户话术直接说 Boolean |

### 6.2 导出 ACL（Deliverables）

| 业务 | 技术 |
|------|------|
| 户型图 / PDF 平面 / 三维浏览件 | DXF / PDF / glTF 字节 |
| 导出闸门（结构未校验通过） | Status≠OK 拒固体 |
| Godot 漫游检查 | 外部进程加载 glb；**不写回** |

### 6.3 设备 ACL（CaptureDevice）

MeasureSample / 深度帧 DTO ← 端口；BLE/UVC/厂商 SDK 细节不出 Domain。

---

## 7. 冲突合成决议（本专家拍板建议）

| ID | 议题 | 决议 |
|----|------|------|
| D1 | Opening 模型 | **Opening + OpeningKind{door,window,archway}**；工厂 Door/Window/ArchwaySpec；UI 强制三选 |
| D2 | 层高/净高 | `Storey.height`=层高；`Room.clearHeightMm?` additive；禁 UI 混用 |
| D3 | Document 命名 | 代码 `FloorPlanDocument`；UL/UI「方案/户型文档」；SceneIR 仍为序列化形态 |
| D4 | 梁柱烟道 P0 | **模型有、验收不阻断**；夹具可无梁 |
| D5 | 净宽含义 | P0 `Opening.width`=净宽意图；日后结构洞宽另字段 |
| D6 | 量房 vs Survey 实体 | **不**另建 Survey 持久 AR；CaptureSession=量房会话；业务词 Survey 作话术 |
| D7 | 户型图/布置图 | P0 交付=户型图；布置图随 Furnishing P1 |
| D8 | SceneIR 0.2 | **仅 additive**：archway、clearHeight、faceDatum、measurements 强化；0.1 可读 |

---

## 8. 包归属建议（Domain only）

```
domain-floorplan/   # 户型建模：Document, Storey, Wall, Opening, Room, events, VOs
domain-capture/     # 量房会话 AR（无网格、无 Manifold）
（P1）domain-furnishing / domain-mep / domain-takeoff …
ports/              # 接口；非 Domain 模型
adapter-*           # 全部在外
```

CI：`domain-*` 禁止 import manifold / godot / 蓝牙栈。

---

*专家 04 完 · FINAL 合成以此决议为主*
