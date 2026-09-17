# 拓间 TopoRoom — 装修设计行业统一语言（Ubiquitous Language）词汇表

> **用途**：产品领域建模前的行业词汇基线；供后续 DDD / SceneIR / 出图与量房流程对齐。  
> **范围**：中国大陆家装 / 整装 / 室内设计常用口语与制图用语 + TopoRoom 已用技术词映射。  
> **非目标**：本稿**不**做聚合设计、不编造规范条文编号、不替代正式国标全文。  
> **来源**：本地文档（`joyplan-prd.md`、`FINAL-toporoom-*`、`toporoom-ddd-architecture.md`、`semantic-3d-capture-ddd.md` 等）+ 大陆量房/硬装/水电/交底常见行业说法。  
> **单位约定**：凡尺寸默认 **毫米（mm）**；面积默认 **平方米（m²）**（见文末「统一语言约定」）。  
> **优先级**：`P0` = 瘦 MVP 必进模型或 UI 话术；`P1` = 可用/预留；`Out` = 本期不进 Domain（可仅 Adapter 或远期）。

---

## 0. 读法与图例

| 列 | 含义 |
|----|------|
| 中文名 | 设计师 / 工长 / 量房员现场说法（首选） |
| 英文/代码建议名 | TopoRoom 代码或 SceneIR 字段建议；技术词保留英文 |
| 定义 | 一句话业务定义 |
| 同义词 / 禁混用 | 可互换说法；**禁**与易混词混用 |
| TopoRoom P0/P1/Out | 产品分期落点 |
| 备注 | Domain vs Adapter；与现有文档映射 |

**分层标记（备注中使用）**

- **D** = 应进入 Domain 层（业务语言 / 聚合可说的话）
- **A** = 留在 Adapter / Infrastructure / 端口 DTO（勿污染领域模型）
- **S** = 会话/交互层概念（Capture / Tool FSM），非持久业务实体
- **行业** = 大陆装修现场标准用语
- **TR** = TopoRoom 已用技术词（需映射到行业说法）

---

## 1. 项目与角色

| 中文名 | 英文/代码建议名 | 定义 | 同义词/禁混用 | TopoRoom P0/P1/Out | 备注 |
|--------|-----------------|------|---------------|-------------------|------|
| 项目 | `Project` | 一次装修业务单元；可含多套方案 | 工程；禁与「方案/文档」混用 | P1（协作） | D；现有 BC: ProjectCollab |
| 方案 / 设计方案 | `DesignScheme` / `Document` | 可编辑的一套户型+布置真相 | 文档、方案文件；禁称「模型文件」为真相 | P0 | D；对应 `FloorPlanDocument` |
| 户型文档 | `FloorPlanDocument` | 语义真相源文档（单位、楼层、墙房洞） | SceneIR 持久形态；禁与 Mesh/glTF 混称真相 | P0 | D+TR；与 SceneIR 同真相 |
| 业主 / 甲方 | `Client` / `Owner` | 付费决策方 | 客户；工装称甲方 | Out（CRM） | 行业；可不进几何 Domain |
| 室内设计师 | `Designer` | 量房、方案、出图主责 | 主创、设计 | P0（角色话术） | 行业 |
| 量房员 | `Surveyor` | 现场测绘执行人（可与设计师同一人） | 测绘员；禁称「扫点云的人」 | P0 | 行业+S |
| 工长 / 项目经理 | `Foreman` / `SitePM` | 施工组织与现场交底对接 | 施工队长 | P1 | 行业 |
| 水电工 | `MEPWorker` | 强弱电水路施工 | 水电师傅 | P1 | 行业 |
| 柜厂 / 全屋定制商 | `CabinetVendor` | 柜体深化与下单方 | 木作厂 | P1 | 行业 |
| 谈单 | `SalesPitch` | 用方案/效果图与业主沟通成交 | 提案；禁与「施工交底」混用 | Out | 行业；JoyPlan 旅程词 |
| 整装 | `TurnkeyRenovation` | 设计+主材+施工打包交付模式 | 全包；相对「半包/清包」 | Out（商业） | 行业语境 |
| 家装 / 工装 | `ResidentialFitout` / `CommercialFitout` | 住宅 vs 商业空间装修 | 勿混计费与规范习惯 | P0 话术偏家装 | 行业 |
| 轻设计 | `LightDesign` | 现场快速布置软硬装、未达全套施工图深度 | 方案级设计 | P1 | JoyPlan/TR 用语 |
| 现场备注 | `FieldNote` | 挂在空间上的多媒体/文字备注 | 现场记录 | P1 | D；现有术语表 |

---

## 2. 空间与户型

