# TopoRoom Domain 模型 — 阅读索引

> 终稿：[`FINAL-toporoom-domain-model.md`](./FINAL-toporoom-domain-model.md)  
> 词汇真源：[`toporoom-industry-ubiquitous-language.md`](./toporoom-industry-ubiquitous-language.md)  
> 日期：2026-09-16（Asia/Shanghai）

## 建议阅读顺序

1. **词汇** — `toporoom-industry-vocab-readme.md` → UL 主表（尤其 §2–§5、§14–§17）  
2. **需求边界** — `FINAL-toporoom-hw-sw-requirements.md`（瘦 P0、激光、FR）  
3. **软件 BC 全景** — `FINAL-toporoom-software-architecture.md` §1–§3  
4. **专家辩论（可选）**  
   - `debate-domain/01-product-domain-expert.md` — P0 必现行业词 / 验收  
   - `debate-domain/02-survey-measure-expert.md` — 量房、层高/净高、来源  
   - `debate-domain/03-hardfit-structure-expert.md` — 墙梁洞房、门窗垭口  
   - `debate-domain/04-ddd-strategist.md` — BC / 聚合 / ACL / 冲突决议  
5. **合成终稿** — `FINAL-toporoom-domain-model.md`（Domain 层唯一建模结论）

## 终稿里看什么

| 需求 | 章节 |
|------|------|
| P0 Domain 词典 | §1 |
| BC 图 | §2 |
| 聚合 / 事件 / 服务 | §3 |
| 不变量 | §4 |
| 旧名→行业名 | §5 |
| 什么不进 Domain | §6 |
| SceneIR 0.2 additive | §7 |
| Domain 包草图 | §8 |

## 五条记牢

1. **门洞 / 窗洞 / 垭口** 必须可区分（`OpeningKind`）。  
2. **层高 ≠ 净高**；**户型图 ≠ 平面布置图**。  
3. 方案/户型文档 = `FloorPlanDocument` / SceneIR 真相。  
4. Manifold / glTF / BLE / Godot **不进** Domain。  
5. 尺寸来源 UI：激光实测 / 手工录入 / 深度辅助。

## 与旧 DDD 文关系

| 文件 | 关系 |
|------|------|
| `toporoom-ddd-architecture.md` | 战术种子；**Domain 用语与 Opening/净高以本 FINAL 为准** |
| `semantic-3d-capture-ddd.md` | 量房会话 / MeasureSource；并入本 FINAL §3.2、§7 |
| `FINAL-toporoom-software-architecture.md` | BC 拓扑仍有效；本 FINAL 做行业化 re-enrich |
