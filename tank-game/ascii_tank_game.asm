#make_COM#
ORG 100h

JMP start

TOP_ROW       EQU 3
BOT_ROW       EQU 23
LEFT_COL      EQU 0
RIGHT_COL     EQU 79
MAX_AMMO      EQU 20
MAX_BULLETS EQU 20
TARGET_COUNT  EQU 8
GAME_TIME     EQU 180

tankCol         DB 5
tankRow         DB 13
tankDir       DB 3

bulletCol       DB MAX_BULLETS DUP(0)
bulletRow       DB MAX_BULLETS DUP(0)
bulletColStep      DB MAX_BULLETS DUP(0)
bulletRowStep      DB MAX_BULLETS DUP(0)
bulletOn  DB MAX_BULLETS DUP(0)
bulletShown DB MAX_BULLETS DUP(0)
bulletCount DB 0

ammoLeft     DB MAX_AMMO
targetsLeft   DB TARGET_COUNT
gameOver      DB 0
resultCode    DB 0

score         DW 0
bestScore     DW 0
level DB 1

lastSecond       DB 0
timeLeft      DB GAME_TIME
oldTime DB 255

nextCol          DB 0
nextRow          DB 0

textRow      DB 0
textCol      DB 0
textColor     DB 0
numBuffer        DB 5 DUP(0)

targetCol       DB 70, 64, 72, 66, 48, 31, 14, 75
targetRow       DB 5,  9,  13, 18, 6,  17, 21, 21
targetOn   DB TARGET_COUNT DUP(1)

introLine     DB '+----------------------------------------------------------+$'
introTitle    DB 'ASCII TANK GAME$'
introInfo1    DB 'ARROW KEYS : Move the tank$'
introInfo2    DB 'SPACE      : Fire bullet$'
introInfo3    DB 'GOAL       : Destroy all X targets$'
introInfo4    DB 'LIMIT      : 20 rounds and 180 seconds$'
introInfo5    DB 'ENTER      : Start game$'
introBest     DB 'Session Best Score: $'

diffTitle     DB 'SELECT DIFFICULTY$'
diffInfo      DB 'Choose obstacle layout. Ammo and targets stay the same.$'
diffEasy      DB '1 - EASY   : fewer obstacles$'
diffMedium    DB '2 - MEDIUM : normal obstacles$'
diffHard      DB '3 - HARD   : more obstacles$'
diffHint      DB 'Press 1, 2, or 3$'

hudAmmo       DB 'Ammo:$'
hudScore      DB 'Score:$'
hudBest       DB 'Best:$'
hudTargets    DB 'Targets:$'
hudTime       DB 'Time:$'
hudHelp       DB 'Arrows=Move     Space=Fire$'
hudLevel      DB 'Level:$'
hudEasyName   DB 'EASY$'
hudMedName    DB 'MEDIUM$'
hudHardName   DB 'HARD$'

overTitle     DB 'GAME RESULT$'
overWin       DB 'RESULT: YOU WIN! ALL TARGETS DESTROYED.$'
overLose      DB 'RESULT: OUT OF AMMO.$'
overTime      DB 'RESULT: TIME IS UP.$'
overScore     DB 'Your Score: $'
overBest      DB 'Session Best: $'
overMenu1     DB 'R - New Game / Select Level$'
overMenu2     DB 'Q - Quit Game$'
overAsk       DB 'Choose: $'

start:
    MOV AX, CS
    MOV DS, AX

    MOV WORD PTR [bestScore], 0
    CALL HideCursor
    CALL IntroScreen

restart_game:
    CALL DifficultyMenu
    CALL NewGame

main_loop:
    CALL TimerCheck

    CMP BYTE PTR [gameOver], 1
    JE show_result

    CALL MoveBullets

    CMP BYTE PTR [gameOver], 1
    JE show_result

    CALL CheckGameOver

    CMP BYTE PTR [gameOver], 1
    JE show_result

    MOV AH, 01h
    INT 16h
    JNZ read_key

    CALL SmallDelay
    JMP main_loop

read_key:
    MOV AH, 00h
    INT 16h

    CMP AL, ' '
    JE key_space

    CMP AH, 48h
    JE key_up

    CMP AH, 50h
    JE key_down

    CMP AH, 4Bh
    JE key_left

    CMP AH, 4Dh
    JE key_right

    JMP main_loop

key_space:
    CALL Shoot
    CALL SmallDelay
    JMP main_loop

