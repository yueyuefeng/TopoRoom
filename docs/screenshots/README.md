# Godot 宿主界面预览

JoyPlan 风格量房 UI（PR #11 主题 + PR #12 拍户型图 / 拆改）。像素只作预览；墙段与尺寸来自 SceneIR 命令。

| 文件 | 画面 |
|------|------|
| [01-home.png](./01-home.png) | 首页工作台：新建方案 / 拍户型图 / 引导量房，纸上户型图 |
| [02-guide.png](./02-guide.png) | 引导量房：画墙 → 门窗洞/垭口 → 关键尺寸 |
| [03-photo-pick.png](./03-photo-pick.png) | 拍户型图 · 导入：示例图 / 相册 / 拍照 |
| [04-photo-review-kinds.png](./04-photo-review-kinds.png) | 确认承重：暖橙剪力墙 + 深墨砌体隔墙 |
| [05-demolish.png](./05-demolish.png) | 拆改：整段拆除 / 中点打断 / 局部拆除 / 打门洞 |
| [06-shear-confirm.png](./06-shear-confirm.png) | 承重墙拆除确认（未勾选 force 则 C API 拒绝） |
| [07-edit-3d-day.png](./07-edit-3d-day.png) | 3D 编辑 · 白天：手柄写回命令，网格不是尺寸真相 |
| [08-edit-3d-warm.png](./08-edit-3d-warm.png) | 3D 编辑 · 暖光预设（Visualization-only） |

## 01 首页

![首页工作台](./01-home.png)

## 02 引导量房

![引导量房](./02-guide.png)

## 03 拍户型图 · 导入

![拍户型图导入](./03-photo-pick.png)

## 04 确认承重

FakeVisionAdapter 识别结果：四边承重/剪力墙（暖橙）+ 一道砌体隔墙（深墨）。点墙切换种类。

![确认承重](./04-photo-review-kinds.png)

## 05 拆改

![拆改](./05-demolish.png)

## 06 承重确认

![承重墙拆除确认](./06-shear-confirm.png)

## 07 3D 编辑 · 白天

![3D 编辑白天](./07-edit-3d-day.png)

## 08 3D 编辑 · 暖光

![3D 编辑暖光](./08-edit-3d-warm.png)

这些 PNG 由 `godot/app/capture_ui.gd` 在 Godot 4.3 `gl_compatibility` 下渲染。APK 不入库（`*.apk` gitignore）。
