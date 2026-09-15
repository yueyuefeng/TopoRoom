# 拓间（TopoRoom）最终软硬件需求规格

> **状态**：FINAL（Go-with-changes 合成）  
> **日期**：2026-09-15  
> **表决**：产品 / 硬件 / DDD / 几何·Godot 四专家均为 **Go-with-changes**  
> **冲突裁决优先级**：(1) SceneIR 唯一真相 (2) 瘦 P0 (3) 激光关键尺寸 (4) Godot 只读 (5) 禁止 GS/写回尺寸 (6) Android 白名单 + 外购 Type-C 深度  
> **关联**：`FINAL-toporoom-software-architecture.md`、`debate/*.md`、`architecture-optimization-review.md`

---

## 1. 文档信息 / 变更相对基线

### 1.1 文档信息

| 项 | 内容 |
|----|------|
| 产品名 | 拓间 TopoRoom |
| 文档类型 | 软硬件联合需求（验收口径） |
| 基线对照 | JoyPlan PRD（旅程/能力参考）+ 旧 `toporoom-ddd-architecture.md` §10 + `semantic-3d-capture-ddd.md` |
| 优化输入 | `architecture-optimization-review.md` O1–O10 |
| 语言 | 中文；类型/端口名保留英文 |

### 1.2 相对基线的 Go-with-changes（必须采纳）

| ID | 相对旧文的变更 | 来源 |
|----|----------------|------|
| Δ1 | **P0 砍薄**：MEP / 软装 / 云同步 / 自动报价 **移出 P0** | 产品 M1、DDD §1、O1 |
| Δ2 | **LaserRangefinderPort 升 P0**；射频 BLE 测距禁止作尺寸主测 | 产品 M2、硬件 §2.2、O2 |
| Δ3 | 补齐 **精度 SLA 四指标 + 话术红线**；禁止「全屋深度处处毫米」 | 产品 §4、硬件 §4、O3 |
| Δ4 | Capture 与 FloorPlan **统一 SceneIR 0.1**；一套 Undo/版本号 | 产品 M4、DDD O4 |
| Δ5 | 显式 **VisualizationDerivative**（可选）；**禁止写回尺寸** | 产品 M5、DDD、O5 |
| Δ6 | **DepthStreamPort 双适配**（VendorSdk 主 / UVC 辅）；**Android 白名单**；iOS 不进首发 | 产品 M6、硬件 O6 |
| Δ7 | **Godot = 只读** glTF 宿主；TopoRoom = 编辑真相 | 产品 M7、几何 O7 |
| Δ8 | **ReleaseTrain + PoC→EVT→DVT→PVT**；PoC 不过门不开模 | 产品 M8、硬件 §5、O8 |
| Δ9 | P0 约束：**正交 + 边长 + 层高**；弧墙 **折线逼近** | 产品 D8、几何、O9 |
| Δ10 | 产品定位收窄为「可靠户型捕获 + 可编辑语义 + 专业导出」；不做自研 TR / LiDAR 一体机 | 产品 M9、O10 |
| Δ11 | SceneIR `measurements[].source ∈ {laser, typed, depth_fit}` 冻结 0.1 | 四专家一致 |
| Δ12 | GeometryPort 最小操作集 + Fault 闸门导出；WASM 交互 / Native 导出 | 几何专家 |

**明确不采纳的旧口径**：§10 将 MEP/软装/云/报价标 P0；F11 激光标 P1；「UVC 为主」单叙事；Godot 可当编辑器；无 Stage-Gate。

---

## 2. 产品定位与范围（In/Out）

### 2.1 定位（一句话）

> **低成本 Type-C 深度配件 + 手机宿主 + 蓝牙激光锚点 → 可编辑户型语义（SceneIR）→ 专业导出（DXF/PDF/glTF）+ Godot 只读漫游检查。**  
> 与 JoyPlan「全能装企 App + LiDAR/云渲染」错位：拓间立在 **可靠捕获 + 语义可改 + 可验收导出**。

### 2.2 In Scope（P0 必须验证的主命题）

- 白名单 Android + 外购 Type-C 深度模组出流  
- 引导式一室采集（校准→外墙→层高→门窗）  
- 关键边激光（或 typed）写入 SceneIR  
- 直线墙 / 成房 / 改厚高 / 矩形开洞 / 单层+层高  
- GeometryPort 编译 + Fault 可见  
- 导出 DXF（关键尺寸）+ PDF 平面 + `.glb`；Godot 可逛  
- 无网络可完成闭环；无自研光机、无云端 GS 依赖  

