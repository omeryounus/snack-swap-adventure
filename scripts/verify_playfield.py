#!/usr/bin/env python3
"""Mirrors PlayfieldGeometry and fails if any reference device overlaps."""

from dataclasses import dataclass


MIN_BOARD = 168.0


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
    hud_h = min(136.0 if is_pad else 120.0, max(88.0, content_h * 0.17))
    dock_h = min(88.0 if is_pad else 76.0, max(64.0, content_h * 0.13))
    board_budget = max(MIN_BOARD, content_h - hud_h - dock_h - gap * 2)
    board_side = min(content_w, board_budget)
    hud = Rect(pad, pad, content_w, hud_h)
    board = Rect(pad + (content_w - board_side) / 2, hud.max_y + gap, board_side, board_side)
    dock_y = min(height - pad - dock_h, board.max_y + gap)
    dock = Rect(pad, dock_y, content_w, dock_h)
    return hud, board, dock


def landscape(width: float, height: float, is_pad: bool) -> tuple[Rect, Rect, Rect]:
    pad = 12.0 if is_pad else 8.0
    gap = 12.0 if is_pad else 8.0
    content_w = max(1.0, width - pad * 2)
    content_h = max(1.0, height - pad * 2)
    board_side = min(content_h, max(MIN_BOARD, content_w * 0.62))
    sidebar_w = max(132.0, content_w - board_side - gap)
    hud_h = min(168.0 if is_pad else 132.0, max(96.0, content_h * 0.42))
    dock_h = max(64.0, content_h - hud_h - gap)
    hud = Rect(pad, pad, sidebar_w, hud_h)
    dock = Rect(pad, hud.max_y + gap, sidebar_w, dock_h)
    board = Rect(pad + sidebar_w + gap, pad + max(0.0, (content_h - board_side) / 2), board_side, board_side)
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
        if pairs or not contained or not board_ok:
            failed += 1
            print(f"FAIL {name}: overlaps={pairs} contained={contained} board={board}")
        else:
            print(f"OK   {name}: board={int(board.w)}x{int(board.h)}")
    if failed:
        print(f"\n{failed} device layouts failed")
        return 1
    print("\nAll reference device layouts are non-overlapping")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