key_up:
    MOV BYTE PTR [tankDir], 0
    CALL MoveTank
    CALL SmallDelay
    JMP main_loop

key_down:
    MOV BYTE PTR [tankDir], 1
    CALL MoveTank
    CALL SmallDelay
    JMP main_loop

key_left:
    MOV BYTE PTR [tankDir], 2
    CALL MoveTank
    CALL SmallDelay
    JMP main_loop

key_right:
    MOV BYTE PTR [tankDir], 3
    CALL MoveTank
    CALL SmallDelay
    JMP main_loop

show_result:
    CALL ResultScreen

    CMP AL, 'R'
    JE restart_game

    JMP ExitProgram

IntroScreen PROC
    CALL ClearScreen

    MOV DH, 4
    MOV DL, 9
    MOV SI, OFFSET introLine
    CALL PrintText

    MOV DH, 6
    MOV DL, 33
    MOV SI, OFFSET introTitle
    CALL PrintText

    MOV DH, 8
    MOV DL, 9
    MOV SI, OFFSET introLine
    CALL PrintText

    MOV DH, 10
    MOV DL, 22
    MOV SI, OFFSET introInfo1
    CALL PrintText

    MOV DH, 11
    MOV DL, 22
    MOV SI, OFFSET introInfo2
    CALL PrintText

    MOV DH, 12
    MOV DL, 22
    MOV SI, OFFSET introInfo3
    CALL PrintText

    MOV DH, 13
    MOV DL, 22
    MOV SI, OFFSET introInfo4
    CALL PrintText

    MOV DH, 15
    MOV DL, 22
    MOV SI, OFFSET introInfo5
    CALL PrintText

    MOV DH, 17
    MOV DL, 26
    MOV SI, OFFSET introBest
    CALL PrintText

    MOV AX, [bestScore]
    MOV DH, 17
    MOV DL, 46
    MOV BL, 0Eh
    CALL PrintNumber

    MOV DH, 19
    MOV DL, 9
    MOV SI, OFFSET introLine
    CALL PrintText

intro_wait:
    MOV AH, 00h
    INT 16h

    CMP AL, 13
    JNE intro_wait

    RET
IntroScreen ENDP

DifficultyMenu PROC
    CALL ClearScreen

    MOV DH, 4
    MOV DL, 9
    MOV SI, OFFSET introLine
    CALL PrintText

    MOV DH, 6
    MOV DL, 31
    MOV SI, OFFSET diffTitle
    CALL PrintText

    MOV DH, 8
    MOV DL, 9
    MOV SI, OFFSET introLine
    CALL PrintText

    MOV DH, 10
    MOV DL, 13
    MOV SI, OFFSET diffInfo
    CALL PrintText

    MOV DH, 12
    MOV DL, 25
    MOV SI, OFFSET diffEasy
    CALL PrintText

    MOV DH, 13
    MOV DL, 25
    MOV SI, OFFSET diffMedium
    CALL PrintText

    MOV DH, 14
    MOV DL, 25
    MOV SI, OFFSET diffHard
    CALL PrintText

    MOV DH, 17
    MOV DL, 24
    MOV SI, OFFSET diffHint
    CALL PrintText

    MOV DH, 19
    MOV DL, 9
    MOV SI, OFFSET introLine
    CALL PrintText

diff_wait:
    MOV AH, 00h
    INT 16h

    CMP AL, '1'
    JE diff_easy_selected

    CMP AL, '2'
    JE diff_medium_selected

    CMP AL, '3'
    JE diff_hard_selected

    JMP diff_wait

diff_easy_selected:
    MOV BYTE PTR [level], 1
    RET

diff_medium_selected:
    MOV BYTE PTR [level], 2
    RET

diff_hard_selected:
    MOV BYTE PTR [level], 3
    RET
DifficultyMenu ENDP

NewGame PROC
    CALL ClearScreen

    MOV BYTE PTR [tankCol], 5
    MOV BYTE PTR [tankRow], 13
    MOV BYTE PTR [tankDir], 3

    MOV BYTE PTR [bulletCount], 0
    XOR SI, SI
    MOV CX, MAX_BULLETS

reset_bullets:
    MOV BYTE PTR [bulletOn + SI], 0
    MOV BYTE PTR [bulletShown + SI], 0
    INC SI
    LOOP reset_bullets

    MOV BYTE PTR [ammoLeft], MAX_AMMO
    MOV BYTE PTR [targetsLeft], TARGET_COUNT
    MOV BYTE PTR [gameOver], 0
    MOV BYTE PTR [resultCode], 0
    MOV WORD PTR [score], 0

    MOV BYTE PTR [timeLeft], GAME_TIME
    MOV BYTE PTR [oldTime], 255

    XOR SI, SI
    MOV CX, TARGET_COUNT

