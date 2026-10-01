---
name: omarchy-shell-hotpatches
description: >
  Runbook for local hotfixes to the Omarchy Quickshell shell config
  (/usr/share/omarchy/shell/shell.qml), which pacman owns and every
  `omarchy update` silently reverts. Use when an Omarchy menu, app launcher,
  bar widget or panel plugin misbehaves in a way that stock omarchy should not
  — especially an EMPTY "Apps" list in the Super+Alt+Space menu, or any symptom
  that appeared right after an Omarchy upgrade. Triggers: app launcher shows no
  apps, menu Apps list empty, "Nothing here yet", cloned or third-party menu
  plugin broken, omarchy.menu / tomikkdyne.menu / *.menu clone, appLibrary null,
  my omarchy fix disappeared after update, QVariantMap, panel Instantiator.
  NOT for upstream Omarchy source development via `omarchy dev link`.
---

# Omarchy shell hotpatches

Omarchy's shell is a Quickshell config living in a **pacman-managed, root-owned**
tree. Nothing you change there survives an upgrade:

```
$OMARCHY_PATH/shell/shell.qml          # /usr/share/omarchy/shell/shell.qml
```

`OMARCHY_PATH` is authoritative — read it from the session, not from a terminal,
because it disagrees with `$OMARCHY_PATH` after `omarchy dev link/unlink`:

```
systemctl --user show-environment | sed -n 's/^OMARCHY_PATH=//p' | tail -n1
```

Note: `~/.local/share/omarchy/` may hold a stale copy of the same tree. It is
**not** the live path unless the session says so. Do not patch it.

## When to use this skill

Reach for it when a shell plugin misbehaves and the same setup works on stock
omarchy. Before assuming a local patch is needed, check the upstream tracker —
if the bug is already fixed upstream, upgrading is the real fix.

## Bug #10661 — third-party menu plugin gets an empty Apps list

**Symptom.** Super+Alt+Space opens the menu, but "Apps..." shows
"Nothing here yet" / an empty list. Only happens with a **cloned or third-party**
menu plugin (e.g. `~/.config/omarchy/plugins/tomikkdyne.menu` with
`"omarchy": { "clonedFrom": "omarchy.menu" }`).

**Confirm it is this bug, not missing app data.** App data should be plentiful:

```
ls /usr/share/omarchy/applications/*.desktop | wc -l   # ~16
ls /usr/share/applications/*.desktop | wc -l           # ~95
omarchy-shell shell listPlugins | python3 -m json.tool | grep -A3 tomikkdyne.menu
```

The plugin must appear with `"firstParty": false` and `"kinds": ["menu", ...]`.

**Why first-party menus are unaffected.** `pluginShellFor()` short-circuits on
`manifest.__isFirstParty` and hands back the shared host shell. Booleans survive
the Qt round-trip, so stock menus never hit the trap below.

### Root cause in one paragraph

The panel loader calls `shell.pluginShellFor(panelEntry.manifest)`, where
`manifest` is `modelData` from a Quickshell `Instantiator`. Having crossed a Qt
model boundary it arrives as a `QVariantMap`: nested `kinds` is a `QVariantList`,
not a JS Array. So `Array.isArray(manifest.kinds)` is **false**, `manifestHasKind`
reports no `"menu"` kind, and `createScopedPluginShell` builds the plugin API with
`appLibrary: null`. The menu's `mergeAppRows()` then early-returns on
`if (!root.appLibrary) return`. Because `pluginShellCapabilityProfile` also derives
from `manifestHasKind`, the capability cache gets poisoned too: a correct API built
via the bar path is revoked and replaced ~1s after startup when the panel model
delivers.

### The fix (upstream PR #10785, targets branch `quattro`)

Two hunks, both in `shell.qml`:

1. `manifestHasKind` — duck-type instead of `Array.isArray`, so a `QVariantList`
   `kinds` (length + index access, no `indexOf`) still matches.
