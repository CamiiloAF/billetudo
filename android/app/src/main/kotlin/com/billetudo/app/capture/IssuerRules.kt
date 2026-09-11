package com.billetudo.app.capture

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * Kotlin half of the parsing catalog.
 *
 * The rules themselves are NOT here: they live in the single source of truth
 * `assets/capture/issuer_rules.json`, which the Dart mirror engine reads too
 * (see `lib/features/capture/domain/usecases/parse_bank_notification.dart`).
 * Only the engine is duplicated. If you add a rule, add it to the JSON and to
 * the Dart test battery — never to one side alone.
 */

/** What a rule does when it matches. */
enum class RuleAction { CAPTURE, IGNORE }

/**
 * Which part of the notification the regex runs against. Declared per rule
 * because issuers disagree: Nu puts the amount in the title and the
 * counterparty in the body, Nequi hides the amount mid-sentence in the body,
 * and Google Wallet puts the merchant in the title and everything else in the
 * body.
 */
enum class RuleTarget { TITLE, TEXT, COMBINED }

/**
 * A regex whose named groups have been rewritten into plain numbered groups.
 *
 * Why: `minSdk` of this app is 24, and `Matcher.group(String)` — the accessor
 * for `(?<name>...)` — only exists from API 26. Instead of dropping named
 * groups from the JSON (which would make the rules unreadable and would break
 * parity with the Dart engine, where they work natively), the names are
 * stripped at load time and resolved to their group INDEX here. Behaviour is
 * identical on every supported Android version.
 */
class NamedRegex(pattern: String) {
    private val nameToIndex = mutableMapOf<String, Int>()
    private val regex: Regex

    init {
        val rewritten = StringBuilder()
        var groupIndex = 0
        var i = 0
        var insideCharClass = false
        while (i < pattern.length) {
            val c = pattern[i]
            when {
                // An escaped character is copied verbatim: `\(` is a literal
                // parenthesis, not a group.
                c == '\\' && i + 1 < pattern.length -> {
                    rewritten.append(c).append(pattern[i + 1])
                    i += 2
                }
                insideCharClass -> {
                    if (c == ']') insideCharClass = false
                    rewritten.append(c)
                    i++
                }
                c == '[' -> {
                    insideCharClass = true
                    rewritten.append(c)
                    i++
                }
                c == '(' -> {
                    // `(?<name>` is a capturing group; `(?<=` and `(?<!` are
                    // lookbehind and are NOT.
                    val isNamedGroup = pattern.startsWith("(?<", i) &&
                        i + 3 < pattern.length &&
                        pattern[i + 3] != '=' && pattern[i + 3] != '!'
                    when {
                        isNamedGroup -> {
                            val close = pattern.indexOf('>', i + 3)
                            require(close > 0) { "unterminated group name in: $pattern" }
                            groupIndex++
                            nameToIndex[pattern.substring(i + 3, close)] = groupIndex
                            rewritten.append('(')
                            i = close + 1
                        }
                        // Any other `(?...` construct is non-capturing.
                        pattern.startsWith("(?", i) -> {
                            rewritten.append("(?")
                            i += 2
                        }
                        else -> {
                            groupIndex++
                            rewritten.append('(')
                            i++
                        }
                    }
                }
                else -> {
                    rewritten.append(c)
                    i++
                }
            }
        }
        regex = Regex(rewritten.toString(), RegexOption.IGNORE_CASE)
    }

    fun find(input: String): MatchResult? = regex.find(input)

    /** Value of the group a rule declared under [name], or null. */
    fun group(match: MatchResult, name: String): String? {
        val index = nameToIndex[name] ?: return null
        return match.groups[index]?.value
    }
}

/** One parsing rule, as declared in the JSON. */
data class IssuerRule(
    val ruleId: String,
    val priority: Int,
    val action: RuleAction,
    val target: RuleTarget,
    /** `income` / `expense` / `transfer`; null for ignore rules. */
    val entryType: String?,
    /** field name (`amount`, `merchant`, `last4`, `currency`, `cardNetwork`) -> group name. */
    val captures: Map<String, String>,
    val regex: NamedRegex,
)