reset_targets:
    MOV BYTE PTR [targetOn + SI], 1
    INC SI
    LOOP reset_targets

    CALL ResetTimer

    CALL DrawTopPanel
    CALL DrawBestScore
    CALL DrawStats
    CALL DrawTime

    CALL DrawGameArea
    CALL DrawTargets
    CALL DrawTank

    RET
NewGame ENDP

ResetTimer PROC
    CALL GetSecond
    MOV [lastSecond], AL
    RET
ResetTimer ENDP

GetSecond PROC
    PUSH CX
    PUSH DX

    MOV AH, 2Ch
    INT 21h
    MOV AL, DH

    POP DX
    POP CX
    RET
GetSecond ENDP

TimerCheck PROC
    PUSH AX

    CMP BYTE PTR [gameOver], 1
    JE timer_done

    CALL GetSecond
    CMP AL, [lastSecond]
    JE timer_done

    MOV [lastSecond], AL

    CMP BYTE PTR [timeLeft], 0
    JE timer_time_up

    DEC BYTE PTR [timeLeft]
    CALL DrawTime

    CMP BYTE PTR [timeLeft], 0
    JNE timer_done

timer_time_up:
    MOV BYTE PTR [timeLeft], 0
    CALL DrawTime
    MOV BYTE PTR [resultCode], 4
    MOV BYTE PTR [gameOver], 1

timer_done:
    POP AX
    RET
TimerCheck ENDP

DrawTime PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV AL, [timeLeft]
    CMP AL, [oldTime]
    JE update_time_done

    MOV [oldTime], AL

    MOV DH, 0
    MOV DL, 72
    MOV CX, 5
    CALL ClearTextArea

    XOR AX, AX
    MOV AL, [timeLeft]
    MOV DH, 0
    MOV DL, 72
    MOV BL, 0Eh
    CALL PrintNumber

update_time_done:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DrawTime ENDP

DrawGameArea PROC
    CALL DrawFrame
    CALL DrawWalls
    RET
DrawGameArea ENDP

DrawFrame PROC
    MOV AL, '#'
    MOV BL, 07h

    MOV DH, TOP_ROW
    MOV DL, 0
    MOV CX, 80
    CALL DrawRow

    MOV DH, BOT_ROW
    MOV DL, 0
    MOV CX, 80
    CALL DrawRow

    MOV DH, TOP_ROW
    MOV DL, LEFT_COL
    MOV CX, 21
    CALL DrawColumn

    MOV DH, TOP_ROW
    MOV DL, RIGHT_COL
    MOV CX, 21
    CALL DrawColumn

    RET
DrawFrame ENDP

DrawWalls PROC
    MOV AL, [level]

    CMP AL, 1
    JE draw_easy_obstacles

    CMP AL, 3
    JE draw_hard_obstacles

    JMP draw_medium_obstacles

draw_easy_obstacles:
    CALL DrawEasyWalls
    RET

draw_medium_obstacles:
    CALL DrawMediumWalls
    RET

draw_hard_obstacles:
    CALL DrawHardWalls
    RET
DrawWalls ENDP

DrawEasyWalls PROC
    MOV AL, '='
    MOV BL, 06h

    MOV DH, 8
    MOV DL, 14
    MOV CX, 17
    CALL DrawRow

    MOV DH, 18
    MOV DL, 36
    MOV CX, 21
    CALL DrawRow

    MOV AL, '|'
    MOV BL, 06h

    MOV DH, 5
    MOV DL, 44
    MOV CX, 8
    CALL DrawColumn

    MOV DH, 14
    MOV DL, 60
    MOV CX, 8
    CALL DrawColumn

    RET
DrawEasyWalls ENDP

DrawMediumWalls PROC
    MOV AL, '='
    MOV BL, 06h

    MOV DH, 7
    MOV DL, 12
    MOV CX, 17
    CALL DrawRow

    MOV DH, 15
    MOV DL, 8
    MOV CX, 17
    CALL DrawRow

    MOV DH, 20
    MOV DL, 28
    MOV CX, 18
    CALL DrawRow

    MOV AL, '|'
    MOV BL, 06h

    MOV DH, 5
    MOV DL, 38
    MOV CX, 8
    CALL DrawColumn

    MOV DH, 12
    MOV DL, 55
    MOV CX, 10
    CALL DrawColumn

    RET