### 2.3 Out of Scope（P0 明确不做）

| 不做 | 去向 |
|------|------|
| MEP / 精简软装 / 云同步 / 自动报价 | P1+ |
| Godot 内编辑写回 SceneIR | 不进 MVP；P2+ 另议 |
| 点云 / 3DGS / 视频写回工程尺寸 | 禁止；衍生轨 P1 只读对齐 |
| 真弧墙、完整 2D 约束求解 | P1 |
| 复式镂空、别墅外景库 | P1/P2 |
| iOS 外接深度对等 | P2 评估 |
| 自研光机 / 旋转多线 LiDAR 一体机 / 自研写实云渲染 / 点数墙 | 非目标 |
| 射频 BLE 测距作尺子 | **永久禁止作尺寸主测** |
| SU/Max 全矩阵、「十几种格式」堆砌 | P2 评估 |
| 直接引用 JoyPlan 营销数字作拓间 KPI | **禁止** |

---

## 3. 用户与场景（P0）

### 3.1 主要用户

| 角色 | 目标 | P0 关注点 |
|------|------|-----------|
| 量房员 / 设计师（现场） | 快速得到可改的一室语义与可出图尺寸 | 引导可走完、激光可写、离线可用 |
| 室内设计主创（回办公室） | 改门洞/墙厚后重导出 | SceneIR 可编、DXF/glb 一致 |
| 技术负责人 / 采购 | 过 PoC 门再开模 | 白名单、供电、BOM 量级、门径 |

### 3.2 P0 核心场景

1. **插拔出流**：白名单机 + 模组 → 深度预览；断开可提示。  
2. **引导一室**：校准→外墙折线→层高→≥1 门洞；≥2 条关键边 `source=laser`（或明示 typed）。  
3. **改洞重编**：改门洞净宽 → 重编译 → DXF 标注 = SceneIR（舍入规则固定）。  
4. **导出闸门**：Status≠OK 拒绝结构固体 glTF；Fault 高亮。  
5. **Godot 检查**：`.glb` 可逛；节点层级可对 Storey/Wall/Room。  
6. **离线闭环**：无云完成 2–5。

### 3.3 P0 验收用例

| ID | 用例 | 通过条件 |
|----|------|----------|
| UC-P0-01 | 插拔深度 | 白名单机深度预览可见；断开可提示 |
| UC-P0-02 | 引导一室 | 完成引导；≥2 关键边 `laser`（或 typed 明示）；层高有测或 typed |
| UC-P0-03 | 改洞一致 | 改净宽→重编译→DXF 与 SceneIR 一致（容差见 §8） |
| UC-P0-04 | 导出/Godot | `.glb` Godot 可逛；Fault 时拒绝出结构固体文件 |
| UC-P0-05 | 离线 | 无网络完成 UC-P0-02～04 |

---

## 4. 软硬件边界与部署拓扑（文字）

### 4.1 边界

| 侧 | 职责 | 不职责 |
|----|------|--------|
| **硬件配件** | 深度帧、激光长度、可选 IMU；固件版本可查 | 不持有户型真相；不做自研光机 |
| **手机 App（Host）** | 引导、语义编辑、本地 SceneIR、WASM 轻量预览编译、会话 meta | 不以三角网为编辑对象 |
| **可选桌面 Compiler** | Native manifold 批处理 / 大户型 ensureBuilt / 金样 CI | 不替代手机现场保存语义 |
| **Godot 4** | 只读加载 `.glb` 漫游检查 | 不写回 SceneIR |
| **云（P1）** | 文档推拉 | P0 不依赖 |

### 4.2 部署拓扑（文字）

```
用户手机（Android 白名单）
  ├─ USB Host ← Type-C 深度模组（+ 必要时供电 Hub）
  ├─ 蓝牙 ← 激光测距仪（传输）
  ├─ 本地存储：SceneIR + 可选外置 EvidencePack
  └─ 导出文件：DXF / PDF / .glb
        │
        ├─（同机或拷贝）→ Godot 4 只读打开 .glb
        └─（可选）→ 桌面 Native Compiler 重编译大场景
```

