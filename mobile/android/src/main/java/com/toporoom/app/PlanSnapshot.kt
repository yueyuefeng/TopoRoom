package com.toporoom.app

data class PlanOpening(
    val id: String,
    val kind: String,
    val offsetMm: Double,
    val widthMm: Double,
    val heightMm: Double = 0.0,
    val sillMm: Double = 0.0,
)

data class PlanWall(
    val id: String,
    val x0: Double,
    val y0: Double,
    val x1: Double,
    val y1: Double,
    val thicknessMm: Double,
    val openings: List<PlanOpening> = emptyList(),
)

data class PlanRoom(
    val id: String,
    val name: String,
    val spaceType: String,
    val clearHeightMm: Double?,
)

data class PlanHosted(
    val id: String,
    val kind: String,
    val zBottomMm: Double = 0.0,
    val depthMm: Double = 0.0,
    val hostWallId: String? = null,
)

data class PlanMeasurement(
    val id: String,
    val valueMm: Double,
    val source: String,
)

data class PlanSnapshot(
    val documentId: String = "",
    val storeyId: String = "",
    val storeyHeightMm: Double = 0.0,
    val walls: List<PlanWall> = emptyList(),
    val rooms: List<PlanRoom> = emptyList(),
    val hosted: List<PlanHosted> = emptyList(),
    val measurements: List<PlanMeasurement> = emptyList(),
) {
    val openingCount: Int get() = walls.sumOf { it.openings.size }
}

internal class JsonLite(private val s: String) {
    private var i = 0

    fun parse(): Any? {
        skipWs()
        if (i >= s.length) return null
        return parseValue()
    }

    private fun parseValue(): Any? {
        skipWs()
        if (i >= s.length) return null
        return when (val c = s[i]) {
            '{' -> parseObject()
            '[' -> parseArray()
            '"' -> parseString()
            't' -> {
                i += 4
                true
            }
            'f' -> {
                i += 5
                false
            }
            'n' -> {
                i += 4
                null
            }
            else -> {
                if (c == '-' || c.isDigit()) parseNumber() else {
                    i += 1
                    null
                }
            }
        }
    }

    private fun parseObject(): Map<String, Any?> {
        expect('{')
        val out = linkedMapOf<String, Any?>()
        skipWs()
        if (peek('}')) {
            i += 1
            return out
        }
        while (i < s.length) {
            skipWs()
            val key = parseString()
            skipWs()
            expect(':')
            out[key] = parseValue()
            skipWs()
            if (peek('}')) {
                i += 1
                break
            }
            expect(',')
        }
        return out
    }

    private fun parseArray(): List<Any?> {
        expect('[')
        val out = mutableListOf<Any?>()
        skipWs()
        if (peek(']')) {
            i += 1
            return out
        }
        while (i < s.length) {
            out.add(parseValue())
            skipWs()
            if (peek(']')) {
                i += 1
                break
            }
            expect(',')
        }
        return out
    }

    private fun parseString(): String {
        expect('"')
        val b = StringBuilder()
        while (i < s.length) {
            val c = s[i]
            i += 1
            when (c) {
                '"' -> return b.toString()
                '\\' -> {
                    if (i >= s.length) break
                    val n = s[i]
                    i += 1
                    b.append(
                        when (n) {
                            'n' -> '\n'
                            't' -> '\t'
                            'r' -> '\r'
                            '"' -> '"'
                            '\\' -> '\\'
                            'u' -> {
                                if (i + 4 <= s.length) {
                                    val hex = s.substring(i, i + 4)
                                    i += 4
                                    hex.toIntOrNull(16)?.toChar() ?: '?'
                                } else '?'
                            }
                            else -> n
                        },
                    )
                }
                else -> b.append(c)
            }
        }
        return b.toString()
    }

    private fun parseNumber(): Double {
        val start = i
        if (peek('-')) i += 1
        while (i < s.length && (s[i].isDigit() || s[i] == '.' || s[i] == 'e' || s[i] == 'E' ||
                s[i] == '+' || s[i] == '-')
        ) {
            i += 1
        }
        return s.substring(start, i).toDoubleOrNull() ?: 0.0
    }

    private fun skipWs() {
        while (i < s.length && s[i].isWhitespace()) i += 1
    }

    private fun peek(c: Char) = i < s.length && s[i] == c

    private fun expect(c: Char) {
        skipWs()
        if (peek(c)) i += 1
    }
}

