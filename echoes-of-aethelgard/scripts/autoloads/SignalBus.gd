## SignalBus.gd
## Autoload Singleton — Bus de señales globales para desacoplar sistemas.
## Añadir en: Proyecto > Configuración > Autoloads como "SignalBus"
extends Node

# ─── Combate ──────────────────────────────────────────────────────────────────
@warning_ignore("unused_signal")
signal battle_started(stage_data: Dictionary)
@warning_ignore("unused_signal")
signal battle_won(rewards: Dictionary)
@warning_ignore("unused_signal")
signal battle_lost()
@warning_ignore("unused_signal")
signal turn_changed(unit_name: String, is_player: bool)
@warning_ignore("unused_signal")
signal combo_hit(hit_number: int, total_damage: int)

# ─── Héroes ───────────────────────────────────────────────────────────────────
@warning_ignore("unused_signal")
signal hero_unlocked(hero_id: String)
@warning_ignore("unused_signal")
signal hero_leveled_up(hero_id: String, new_level: int)
@warning_ignore("unused_signal")
signal hero_ascended(hero_id: String, new_stars: int)
@warning_ignore("unused_signal")
signal team_changed(team: Array[String])

# ─── Gacha ────────────────────────────────────────────────────────────────────
@warning_ignore("unused_signal")
signal gacha_pull_started(is_multi: bool)
@warning_ignore("unused_signal")
signal gacha_pull_completed(results: Array)
@warning_ignore("unused_signal")
signal pity_milestone(current: int, cap: int)

# ─── Economía ─────────────────────────────────────────────────────────────────
@warning_ignore("unused_signal")
signal currency_changed(currency_type: String, new_amount: int)
@warning_ignore("unused_signal")
signal insufficient_currency(currency_type: String, needed: int, current: int)

# ─── Progresión ───────────────────────────────────────────────────────────────
@warning_ignore("unused_signal")
signal stage_completed(chapter: int, stage: int)
@warning_ignore("unused_signal")
signal chapter_unlocked(chapter: int)
@warning_ignore("unused_signal")
signal stamina_changed(current: int, maximum: int)

# ─── UI / Sistema ─────────────────────────────────────────────────────────────
@warning_ignore("unused_signal")
signal popup_requested(title: String, message: String, type: String)
@warning_ignore("unused_signal")
signal notification_queued(text: String, icon: String, duration: float)
@warning_ignore("unused_signal")
signal settings_changed(setting: String, value: Variant)

# ─── Daily / Rewards ─────────────────────────────────────────────────────────
@warning_ignore("unused_signal")
signal daily_login_reward(day: int, rewards: Dictionary)
@warning_ignore("unused_signal")
signal achievement_unlocked(achievement_id: String)