/** One catalogued issuer and its rules. */
data class IssuerDefinition(
    val issuerId: String,
    val displayName: String,
    val packageNames: List<String>,
    val defaultCurrency: String,
    val rules: List<IssuerRule>,
)

/** The whole catalog. */
data class IssuerRuleSet(
    val globalIgnoreRules: List<IssuerRule>,
    val issuers: List<IssuerDefinition>,
) {
    /**
     * The issuer that owns [packageName], or null.
     *
     * Comparison is EXACT and case-sensitive on purpose: `com.nequi.MobileApp`
     * really is capitalized and Wallet really is `walletnfcrel`, not `wallet`.
     * A typo here captures nothing and reports nothing — that silence is the
     * price of never guessing which app sent something.
     */
    fun issuerForPackage(packageName: String): IssuerDefinition? =
        issuers.firstOrNull { it.packageNames.contains(packageName) }
}

/**
 * Reads and caches the catalog from the Flutter asset bundle.
 *
 * The service may start with no Flutter engine alive, so the asset is opened
 * straight from `AssetManager` at the path Flutter packs it into.
 */
object IssuerRulesLoader {
    /** Must match the `assets:` entry in `pubspec.yaml`. */
    private const val ASSET_PATH = "flutter_assets/assets/capture/issuer_rules.json"

    @Volatile
    private var cached: IssuerRuleSet? = null

    fun load(context: Context): IssuerRuleSet {
        cached?.let { return it }
        synchronized(this) {
            cached?.let { return it }
            val raw = context.assets.open(ASSET_PATH).bufferedReader().use { it.readText() }
            val parsed = parse(JSONObject(raw))
            cached = parsed
            return parsed
        }
    }

    private fun parse(json: JSONObject): IssuerRuleSet = IssuerRuleSet(
        globalIgnoreRules = parseRules(json.optJSONArray("globalIgnoreRules")),
        issuers = buildList {
            val issuers = json.getJSONArray("issuers")
            for (i in 0 until issuers.length()) {
                val issuer = issuers.getJSONObject(i)
                add(
                    IssuerDefinition(
                        issuerId = issuer.getString("issuerId"),
                        displayName = issuer.getString("displayName"),
                        packageNames = buildList {
                            add(issuer.getString("packageName"))
                            val extra = issuer.optJSONArray("additionalPackageNames")
                            if (extra != null) {
                                for (j in 0 until extra.length()) add(extra.getString(j))
                            }
                        },
                        defaultCurrency = issuer.optString("defaultCurrency", "COP"),
                        rules = parseRules(issuer.getJSONArray("rules")),
                    ),
                )
            }
        },
    )

    private fun parseRules(array: JSONArray?): List<IssuerRule> = buildList {
        if (array == null) return@buildList
        for (i in 0 until array.length()) {
            val rule = array.getJSONObject(i)
            val captures = mutableMapOf<String, String>()
            rule.optJSONObject("captures")?.let { json ->
                json.keys().forEach { key -> captures[key] = json.getString(key) }
            }
            add(
                IssuerRule(
                    ruleId = rule.getString("ruleId"),
                    priority = rule.optInt("priority", 0),
                    action = if (rule.optString("action", "capture") == "ignore") {
                        RuleAction.IGNORE
                    } else {
                        RuleAction.CAPTURE
                    },
                    target = when (rule.optString("target", "combined")) {
                        "title" -> RuleTarget.TITLE
                        "text" -> RuleTarget.TEXT
                        else -> RuleTarget.COMBINED
                    },
                    entryType = if (rule.isNull("entryType")) null else rule.optString("entryType", null),
                    captures = captures,
                    regex = NamedRegex(rule.getString("match")),
                ),
            )
        }
    }
}
