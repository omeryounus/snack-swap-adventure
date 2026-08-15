#!/usr/bin/env python3
"""Mirrors PlayfieldGeometry and fails if any reference device overlaps."""

from dataclasses import dataclass


MIN_BOARD = 168.0
LANDSCAPE_GAMEPLAY_RATIO = 0.70
LANDSCAPE_MIN_SIDEBAR = 140.0


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


def portrait(width: float, height: float, is_pad: bool) -> tuple[Rect, Rect, Rect]:
    pad = 12.0 if is_pad else 8.0
    gap = 12.0 if is_pad else 8.0
    content_w = max(1.0, width - pad * 2)
    content_h = max(1.0, height - pad * 2)
    hud_h = min(92.0 if is_pad else 76.0, max(60.0, content_h * 0.10))
    dock_h = min(80.0 if is_pad else 68.0, max(56.0, content_h * 0.10))
    leftover = content_h - hud_h - dock_h - gap * 2
    board_side = min(content_w, max(MIN_BOARD, leftover))
    hud = Rect(pad, pad, content_w, hud_h)
    board = Rect(pad + (content_w - board_side) / 2, hud.max_y + gap, board_side, board_side)
    bottom_dock_y = height - pad - dock_h
    if bottom_dock_y >= board.max_y + gap - 0.5:
        dock_y = bottom_dock_y
    else:
        dock_y = min(bottom_dock_y, board.max_y + gap)
    dock = Rect(pad, dock_y, content_w, dock_h)
    return hud, board, dock


def landscape(width: float, height: float, is_pad: bool) -> tuple[Rect, Rect, Rect]:
    pad = 12.0 if is_pad else 8.0
    gap = 12.0 if is_pad else 8.0
    content_w = max(1.0, width - pad * 2)
    content_h = max(1.0, height - pad * 2)
    play_w = content_w * LANDSCAPE_GAMEPLAY_RATIO
    sidebar_w = content_w - play_w - gap
    if sidebar_w < LANDSCAPE_MIN_SIDEBAR:
        sidebar_w = min(LANDSCAPE_MIN_SIDEBAR, content_w * 0.38)
        play_w = max(MIN_BOARD, content_w - sidebar_w - gap)
    hud_h = min(200.0 if is_pad else 160.0, max(88.0, content_h * 0.48))
    dock_h = max(64.0, content_h - hud_h - gap)
    hud = Rect(pad, pad, sidebar_w, hud_h)
    dock = Rect(pad, hud.max_y + gap, sidebar_w, dock_h)
    board = Rect(pad + sidebar_w + gap, pad, play_w, content_h)
    return hud, board, dock


def make(width: float, height: float, is_landscape: bool, is_pad: bool):
    if is_landscape and width >= 520:
        return landscape(width, height, is_pad)
    return portrait(width, height, is_pad)


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
        hud, board, dock = make(w, h, is_land, is_pad)
        pairs = []
        items = [("hud", hud.inset(0.5)), ("board", board.inset(0.5)), ("dock", dock.inset(0.5))]
        for i, (a_name, a) in enumerate(items):
            for b_name, b in items[i + 1 :]:
                if a.intersects(b):
                    pairs.append(f"{a_name}/{b_name}")
        contained = all(r.contained_in(w, h) for r in (hud, board, dock))
        board_ok = min(board.w, board.h) + 0.5 >= MIN_BOARD
        ratio_ok = True
        ratio = 0.0
        if is_land and w >= 520:
            pad = 12.0 if is_pad else 8.0
            content_w = w - pad * 2
            ratio = board.w / content_w
            ratio_ok = abs(ratio - LANDSCAPE_GAMEPLAY_RATIO) <= 0.02
        hud_ok = (not is_land) or True
        if not is_land:
            hud_ok = hud.h <= (92.5 if is_pad else 76.5)
        if pairs or not contained or not board_ok or not ratio_ok or not hud_ok:
            failed += 1
            print(
                f"FAIL {name}: overlaps={pairs} contained={contained} "
                f"board={board} ratio={ratio:.3f} hud={hud.h:.0f}"
            )
        else:
            extra = f" hud={int(hud.h)}" if not is_land else f" play={ratio:.0%}"
            print(f"OK   {name}: board={int(board.w)}x{int(board.h)}{extra}")
    if failed:
        print(f"\n{failed} device layouts failed")
        return 1
    print("\nAll reference device layouts are non-overlapping")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
