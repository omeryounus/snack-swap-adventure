#!/usr/bin/env python3
"""Cross-checks IAP product IDs across the code, the StoreKit config and the docs.

A mismatch here is silent and expensive: Product.products(for:) simply returns
nothing, every buy button goes dead, and the shop falls back to placeholder
prices. That is exactly how the stars.500 / stars60 drift went unnoticed.

Run from the repo root:  python3 scripts/verify_products.py
"""

import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
STORE_MANAGER = ROOT / "SnackSwapAdventure/SnackSwapAdventure/Managers/StoreManager.swift"
STOREKIT_CONFIG = ROOT / "SnackSwapAdventure/Configuration.storekit"
TESTFLIGHT_DOC = ROOT / "TESTFLIGHT.md"

PRODUCT_RE = re.compile(r'static let \w+ = "(com\.snackswap\.adventure\.[\w.]+)"')
PACK_RE = re.compile(
    r'StarPack\(id:\s*ProductIDs\.(\w+),\s*stars:\s*(\d+),\s*title:\s*"([^"]+)"'
)


def fail(msg: str) -> None:
    print(f"FAIL {msg}")


def main() -> int:
    failures = 0

    swift = STORE_MANAGER.read_text()
    code_ids = set(PRODUCT_RE.findall(swift))
    if not code_ids:
        print("FAIL could not parse product IDs from StoreManager.swift")
        return 1

    config = json.loads(STOREKIT_CONFIG.read_text())
    config_ids = {p["productID"] for p in config.get("products", [])}

    print("StoreManager.swift product IDs:")
    for pid in sorted(code_ids):
        print(f"  {pid}")

    missing = code_ids - config_ids
    for pid in sorted(missing):
        fail(f"{pid} requested by the app but absent from Configuration.storekit")
        failures += 1

    extra = config_ids - code_ids
    for pid in sorted(extra):
        fail(f"{pid} defined in Configuration.storekit but never requested by the app")
        failures += 1

    # A bundle must credit exactly what its title advertises.
    for name, stars, title in PACK_RE.findall(swift):
        digits = re.sub(r"[^0-9]", "", title)
        if digits != stars:
            fail(f'star pack "{title}" credits {stars} stars')
            failures += 1
        else:
            print(f'  pack "{title}" credits {stars} — consistent')

    if TESTFLIGHT_DOC.exists():
        doc = TESTFLIGHT_DOC.read_text()
        for pid in sorted(code_ids):
            if pid not in doc:
                fail(f"{pid} is not documented in TESTFLIGHT.md")
                failures += 1

    if failures:
        print(f"\n{failures} product configuration problem(s)")
        return 1
    print("\nProduct IDs agree across code, StoreKit config and docs")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
