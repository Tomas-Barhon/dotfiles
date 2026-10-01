#!/usr/bin/env python3
"""Check / apply / revert the omarchy#10661 hotpatch in the live shell.qml.

The Omarchy shell config lives in a pacman-managed, root-owned tree
(/usr/share/omarchy/shell/shell.qml). Any local fix there is silently reverted
by the next `omarchy update`, so this script is idempotent and re-runnable:
run it after every Omarchy upgrade.

Usage:
    patch-omarchy-shell-qml.py --check     # report state, change nothing
    patch-omarchy-shell-qml.py --apply     # write a patched copy to stdout path
    patch-omarchy-shell-qml.py --revert    # write a pristine copy
    patch-omarchy-shell-qml.py --apply --out FILE
    patch-omarchy-shell-qml.py --apply --in-place     # needs root

Exit codes: 0 = done (or already in the requested state), 1 = aborted.
"""

import argparse
import pathlib
import sys

DEFAULT_SHELL = pathlib.Path("/usr/share/omarchy/shell/shell.qml")

# ---------------------------------------------------------------- hunks ----
# Hunk 1: manifestHasKind must not require a real JS Array. A manifest handed
# to the plugin through Quickshell's panel Instantiator arrives as a
# QVariantMap, so `kinds` is a QVariantList: Array.isArray() is false even
# though length + index access work.
HUNK_OLD_1 = """  function manifestHasKind(manifest, kind) {
    return !!manifest && Array.isArray(manifest.kinds)
      && manifest.kinds.indexOf(kind) !== -1
  }
"""
HUNK_NEW_1 = """  function manifestHasKind(manifest, kind) {
    if (!manifest || manifest.kinds == null) return false
    var kinds = manifest.kinds
    // Instantiator modelData turns nested JS arrays into QVariantList:
    // Array.isArray is false, but length + index access still work.
    if (typeof kinds.indexOf === "function") return kinds.indexOf(kind) !== -1
    var n = kinds.length
    if (typeof n !== "number") return false
    for (var i = 0; i < n; i++) {
      if (kinds[i] === kind) return true
    }
    return false
  }
"""

# Hunk 2: capability decisions must run on the registry's raw manifest, which
# always holds real arrays, rather than on a copy that may have crossed a Qt
# model boundary. Without this, the panel loader replaces the correct cached
# API with an appLibrary-less one ~1s after startup.
HUNK_OLD_2 = """    return shell.createScopedPluginShell(manifest, key, true, shell.pluginHasBarCapabilities(manifest))
  }
"""
HUNK_NEW_2 = """    // A manifest handed through a QObject model (e.g. the panel
    // Instantiator's modelData) arrives as a QVariantMap: nested arrays are
    // no longer JS Arrays, so kind checks would under-declare capabilities.
    // The registry always holds the raw manifest for this id; prefer it.
    var raw = shell.pluginRegistry ? shell.pluginRegistry.installedPlugins[key] : null
    var resolved = raw && raw.id === key ? raw : manifest
    return shell.createScopedPluginShell(resolved, key, true, shell.pluginHasBarCapabilities(resolved))
  }
"""

PATCH = [(HUNK_OLD_1, HUNK_NEW_1), (HUNK_OLD_2, HUNK_NEW_2)]

SENTINEL = "// Instantiator modelData turns nested JS arrays into QVariantList:"


def classify(text):
    """Count how many patched hunks are present -> 'patched' | 'pristine' | 'mixed:<n>'."""
    applied = sum(1 for _, new in PATCH if new in text)
    if applied == len(PATCH):
        return "patched"
    if applied == 0:
        return "pristine"
    return "mixed:%d/%d" % (applied, len(PATCH))


def swap(text, forward):
    """Replace every hunk (forward=True) or restore it (forward=False)."""
    pairs = PATCH if forward else [(new, old) for old, new in PATCH]
    for old, new in pairs:
        hits = text.count(old)
        if hits != 1:
            sys.exit(
                "ABORT: hunk matched %d times (expected exactly 1).\n"
                "Upstream changed this file — re-read the current function and\n"
                "update this script rather than forcing a partial patch.\n\n%s"
                % (hits, old)
            )
        text = text.replace(old, new)
    return text


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--shell", type=pathlib.Path, default=DEFAULT_SHELL)
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--revert", action="store_true")
    ap.add_argument("--out", type=pathlib.Path)
    ap.add_argument("--in-place", action="store_true")
    args = ap.parse_args()

    if not args.shell.is_file():
        sys.exit("not found: %s" % args.shell)

    text = args.shell.read_text()
    state = classify(text)

    if args.check:
        print("%s: %s" % (args.shell, state))
        print(
            "-> app list works for third-party/cloned menu plugins"
            if state == "patched"
            else "-> BUG #10661 WILL REGRESS: re-apply with --apply"
        )
        return 0

    if args.revert:
        if state == "pristine":
            print("already unpatched; nothing to do")
            return 0
        out = swap(text, forward=False)
    elif args.apply:
        if state == "patched":
            print("already patched; nothing to do")
            return 0
        out = swap(text, forward=True)
    else:
        ap.error("one of --check / --apply / --revert is required")

    if args.in_place:
        args.shell.write_text(out)
        print("wrote %s" % args.shell)
        return 0

    dest = args.out or (pathlib.Path.cwd() / args.shell.name)
    dest.write_text(out)
    print("wrote %s" % dest)
    return 0


if __name__ == "__main__":
    sys.exit(main())