---

## 5. 功能需求 FR（统一编号）

> 合并产品 FR-01…、硬件 FR-H*、几何约束；去重后统一为 **FR-xxx**。优先级 = 验收阻断级别。

### 5.1 P0

| ID | 陈述 | 溯源 |
|----|------|------|
| **FR-001** | 系统须以 FloorPlanDocument / SceneIR 为唯一可编辑真相源；Mesh、点云、3DGS、glTF 均为派生，禁止作为主编辑对象。 | 产品 FR-01 |
| **FR-002** | 须提供引导式采集会话（CaptureSession）：至少覆盖校准、外墙折线、层高、门窗开口；产出 Command/DomainEvent 写入 FloorPlanModeling；须支持保存草稿 / 最小断点续扫。 | 产品 FR-02、硬件 FR-H07 |
| **FR-003** | 须实现 DepthStreamPort，并在白名单机型上通过 **VendorSdkAdapter 与/或 UvcAdapter** 至少一条稳定出流；双适配须满足同一端口契约。 | 产品 FR-03、硬件 FR-H01/H02 |
| **FR-004** | 须实现 LaserRangefinderPort（蓝牙仅传输 + **激光**测距数据）；关键边长/门洞净宽/层高可写入且标记 `source=laser`；允许 Typed 适配器但须标 `typed`。 | 产品 FR-04、硬件 FR-H03 |
| **FR-005** | 射频类 BLE 测距不得作为尺寸主测路径；产品文案与默认工作流不得引导其替代激光。 | 产品 FR-05、硬件 HW-L4 |
| **FR-006** | 引导中门洞净宽/层高/关键轴长须优先触发激光或键入，不得仅用深度点选静默定案；深度拟合不得静默覆盖 `laser` 源。 | 硬件 FR-H05 |
| **FR-007** | 须支持直线墙绘制/编辑、房间闭合、墙厚/墙高/WallKind、矩形 Opening、层高设置；尺寸可手改（`typed`）。 | 产品 FR-06 |
| **FR-008** | 弧墙在 P0 仅允许折线逼近；真弧参数与完整 2D 约束求解不得阻塞 P0 验收。 | 产品 FR-07、O9 |
| **FR-009** | 须经 GeometryPort 执行 CrossSection→Extrude→Boolean 编译，并向 UI 暴露 GeometryFault；Status 非成功时禁止导出结构固体交付物。 | 产品 FR-08、几何 |
| **FR-010** | 须导出 DXF（墙/门窗/关键尺寸）、PDF 平面图、glTF 2.0（`.glb`/`.gltf`）。 | 产品 FR-09 |
| **FR-011** | Godot 4 须能只读加载导出之 `.glb` 完成漫游检查；节点层级可核对 Storey/Wall/Room；P0 不要求 Godot 内编辑写回。 | 产品 FR-10、几何 |
| **FR-012** | SceneIR 0.1 须包含 `measurements[].source` 枚举 `{laser, typed, depth_fit}`，并在 UI 展示尺寸来源。 | 产品 FR-11、硬件 FR-H04 |
| **FR-013** | P0 软件范围不得将 MEP、软装库、云同步、自动报价列为验收阻断项（可预留端口/BC，不计入 P0 Done）。 | 产品 FR-12 |
| **FR-014** | 须能读取 IMU 样本用于重力对齐；无配件 IMU 时可回退手机 IMU 并提示能力降级。 | 硬件 FR-H06 |
| **FR-015** | 须查询并记录配件固件版本、模组 SKU 至会话/文档 meta；非白名单组合须「实验模式」水印，不得伪装已认证。 | 硬件 FR-H08/H09 |
| **FR-016** | EvidencePack 可空；有则可外置、可删；删后仍可编辑已确认语义并重编译。 | 产品 P0 证据、NFR-05 |
| **FR-017** | 自研写实云渲染、点数墙、LiDAR-only 主路径、SU/Max 全矩阵不得作为 P0/P1 阻断需求。 | 产品 FR-19 |

### 5.2 P1