DrawMediumWalls ENDP

DrawHardWalls PROC
    MOV AL, '='
    MOV BL, 06h

    MOV DH, 6
    MOV DL, 9
    MOV CX, 17
    CALL DrawRow

    MOV DH, 10
    MOV DL, 44
    MOV CX, 25
    CALL DrawRow

    MOV DH, 16
    MOV DL, 6
    MOV CX, 23
    CALL DrawRow

    MOV DH, 19
    MOV DL, 42
    MOV CX, 21
    CALL DrawRow

    MOV AL, '|'
    MOV BL, 06h

    MOV DH, 5
    MOV DL, 36
    MOV CX, 10
    CALL DrawColumn

    MOV DH, 13
    MOV DL, 58
    MOV CX, 10
    CALL DrawColumn

    MOV DH, 17
    MOV DL, 22
    MOV CX, 6
    CALL DrawColumn

    RET
DrawHardWalls ENDP

DrawTargets PROC
    XOR SI, SI
    MOV CX, TARGET_COUNT

draw_targets_loop:
    CMP BYTE PTR [targetOn + SI], 1
    JNE draw_targets_next

    MOV DL, [targetCol + SI]
    MOV DH, [targetRow + SI]
    MOV AL, 'X'
    MOV BL, 0Ch
    CALL PutChar

draw_targets_next:
    INC SI
    LOOP draw_targets_loop

    RET
DrawTargets ENDP

DrawTopPanel PROC
    MOV DH, 0
    MOV DL, 2
    MOV SI, OFFSET hudAmmo
    CALL PrintText

    MOV DH, 0
    MOV DL, 16
    MOV SI, OFFSET hudScore
    CALL PrintText

    MOV DH, 0
    MOV DL, 32
    MOV SI, OFFSET hudBest
    CALL PrintText

    MOV DH, 0
    MOV DL, 48
    MOV SI, OFFSET hudTargets
    CALL PrintText

    MOV DH, 0
    MOV DL, 64
    MOV SI, OFFSET hudTime
    CALL PrintText

    MOV DH, 1
    MOV DL, 2
    MOV SI, OFFSET hudHelp
    CALL PrintText

    MOV DH, 1
    MOV DL, 56
    MOV SI, OFFSET hudLevel
    CALL PrintText

    CALL DrawLevelName

    RET
DrawTopPanel ENDP

DrawLevelName PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    MOV DH, 1
    MOV DL, 63
    MOV CX, 10
    CALL ClearTextArea

    MOV AL, [level]
    CMP AL, 1
    JE draw_level_easy

    CMP AL, 3
    JE draw_level_hard

    MOV SI, OFFSET hudMedName
    JMP draw_level_print

draw_level_easy:
    MOV SI, OFFSET hudEasyName
    JMP draw_level_print

draw_level_hard:
    MOV SI, OFFSET hudHardName

draw_level_print:
    MOV DH, 1
    MOV DL, 63
    CALL PrintText

    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DrawLevelName ENDP

DrawBestScore PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV DH, 0
    MOV DL, 38
    MOV CX, 5
    CALL ClearTextArea

    MOV AX, [bestScore]
    MOV DH, 0
    MOV DL, 38
    MOV BL, 0Eh
    CALL PrintNumber

    POP DX
    POP CX
    POP BX
    POP AX
    RET
DrawBestScore ENDP

DrawStats PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV DH, 0
    MOV DL, 8
    MOV CX, 5
    CALL ClearTextArea

    XOR AX, AX
    MOV AL, [ammoLeft]
    MOV DH, 0
    MOV DL, 8
    MOV BL, 0Eh
    CALL PrintNumber

    MOV DH, 0
    MOV DL, 23
    MOV CX, 5
    CALL ClearTextArea

    MOV AX, [score]
    MOV DH, 0
    MOV DL, 23
    MOV BL, 0Eh
    CALL PrintNumber

    MOV DH, 0
    MOV DL, 57
    MOV CX, 5
    CALL ClearTextArea

    XOR AX, AX
    MOV AL, [targetsLeft]
    MOV DH, 0
    MOV DL, 57
    MOV BL, 0Eh
    CALL PrintNumber

    POP DX
    POP CX
    POP BX
    POP AX
    RET
DrawStats ENDP