| 中文名 | 英文/代码建议名 | 定义 | 同义词/禁混用 | TopoRoom P0/P1/Out | 备注 |
|--------|-----------------|------|---------------|-------------------|------|
| 户型 | `UnitLayout` / `FloorPlan`（业务） | 套内空间分隔与关系的总体 | 平面格局；禁与「平面布置图」完全等同 | P0 | 行业；代码可保留 FloorPlan* |
| 户型图 | `UnitPlanDrawing` | 表达墙体分隔与空间命名的图（常无家具） | 建筑户型图、原始结构图 | P0 | 行业；≠ 平面布置图 |
| 平面布置图 | `FurnitureLayoutPlan` | 在户型上布置家具/软装后的平面 | 布置图、家具平面；禁称「户型图」 | P1 | 行业 |
| 楼层 | `Storey` | 同一标高上的墙/房/洞集合 | 层、F1/F2；禁与「楼板」混用 | P0 | D；现有 AR 候选 |
| 层高 | `StoreyHeight` / `floorToFloorHeight` | 本层楼地面结构面至上层楼地面结构面的高度 | 建筑层高；禁与「净高」混用 | P0 | D+行业 |
| 室内净高 | `ClearHeight` / `netHeight` | 完成地面至吊顶底或楼板底的垂直净距 | 净空高度；禁称层高 | P0 | D+行业（GB 住宅设计规范用语） |
| 标高 | `ElevationLevel` / `levelMm` | 相对 ±0.000 的竖向定位 | 相对标高；禁与层高数值混称 | P1 | D |
| 房间 / 空间 | `Room` / `Space` | 由闭合墙环界定的可命名空间单元 | 功能分区；未闭合不算房间 | P0 | D |
| 空间类型 | `SpaceType` | 室内/室外/露台等语义，影响天花与面积 | 禁仅用英文 enum 对用户展示 | P0 | D；现有 VO |
| 开间 | `BayWidth` / `roomWidth` | 房间面宽方向的轴线或墙中距常用边长 | 面宽；与进深成对 | P0 标注 | 行业 |
| 进深 | `Depth` / `roomDepth` | 房间进深方向边长 | 禁与「墙厚」混用 | P0 标注 | 行业 |
| 套内面积 | `InternalArea` | 套内使用空间面积（含墙中分等规则依计面积标准） | 使用面积近似说法需注明规则 | P1 | 行业；规则待产品确认 |
| 建筑面积 | `GrossFloorArea` | 含外墙等的建筑面积口径 | 建面 | Out/P1 | 行业；报价谨慎 |
| 公摊 | `SharedArea` | 分摊共有建筑面积 | 公摊面积 | Out | 行业；非几何建模核心 |
| 玄关 | `SpaceType.entry` / `xuanguan` | 入户过渡空间 | 门厅 | P0 命名 | 行业空间名 |
| 客厅 / 起居室 | `living` | 起居会客主空间 | 厅、客餐厅连通时注明 | P0 | 行业 |
| 餐厅 | `dining` | 就餐空间 | 可与客厅合并标注 | P0 | 行业 |
| 主卧 | `masterBedroom` | 主卧室 | 主卧套房含衣帽间/卫时拆分命名 | P0 | 行业 |
| 次卧 | `bedroom` | 次卧室 | 儿童房、客房 | P0 | 行业 |
| 书房 | `study` | 办公阅读空间 | 多功能房 | P0 | 行业 |
| 厨房 | `kitchen` | 炊事空间 | 中厨/西厨 | P0 | 行业 |
| 卫生间 | `bathroom` / `wc` | 卫浴空间 | 洗手间、厕所；干湿分区需子空间 | P0 | 行业 |
| 阳台 | `balcony` | 挑出或凹入的室外/半室外空间 | 封闭阳台注明 | P0 | 行业 |
| 储物间 | `storage` | 储藏空间 | 杂物间 | P0 | 行业 |
| 衣帽间 | `walkInCloset` | 独立更衣储衣空间 | WIC | P1 | 行业 |
| 走道 / 走廊 | `corridor` | 交通空间 | 过道 | P0 | 行业 |
| 设备平台 / 管井间 | `equipment` / `shaftRoom` | 设备或管井检修空间 | 禁与「烟道」混用 | P1 | 行业 |
| 复式 / 跃层 | `duplex` | 跨层连通户型 | 镂空、挑空需单独构件 | P1 | 行业；现有「复式镂空」 |
| 原始户型 / 现状 | `AsBuiltLayout` | 改造前实测或开发商图现状 | 毛坯现状、精装现状 | P0 | 行业 |
| 拆改后户型 | `AfterDemolitionLayout` | 拆墙改门后的目标分隔 | 拆改图 | P1 | 行业 |

---

## 3. 墙体与结构

| 中文名 | 英文/代码建议名 | 定义 | 同义词/禁混用 | TopoRoom P0/P1/Out | 备注 |
|--------|-----------------|------|---------------|-------------------|------|
| 墙 / 墙段 | `Wall` | 以中线+厚度表达的一段墙体 | 墙体；弧墙可折线逼近（P0） | P0 | D |
| 墙中线 | `WallCenterline` | 墙厚方向几何中心线，平面绘图主参照 | 中线；禁与完成面线混用 | P0 | D+行业 |
| 墙厚 | `WallThickness` | 墙体厚度（常指结构/砌体厚，完成面另计） | 厚度 | P0 | D |
| 墙高 | `WallHeight` | 墙体竖向高度（可等于层高或房间高度） | 禁默认=净高 | P0 | D |
| 墙属性 / 墙类型 | `WallKind` | 砌体/剪力墙/玻璃隔断等分类 | 墙材质属性 | P0 | D；现有 VO |
| 承重墙 / 剪力墙 | `shearWall` / `loadBearing` | 不可随意拆除的结构墙 | 禁对用户仅标「红墙」无说明 | P0 | 行业 |
| 砌体墙 / 填充墙 | `masonry` / `partition` | 可拆改的非承重墙 | 隔墙 | P0 | 行业 |
| 玻璃隔断 | `glassPartition` | 玻璃分隔墙 | 玻璃墙 | P1 | 行业 |
| 内墙 / 外墙 | `interiorWall` / `exteriorWall` | 室内分隔 vs 外围护 | 禁仅用颜色区分无语义 | P0 | JoyPlan/TR |
| 共墙 | `SharedWall` | 两空间共用的同一墙段 | 分户墙另标 | P0 | D |
| 构造柱 | `StructuralColumn` / hosted | 墙中或墙端的构造柱 | 禁与独立框架柱概念完全等同（现场口语常混） | P1 | D=`HostedComponent` |
| 柱 | `Column` | 竖向承重构件 | 方柱/圆柱 | P0 | D |
| 梁 | `Beam` | 水平承重构件；影响吊顶净高 | 框架梁、过梁 | P0 | D |
| 过梁 | `Lintel` | 门窗洞口上方梁 | 禁与主梁混用 | P1 | 行业 |
| 门垛 / 墙垛 | `Pier` / `doorJambWall` | 洞口旁残留墙垛宽度 | 垛子 | P0 量房必标 | 行业 |
| 烟道 | `Flue` / `smokeDuct` | 厨卫排烟竖向通道 | 禁与新风管井混用 | P0 量房 | 行业 |
| 管井 / 管道井 | `PipeShaft` / `riserShaft` | 给排水/强电等竖向井道 | 强电井、弱电井细分 | P1 | 行业 |
| 风道 | `AirDuctShaft` | 通风竖井 | | P1 | 行业 |
| 沉降缝 / 伸缩缝 | `ExpansionJoint` | 结构变形缝，装修需特殊收口 | 禁当普通缝隙抹平 | Out/P1 | 行业 |
| 地台 | `RaisedFloor` / `platform` | 抬高地面平台 | 台阶式地台 | P1 | JoyPlan 构件 |
| 壁龛 | `Niche` | 墙内凹龛 | 禁当普通开洞无深度 | P1 | JoyPlan |
| 打断（墙） | `WallSplit` | 将一墙段在节点处拆成多段 | 打断墙 | P0 | D 服务动作 |
| 转弧 / 弧墙 | `ArcWall` | 弧形墙；P0 可用折线逼近 | 禁对外宣传「真圆弧实体」若仅折线 | P0 折线 | TR 约束 |
| 斜墙 | `SkewWall` | 非正交墙段 | 需显示夹角 | P1 | JoyPlan |