| ID | 陈述 |
|----|------|
| **FR-101** | 稀疏证据平面拟合→墙假设；闭合提示；校准体验增强。 |
| **FR-102** | 户型临摹（底图+比例尺描墙）。 |
| **FR-103** | Storey 复制/层高/多层 3D 展示。 |
| **FR-104** | 立面精放门窗；参考线吸附；放大镜级 mm 编辑 UX。 |
| **FR-105** | 精简 MEP：点位+折线+DXF 点位层；回路简化。 |
| **FR-106** | 精简软装：库拖拽+PickLayer；不默认 Boolean。 |
| **FR-107** | 分空间投影面积清单；报价若做须基于可替换计价策略。 |
| **FR-108** | 文档级云同步（至少 LWW 或明确手动分支）；上传须显式用户动作。 |
| **FR-109** | VisualizationDerivative：视频/GS 漫游对齐 SceneIR；**禁止写回尺寸**；视频草稿入库须人工确认。 |
| **FR-110** | 蓝牙激光仪自动重连与常用仪具预设。 |

### 5.3 P2

| ID | 陈述 |
|----|------|
| **FR-201** | 导入第三方点云/扫描为 Evidence 并蒸馏语义（须人工确认）；不得以稠密点云为主存。 |
| **FR-202** | 第三方渲染/全景对接；漫游视频；不做自研 TR。 |
| **FR-203** | SU/Max/obj 等；IFC 子集评估。 |
| **FR-204** | iOS 外设路径评估；非白名单 Android 扩展。 |
| **FR-205** | 朝向/日照等分析（JoyPlan R20 级）评估。 |

---

## 6. 非功能 NFR

| ID | 陈述 | 优先级 |
|----|------|--------|
| **NFR-001** | P0 目标平台：Android 机型白名单；须文档化 OTG/供电/USB Host 限制；iOS 外接深度不进 P0。 | P0 |
| **NFR-002** | P0 须可在无云、无自研光机、无云端 GS 条件下完成「采集→编辑→DXF/glTF」闭环。 | P0 |
| **NFR-003** | 关键边（门洞净宽、约定轴长、层高）验收：以激光测距值为准，偏差不超过所用仪具标称误差；平面/深度拟合仅用于走向与辅助，不得单独支撑对外「毫米」宣传。 | P0 |
| **NFR-004** | 禁止对外使用「全屋毫米级 / 零误差 / 深度处处毫米」等话术；所有精度声明须标明指标类型（测量/建模/UI/导出）。 | P0 |
| **NFR-005** | 主项目文件体积以语义 JSON 为主；EvidencePack 可外置可删。 | P0 |
| **NFR-006** | Geometry / Capture 端口须可 mock；无真机时可用深度回放夹具回归 Compiler 与引导 FSM。 | P0 |
| **NFR-007** | 软硬件发布须绑定 ReleaseTrain：软件 tag ↔ 模组 SKU/固件版本/白名单表；外购模组 PoC 未过门不得开模。 | P0 |
| **NFR-008** | 不以竞品营销数字（如 30 分钟量完、谈单成功率等）作为验收 KPI；须自建可复现样板间抽检集。 | P0 |
| **NFR-009** | P0 BOM 以消费级/模组级配件 + 用户手机为主；不将定制旋转多线 LiDAR 一体机作为 MVP 前提。 | P0 |
| **NFR-010** | 隐私：P0 默认可本地完成；上传云须显式用户动作（P1）。 | P0/P1 |
| **NFR-011** | 对外承诺的兼容范围 = 已发布白名单；白名单外零承诺。 | P0 |
| **NFR-012** | PoC/交付文档必须说明供电 Hub 场景；裸 OTG 仅白名单内验证通过机型可标「免 Hub」。 | P0 |
| **NFR-013** | 输出结构固体须流形；非流形不得进入结构固体交付物；Fault 必达 UI。 | P0 |
| **NFR-014** | 同 Document 写命令与 rebuild 须串行队列；禁止多 Worker 并行写同一几何缓存。 | P0 |
| **NFR-015** | CI 禁止 `domain-*` 包 import `manifold` / `manifold-3d`。 | P0 |
| **NFR-016** | 单位：语义 mm；glTF 导出单一换算点 mm→m。 | P0 |
| **NFR-017** | 室内使用；不要求工业 IP；激光仪遵循仪具安全等级（勿对眼直射）。 | P0 |
| **NFR-018** | Depth/Laser/IMU 均经端口；更换模组厂商不得改 Domain 模型。 | P0 |
| **NFR-019** | 浏览器交互默认 WASM Worker；大户型/批处理/导出 ensureBuilt 走 Native（待验证阈值与切换 UX）。 | P0 |
| **NFR-020** | Godot/移动端加载性能 **待验证**；不做虚假 FPS 承诺。 | P0 |