MoveTank PROC
    PUSH AX
    PUSH BX
    PUSH DX

    MOV DL, [tankCol]
    MOV DH, [tankRow]
    CALL NextTankCell

    CALL BlockedCell
    CMP AL, 1
    JE tank_blocked

    MOV [nextCol], DL
    MOV [nextRow], DH

    MOV DL, [tankCol]
    MOV DH, [tankRow]
    MOV AL, ' '
    MOV BL, 07h
    CALL PutChar

    MOV DL, [nextCol]
    MOV DH, [nextRow]
    MOV [tankCol], DL
    MOV [tankRow], DH

    CALL DrawTank
    JMP tank_move_done

tank_blocked:

    CALL DrawTank

tank_move_done:
    POP DX
    POP BX
    POP AX
    RET
MoveTank ENDP

NextTankCell PROC
    MOV AL, [tankDir]

    CMP AL, 0
    JE apply_up

    CMP AL, 1
    JE apply_down

    CMP AL, 2
    JE apply_left

    INC DL
    RET

apply_up:
    DEC DH
    RET

apply_down:
    INC DH
    RET

apply_left:
    DEC DL
    RET
NextTankCell ENDP

DrawTank PROC
    PUSH AX
    PUSH BX
    PUSH DX

    MOV AL, [tankDir]

    CMP AL, 0
    JE tank_up

    CMP AL, 1
    JE tank_down

    CMP AL, 2
    JE tank_left

    MOV AL, '>'
    JMP tank_draw

tank_up:
    MOV AL, '^'
    JMP tank_draw

tank_down:
    MOV AL, 'v'
    JMP tank_draw

tank_left:
    MOV AL, '<'

tank_draw:
    MOV DL, [tankCol]
    MOV DH, [tankRow]
    MOV BL, 0Ah
    CALL PutChar

    POP DX
    POP BX
    POP AX
    RET
DrawTank ENDP

Shoot PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    CMP BYTE PTR [ammoLeft], 0
    JE fire_done

    XOR SI, SI
    MOV CX, MAX_BULLETS

find_free_bullet_slot:
    CMP BYTE PTR [bulletOn + SI], 0
    JE free_bullet_slot_found

    INC SI
    LOOP find_free_bullet_slot

    JMP fire_done

free_bullet_slot_found:
    DEC BYTE PTR [ammoLeft]
    CALL DrawStats

    MOV AL, [tankCol]
    MOV [bulletCol + SI], AL

    MOV AL, [tankRow]
    MOV [bulletRow + SI], AL

    MOV BYTE PTR [bulletShown + SI], 0
    MOV AL, [tankDir]

    CMP AL, 0
    JE fire_up

    CMP AL, 1
    JE fire_down

    CMP AL, 2
    JE fire_left

    JMP fire_right

fire_up:
    MOV BYTE PTR [bulletColStep + SI], 0
    MOV BYTE PTR [bulletRowStep + SI], 0FFh
    JMP fire_start

fire_down:
    MOV BYTE PTR [bulletColStep + SI], 0
    MOV BYTE PTR [bulletRowStep + SI], 1
    JMP fire_start

fire_left:
    MOV BYTE PTR [bulletColStep + SI], 0FFh
    MOV BYTE PTR [bulletRowStep + SI], 0
    JMP fire_start

fire_right:
    MOV BYTE PTR [bulletColStep + SI], 1
    MOV BYTE PTR [bulletRowStep + SI], 0

fire_start:
    MOV BYTE PTR [bulletOn + SI], 1
    INC BYTE PTR [bulletCount]

    CALL MoveBullets

fire_done:
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
Shoot ENDP

MoveBullets PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    CMP BYTE PTR [bulletCount], 0
    JE update_bullet_done

    XOR SI, SI
    MOV CX, MAX_BULLETS

update_bullet_loop:
    CMP BYTE PTR [bulletOn + SI], 1
    JNE update_bullet_next

    CMP BYTE PTR [bulletShown + SI], 1
    JNE skip_clear_old_bullet

    MOV DL, [bulletCol + SI]
    MOV DH, [bulletRow + SI]
    MOV AL, ' '
    MOV BL, 07h
    CALL PutChar

    MOV AL, [bulletCol + SI]
    CMP AL, [tankCol]
    JNE skip_redraw_tank_after_clear

    MOV AL, [bulletRow + SI]
    CMP AL, [tankRow]
    JNE skip_redraw_tank_after_clear

    CALL DrawTank

skip_redraw_tank_after_clear:

skip_clear_old_bullet:

    MOV AL, [bulletCol + SI]
    ADD AL, [bulletColStep + SI]
    MOV [bulletCol + SI], AL

    MOV AL, [bulletRow + SI]
    ADD AL, [bulletRowStep + SI]
    MOV [bulletRow + SI], AL

    MOV DL, [bulletCol + SI]
    MOV DH, [bulletRow + SI]
    CALL TargetHere
    CMP AL, 1
    JE update_bullet_hit_target

    MOV DL, [bulletCol + SI]
    MOV DH, [bulletRow + SI]
    CALL WallHere
    CMP AL, 1
    JE update_bullet_stop

    MOV DL, [bulletCol + SI]
    MOV DH, [bulletRow + SI]
    MOV AL, '*'
    MOV BL, 0Eh
    CALL PutChar

    MOV BYTE PTR [bulletShown + SI], 1
    JMP update_bullet_next

update_bullet_hit_target:
    MOV DL, [bulletCol + SI]
    MOV DH, [bulletRow + SI]
    CALL HitTarget

    MOV BYTE PTR [bulletOn + SI], 0
    MOV BYTE PTR [bulletShown + SI], 0
    DEC BYTE PTR [bulletCount]
    JMP update_bullet_next

update_bullet_stop:
    MOV BYTE PTR [bulletOn + SI], 0
    MOV BYTE PTR [bulletShown + SI], 0
    DEC BYTE PTR [bulletCount]

update_bullet_next:
    INC SI
    LOOP update_bullet_loop

update_bullet_done:
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
MoveBullets ENDP

TargetHere PROC
    PUSH CX
    PUSH DX
    PUSH SI

    XOR SI, SI
    MOV CX, TARGET_COUNT

is_target_loop:
    CMP BYTE PTR [targetOn + SI], 1
    JNE is_target_next

    CMP BYTE PTR [targetCol + SI], DL
    JNE is_target_next

    CMP BYTE PTR [targetRow + SI], DH
    JNE is_target_next

    MOV AL, 1
    JMP is_target_done

is_target_next:
    INC SI
    LOOP is_target_loop

    MOV AL, 0

is_target_done:
    POP SI
    POP DX
    POP CX
    RET
TargetHere ENDP

BlockedCell PROC
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    CALL WallHere
    CMP AL, 1
    JE is_blocked_done

    XOR SI, SI
    MOV CX, TARGET_COUNT

check_target_block:
    CMP BYTE PTR [targetOn + SI], 1
    JNE next_target_block

    CMP BYTE PTR [targetCol + SI], DL
    JNE next_target_block

    CMP BYTE PTR [targetRow + SI], DH
    JNE next_target_block

    MOV AL, 1
    JMP is_blocked_done

next_target_block:
    INC SI
    LOOP check_target_block

    MOV AL, 0

is_blocked_done:
    POP SI
    POP DX
    POP CX
    POP BX
    RET
BlockedCell ENDP

WallHere PROC
    CMP DH, TOP_ROW
    JBE wall_blocked

    CMP DH, BOT_ROW
    JAE wall_blocked

    CMP DL, LEFT_COL
    JBE wall_blocked

    CMP DL, RIGHT_COL
    JAE wall_blocked

    MOV AL, [level]

    CMP AL, 1
    JE check_easy_obstacles

    CMP AL, 3
    JE check_hard_obstacles

    JMP check_medium_obstacles

check_easy_obstacles:

    CMP DH, 8
    JNE easy_h2

    CMP DL, 14
    JB easy_h2

    CMP DL, 30
    JBE wall_blocked

easy_h2:

    CMP DH, 18
    JNE easy_v1

    CMP DL, 36
    JB easy_v1

    CMP DL, 56
    JBE wall_blocked

easy_v1:

    CMP DL, 44
    JNE easy_v2

    CMP DH, 5
    JB easy_v2

    CMP DH, 12
    JBE wall_blocked

easy_v2:

    CMP DL, 60
    JNE free_cell

    CMP DH, 14
    JB free_cell

    CMP DH, 21
    JBE wall_blocked

    JMP free_cell

check_medium_obstacles:

    CMP DH, 7
    JNE med_h2

    CMP DL, 12
    JB med_h2

    CMP DL, 28
    JBE wall_blocked

med_h2:

    CMP DH, 15
    JNE med_h3

    CMP DL, 8
    JB med_h3

    CMP DL, 24
    JBE wall_blocked

med_h3:

    CMP DH, 20
    JNE med_v1

    CMP DL, 28
    JB med_v1

    CMP DL, 45
    JBE wall_blocked