---

## 4. 门窗洞口

| 中文名 | 英文/代码建议名 | 定义 | 同义词/禁混用 | TopoRoom P0/P1/Out | 备注 |
|--------|-----------------|------|---------------|-------------------|------|
| 洞口 / 开洞 | `Opening`（总类） | 墙上开口的统称（门/窗/垭口/洞） | **应对用户细分**，勿只说 Opening | P0 | D+TR；建议细分子类 |
| 门洞 | `DoorOpening` | 供通行的门洞口（结构洞） | 门口；净宽≠门扇宽 | P0 | D+行业 |
| 窗洞 | `WindowOpening` | 窗洞口 | 窗口 | P0 | D+行业 |
| 垭口 | `ArchwayOpening` / `passThrough` | **不安门扇**的通道口（可做垭口套） | 禁与门洞/空门套混为一谈 | P0 | 行业强区分 |
| 门洞净宽 | `DoorClearWidth` | 洞口内侧完成面之间的通行净宽 | 禁与门扇宽度、洞口结构宽混用 | P0 | D；需求 FR 关键尺寸 |
| 门洞净高 | `DoorClearHeight` | 洞口通行净高（不含亮子时需注明） | | P0 | D |
| 窗宽 / 窗高 | `WindowWidth` / `WindowHeight` | 窗洞宽高 | | P0 | D |
| 窗台高 | `SillHeight` | 窗洞下沿距完成地面高度 | 台高；凸窗另测台深 | P0 | D；现有 Opening.sill |
| 窗台深 | `SillDepth` | 窗台出挑/台面深度（飘窗必测） | | P1 | 行业 |
| 亮子 | `Transom` | 门/窗上部固定或开启的采光小扇 | 上亮；高度不含在「门洞高」时常单独标 | P1 | 行业 |
| 平开门 | `SwingDoor` | 铰链平开的门 | 单开/双开 | P0 | 行业门型 |
| 推拉门 | `SlidingDoor` | 左右推移的门 | 移门 | P0 | 行业 |
| 折叠门 | `FoldingDoor` | 多扇折叠门 | 折叠移门 | P1 | 行业 |
| 子母门 | `PrimarySecondaryDoor` | 一大一小双扇平开 | | P1 | 行业 |
| 入户门 / 分户门 | `EntryDoor` | 套型入口门 | 防盗门 | P0 | 行业 |
| 房门 / 室内门 | `InteriorDoor` | 套内房间门 | | P0 | 行业 |
| 门套 | `DoorCasing` | 包覆门洞、固定门扇的套线结构 | 禁与垭口套混用 | P1 | 硬装 |
| 窗套 | `WindowCasing` | 包覆窗洞的套线 | | P1 | 硬装 |
| 垭口套 | `ArchwayCasing` | 垭口装饰包边（通常无门扇安装企口） | 空门套口语易混，建模宜用垭口套 | P1 | 行业 |
| 开启方向 | `SwingDirection` / `handing` | 门扇内开/外开及左右手 | 平面须画开启弧线 | P1 | 行业制图 |
| 门楣高 | `HeadToCeiling` | 门洞上沿至天花的距离（量房常用） | | P1 | 量房口语 |
| 填充门窗 | `OpeningFill` / hosted fill | 洞口内安装的门扇/窗扇几何 | 结构洞 vs 扇料分层 | P1 | 可挂 HostedComponent |
| 矩形开洞 | `RectOpening` | P0 支持的矩形参数洞 | 异形洞 P1+ | P0 | TR |

---

## 5. 尺寸与测量

| 中文名 | 英文/代码建议名 | 定义 | 同义词/禁混用 | TopoRoom P0/P1/Out | 备注 |
|--------|-----------------|------|---------------|-------------------|------|
| 量房 / 实地量房 | `Survey` / `FieldSurvey` | 现场实测户型尺寸与构件 | 测绘；禁称「扫一遍点云」等同完成量房 | P0 | S+行业 |
| 测距 | `Ranging` | 用激光/卷尺读取长度 | | P0 | 行业 |
| 激光测距 | `LaserMeasure` / `source=laser` | 激光测距仪得到的尺寸证据 | 禁与蓝牙射频「伪测距」混宣传 | P0 | TR+行业 |
| 手输尺寸 | `TypedMeasure` / `source=typed` | 人工键入的尺寸 | 手记 | P0 | TR |
| 深度拟合 | `DepthFit` / `source=depth_fit` | 由深度/视觉拟合的尺寸（辅助） | **不得静默冒充激光**；施工承诺尺寸慎用 | P0 标记 | TR |
| 量测样本 | `MeasureSample` | 一次测距读数（含来源、时刻） | | P0 | S/TR |
| 净宽 | `ClearWidth` | 完成面之间的可用宽度 | 禁与轴线距、中线距混用 | P0 | 行业 |
| 净深 | `ClearDepth` | 完成面之间的可用进深 | | P0 | 行业 |
| 轴线 / 轴网 | `GridAxis` / `StructuralGrid` | 建筑定位轴线体系 | 家装现场常弱化；别墅/工装更重要 | P1 | 行业 CAD |
| 轴线距 | `AxisDistance` | 两轴线之间距离 | 禁直接当净空 | P1 | 行业 |
| 中线距 | `CenterlineDistance` | 两墙中线距离 | 与净宽差一个墙厚关系 | P0 | D |
| 完成面 | `FinishedFace` / `FF` | 饰面施工完成后的表面 | 完成面线；禁与结构面混用 | P0 话术 | 行业核心 |
| 建筑面 | `ArchitecturalFace` | 建筑交付/找平后的建筑面层（各地口径略差） | 常介于结构面与完成面之间 | P1 | 行业；对外要注明口径 |
| 结构面 | `StructuralFace` | 主体结构表面（混凝土/砌体原面） | 毛坯结构面 | P0 量房 | 行业 |
| 预留 | `Allowance` / `reserve` | 为门套、柜体、管线等预留的尺寸 | 扩孔预留、安装预留 | P1 | 行业 |
| 找平层 | `Screed` | 地面找平构造层 | | P1 | 行业 |
| 水平基准线 | `DatumLine` / `1mLine` | 常取距完成地面 1.0m 的全屋水平控制线 | 一米线 | P1 | 精装放线 |
| 完成面线 | `FinishedFaceLine` | 墙/地/顶完成面控制线 | | P1 | 精装放线 |
| 误差 / 容差 | `Tolerance` | 允许偏差 | 单次量房常见口语 ±5mm 级，**产品以仪具标称+约束策略为准** | P0 | 勿写死假国标 |
| 正交约束 | `OrthogonalConstraint` | 墙角按直角约束求解 | P0 建模约束 | P0 | TR |
| 边长约束 | `EdgeLengthConstraint` | 以测得边长锚定位姿 | P0 | TR |
| 关键尺寸 | `CriticalDimension` | 进入施工/报价承诺的尺寸（门洞净宽、轴长、层高等） | 须有 laser/typed 来源策略 | P0 | TR 需求 |
| 尺寸来源 | `MeasureSource` | `laser` / `typed` / `depth_fit` | 须对用户可见 | P0 | TR；行业表述见约定 |
| 指北针 / 朝向 | `NorthArrow` / `orientation` | 图面朝向约定（量房常上北下南） | | P1 | 量房习惯 |

