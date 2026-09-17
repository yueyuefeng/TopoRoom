class_name Tokens
extends Object
## 拓间 design tokens — light “design studio” (量房 / 室内设计).
## 8px grid. Prefer these over ad-hoc ColorRect fills.

# --- Surfaces ---
const BG := Color("F4EEE4")
const BG_GRID := Color("E7DFD2")
const SURFACE := Color("FFFBF6")
const SURFACE_MUTED := Color("F0E8DC")
const SURFACE_ELEVATED := Color("FFFFFF")
const HAIRLINE := Color("E2D6C6")
const INK_FAINT := Color(0.22, 0.18, 0.14, 0.08)

# --- Text ---
const TEXT := Color("2A2622")
const TEXT_SECONDARY := Color("6E675E")
const TEXT_ON_ACCENT := Color("FFF8F2")
const TEXT_DISABLED := Color("A39B92")

# --- Brand / actions ---
const PRIMARY := Color("C45C26")
const PRIMARY_HOVER := Color("B04F1E")
const PRIMARY_SOFT := Color("F6DCCB")
const ACCENT := Color("2F6B5A")
const ACCENT_SOFT := Color("D5E6DF")
const DANGER := Color("C23B2A")
const DANGER_SOFT := Color("F4D4CE")
const SUCCESS := Color("2F7A4A")
const SUCCESS_SOFT := Color("D5E8D8")
const WARNING := Color("C48A22")

# --- 户型图 walls / openings (行业配色) ---
const WALL_SHEAR := Color("E06A3A") ## 承重 / 剪力墙
const WALL_MASONRY := Color("2C2A28") ## 非承重 / 砌体 / 隔墙
const OPENING_DOOR := Color("2F7A4A")
const OPENING_WINDOW := Color("3A7CA5")
const OPENING_ARCH := Color("7A4E8C")
const PAPER := Color("FBF6EE")
const GRID := Color(0.28, 0.24, 0.18, 0.10)
const DIM := Color("8A7F72")

# --- 3D HUD glass ---
const HUD_FILL := Color(0.99, 0.97, 0.93, 0.92)
const HUD_BORDER := Color(0.88, 0.82, 0.74, 0.9)

# --- Type (px) ---
const FONT_DISPLAY := 30
const FONT_TITLE := 22
const FONT_SECTION := 16
const FONT_BODY := 15
const FONT_CAPTION := 12
const FONT_CHIP := 13

# --- Space (8px grid) ---
const S1 := 8
const S2 := 16
const S3 := 24
const S4 := 32
const S5 := 40
const S6 := 48

# --- Radius ---
const R_SM := 8
const R_MD := 12
const R_LG := 16
const R_XL := 20
const R_PILL := 999

const SHADOW := Color(0.18, 0.12, 0.08, 0.14)


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
