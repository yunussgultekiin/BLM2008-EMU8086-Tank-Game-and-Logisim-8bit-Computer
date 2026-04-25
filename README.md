# ASCII Tank Game

> **Note:** This repository also contains an 8-bit computer design created with Logisim. You can find the related files in the corresponding folder.

It is a retro-style tank game written in x86 Assembly and running on **emu8086**. All graphical output, timing, and input operations are performed directly through **BIOS/DOS interrupts** without using any library or operating system service. The game is compiled into a single `.COM` file and runs in 80×25 text mode.

---

## Controls

| Key | Action |
|-----|--------|
| `↑` Arrow Key | Move / direct the tank **up** |
| `↓` Arrow Key | Move / direct the tank **down** |
| `←` Arrow Key | Move / direct the tank **left** |
| `→` Arrow Key | Move / direct the tank **right** |
| `Space` | Fire a bullet |
| `Enter` | Confirm / start the game |
| `R` | Restart (returns to difficulty selection) |
| `Q` | Quit the game |

Keyboard input is checked with `INT 16h / AH=01h`; if a key exists in the buffer, the scan code + ASCII code is read with `AH=00h`. Arrow keys are detected through `AH` (scan code) (`48h`, `50h`, `4Bh`, `4Dh`), while `Space` is detected through `AL`.

---

## Rules and Objectives

- **Objective:** Destroy the **8 `X` targets** placed on the map.
- **Ammo:** A total of **20 bullets** are given per game; missed bullets cannot be recovered.
- **Time Limit:** Each game is limited to **180 seconds**; the counter works by reading the real-time clock.
- **Scoring:** **10 points** are added for each target hit. The score is stored in a `DW` (16-bit word) variable.
- **Best Score:** The `bestScore` variable is kept in memory during the session; it is not reset until the program is closed.

### Game Over Conditions

| Condition | `resultCode` | Message |
|-----------|-------------|---------|
| All 8 targets destroyed | `1` | YOU WIN! ALL TARGETS DESTROYED. |
| Ammo finished and no bullet is in the air | `2` | OUT OF AMMO. |
| Time is up | `4` | TIME IS UP. |

`CheckGameOver` is called in every main loop iteration. The `targetsLeft == 0` check is performed first; therefore, if the last bullet hits the last target, the winning condition has priority over the out-of-ammo condition.

---

## Difficulty Levels

Difficulty selection only changes the obstacle layout; ammo count, target positions, and time limit are the same for all levels. The `level` variable is stored as `DB` (`1`=Easy, `2`=Medium, `3`=Hard). The `DrawWalls` and `WallHere` procedures read this value and branch to the related code path.

### 1 — EASY

```

Horizontal Walls:
'=' × 17  → row 8,  columns 14–30
'=' × 21  → row 18, columns 36–56

Vertical Walls:
'|' × 8   → column 44, rows 5–12
'|' × 8   → column 60, rows 14–21

```

### 2 — MEDIUM

```

Horizontal Walls:
'=' × 17  → row 7,  columns 12–28
'=' × 17  → row 15, columns 8–24
'=' × 18  → row 20, columns 28–45

Vertical Walls:
'|' × 8   → column 38, rows 5–12
'|' × 10  → column 55, rows 12–21

```

### 3 — HARD

```

Horizontal Walls:
'=' × 17  → row 6,  columns 9–25
'=' × 25  → row 10, columns 44–68
'=' × 23  → row 16, columns 6–28
'=' × 21  → row 19, columns 42–62

Vertical Walls:
'|' × 10  → column 36, rows 5–14
'|' × 10  → column 58, rows 13–22
'|' × 6   → column 22, rows 17–22

```

---

## HUD Layout

The first two rows of the screen are drawn once at the start of the game by `DrawTopPanel`. Numerical values are updated only when they change by `DrawStats`, `DrawTime`, and `DrawBestScore` — unnecessary screen writing is avoided.

```

Row 0:  Ammo: ##    Score: ##    Best: ##    Targets: ##    Time: ###
Row 1:  Arrows=Move     Space=Fire                  Level: EASY|MEDIUM|HARD

```

The `PrintNumber` procedure divides the number by 10 and writes the digits into `numBuffer` in reverse order, then prints them to the screen in the opposite direction. If the number is `0`, the `'0'` character is printed directly.

---

## Technical Details

### Platform and Compilation Format

| Feature | Value |
|---------|-------|
| Assembler / Emulator | **emu8086** |
| Output format | **COM** file (`#make_COM#` directive) |
| Architecture | **x86 16-bit Real Mode** |
| Start address | `ORG 100h` |
| Video mode | **80×25 text mode** |
| Segment structure | `CS = DS` (all segments are the same because of the COM format) |