med_v1:

    CMP DL, 38
    JNE med_v2

    CMP DH, 5
    JB med_v2

    CMP DH, 12
    JBE wall_blocked

med_v2:

    CMP DL, 55
    JNE free_cell

    CMP DH, 12
    JB free_cell

    CMP DH, 21
    JBE wall_blocked

    JMP free_cell

check_hard_obstacles:

    CMP DH, 6
    JNE hard_h2

    CMP DL, 9
    JB hard_h2

    CMP DL, 25
    JBE wall_blocked

hard_h2:

    CMP DH, 10
    JNE hard_h3

    CMP DL, 44
    JB hard_h3

    CMP DL, 68
    JBE wall_blocked

hard_h3:

    CMP DH, 16
    JNE hard_h4

    CMP DL, 6
    JB hard_h4

    CMP DL, 28
    JBE wall_blocked

hard_h4:

    CMP DH, 19
    JNE hard_v1

    CMP DL, 42
    JB hard_v1

    CMP DL, 62
    JBE wall_blocked

hard_v1:

    CMP DL, 36
    JNE hard_v2

    CMP DH, 5
    JB hard_v2

    CMP DH, 14
    JBE wall_blocked

hard_v2:

    CMP DL, 58
    JNE hard_v3

    CMP DH, 13
    JB hard_v3

    CMP DH, 22
    JBE wall_blocked

hard_v3:

    CMP DL, 22
    JNE free_cell

    CMP DH, 17
    JB free_cell

    CMP DH, 22
    JBE wall_blocked

free_cell:
    MOV AL, 0
    RET

wall_blocked:
    MOV AL, 1
    RET
WallHere ENDP

HitTarget PROC
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    XOR SI, SI
    MOV CX, TARGET_COUNT

hit_loop:
    CMP BYTE PTR [targetOn + SI], 1
    JNE hit_next

    CMP BYTE PTR [targetCol + SI], DL
    JNE hit_next

    CMP BYTE PTR [targetRow + SI], DH
    JNE hit_next

    MOV BYTE PTR [targetOn + SI], 0
    DEC BYTE PTR [targetsLeft]
    ADD WORD PTR [score], 10

    MOV AL, ' '
    MOV BL, 07h
    CALL PutChar

    CALL DrawStats

    MOV AL, 1
    JMP hit_done

hit_next:
    INC SI
    LOOP hit_loop

    MOV AL, 0

hit_done:
    POP SI
    POP DX
    POP CX
    POP BX
    RET
HitTarget ENDP

CheckGameOver PROC
    CMP BYTE PTR [gameOver], 1
    JE check_done

    CMP BYTE PTR [targetsLeft], 0
    JNE check_ammo

    MOV BYTE PTR [resultCode], 1
    MOV BYTE PTR [gameOver], 1
    RET

check_ammo:
    CMP BYTE PTR [ammoLeft], 0
    JNE check_done

    CMP BYTE PTR [bulletCount], 0
    JNE check_done

    MOV BYTE PTR [resultCode], 2
    MOV BYTE PTR [gameOver], 1

check_done:
    RET
CheckGameOver ENDP

ResultScreen PROC
    CALL SaveBestScore
    CALL ClearScreen

    MOV DH, 4
    MOV DL, 9
    MOV SI, OFFSET introLine
    CALL PrintText

    MOV DH, 6
    MOV DL, 34
    MOV SI, OFFSET overTitle
    CALL PrintText

    MOV DH, 8
    MOV DL, 9
    MOV SI, OFFSET introLine
    CALL PrintText

    CMP BYTE PTR [resultCode], 1
    JE show_win

    CMP BYTE PTR [resultCode], 4
    JE show_time

    JMP show_lose

show_win:
    MOV DH, 11
    MOV DL, 19
    MOV SI, OFFSET overWin
    CALL PrintText
    JMP result_text_done

show_lose:
    MOV DH, 11
    MOV DL, 28
    MOV SI, OFFSET overLose
    CALL PrintText
    JMP result_text_done

show_time:
    MOV DH, 11
    MOV DL, 30
    MOV SI, OFFSET overTime
    CALL PrintText

