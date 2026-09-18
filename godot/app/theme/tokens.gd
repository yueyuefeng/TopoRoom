class_name Tokens
extends Object
## 拓间 design tokens — contemporary phone app (soft gray / one blue accent).
## 8px grid. Prefer these over ad-hoc ColorRect fills.

# --- Surfaces ---
const BG := Color("F3F4F6")
const BG_GRID := Color("E8EAED")
const SURFACE := Color("FFFFFF")
const SURFACE_MUTED := Color("F1F3F5")
const SURFACE_ELEVATED := Color("FFFFFF")
const HAIRLINE := Color("E5E7EB")
const INK_FAINT := Color(0.12, 0.14, 0.18, 0.06)

# --- Text ---
const TEXT := Color("1C1C1E")
const TEXT_SECONDARY := Color("6C6C70")
const TEXT_ON_ACCENT := Color("FFFFFF")
const TEXT_DISABLED := Color("AEAEB2")

# --- Brand / actions (single accent) ---
const PRIMARY := Color("3478F6")
const PRIMARY_HOVER := Color("2B68DB")
const PRIMARY_SOFT := Color("E8F0FE")
const ACCENT := Color("3478F6")
const ACCENT_SOFT := Color("E8F0FE")
const DANGER := Color("E5484D")
const DANGER_SOFT := Color("FDECEC")
const SUCCESS := Color("2F9E44")
const SUCCESS_SOFT := Color("E5F6E8")
const WARNING := Color("E0A106")

# --- 户型图 walls / openings (readable on white paper, not CAD chrome) ---
const WALL_SHEAR := Color("E07050") ## 承重 / 剪力墙
const WALL_MASONRY := Color("3D4248") ## 非承重 / 砌体 / 隔墙
const OPENING_DOOR := Color("2F9E44")
const OPENING_WINDOW := Color("3478F6")
const OPENING_ARCH := Color("7A5C9E")
const PAPER := Color("FAFBFC")
const GRID := Color(0.20, 0.22, 0.26, 0.07)
const DIM := Color("8E8E93")

# --- 3D HUD glass ---
const HUD_FILL := Color(1.0, 1.0, 1.0, 0.94)
const HUD_BORDER := Color(0.90, 0.91, 0.93, 0.95)

# --- Page-clone islands (JoyPlan video S2–S7) ---
const PAGE_PINK := Color("E85A8C")
const PAGE_PINK_HOVER := Color("D44878")
const PAGE_GREEN := Color("34C759")
const PAGE_GREEN_HOVER := Color("28A745")
const PAGE_PURPLE := Color("7C5CFF")
const PAGE_DARK := Color(0.16, 0.16, 0.18, 0.94)
const PAGE_DARK_SOFT := Color(0.12, 0.12, 0.14, 0.78)
const PAGE_ISLAND := Color(1, 1, 1, 0.96)
const PAGE_DIM_RED := Color("E23B3B")
const PAGE_WASH := Color(0.95, 0.55, 0.70, 0.16)

# --- Type (px) ---
const FONT_DISPLAY := 32
const FONT_TITLE := 22
const FONT_SECTION := 17
const FONT_BODY := 16
const FONT_CAPTION := 13
const FONT_CHIP := 14

# --- Space (8px grid) ---
const S1 := 8
const S2 := 16
const S3 := 24
const S4 := 32
const S5 := 40
const S6 := 48

# --- Radius ---
const R_SM := 10
const R_MD := 14
const R_LG := 20
const R_XL := 24
const R_PILL := 999

const SHADOW := Color(0.10, 0.12, 0.16, 0.10)


static func is_load_bearing_kind(kind: String) -> bool:
	var k := kind.strip_edges()
	return k == "shearWall" or k == "shear_wall" or k == "exterior"


static func wall_stroke(kind: String) -> Color:
	return WALL_SHEAR if is_load_bearing_kind(kind) else WALL_MASONRY


static func opening_stroke(kind: String) -> Color:
	if kind == "window":
		return OPENING_WINDOW
	if kind == "archway":
		return OPENING_ARCH
	return OPENING_DOOR


static func opening_label(kind: String) -> String:
	if kind == "window":
		return "窗洞"
	if kind == "archway":
		return "垭口"
	if kind == "door":
		return "门洞"
	return kind


static func cjk_font() -> Font:
	var font := SystemFont.new()
	font.font_names = PackedStringArray([
		"Noto Sans CJK SC",
		"Noto Sans CJK",
		"Source Han Sans SC",
		"DroidSansFallback",
		"Noto Sans SC",
		"WenQuanYi Micro Hei",
		"sans-serif",
	])
	font.multichannel_signed_distance_field = false
	return font