---

## 6. 楼地面 · 天花 · 吊顶（硬装界面）

| 中文名 | 英文/代码建议名 | 定义 | 同义词/禁混用 | TopoRoom P0/P1/Out | 备注 |
|--------|-----------------|------|---------------|-------------------|------|
| 楼地面 | `FloorSurface` | 本层地面（结构+找平+饰面体系） | 地面；禁与「楼层 Storey」混用 | P0 | D 表面语义 |
| 天花 / 顶棚 | `Ceiling` | 房间顶部界面（结构板底或吊顶面） | 顶面 | P0 | D |
| 吊顶 | `SuspendedCeiling` | 悬挂于结构下的装饰顶棚 | 天花板造型；平顶/叠级/异形顶 | P1 | 行业 |
| 平顶 | `FlatCeiling` | 平面吊顶或原顶简单饰面 | | P1 | 行业 |
| 叠级吊顶 | `SteppedCeiling` | 有高低差的分层吊顶 | 二级顶等 | P1 | 行业 |
| 吊顶净高 | `CeilingClearHeight` | 完成地到吊顶完成面净高 | 常即室内净高（有吊顶时） | P0 | 行业 |
| 踢脚 / 踢脚线 | `Skirting` / `baseboard` | 墙地交界保护与收口条 | 踢脚线 | P1 | 硬装 |
| 墙面 | `WallFinishFace` | 墙体饰面完成面 | | P0 | 行业 |
| 地面铺装 | `FloorFinish` / `TilingSpec` | 地砖/地板等铺法与材质 | 铺贴 | P1 | D=`TilingSpec` |
| 墙砖铺贴 | `WallTiling` | 墙面砖铺贴 | | P1 | 行业 |
| 防水 | `Waterproofing` | 厨卫等防水层 | | Out/P1 | 行业；非 P0 几何 |
| 下沉 / 同层排水落差 | `SunkenSlabOffset` | 厨卫相对楼板的下沉量 | 量房标 -300 等 | P1 | 量房 |
| 栏杆 / 护栏 | `Railing` | 楼梯/阳台防护 | | P1 | JoyPlan 构件 |
| 楼梯 | `Stair` | 楼层垂直交通 | | P1 | HostedComponent |
| 屋顶 / 坡顶 | `Roof` | 屋顶造型（别墅） | P0 可不做 | Out/P1 | JoyPlan 有 Optimize Roof |

---

## 7. 给排水 · 电气 · 暖通（MEP）入门词

> 整类 **P1 可用**（瘦 P0 不阻断验收）；词汇仍进入统一语言，避免以后污染命名。

| 中文名 | 英文/代码建议名 | 定义 | 同义词/禁混用 | TopoRoom P0/P1/Out | 备注 |
|--------|-----------------|------|---------------|-------------------|------|
| 管综 / 水电 | `MEP` | 强电、弱电、给排水等管线综合布置 | 禁对外只说 MEP 无中文 | P1 | D BC |
| 点位 / 末端 | `MEPNode` | 开关、插座、灯位、水嘴等末端位置 | 末端装置 | P1 | D |
| 管段 | `MEPSegment` | 点位之间的管线路径 | 管线 | P1 | D |
| 回路 | `MEPCircuit` | 照明/插座/空调等电气分组或水路分组 | 禁与「点位」混用 | P1 | D |
| 强电 | `Power` / `strongCurrent` | 220V 照明与插座供电系统 | 禁与弱电共槽 | P1 | 行业 |
| 弱电 | `WeakCurrent` / `lowVoltage` | 网络/电话/电视/门禁等信号线路 | | P1 | 行业 |
| 开关面板 | `SwitchPanel` | 墙面开关面板及联数 | 开关 | P1 | 行业 |
| 插座 | `Socket` / `outlet` | 电源插座点位 | 五孔/三孔/空调插座 | P1 | 行业 |
| 灯位 | `LightPoint` | 灯具安装点 | 灯具点位 | P1 | 行业 |
| 配电箱 | `DistributionBox` | 户内强电分配箱 | 空气开关箱 | P1 | 行业 |
| 弱电箱 | `WeakCurrentBox` | 户内弱电集中箱 | 多媒体箱 | P1 | 行业 |
| 冷给水 / 热给水 | `ColdWater` / `HotWater` | 给水冷热分支 | **左热右冷**为常见安装习惯 | P1 | 行业 |
| 给水口 / 水嘴预留 | `WaterOutlet` | 墙出冷热水口中心定位 | 角阀位 | P1 | 行业 |
| 排水口 / 地漏 | `Drain` / `FloorDrain` | 地面或器具排水点 | | P1 | 行业 |
| 存水弯 | `Trap` | 防臭水封弯 | | Out | 行业施工 |
| 走顶 / 走地 / 走墙 | `RouteCeiling` / `RouteFloor` / `RouteWall` | 管线敷设路径策略 | | P1 | JoyPlan/行业 |
| 开槽 / 暗装 | `Chasing` / `concealed` | 墙地开槽埋管 | 横平竖直 | Out | 行业施工 |
| 暖通 / 空调点位 | `HVAC` / `ACPoint` | 空调室内外机与冷凝水等 | P1 简化可先做插座点位 | P1 | 行业 |
| 挂墙参照 | `WallMountRef` | 点位相对某墙的偏移与离地高 | | P1 | TR VO |
| 左热右冷 | `HotLeftColdRight` | 冷热出水口左右约定（面对墙） | 习惯非绝对国标，图纸应明示 | P1 | 行业习惯 |