---

## 7. 硬件需求

### 7.1 模组 / 激光 / 接口

| 项 | 要求 |
|----|------|
| 深度模组 | 外购成品/开发板；室内优先结构光或主动双目；须有 Android SDK 或可解析深度路径；原理标签写入 AccessoryProfile |
| 接口 | Type-C；DepthStreamPort：`VendorSdkAdapter`（主）+ `UvcAdapter`（辅）；**UVC ≠ 深度原理** |
| 激光 | 手持蓝牙**激光**测距仪；蓝牙仅传数；LaserRangefinderPort |
| IMU | P0 强烈建议；模组无则外挂或手机 IMU 回退并标注降级 |
| 供电 | PoC 夹具含带外部供电的 USB Hub；额定电流/USB2 降级写入采购条款 |
| 明确不进 P0 | 自研光机、旗舰手持一体机、射频 BLE 尺子、iOS 外设链路 |

### 7.2 Android 白名单

- **Whitelist 六元组** = `(手机型号, Android 版本, 模组 SKU, 固件版本, 线材/Hub SKU, App 版本)`  
- 未入白：不承诺；可实验模式 +「未认证」水印  
- PoC 最低集：≥ **3** 品牌手机 × **1** 主选模组 × 供电 Hub 有/无各测一轮  
- 建议 API 覆盖以模组 SDK 官方支持矩阵为准（待实测锁定）

### 7.3 BOM 量级（非精确报价）

| 物料 | 量级直觉 | 备注 |
|------|----------|------|
| 深度模组开发板/成品 dongle | 数百～两千元人民币量级 | 询价为准 |
| 蓝牙激光测距仪 | 百元～千元量级 | P0 必备 |
| 供电 Hub + 指定线材 | 数十～数百元量级 | PoC 夹具 |
| 开模结构件+认证+固件定制 | 显著更高、周期长 | **仅 PoC 过门后** |
| 用户手机 | 自备或 PoC 池 3～5 台 | Host |

### 7.4 DepthStreamPort / Laser / IMU 契约要点

见架构文档端口摘要；硬件验收须满足：

- HW-D1…D6：对齐深度、Profile、热插拔错误码、稀疏证据、双实现、彩色可选  
- HW-L1…L6：激光原理、source 枚举、关键边引导、禁射频主测、typed 降级、断连可续  
- HW-I1…I5：重力对齐、校准向导、非 Multi-SLAM 前提、回退标注、外参粗/精分档  

### 7.5 门径 PoC / EVT / DVT / PVT 过门标准

| 阶段 | 硬件形态 | 过门标准（摘要） | 失败则 |
|------|----------|------------------|--------|
| **PoC** | 外购模组+Hub+激光+白名单样机 | ① ≥1 台白名单稳定开流 ≥30min；② 一室引导完成；③ 关键边激光入 SceneIR；④ glb Godot 可开；⑤ 初版白名单+问题单 | 换模组/机型；**禁止开模** |
| **EVT** | 小批量结构件、线材固定、固件候选 | ① 3 机型×模组回归；② 供电/热/掉线关闭或手册 workaround；③ 非开发可走通校准；④ 固件版本可查并写入 meta | 打回 PoC / 换 SKU |
| **DVT** | 开模前最终结构/包装；认证预测试 | ① 插拔/线材/室内级跌落；② App+固件冻结候选；③ 精度矩阵全通过；④ 双源或备料策略 | 改模/改料；不开 PVT |
| **PVT** | 试产与售后 | ① 良率与返修就绪；② 白名单对外发布；③ 软件 tag↔SKU 绑定；④ 入门/OTG/配对文档 | 停产整改 |

**软件绑定**：PoC 需引导 FSM+SceneIR+Laser/Typed+编译 glTF；EVT 需断点续扫/Profile/错误码 UX；DVT 需精度报告/白名单检测/固件门禁；PVT 需生产配置与售后换机流程。

---

## 8. 精度 SLA 与话术红线

### 8.1 四条指标（分开写、分开测）