result_text_done:
    MOV DH, 13
    MOV DL, 27
    MOV SI, OFFSET overScore
    CALL PrintText

    MOV AX, [score]
    MOV DH, 13
    MOV DL, 39
    MOV BL, 0Eh
    CALL PrintNumber

    MOV DH, 14
    MOV DL, 27
    MOV SI, OFFSET overBest
    CALL PrintText

    MOV AX, [bestScore]
    MOV DH, 14
    MOV DL, 41
    MOV BL, 0Eh
    CALL PrintNumber

    MOV DH, 17
    MOV DL, 26
    MOV SI, OFFSET overMenu1
    CALL PrintText

    MOV DH, 18
    MOV DL, 31
    MOV SI, OFFSET overMenu2
    CALL PrintText

    MOV DH, 20
    MOV DL, 31
    MOV SI, OFFSET overAsk
    CALL PrintText

    MOV DH, 21
    MOV DL, 9
    MOV SI, OFFSET introLine
    CALL PrintText

result_wait:
    MOV AH, 00h
    INT 16h

    CMP AL, 'r'
    JE result_restart

    CMP AL, 'R'
    JE result_restart

    CMP AL, 'q'
    JE result_quit

    CMP AL, 'Q'
    JE result_quit

    JMP result_wait

result_restart:
    MOV AL, 'R'
    RET

result_quit:
    MOV AL, 'Q'
    RET
ResultScreen ENDP

SaveBestScore PROC
    PUSH AX

    MOV AX, [score]
    CMP AX, [bestScore]
    JBE best_session_done

    MOV [bestScore], AX

best_session_done:
    POP AX
    RET
SaveBestScore ENDP

ClearScreen PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV AX, 0003h
    INT 10h

    MOV AX, 0600h
    MOV BH, 07h
    MOV CX, 0000h
    MOV DX, 184Fh
    INT 10h

    MOV DH, 0
    MOV DL, 0
    CALL SetCursor
    CALL HideCursor

    POP DX
    POP CX
    POP BX
    POP AX
    RET
ClearScreen ENDP

HideCursor PROC
    MOV AH, 01h
    MOV CH, 20h
    MOV CL, 00h
    INT 10h
    RET
HideCursor ENDP

ShowCursor PROC
    MOV AH, 01h
    MOV CH, 06h
    MOV CL, 07h
    INT 10h
    RET
ShowCursor ENDP

SetCursor PROC
    PUSH AX
    PUSH BX

    MOV AH, 02h
    MOV BH, 0
    INT 10h

    POP BX
    POP AX
    RET
SetCursor ENDP

PrintText PROC
    PUSH AX
    PUSH DX

    CALL SetCursor

    MOV DX, SI
    MOV AH, 09h
    INT 21h

    POP DX
    POP AX
    RET
PrintText ENDP

PrintNumber PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    MOV [textRow], DH
    MOV [textCol], DL
    MOV [textColor], BL

    CMP AX, 0
    JNE pw_convert

    MOV AL, '0'
    MOV DH, [textRow]
    MOV DL, [textCol]
    MOV BL, [textColor]
    CALL PutChar
    JMP pw_done

pw_convert:
    MOV SI, OFFSET numBuffer
    XOR CX, CX
    MOV BX, 10

pw_divide:
    XOR DX, DX
    DIV BX
    MOV [SI], DL
    INC SI
    INC CX
    CMP AX, 0
    JNE pw_divide

pw_print:
    DEC SI
    MOV AL, [SI]
    ADD AL, '0'

    MOV DH, [textRow]
    MOV DL, [textCol]
    MOV BL, [textColor]
    CALL PutChar

    INC BYTE PTR [textCol]
    LOOP pw_print

pw_done:
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PrintNumber ENDP

ClearTextArea PROC
    PUSH AX
    PUSH BX

    MOV AL, ' '
    MOV BL, 07h
    CALL DrawRow

    POP BX
    POP AX
    RET
ClearTextArea ENDP

DrawRow PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    CALL SetCursor

    MOV AH, 09h
    MOV BH, 0
    INT 10h

    POP DX
    POP CX
    POP BX
    POP AX
    RET
DrawRow ENDP

DrawColumn PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

v_loop:
    CALL PutChar
    INC DH
    LOOP v_loop

    POP DX
    POP CX
    POP BX
    POP AX
    RET
DrawColumn ENDP

PutChar PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    CALL SetCursor

    MOV AH, 09h
    MOV BH, 0
    MOV CX, 1
    INT 10h

    POP DX
    POP CX
    POP BX
    POP AX
    RET
PutChar ENDP

SmallDelay PROC
    PUSH CX

    MOV CX, 25

game_delay_loop:
    LOOP game_delay_loop

    POP CX
    RET
SmallDelay ENDP

ExitProgram:
    CALL ShowCursor
    MOV AX, 0003h
    INT 10h

    MOV AX, 4C00h
    INT 21h

END start