---

## 8. 软装 · 家具 · 定制

| 中文名 | 英文/代码建议名 | 定义 | 同义词/禁混用 | TopoRoom P0/P1/Out | 备注 |
|--------|-----------------|------|---------------|-------------------|------|
| 软装 | `Furnishing` | 可移动或布置类家具家电陈设 | 禁把柜体硬装层全叫软装 | P1 | D BC |
| 硬装 | `HardFitout` | 固定于建筑界面的装饰工程 | 与软装相对 | P0 话术 | 行业 |
| 家具实例 | `FurnishingInstance` | 场景中的一件家具/电器 | 默认不进墙体 Boolean | P1 | D |
| 定制柜 / 柜体 | `CabinetInstance` | 参数化柜体（衣柜/橱柜等） | 全屋定制 | P1 | D |
| 台面 | `Countertop` | 厨卫/家具上沿工作面 | 台面高影响插座定位 | P1 | 行业 |
| 五金 | `Hardware` | 铰链、拉手、轨道、水暖五金等 | | P1 | 行业 |
| 饰面材质 | `FinishMaterial` | 可见表面材料（木皮、岩板、布艺等） | 材质；禁与结构材料混用 | P1 | 行业 |
| 拾取层 | `PickLayer` | 结构/硬装/软装分层拾取 | | P1 | TR |
| 最小间隙 | `MinGap` | 软装与墙体碰撞间隙规则 | | P1 | TR |
| 橱柜 | `KitchenCabinet` | 厨房定制柜系统 | | P1 | 行业 |
| 衣柜 | `Wardrobe` | 卧室储衣柜 | | P1 | 行业 |
| 护墙 / 墙板 | `WallPanel` | 墙面装饰板系统 | | P1 | 行业 |
| 窗帘盒 | `CurtainBox` | 窗帘轨道隐藏构造 | | Out | 行业 |

---

## 9. 材质 · 饰面 · 材料表

| 中文名 | 英文/代码建议名 | 定义 | 同义词/禁混用 | TopoRoom P0/P1/Out | 备注 |
|--------|-----------------|------|---------------|-------------------|------|
| 材料表 | `MaterialSchedule` | 图中材料编号与规格汇总 | 材料清单；与「材料档案」分工见备注 | P1 | 行业 |
| 材料档案 | `MaterialLibraryEntry` | 含样板图、厂家、工艺的材料库条目 | 方案阶段常用 | P1 | 行业 |
| 主材 | `MainMaterial` | 业主可见的主要饰面材料 | | P1 | 行业 |
| 辅材 | `AuxMaterial` | 水泥砂浆龙骨胶水等 | | Out | 行业 |
| 基材 | `Substrate` | 石膏板、细木工板等基层板 | | P1 | 行业 |
| 涂料 | `Paint` | 乳胶漆等涂饰 | | P1 | 行业 |
| 壁纸 / 墙布 | `Wallpaper` | 卷材墙面饰面 | | P1 | 行业 |
| 瓷砖 / 石材 | `Tile` / `Stone` | 硬质铺贴材料 | | P1 | 行业 |
| 木地板 | `WoodFlooring` | 木/复合地板 | | P1 | 行业 |
| 排版图 | `LayoutPatternPlan` | 砖模/地板铺贴定向与分割 | 铺贴图 | P1 | 行业 |

---

## 10. 图纸与交付物

| 中文名 | 英文/代码建议名 | 定义 | 同义词/禁混用 | TopoRoom P0/P1/Out | 备注 |
|--------|-----------------|------|---------------|-------------------|------|
| 交付物 | `Deliverable` | 可导出给施工/业主的图档产物 | 出图成果 | P0 | D BC |
| 施工图 | `ConstructionDrawingSet` | 指导施工的正式图册（平面/立面/节点/水电等） | 禁把效果图当施工图 | P1 | 行业 |
| 效果图 | `Rendering` / `VizImage` | 视觉表现图，非尺寸契约 | 彩图；尺寸以施工图/语义为准 | P1 | 行业 |
| 平面图 | `PlanView` | 水平剖切俯视的图 | 含户型平面/布置平面等细分 | P0 | 行业 |
| 立面图 | `ElevationView` | 墙面正投影图 | 立面展开图 | P0/P1 | D 视图；编辑写回语义 |
| 剖面图 | `SectionView` | 竖直剖切图 | | P1 | 行业 |
| 节点大样 | `DetailDrawing` | 局部构造详图 | 大样图 | Out/P1 | 行业 |
| 天花图 / 顶平面图 | `ReflectedCeilingPlan` | 吊顶与灯位平面 | 天棚图 | P1 | 行业 |
| 地面铺设图 | `FloorFinishPlan` | 地面材料与标高铺设 | 地坪图 | P1 | 行业 |
| 点位图 | `MEPPointPlan` | 强弱电/给排水点位平面 | | P1 | JoyPlan CAD |
| 彩色平面 | `ColorPlan` | 带材质色块的平面表现 | | P1 | JoyPlan |
| 鸟瞰图 | `AxonBirdView` | 轴测/鸟瞰表现 | | P1 | JoyPlan |
| CAD 导出 | `CadExport` / DXF | 矢量 CAD 交换 | | P0 | Deliverables |
| PDF 平面 | `PdfPlan` | 分页平面交付 | | P0 | Deliverables |
| glTF / GLB | `GltfExport` | 三维网格场景交换（只读浏览） | **派生**，非真相 | P0 | A/派生 |
| 材料清单 / 算量 | `TakeoffLine` / BOM | 工程量与材料数量行 | | P1 | D TakeoffQuote |
| 报价单 | `Quote` | 量×单价的商务文件 | 预算报表 | P1 | D |
| 设计说明 | `DesignStatement` | 文字说明设计意图与工艺 | | Out | 行业 |
| 索引符号 | `DrawingIndex` | 图面指向大样/立面的索引 | | Out | 制图 |