2. `pluginShellFor` — prefer the registry's raw manifest
   (`shell.pluginRegistry.installedPlugins[key]`) over the `modelData` copy, since
   the registry always holds real JS arrays.

Hunk 1 alone is enough to restore the app list; hunk 2 stops the capability cache
being poisoned. Apply both.

### Apply it

`patch-omarchy-shell-qml.py` sits next to this file. It is idempotent and
re-runnable, and aborts loudly rather than half-patching if upstream changed the
surrounding code.

```bash
S=~/.config/opencode/skills/omarchy-shell-hotpatches/patch-omarchy-shell-qml.py

python3 "$S" --check                       # current state: patched | pristine | mixed
python3 "$S" --apply --out /tmp/shell.qml  # writes a patched copy (no root needed)

# install it (needs your password):
sudo cp -a /usr/share/omarchy/shell/shell.qml /usr/share/omarchy/shell/shell.qml.bak
sudo install -m 644 /tmp/shell.qml /usr/share/omarchy/shell/shell.qml

omarchy restart shell
```

`--in-place` writes straight to the live file (still needs root).
`--revert` restores the stock function bodies byte-for-byte.

**If the script aborts with "hunk matched 0 times":** upstream rewrote those
functions. Re-read the current `manifestHasKind` and `pluginShellFor` in the live
`shell.qml`, update the `PATCH` list in the script, and re-run. Do not force it.

### Verify without sudo

The plugin lives in user config, so instrument the clone rather than the shell.
Add to `mergeAppRows()` in the clone's `Menu.qml`, right after the guard:

```qml
console.warn("APPLIB-DEBUG appLibrary=" + (root.appLibrary ? "present" : "NULL")
  + " rows=" + (root.appLibrary ? root.appLibrary.sortedEntries("").length : -1))
```

```bash
omarchy restart shell
omarchy-shell shell toggle tomikkdyne.menu '{"menu":"apps"}'
journalctl --user --since "-30s" --no-pager | grep APPLIB-DEBUG
```

Healthy output: `appLibrary=present rows=54`. Bug present: `appLibrary=NULL`.
Revert the instrumentation afterwards (`diff` the clone against
`$OMARCHY_PATH/shell/plugins/menu/Menu.qml` to confirm it is pristine).

If the CLI cannot read images, a screenshot is not a verification method here —
the journal line above is.

### Sudo-free workaround

Re-enable the stock menu in `~/.config/omarchy/shell.json`: drop the clone id from
`bar.layout`, remove it from `disabledPlugins`, and remove `"omarchy.menu"` from
`disabledPlugins`. First-party menus are immune to this bug. Only worth it if
sudo is unavailable — the clone is then your customization base again.

### After every `omarchy update`

Run `python3 "$S" --check`. If it reports anything but `patched`, re-apply.
Delete the patch once the installed omarchy version contains the upstream fix.

## Adding a new hotpatch to this skill

1. Confirm it is an omarchy bug, not local misconfiguration, and check upstream.
2. Prefer a fix inside `~/.config/omarchy/` (yours, survives upgrades). Only fall
   back to patching `$OMARCHY_PATH` when there is no user-level hook.
3. Add the hunks as exact-match `(old, new)` string pairs to `PATCH` in
   `patch-omarchy-shell-qml.py` — never line numbers, which drift.
4. Round-trip test it against a stock copy before installing:
   `--revert` then `--apply` must reproduce the file byte-for-byte.
5. Document symptom, upstream link, and a sudo-free verification here.

## Other shell IPC worth knowing

```
omarchy-shell shell ping
omarchy-shell shell listPlugins        # includes kinds/enabled/firstParty/clonedFrom
omarchy-shell shell listShellConfig
omarchy-shell shell toggle <id> '{"menu":"apps"}'
omarchy-shell shell summon <id> '{"menu":"apps"}'
```

There is **no** IPC method that exposes a plugin's `appLibrary`, which is why
verification goes through plugin-side logging.