In COM format, code and data share the same 64 KB segment. Therefore, at the beginning of the program, `DS` is explicitly set equal to `CS` with `MOV AX, CS` / `MOV DS, AX`; this ensures correct access to data labels such as `tankCol`, `bulletOn`, and others.

### Game Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `TOP_ROW` | 3 | Top border row |
| `BOT_ROW` | 23 | Bottom border row |
| `LEFT_COL` | 0 | Left border column |
| `RIGHT_COL` | 79 | Right border column |
| `MAX_AMMO` | 20 | Initial ammo count |
| `MAX_BULLETS` | 20 | Maximum number of bullets in the air at the same time |
| `TARGET_COUNT` | 8 | Number of targets on the map |
| `GAME_TIME` | 180 | Time limit in seconds |

### Screen Layout (Row Ranges)

```

Rows  0–1 : HUD (Ammo, Score, Best, Targets, Time, Level)
Row   2   : Empty
Row   3   : Top frame ('#' × 80)
Rows  4–22: Game area
Row   23  : Bottom frame ('#' × 80)
Row   24  : Unused

```

---

## Subsystems

### Main Loop

```

main_loop:
TimerCheck       ← Has the second changed? → timeLeft--
MoveBullets      ← Move all active bullets one cell forward
CheckGameOver    ← Check win / lose conditions
INT 16h (01h)    ← Is the key buffer full? (non-blocking)
→ Yes: read the key, call MoveTank / Shoot
→ No: SmallDelay, enter the loop again

````

`SmallDelay` runs an empty `LOOP` cycle with `CX=25`. This approach assumes a fixed CPU speed; results may vary on real hardware, but it provides sufficient slowdown in emu8086.

---

### Bullet System

Each bullet is stored in the following parallel `DB` arrays, each having `MAX_BULLETS=20` elements:

| Array | Type | Description |
|-------|------|-------------|
| `bulletCol` | `DB` | Current column of the bullet |
| `bulletRow` | `DB` | Current row of the bullet |
| `bulletColStep` | `DB` | Horizontal step: `+1`, `FFh` (−1), or `0` |
| `bulletRowStep` | `DB` | Vertical step: `+1`, `FFh` (−1), or `0` |
| `bulletOn` | `DB` | `1` = active, `0` = empty slot |
| `bulletShown` | `DB` | `1` = displayed on the screen in the previous frame |

**`Shoot` procedure:**
1. Exits if `ammoLeft == 0`.
2. Scans the `bulletOn` array and finds the first empty slot (`SI` index).
3. Decreases `ammoLeft` and updates the HUD.
4. Copies `tankCol`/`tankRow` as the initial bullet position.
5. Assigns `ColStep`/`RowStep` according to the `tankDir` value:
   - Up → `ColStep=0, RowStep=FFh`
   - Down → `ColStep=0, RowStep=1`
   - Left → `ColStep=FFh, RowStep=0`
   - Right → `ColStep=1, RowStep=0`
6. Sets `bulletOn[SI]=1`, increases `bulletCount`, and immediately calls `MoveBullets`.

**`MoveBullets` procedure** loops over `MAX_BULLETS`:
1. If the slot is active and `bulletShown==1`, it erases the old position with `' '`. If the erased cell overlaps with `tankCol`/`tankRow`, the tank is redrawn.
2. Adds `ColStep`/`RowStep` to the position and calculates the new position.
3. **Collision priority:** First `TargetHere` → if there is a hit, `HitTarget` is called and the slot is released. Otherwise `WallHere` → if there is a wall, the slot is released. If neither exists, the `'*'` character is drawn with the `0Eh` (yellow) color.

---

### Tank Movement and Direction System

The `tankDir` variable encodes the direction of the tank:

| Value | Direction | Character |
|-------|-----------|-----------|
| `0` | Up | `^` |
| `1` | Down | `v` |
| `2` | Left | `<` |
| `3` | Right | `>` |

`MoveTank` procedure:
1. Calculates the target cell with `NextTankCell` (`DH`/`DL` ±1 according to `tankDir`).
2. Calls `BlockedCell`:
   - `WallHere` → if there is a border or obstacle collision, `AL=1`
   - Then scans the `targetOn` array; a target cell is also considered blocked.
3. If the cell is free: the old position is erased with `' '`, `tankCol`/`tankRow` is updated, and `DrawTank` is called.
4. If the cell is occupied: only `DrawTank` is called (the direction arrow character is updated, but the position does not change).

The tank character is drawn with `PutChar` using the `0Ah` (bright green) color attribute.

---

### Timing System

```asm
GetSecond:
    MOV AH, 2Ch
    INT 21h          ; DH = second (0–59)
    MOV AL, DH
    RET