---

## 11. 流程节点

| 中文名 | 英文/代码建议名 | 定义 | 同义词/禁混用 | TopoRoom P0/P1/Out | 备注 |
|--------|-----------------|------|---------------|-------------------|------|
| 约量 / 上门量房 | `SurveyAppointment` | 约定实地量房 | | Out | 行业旅程 |
| 实地量房 | `OnSiteSurvey` | 现场完成测绘采集 | | P0 | 行业 |
| 方案确认 | `SchemeApproval` | 业主确认平面/风格/效果 | 签方案 | P1 | 行业 |
| 深化设计 | `DesignDevelopment` | 方案到可施工深度 | | P1 | 行业 |
| 图纸会审 | `DrawingReviewMeeting` | 施工前各方审图对图 | 禁与「设计交底」完全等同 | Out | 行业 |
| 设计交底 | `DesignDisclosure` | 设计方向施工方说明意图与重点 | 技术交底 | Out | 行业 |
| 变更洽商 | `ChangeOrder` / `Variation` | 正式变更手续与签证 | 变更单；口头改图无效 | Out | 行业 |
| 放线 | `SettingOut` | 现场按图弹控制线与完成面线 | | Out | 施工 |
| 水电验收 | `MEPAcceptance` | 隐蔽前水电试压通球等验收 | | Out | 施工 |
| 竣工验收 | `HandoverAcceptance` | 完工交付验收 | | Out | 行业 |
| 断点续扫 | `ResumeCapture` | 采集会话中断后继续 | | P0 | TR 会话 |
| 引导采集 | `GuidedCapture` | 按步骤引导的量房采集 | 校准→外墙→层高→门窗 | P0 | TR+S |

---

## 12. 采集与设备（TopoRoom 特有）

| 中文名 | 英文/代码建议名 | 定义 | 同义词/禁混用 | TopoRoom P0/P1/Out | 备注 |
|--------|-----------------|------|---------------|-------------------|------|
| 采集会话 | `CaptureSession` | 一次进场量房的会话聚合（状态机） | 禁持有网格实体 | P0 | S；非几何真相 |
| 引导步骤 | `GuidedStep` | 会话内一步（校准/外墙/层高/门洞…） | | P0 | S |
| 深度配件 | `DepthAccessory` | Type-C 深度模组等外设 | UVC 深度配件 | P0 | 硬件 |
| 激光测距仪 | `LaserRangefinder` | 蓝牙激光测距仪（尺寸主测） | **Laser only**；禁射频冒充 | P0 | 硬件端口 |
| 配件画像 | `AccessoryProfile` | 白名单机型/固件配置 | | P0 | A |
| 校准 | `Calibration` | 设备与坐标系校准 | | P0 | S |
| 观测证据包 | `EvidencePack` | 关键帧、稀疏深度、平面假设等外置证据 | **非真相源**；可空 | P0 可空 | A/支撑 |
| 轻轨迹 | `TrajectoryLite` | 位姿关键帧轨迹 | 非完整 SLAM 地图 | P0 | S |
| 语义场景 / SceneIR | `SceneIR` | 可编辑语义中间表示（墙房洞层…） | 与 FloorPlanDocument 同真相策略 | P0 | TR 主存 |
| 重建编译 | `ReconstructionCompiler` | 语义→几何网格的编译服务 | | P0 | Domain Service + Port |
| 点云 | `PointCloud` | 密集三维点集合 | **不作真相**；可作证据/衍生 | Out 主路径 | A |
| 3DGS | `GaussianSplat` | 高斯溅射新视表现 | 禁止写回尺寸；非 MVP | Out | A |
| Godot 只读浏览 | `GodotViewer` | 用 glTF 加载的只读查看 | 禁当编辑器 | P0 | A |
| 手机宿主 | `PhoneHost` | 运行采集 App 的手机 | Android 优先白名单 | P0 | 产品 |

---

## 13. 几何与导出（技术边界词）

| 中文名 | 英文/代码建议名 | 定义 | 同义词/禁混用 | TopoRoom P0/P1/Out | 备注 |
|--------|-----------------|------|---------------|-------------------|------|
| 几何端口 | `GeometryPort` | Domain 可见的几何能力接口 | **禁**在聚合内出现 Manifold 类型 | P0 | A 端口；领域只依赖端口 |
| 几何内核 | `GeometryKernel` | 端口背后的实现边界 | | P0 | A |
| 二维截面 DTO | `Section2D` | 墙/房截面的端口 DTO | 禁名 CrossSection 进 Domain | P0 | A DTO |
| 三维实体 DTO | `Solid3D` | 端口侧实体句柄/DTO | 禁名 Manifold 进 Domain | P0 | A DTO |
| 网格投影 | `MeshProjection` / `MeshGL` | 派生三角网格 | **不可编辑真相** | P0 | A |
| 几何缓存 | `GeometryCache` | 按语义 hash 的网格缓存 | 属 Infrastructure | P0 | A |
| 脏区 | `DirtyRegion` | 局部重算范围 | | P0 | A 策略 |
| 布尔开洞 | `BooleanSubtractOpening` | 用洞口体积差集挖墙 | 由编译触发，非用户语言 | P0 | A |
| 挤出 | `Extrude` | 截面沿法向生成实体 | | P0 | A |
| 导出闸门 | `ExportGate` / Fault | 几何 Status 非 OK 时拒绝固体导出 | 语义线可否导出需产品书面确认 | P0 | A+产品 |
| 工具处理器 | `ToolHandler` | UI 工具命令处理 | **非**领域实体 | P0 | S/Application |
| 参数采集状态机 | `ParamGatheringFSM` | 多步点选参数交互态 | 非领域状态 | P0 | S |
| 文档快照 | `DocumentSnapshot` | 只读发布给可视化的投影 | Published Language | P0 | A/集成 |
| 临摹底图 | `TraceOverlay` | 栅格/矢量底图+比例尺描墙 | | P1 | D 轻量 |
| 吸附 / 参考线 | `Snap` / `GuideLine` | 绘图辅助 | snapMm 文档级 | P0/P1 | Application+设置 |