| 指标 | 定义 | P0 口径 |
|------|------|---------|
| **测量误差** | 仪具+操作相对真值 | 关键边以激光为准；对照仪具标称误差（**不编造绝对 mm 数**）；深度**不作**关键边主测 |
| **建模容差** | 约束后语义偏差 | P0：正交+边长+层高；未激光锚边标 `depth_fit`/`typed`，UI 可见来源 |
| **UI 吸附精度** | 编辑分辨率 | 可配置 snap（如 1–100 mm 档）；**≠** 测量误差 |
| **导出尺寸精度** | DXF/标注 vs SceneIR | 关键尺寸导出值 = 语义值（舍入规则写死）；禁止网格量尺覆盖激光尺 |

### 8.2 验收矩阵（可测）

| 场景 | 真值 | 通过标准 |
|------|------|----------|
| 门洞净宽 | 激光三次取中位 | SceneIR `source=laser`，与仪具读数差 ≤ **仪具标称误差** |
| 房间轴长 | 激光 | 同上；正交约束后边长一致 |
| 层高 | 激光或两点法 | `laser` 或 `typed`；禁止仅深度单点冒充 |
| 墙面垂直/共面 | 深度拟合+铅垂 | UI 可提示倾角；不设虚假「全场 1mm」 |
| 深度点选两点距 | 深度 | **仅草测**；与激光冲突则以激光为准并记录冲突 |

### 8.3 话术红线

| 禁止 | 允许 |
|------|------|
| 「全屋毫米级」「深度处处毫米」「零出错」 | 「关键边以激光为准，误差不超过仪具标称」 |
| 「对标 JoyPlan LiDAR 3cm 全自动」 | 「引导采集 + 激光锚点 + 可编辑语义；深度用于走向/拟合」 |
| 「插上任意手机即用」 | 「P0 支持 Android 白名单（附列表与 OTG/供电说明）」 |
| 「点云/3DGS 即施工尺寸」 | 「衍生观感，不写回工程尺寸」 |
| 引用 JoyPlan「30 分钟」「谈单+25%」等作拓间承诺 | 自建样板抽检：关键尺寸通过率 / 导出可用性 |
| 「射频蓝牙测距 = 激光量房」 | 明确 Laser only 作尺寸主测 |
| 「UVC 深度 = 测量级」 | UVC 仅为传输壳 |

### 8.4 施工/报价尺寸硬约束

- 凡进入报价/施工导出默认图层的「承诺尺寸」，**不得仅有 `depth_fit`**（除非用户显式确认降级并水印提示）。

---

## 9. SceneIR / 数据需求要点

### 9.1 Published Language 硬约束（C1–C10 摘要）

1. 唯一可编辑主存；打开/保存/Undo 以 SceneIR（或同构序列化）为准  
2. 禁止嵌入 Manifold / MeshGL / 原始深度视频 / Godot Node 为必需字段  
3. `format` + `version` 必填；破坏性变更走迁移器  
4. 单位显式；P0 锁定 **mm**  
5. `measurements[].source: laser | typed | depth_fit`  
6. evidenceIds 弱引用；悬空不致命  
7. StoreyId/WallId/RoomId/OpeningId 稳定；与 glTF `extras.toporoomId` 对齐  
8. 编译选项外置（不进语义必填）  
9. P0：直线墙 + 折线弧；约束正交+边长+层高  
10. 与 FloorPlan 聚合同构（序列化投影，非第二套模型）

### 9.2 分层

| 层 | 名称 | 关系 |
|----|------|------|
| L1 | SceneIR / FloorPlanDocument | 真相 |
| L2 | Sparse Evidence Pack | 可选可丢 |
| L3 | MeshGL / MeshProjection | 派生缓存 |
| L4 | glTF 2.0 | 引擎 PL |
| L5 | 点云/3DGS/视频 | 衍生；禁止反向覆盖尺寸 |

### 9.3 measurements 示例字段

```json
{
  "id": "ev_measure_7",
  "kind": "length",
  "valueMm": 900,
  "source": "laser",
  "instrumentId": "laser_sku_x",
  "between": ["lm_a", "lm_b"]
}
```

### 9.4 glTF 节点约定（交付侧）

- `Storey_{id}` / `Wall_{id}` / `Room_{id}` / `Opening_{id}`  
- `extras.toporoomId` / `extras.kind`  
- Y-up；mm→m；`asset.generator = "toporoom-compiler/<semver>"`  
- P0 推荐 per-wall solid；Opening 可空节点锚点  