````

`TimerCheck`:

1. Reads the real-time clock second with `GetSecond`.
2. Compares it with `lastSecond`. If the value has not changed, it exits early.
3. If it has changed, `lastSecond` is updated, `timeLeft` is decreased, and `DrawTime` is called.
4. When `timeLeft == 0`, `resultCode=4` and `gameOver=1` are assigned.

`DrawTime` does not write the new value to the screen unless it is different from `oldTime`. This way, the screen is updated only once per second.

---

### Collision System (`WallHere` / `BlockedCell`)

**`WallHere`** returns `1` (blocked) or `0` (free) in `AL`:

1. **Border check:** `DH ≤ TOP_ROW`, `DH ≥ BOT_ROW`, `DL ≤ LEFT_COL`, `DL ≥ RIGHT_COL` → directly branches to `wall_blocked`.
2. **Level selection:** The `level` variable is read; execution branches to the related block with `JE check_easy/medium/hard_obstacles`.
3. **Obstacle detection:** For each obstacle, the row (`DH`) is checked first, then the column range (`DL`). If both conditions are satisfied, execution jumps to the `wall_blocked` label. If none match, it returns through `free_cell` (`AL=0`).

Obstacle coordinates are hardcoded with fixed comparisons; no lookup table or data structure is used. This method keeps the COM file size small and does not introduce extra memory access cost.

**`BlockedCell`** is used for tank movement and, in addition to `WallHere`, also scans active target positions: if `targetOn[i]==1` and coordinates match, it returns `AL=1`. This prevents the tank from moving onto `X` targets.

---

### Target Collision (`HitTarget`)

`HitTarget` scans `TARGET_COUNT` targets in a loop using the `DL`/`DH` (column/row) coordinates:

* `targetOn[i]==1` and `targetCol[i]==DL` and `targetRow[i]==DH` → hit.
* `targetOn[i]=0`, `targetsLeft` is decreased, and `score += 10`.
* The hit point is erased from the screen with the `' '` character, and `DrawStats` is called.
* Returns `AL=1` (hit) or `AL=0` (no hit).

---

### Screen Rendering Infrastructure

All drawing operations are performed through **BIOS INT 10h**; DOS write functions are used only for `$`-terminated text strings (`INT 21h / AH=09h`).

| Procedure     | INT                               | Description                                                                  |
| ------------- | --------------------------------- | ---------------------------------------------------------------------------- |
| `PutChar`     | `INT 10h / AH=09h`                | Writes a single character with a color attribute (`BL`=color, `CX=1`)        |
| `DrawRow`     | `INT 10h / AH=09h`                | Draws the same character horizontally `CX` times (cursor is positioned once) |
| `DrawColumn`  | `PutChar` loop                    | Creates a vertical line by increasing `DH` in each iteration                 |
| `PrintText`   | `INT 21h / AH=09h`                | Prints text from `SI` until the `$` character                                |
| `PrintNumber` | `PutChar` loop                    | Converts a 16-bit number into ASCII digits                                   |
| `ClearScreen` | `INT 10h / AX=0003h` + `AX=0600h` | Resets video mode and clears the entire screen                               |
| `HideCursor`  | `INT 10h / AH=01h, CH=20h`        | Hides the cursor display                                                     |
| `SetCursor`   | `INT 10h / AH=02h`                | Positions the cursor with `DH`=row, `DL`=column                              |

`ClearTextArea` calls `DrawRow` with `AL=' '`, `BL=07h` to erase the old numeric value in the specified area; then `PrintNumber` writes the new value. This two-step erase–rewrite approach prevents "ghost" digits from remaining on the screen.

---

## File Structure

```
ascii_tank_game.asm   ← Single source file containing all code, data, and text strings
README.md
```

---

## How to Run

### Requirements

* **emu8086** (v4.x recommended)

### Steps

1. Open **emu8086**.
2. Select **Open** → `ascii_tank_game.asm`.
3. Click the **Compile** button or press `F5`.
4. Click the **Run** button — the emulator opens the virtual screen window.
5. Press **Enter** on the intro screen.
6. Select the difficulty level (`1`, `2`, or `3`).
7. Move the tank with the arrow keys and fire with `Space`.

> **Note:** The game requires direct access to BIOS/DOS interrupts. It only runs in a compatible real-mode DOS emulator such as emu8086 or DOSBox; it cannot be run directly on modern 64-bit operating systems.

---

```
```
