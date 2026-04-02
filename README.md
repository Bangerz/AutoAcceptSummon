# Auto Accept Summon

World of Warcraft **retail** addon (Midnight / 12.x interface). When someone summons you, it **accepts automatically once only a little time is left** on the summon timer, so you can still cancel early or accept manually.

## Behavior

- Watches `CONFIRM_SUMMON` and polls `C_SummonInfo.GetSummonConfirmTimeLeft()`.
- **Default:** accepts when **5 seconds** or fewer remain (and you are **not in combat**).
- **Configurable:** any whole number from **5** to **120** seconds.
- If you **accept** or **decline** before that window, the addon does nothing further for that summon.
- Adds a **countdown line** on the summon dialog (time until auto-accept, combat pause, or “Auto-accepting…”).

## Install

Copy the `AutoAcceptSummon` folder into:

`World of Warcraft\_retail_\Interface\AddOns\`

Enable **Auto Accept Summon** in the AddOns list and `/reload` if needed.

## Commands

| Command | Description |
|--------|-------------|
| `/aas` | Show current threshold and usage |
| `/autoacceptsummon` | Same as `/aas` |
| `/aas 30` | Auto-accept when 30 seconds remain (must be 5–120) |

Settings are stored in `AutoAcceptSummonDB` (SavedVariables).

## Author

**Bangerz-DarkIron**

## License

See [LICENSE](LICENSE) (CC0 1.0).