---

## 14. 行业标准用语 ↔ TopoRoom 技术词映射

| 行业说法（优先对用户/工长） | TopoRoom / 代码现用词 | 映射说明 | Domain 还是 Adapter |
|----------------------------|----------------------|----------|---------------------|
| 户型方案 / 设计文档 | `FloorPlanDocument` / SceneIR | 同一可编辑真相；对外说「方案/户型文档」 | Domain |
| 语义中间表示 | `SceneIR` | 对内技术名；对外少说 IR | Domain 序列化形态 |
| 楼层 | `Storey` | 保留 Storey；UI 显示「楼层」 | Domain |
| 墙段 | `Wall` | 一致 | Domain |
| 房间 | `Room` | 一致；须闭合 | Domain |
| 门洞 / 窗洞 / 垭口 | `Opening` + `OpeningType` | **必须细分类型**，避免统称 Opening | Domain |
| 窗台高 | `Opening.sill` / `SillHeight` | 一致 | Domain |
| 层高 | `StoreyHeight` | 勿显示成净高 | Domain |
| 净高 / 净空 | `ClearHeight` | 现文档较少，建议补 VO | Domain |
| 量房 | `Survey` / `CaptureSession` | Survey=业务说法；CaptureSession=会话实现 | 业务 D / 会话 S |
| 激光实测 | `source=laser` | UI：「激光实测」 | Domain 属性 |
| 手工录入 | `source=typed` | UI：「手工录入」 | Domain 属性 |
| 深度推算 / 辅助拟合 | `source=depth_fit` | UI：「深度辅助（未实测）」 | Domain 属性 |
| 量测读数 | `MeasureSample` | 对内；对外「测距记录」 | Session/Port |
| 证据包 | `EvidencePack` | 勿对业主说成「模型」 | Adapter |
| 网格 / 三维模型文件 | `MeshGL` / glTF | 派生浏览件 | Adapter |
| 几何引擎 | `GeometryPort` / manifold | 永不进聚合字段类型 | Adapter |
| 管综 | `MEP` | UI 用「水电/管综」 | Domain（P1） |
| 点位 | `MEPNode` | 一致 | Domain（P1） |
| 回路 | `MEPCircuit` | 一致 | Domain（P1） |
| 软装布置 | `FurnishingLayout` | UI「软装」 | Domain（P1） |
| 定制柜 | `CabinetInstance` | 一致 | Domain（P1） |
| 铺贴 | `TilingSpec` | UI「地面/墙面铺法」 | Domain（P1） |
| 立面 | `ElevationView` | 视图；改洞仍写回墙洞语义 | 视图 / 写回 Domain |
| 出图 | `Deliverable` | UI「导出/出图」 | Domain 规则 + Adapter 格式 |
| 算量 / 报价 | `TakeoffLine` / `Quote` | P1 | Domain（P1） |
| 画墙工具 | `WallDrawTool` / ToolHandler | 工具非实体 | Application |
| 成房 / 闭合 | `RoomClosureService` | UI「识别房间/成房」 | Domain Service |

---

## 15. 推荐替换（当前偏技术/模糊词 → 行业词）

| 当前代码/文档用词 | 问题 | 推荐行业表述（UI/文档/统一语言） | 代码层建议 |
|-------------------|------|----------------------------------|------------|
| `Opening`（统称） | 过粗，工长会问是门还是窗还是垭口 | **门洞 / 窗洞 / 垭口 / 洞口** | `Opening` 保留作基类；必有 `OpeningType`；UI 禁用裸 Opening |
| `Storey` | 英文对业务不友好 | **楼层**；层高/标高分说 | 类名可留 Storey；文案用楼层 |
| `FloorPlan` | 易混「户型图」与「平面布置图」 | 结构语义说**户型**；带家具说**平面布置** | Document 名可留；产品文案区分 |
| `Floor`（若指楼层） | 与楼地面混淆 | 楼层用 Storey；地面用 FloorSurface | 禁止 Floor 同时指两者 |
| `Space` 无类型 | 无法出材料与天花规则 | **空间** + 客厅/卧室…或 SpaceType | 强制 SpaceType/名称 |
| `Measurement source` | 技术枚举直出 | **尺寸来源：激光实测 / 手工录入 / 深度辅助** | 枚举值可英文，UI 中文 |
| `depth_fit` | 像算法黑话 | **深度辅助拟合（非承诺尺寸）** | 内部保留；导出水印中文 |
| `CaptureSession` | 对设计师生硬 | **量房会话 / 本次量房** | 类名可留 |
| `SceneIR` | 对施工零意义 | 对内 SceneIR；对外 **户型语义方案** | 双名并存 |
| `GeometryPort` / `Manifold` | 绝不能进业务会话语境 | 业务说「重建三维 / 更新模型」 | 严格 Adapter |
| `Mesh` 当可编对象 | 破坏尺寸即真相 | **改墙/改洞**，不要「拉网格」 | 禁止 |
| `HostedComponent` | 过抽象 | **梁 / 柱 / 楼梯 / 烟道…** 具体名 | 基类可留；UI 具体 |
| `MEP` 直出 | 英文缩写 | **水电管综**；子系统：**强电 / 弱电 / 水路** | BC 名可 MEP |
| `Fixture`（若用） | 洁具/灯具/末端易混 | 分别：**洁具 / 灯具 / 末端点位** | 拆类型 |
| `Elevation` 仅英文 | | **立面** | |
| `WalkMode` | | **漫游 / 第一人称逛房** | |
| `Takeoff` | 造价黑话 | **算量**；行项目「工程量」 | |
| `TraceOverlay` | | **临摹底图** | |
| `DirtyRegion` | | 对内即可；对外「局部更新」 | Adapter |
| `Boolean` | | 对内；对外「挖门洞/开窗洞」 | Adapter |
| `Extrude` | | 对内；对外「生成墙体三维」 | Adapter |
| `Project` vs `Document` | 易混 | **项目**含多 **方案** | 保持两级 |
| 「扫描完成」 | 暗示点云成品 | **量房采集完成（已生成可编辑户型）** | 话术红线 |
| 「毫米级全屋」无来源 | 违规宣传风险 | 关键尺寸：**以激光/手输为准**；拟合标辅助 | NFR |

