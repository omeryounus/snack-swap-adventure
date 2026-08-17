#!/usr/bin/env python3
"""Mirrors PlayfieldGeometry and fails if any reference device overlaps.

Sweeps every device size against every transient-HUD-row count, because the
Sugar Rush banner and hammer prompt are what used to push the HUD onto the
board.
"""

from dataclasses import dataclass


MIN_BOARD = 168.0
PORTRAIT_TOP_RATIO = 0.02
LANDSCAPE_MIN_SIDEBAR = 140.0
LANDSCAPE_MAX_SIDEBAR_PHONE = 260.0
LANDSCAPE_MAX_SIDEBAR_PAD = 320.0
LANDSCAPE_SECTION_GAP_RATIO = 0.10
HUD_ACCESSORY_ROW_HEIGHT = 34.0
HUD_ACCESSORY_RESERVE_ROWS = 2.0
ACCESSORY_ROW_CASES = (0, 1, 2)


@dataclass
class Rect:
    x: float
    y: float
    w: float
    h: float

    @property
    def max_x(self) -> float:
        return self.x + self.w

    @property
    def max_y(self) -> float:
        return self.y + self.h

    def inset(self, d: float) -> "Rect":
        return Rect(self.x + d, self.y + d, max(0.0, self.w - 2 * d), max(0.0, self.h - 2 * d))

    def intersects(self, other: "Rect") -> bool:
        return self.x < other.max_x and self.max_x > other.x and self.y < other.max_y and self.max_y > other.y

    def contained_in(self, width: float, height: float, tol: float = 0.5) -> bool:
        return (
            self.x >= -tol
            and self.y >= -tol
            and self.max_x <= width + tol
            and self.max_y <= height + tol
        )


def portrait(width: float, height: float, is_pad: bool, accessories: float):
    pad = 12.0 if is_pad else 8.0
    gap = 12.0 if is_pad else 8.0
    content_w = max(1.0, width - pad * 2)
    base_hud = min(300.0 if is_pad else 250.0, max(250.0 if is_pad else 230.0, height * 0.28))
    dock_h = min(80.0 if is_pad else 68.0, max(56.0, height * 0.08))
    hud_ceiling = max(96.0, height - dock_h - gap * 2 - pad * 2 - 120.0)
    hud_h = min(base_hud + accessories, hud_ceiling)

    ideal_top = max(pad, height * PORTRAIT_TOP_RATIO)
    fixed = hud_h + dock_h + gap * 2 + pad
    wanted = min(content_w, MIN_BOARD)
    top_space = max(pad, min(ideal_top, height - fixed - wanted))

    hud = Rect(pad, top_space, content_w, hud_h)
    dock = Rect(pad, height - pad - dock_h, content_w, dock_h)
    mid_top = hud.max_y + gap
    mid_bottom = max(mid_top + 1.0, dock.y - gap)
    available = max(1.0, mid_bottom - mid_top)
    board_side = min(content_w, available)
    board = Rect(
        pad + (content_w - board_side) / 2,
        mid_top + max(0.0, (available - board_side) / 2),
        board_side,
        board_side,
    )
    return hud, board, dock


def landscape(width: float, height: float, is_pad: bool, accessories: float):
    pad = 12.0 if is_pad else 8.0
    gap = 12.0 if is_pad else 8.0
    content_w = max(1.0, width - pad * 2)
    content_h = max(1.0, height - pad * 2)

    max_sidebar = LANDSCAPE_MAX_SIDEBAR_PAD if is_pad else LANDSCAPE_MAX_SIDEBAR_PHONE
    square_budget = max(MIN_BOARD, min(content_h, content_w - LANDSCAPE_MIN_SIDEBAR - gap))
    sidebar_w = min(
        max(LANDSCAPE_MIN_SIDEBAR, content_w - square_budget - gap),
        max(LANDSCAPE_MIN_SIDEBAR, min(max_sidebar, content_w - MIN_BOARD - gap)),
    )
    column_w = max(MIN_BOARD, content_w - sidebar_w - gap)

    min_dock = 80.0 if is_pad else 68.0
    dock_h = max(min_dock, min(content_h * 0.22, 96.0 if is_pad else 84.0))
    min_hud = (200.0 if is_pad else 184.0) + accessories
    ideal_gap = max(gap, content_h * LANDSCAPE_SECTION_GAP_RATIO)

    section_gap = ideal_gap
    hud_h = max(1.0, content_h - dock_h - section_gap)
    if hud_h < min_hud:
        section_gap = max(gap, content_h - min_hud - dock_h)
        hud_h = max(1.0, content_h - dock_h - section_gap)

    hud = Rect(pad, pad, sidebar_w, hud_h)
    dock = Rect(pad, hud.max_y + section_gap, sidebar_w, dock_h)

    board_side = max(1.0, min(column_w, content_h))
    board = Rect(
        pad + sidebar_w + gap + (column_w - board_side) / 2,
        pad + (content_h - board_side) / 2,
        board_side,
        board_side,
    )
    return hud, board, dock


