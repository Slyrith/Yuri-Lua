# Your first Yuri script

You do not need to understand the manifest format to begin.

## 1. Create it in Yuri

1. Open **Script library → New script** in Yuri Launcher 0.11.0 or later.
2. Give it a name and enter your creator name.
3. Leave the template on **Hello — a button and message** and click **Create script**.
4. Click **Open its folder**. Open `main.lua` in your text editor (VS Code is useful, but not required).
5. Find your script under **Installed → Review & enable**, review its permissions, and enable it. Scripts start OFF.

Yuri already filled in `script.json`. You mainly work in `main.lua`:

```lua
local message = yuri.label("Ready!")

yuri.button("Say hello", function()
    message:set_text("My script works!")
    yuri.notify("Hello!")
end)
```

Change the words inside quotes, save the file, then reload/review the changed version. Changed source invalidates old approval; the running version may stop before you press Reload. That is expected.

## 2. Understand the three parts

- `local message` remembers the label so your script can change it later.
- `yuri.button` creates a button. Yuri gives simple controls their own IDs automatically.
- `function() ... end` says what happens when someone clicks it. It does not run immediately when the script loads.

You can use `message:set_text("New text")` or `message.set_text("New text")`. Both styles work for the handle methods in this SDK.

## 3. Try a toggle

```lua
yuri.toggle("Enable greeting", false, function(enabled)
    if enabled then
        yuri.notify("Greeting is enabled")
    end
end)
```

The `false` value means it begins OFF. The callback receives `true` or `false` after the user changes it. Programmatically calling `control:set(value)` does not call that callback again.

## 4. Repeat something without freezing Yuri

```lua
local enabled = yuri.toggle("Remind me", false)

local cancel = yuri.every(30, function()
    if enabled:get() then
        yuri.notify("Time for a break!")
    end
end)

-- Call cancel() when you want to stop that timer.
```

Timers are checked by host ticks, roughly once per second. A timer is not an exact clock, and missed ticks do not produce a burst of catch-up calls. Disabling the script stops its worker and all its timers.

## 5. Save a setting

Choose the **Save a setting** template; it includes `storage` permission:

```lua
local level = yuri.slider("My setting", 1, 10, yuri.settings.get("level", 5))

level:on_change(function(value)
    yuri.settings.set("level", value)
    print("Saved:", value)
end)
```

The `5` is the fallback if no value has been saved. Settings accept numbers, true/false and text. `print` and `yuri.log` appear in Yuri's local activity/logging view, under Settings → Logging. They do not print to the game chat.

## Files you will see

| File | What it does |
| --- | --- |
| `main.lua` | Your script's behavior. Start here. |
| `script.json` | Name, creator, supported game, API version and requested permissions. Yuri creates it for you. |
| `.luarc.json` | Editor hints so VS Code's Lua extension can find the bundled API declarations. |
| `Locales/` | Optional script translations; you can ignore this when starting. |

## If something goes wrong

| Message / symptom | What to check |
| --- | --- |
| `main.lua:12` | Open line 12 of your script. The line refers to your file, not a hidden wrapper. |
| Expected text | Labels and messages need quotes: `"Hello"`. |
| An unavailable/nil module | Check spelling and `script.json` permissions. UI uses `ui`, notifications use `notifications`, saved settings use `storage`. |
| Callback needs a function | Use `function(value) ... end`, not the result of calling a function immediately. |
| Changed version / disabled script | Review the new source version before enabling it again. |
| Slider value outside bounds | Keep it between its minimum and maximum. |
| Worker deadline / instruction budget | Avoid endless loops. Use events and timers instead. |

## What this SDK can do today

API 1.1 adds easier authoring to the existing foundation: controls, notifications, settings, timers, logging and events. It does not yet expose game entities, farming actions, combat modifications or custom gameplay ESP. Those need tested game adapters. Pick a supported template, make it work, then consult [API.md](API.md) and [ROADMAP.md](ROADMAP.md).