object SceneIrPlanParser {
    fun parse(json: String?): PlanSnapshot {
        if (json.isNullOrBlank()) return PlanSnapshot()
        val root = JsonLite(json).parse() as? Map<*, *> ?: return PlanSnapshot()
        val storeys = root["storeys"] as? List<*> ?: emptyList<Any?>()
        val storey = storeys.firstOrNull() as? Map<*, *>
        val walls = (storey?.get("walls") as? List<*> ?: emptyList<Any?>()).mapNotNull { wallOf(it) }
        val rooms = (storey?.get("rooms") as? List<*> ?: emptyList<Any?>()).mapNotNull { roomOf(it) }
        val hosted = (storey?.get("hostedComponents") as? List<*> ?: emptyList<Any?>()).mapNotNull {
            hostedOf(it)
        }
        val measurements = (root["measurements"] as? List<*> ?: emptyList<Any?>()).mapNotNull {
            measurementOf(it)
        }
        return PlanSnapshot(
            documentId = str(root["id"]),
            storeyId = str(storey?.get("id")),
            storeyHeightMm = num(storey?.get("heightMm")),
            walls = walls,
            rooms = rooms,
            hosted = hosted,
            measurements = measurements,
        )
    }

    private fun wallOf(raw: Any?): PlanWall? {
        val o = raw as? Map<*, *> ?: return null
        val start = o["start"] as? Map<*, *>
        val end = o["end"] as? Map<*, *>
        val openings = (o["openings"] as? List<*> ?: emptyList<Any?>()).mapNotNull { openingOf(it) }
        return PlanWall(
            id = str(o["id"]),
            x0 = num(start?.get("x")),
            y0 = num(start?.get("y")),
            x1 = num(end?.get("x")),
            y1 = num(end?.get("y")),
            thicknessMm = num(o["thicknessMm"]),
            openings = openings,
        )
    }

    private fun openingOf(raw: Any?): PlanOpening? {
        val o = raw as? Map<*, *> ?: return null
        return PlanOpening(
            id = str(o["id"]),
            kind = str(o["kind"]),
            offsetMm = num(o["offsetMm"]),
            widthMm = num(o["widthMm"]),
            heightMm = num(o["heightMm"]),
            sillMm = num(o["sillHeightMm"]),
        )
    }

    private fun roomOf(raw: Any?): PlanRoom? {
        val o = raw as? Map<*, *> ?: return null
        val clear = o["clearHeightMm"]
        return PlanRoom(
            id = str(o["id"]),
            name = str(o["label"]).ifEmpty { str(o["name"]) },
            spaceType = str(o["spaceType"]).ifEmpty { "interior" },
            clearHeightMm = if (clear == null) null else num(clear),
        )
    }

    private fun hostedOf(raw: Any?): PlanHosted? {
        val o = raw as? Map<*, *> ?: return null
        val params = o["params"] as? Map<*, *>
        return PlanHosted(
            id = str(o["id"]),
            kind = str(o["kind"]),
            zBottomMm = num(o["zBottomMm"]).let { if (it == 0.0) num(params?.get("zBottomMm")) else it },
            depthMm = num(o["depthMm"]).let { if (it == 0.0) num(params?.get("depthMm")) else it },
            hostWallId = str(o["hostWallId"]).ifEmpty { null },
        )
    }

    private fun measurementOf(raw: Any?): PlanMeasurement? {
        val o = raw as? Map<*, *> ?: return null
        return PlanMeasurement(
            id = str(o["id"]),
            valueMm = num(o["valueMm"]),
            source = str(o["source"]),
        )
    }

    private fun str(v: Any?): String = v as? String ?: ""

    private fun num(v: Any?): Double = when (v) {
        is Number -> v.toDouble()
        is String -> v.toDoubleOrNull() ?: 0.0
        else -> 0.0
    }
}

fun phaseLabelZh(phase: String): String = when (phase) {
    "host_check" -> "白名单检查"
    "draw_walls" -> "画墙"
    "measure_keys" -> "关键尺寸"
    "place_openings" -> "门窗洞/垭口"
    "rebuild" -> "重建"
    "export" -> "可导出"
    else -> phase
}

fun blockingReasonZh(reason: String): String = when {
    reason.isEmpty() -> "可以进行下一步"
    reason.contains("whitelist") -> "主机不在 Android 白名单（调试包可用 Fake/Replay）"
    reason.contains("4 walls") -> "请先画至少 4 面墙"
    reason.contains("laser") || reason.contains("typed") ->
        "需要 ≥2 条激光关键尺寸，或手输且勾选确认"
    reason.contains("opening") -> "请至少放置 1 个门窗洞/垭口"
    reason.contains("rebuild") -> "重建成功后才能导出"
    else -> reason
}

fun openingKindZh(kind: String): String = when (kind) {
    "door" -> "门洞"
    "window" -> "窗洞"
    "archway" -> "垭口"
    else -> kind
}

fun hostedKindZh(kind: String): String = when (kind) {
    "beam" -> "梁"
    "column" -> "柱"
    "flue" -> "烟道"
    else -> kind
}