def make(width: float, height: float, is_landscape: bool, is_pad: bool, rows: int = 0):
    # Reserved permanently, so the board never moves when a transient row shows.
    del rows
    accessories = HUD_ACCESSORY_RESERVE_ROWS * HUD_ACCESSORY_ROW_HEIGHT
    if is_landscape and width >= 520:
        return landscape(width, height, is_pad, accessories)
    return portrait(width, height, is_pad, accessories)


DEVICES = [
    ("iPhone SE 1 portrait", 320, 568, False),
    ("iPhone SE 1 landscape", 568, 320, False),
    ("iPhone SE 3 portrait", 375, 667, False),
    ("iPhone SE 3 landscape", 667, 375, False),
    ("iPhone 14 portrait", 390, 844, False),
    ("iPhone 14 landscape", 844, 390, False),
    ("iPhone 16 Pro portrait", 402, 874, False),
    ("iPhone 16 Pro landscape", 874, 402, False),
    ("iPhone 16 Pro Max portrait", 440, 956, False),
    ("iPhone 16 Pro Max landscape", 956, 440, False),
    ("iPhone 17 Pro Max portrait", 440, 956, False),
    ("iPhone 17 Pro Max landscape", 956, 440, False),
    ("iPad mini portrait", 744, 1133, True),
    ("iPad mini landscape", 1133, 744, True),
    ("iPad 11 portrait", 834, 1194, True),
    ("iPad 11 landscape", 1194, 834, True),
    ("iPad Pro 12.9 portrait", 1024, 1366, True),
    ("iPad Pro 12.9 landscape", 1366, 1024, True),
    ("iPad Split 1/3", 320, 834, True),
    ("iPad Split 1/2 landscape", 694, 834, True),
]


def main() -> int:
    failed = 0
    for name, w, h, is_pad in DEVICES:
        is_land = w > h + 12
        summaries = []
        for rows in ACCESSORY_ROW_CASES:
            hud, board, dock = make(w, h, is_land, is_pad, rows)
            pairs = []
            items = [("hud", hud.inset(0.5)), ("board", board.inset(0.5)), ("dock", dock.inset(0.5))]
            for i, (a_name, a) in enumerate(items):
                for b_name, b in items[i + 1 :]:
                    if a.intersects(b):
                        pairs.append(f"{a_name}/{b_name}")
            contained = all(r.contained_in(w, h) for r in (hud, board, dock))
            board_ok = min(board.w, board.h) + 0.5 >= MIN_BOARD
            square_ok = abs(board.w - board.h) <= 0.5
            if pairs or not contained or not board_ok or not square_ok:
                failed += 1
                print(
                    f"FAIL {name} rows={rows}: overlaps={pairs} contained={contained} "
                    f"square={square_ok} board={board}"
                )
            else:
                summaries.append(f"{rows}:{int(board.w)}px/hud{int(hud.h)}")
        if len(summaries) == len(ACCESSORY_ROW_CASES):
            print(f"OK   {name}: " + "  ".join(summaries))
    if failed:
        print(f"\n{failed} device layouts failed")
        return 1
    print("\nAll reference device layouts are non-overlapping (0-2 accessory rows)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