---

## 16. Domain 层 vs Adapter/技术层（勿污染清单）

### 16.1 应进入 Domain（业务可说、可持久、可校验不变量）

项目/方案、楼层、层高、墙与墙属性、房间与空间类型、门洞/窗洞/垭口及净宽净高窗台、梁柱烟道等结构构件、尺寸数值与**尺寸来源**、面积（规则明确后）、软装实例与柜体参数（P1）、MEP 点位/管段/回路（P1）、铺贴规格（P1）、交付物类型与「是否允许导出」的业务闸门条件、现场备注。

### 16.2 应留在 Adapter / Infrastructure / 端口

`Manifold` / `CrossSection` / `MeshGL`、具体 CAD SDK、蓝牙协议细节、UVC/深度驱动、Godot Node、点云/LAS/E57/3DGS、Evidence 二进制大对象、GeometryCache、导出文件字节、WASM/线程、Accessory 白名单表实现。

### 16.3 应留在 Application / Interaction（会话态）

`ToolHandler`、`ParamGatheringFSM`、引导步骤进度、未提交的点选草稿、相机漫游姿态、拾取高亮。

---

## 17. 统一语言约定

### 17.1 命名规则

1. **对外（UI、说明书、工长沟通）优先中文行业词**；英文仅作括号补充。  
2. **对内代码**：聚合/实体可用英文（`Wall`/`Storey`）；但 **Opening 必须可映射到门洞/窗洞/垭口**。  
3. **同一概念全链路同名**：文档、事件、`SceneIR` 字段、UI 文案对齐（例：层高≠净高）。  
4. **禁止用实现库名命名领域对象**（Manifold、Godot、Three、MeshGL）。  
5. **事件用业务过去式**：如「门洞已添加」对应 `OpeningAdded`（类型为门）。

### 17.2 单位与精度表达

| 量 | 单位 | 约定 |
|----|------|------|
| 长度/标高/层高/洞口 | **mm** | Document 级单位冻结为 mm；UI 可显示 m 但存储 mm |
| 面积 | m² | 展示一位或两位小数；计面积规则产品确认前标注「投影/套内口径待确认」 |
| 角度 | 度（°） | 斜墙夹角 |
| 吸附步长 | `snapMm` | 文档设置，默认产品自定 |

不编造「必须 ±1mm」等假指标；关键尺寸验收对齐仪具标称误差与产品 NFR。

### 17.3 尺寸来源的行业表述（强制）

| 枚举（代码） | 行业表述（UI） | 可否作为施工/报价承诺尺寸 |
|--------------|----------------|---------------------------|
| `laser` | 激光实测 | 可以（主路径） |
| `typed` | 手工录入 | 可以（须用户明确） |
| `depth_fit` | 深度辅助拟合 | **默认不可以**；除非用户确认降级并水印提示 |

深度拟合**不得静默覆盖**激光来源。

### 17.4 面层口径（量房必问清）

口头「量的是完成面还是结构面」必须可记录：

- **结构面**：毛坯/拆改前结构；  
- **建筑面**：土建找平后（若适用）；  
- **完成面**：饰面后；柜体/门净宽通常按**完成面净距**沟通。

P0 至少支持在文档或量房备注中标记口径；P1 可做成墙厚「结构厚 + 两边饰面厚」参数。

### 17.5 图种称呼约定

| 说法 | 指什么 |
|------|--------|
| 户型图 | 墙体分隔 + 空间名为主，可无家具 |
| 平面布置图 | 户型 + 家具软装布置 |
| 施工图 | 可指导施工的图册（含尺寸、材料、节点、水电等） |
| 效果图 | 视觉参考，**不代替尺寸契约** |
| 点位图 | 水电末端平面 |

### 17.6 与现有反模式对齐（重申）

- 不以 Mesh/点云/GS 为可编辑真相；  
- 不以「扫完」替代「门洞净宽/层高已确认」；  
- 不以射频测距宣传为激光量房；  
- Godot / glTF 只读浏览，不回写尺寸。

---

## 18. 词汇统计（本稿）

| 分类 | 词条（表数据行） |
|------|------------------|
| 1 项目与角色 | 14 |
| 2 空间与户型 | 30 |
| 3 墙体与结构 | 24 |
| 4 门窗洞口 | 23 |
| 5 尺寸与测量 | 24 |
| 6 楼地面天花 | 15 |
| 7 MEP | 20 |
| 8 软装家具 | 13 |
| 9 材质饰面 | 10 |
| 10 图纸与交付物 | 19 |
| 11 流程节点 | 12 |
| 12 采集与设备 | 14 |
| 13 几何与导出 | 15 |
| **分类词条合计（§1–§13）** | **233** |
| 14 映射行 | 28 |
| 15 推荐替换行 | 24 |
| **含映射/替换总行** | **285** |

> 统计为表数据行；同义词列内别名不另计。后续专家建模可裁剪进正式 Domain 词典。

---

## 19. 参考输入（本地）

- `joyplan-prd.md` — 量房/构件/管综/出图/报价旅程用语  
- `FINAL-toporoom-hw-sw-requirements.md` — 激光来源、门洞净宽、层高、瘦 P0  
- `FINAL-toporoom-software-architecture.md` — SceneIR 真相、端口边界  
- `toporoom-ddd-architecture.md` §1 — 已有统一语言种子表  
- `semantic-3d-capture-ddd.md` — CaptureSession / MeasureSample / Evidence  

---

*文档版本：2026-09-16 · 词汇表 only · 未开展聚合建模*
