# 拓间 TopoRoom — FINAL 交付索引

> **日期**：2026-09-15  
> **裁决**：四专家均为 **Go-with-changes**（已吸收进 FINAL）  
> **用途**：一页纸导航；实施与验收以 FINAL 两篇为准。

---

## 读哪两篇

| 文档 | 路径 | 内容 |
|------|------|------|
| **A. 软硬件需求** | [FINAL-toporoom-hw-sw-requirements.md](./FINAL-toporoom-hw-sw-requirements.md) | 定位/In-Out、FR/NFR、硬件 BOM 与门径、精度 SLA 与话术红线、SceneIR 要点、里程碑、开放问题、表决表 |
| **B. 软件架构** | [FINAL-toporoom-software-architecture.md](./FINAL-toporoom-software-architecture.md) | 不变量、BC 全景、组件/内部/序列/集成/部署/数据流 **ASCII 图**、端口契约、gotbot×manifold、P0 包结构 |

---

## 辩论与评审（输入归档）

| 文件 | 角色 |
|------|------|
| [debate/01-product-expert.md](./debate/01-product-expert.md) | 产品与验收 |
| [debate/02-hardware-expert.md](./debate/02-hardware-expert.md) | 深度模组 / 激光 / Stage-Gate |
| [debate/03-ddd-expert.md](./debate/03-ddd-expert.md) | BC / 事件 / ACL |
| [debate/04-geometry-godot-expert.md](./debate/04-geometry-godot-expert.md) | GeometryPort / glTF / Godot |
| [architecture-optimization-review.md](./architecture-optimization-review.md) | O1–O10 优化基线 |

旧长文（`toporoom-ddd-architecture.md`、`semantic-3d-capture-ddd.md` 等）作历史参考；**与 FINAL 冲突时以 FINAL 为准**。

---

## 六条硬裁决（勿再争论）

1. **SceneIR** = 唯一真相  
2. **瘦 P0**（无 MEP/软装/云/报价阻断）  
3. **激光**进 P0 关键尺寸；禁射频主测  
4. **Godot 只读**  
5. **禁 GS/视频写回尺寸**  
6. **Android 白名单 + 外购 Type-C 深度**

---

## 建议阅读顺序

1. 本页硬裁决  
2. 需求 A §2–3、§5、§8、§10  
3. 架构 B §0–1、§4、§9、§12  
4. 需要时再查 `debate/` 原文论据  

---

*索引结束。*