---

## 10. 验收标准与里程碑

### 10.1 P0 成功标准（产品+硬件联合）

白名单 Android + 深度模组 → 引导一室语义（关键边激光写入）→ 可编辑 → `.glb` Godot 可逛 + DXF 可量关键尺寸 → 无自研光机、无云端 GS。

### 10.2 里程碑建议

| 里程碑 | 内容 | 门禁 |
|--------|------|------|
| M0 | SceneIR 0.1 冻结 + Port 契约评审 + 夹具 JSON→glb 金样 | Schema/Port 签字 |
| M1 PoC | 真机出流 + 激光写入 + 一室闭环 + Godot 打开 | §7.5 PoC |
| M2 EVT | 3 机型回归 + 断点续扫 + 手册 workaround | §7.5 EVT |
| M3 DVT | 精度矩阵 + 固件冻结候选 + 结构定稿 | §7.5 DVT |
| M4 PVT | 试产 + 白名单发布 + tag↔SKU | §7.5 PVT |

### 10.3 No-Go 触发器（任一建议停）

- 坚持「迷你 JoyPlan 全科」作样机 Done  
- 坚持无激光锚点却宣传毫米  
- 坚持点云/GS 写回尺寸  
- 坚持全机型/双端外设对等才发布  
- Domain 直接依赖 manifold 类型  
- Godot（或 Three）内建模并自动回写为主路径  

---

## 11. 开放问题（仅未决）

| # | 问题 | 备注 |
|---|------|------|
| Q1 | 主选深度模组最终 SKU 与 Android SDK 矩阵 | 询价+PoC 实测 |
| Q2 | 白名单首发机型名单与「免 Hub」机型 | PoC 后锁定 |
| Q3 | 语义 DXF 在 Geometry Fault 时是否仍允许出「中线层」 | 几何建议：语义线可出、实体网格不可出——产品需书面确认 |
| Q4 | 手机端 WASM 现场编译 vs「仅保存 SceneIR、桌面出 glb」的默认策略阈值 | 待验证 |
| Q5 | 激光仪开放协议清单（可自动配对 vs 仅 typed） | 采购测试 |
| Q6 | P1 云冲突策略最终选 LWW 还是手动分支 | P1 启动前 |
| Q7 | 服务端布尔配额/权益是否做 | 开放；非 P0 |
| Q8 | EXT_mesh_manifold 是否写入 glTF | 可选；Godot 不依赖 |

*已决议不再列为开放：SceneIR 唯一真相、激光 P0、Godot 只读、P0 砍 MEP/软装/云/报价、弧墙折线、Android 优先、禁射频主测、禁 GS 写回。*

---

## 12. 附录：专家表决摘要表

| 专家 | 裁决 | 强制变更要点 |
|------|------|--------------|
| 01 产品 | **Go-with-changes** | 瘦 P0；激光 P0；精度/话术红线；统一 SceneIR；Godot 只读；白名单；好看轨不写回；禁 JoyPlan 营销 KPI |
| 02 硬件 | **Go-with-changes** | 外购 Type-C+激光+手机；双适配；白名单+Hub；Stage-Gate；BOM 砍自研光机；source 枚举 |
| 03 DDD | **Go-with-changes** | 最终 BC 列表；Capture→Command；Compiler/Godot/Firmware 降级；Session 串行；文档收拢 |
| 04 几何·Godot | **Go-with-changes** | 冻结 GeometryPort/Fault/glTF 节点；Godot 只读；WASM/Native 双运行时；禁 LAS/E57/LCC/GS 一等输入 |

| 冲突点 | 裁决（按总优先级） |
|--------|-------------------|
| P0 是否含 MEP/软装/云/报价 | **否**（瘦 P0） |
| 激光优先级 | **P0** |
| UVC vs VendorSdk | **双适配，VendorSdk 主** |
| Godot 是否可编辑 | **只读** |
| GS/视频与尺寸 | **禁止写回** |
| 平台 | **Android 白名单；iOS 出局首发** |
| 真相源 | **仅 SceneIR** |

---

*文档结束。实施以本 FINAL 与 `FINAL-toporoom-software-architecture.md` 为准；辩论稿归档于 `debate/`。*
