RAM_CURRENT_MENU_SELECTION: equ $FF3F80
RAM_TEXT_DRAW_POSITION:     equ $FF0006

NEW_MAX_SETTINGS_INDEX:     equ $5

FUNCTION_DRAW_TEXT:         equ $560
FUNCTION_UPDATE_OPTION_TEXT equ $55D6

TEXT_TABLE:
    dc.b $40
    dc.b $0B, $02 ; X,Y
    dc.b "Configuration Mode", $00, $00
    dc.b $08, $05 ; X,Y
    dc.b "Game level", $00, $00
    dc.b $08, $08 ; X,Y
    dc.b "Music test               0", $00, $00
    dc.b $08, $0B ; X,Y
    dc.b "Sound test               0", $00, $00
    dc.b $08, $0E ; X,Y
    dc.b "Strafe shoot (XYZ)", $00, $00
    dc.b $08, $11 ; X,Y
    dc.b "Control PAD mode  A:Magic", $00, $00
    dc.b $08, $13 ; X,Y
    dc.b "                  B:Shot", $00, $00
    dc.b $08, $15 ; X,Y
    dc.b "                  C:Select", $00, $00
    dc.b $08, $17 ; X,Y
    dc.b "EXIT", $00
    dc.w $FFFF

    align 2

FUNCTION_TOGGLE_STRAFE:
    eori.w #$1,(RAM_STRAFE_ENABLED)
    jmp FUNCTION_UPDATE_OPTION_TEXT

DETOUR_CURSOR_POSITION_TABLE:
    move.w (.table-DETOUR_CURSOR_POSITION_TABLE-2,PC,D1.w),($6,A6)
    dc.w $F004
    dc.w $0001
    jmp $5722
.table
    dc.w $0300 ; Game level
    dc.w $0480 ; Music test
    dc.w $0600 ; Sound test
    dc.w $0780 ; Strafe
    dc.w $0900 ; Control PAD mode
    dc.w $0C00 ; EXIT (unchanged, just for completeness sake)

DETOUR_LEFT_HANDLER:
    movea.l (.table-DETOUR_LEFT_HANDLER-2,PC,D1.w),A0
    move.w ($FF3F80),D1
    jmp (A0)
.table
    dc.l $000054E0              ; Game level
    dc.l $000054FC              ; Music test
    dc.l $00005518              ; Sound test
    dc.l FUNCTION_TOGGLE_STRAFE ; Strafe Mode
    dc.l $00005534              ; Control PAD mode
    dc.l $000053C8              ; EXIT ???

DETOUR_RIGHT_HANDLER:
    movea.l (.table-DETOUR_RIGHT_HANDLER-2,PC,D1.w),A0
    move.w ($FF3F80),D1
    jmp (A0)
.table
    dc.l $0000557E              ; Game level
    dc.l $00005594              ; Music test
    dc.l $000055AA              ; Sound test
    dc.l FUNCTION_TOGGLE_STRAFE ; Strafe Mode
    dc.l $000055C0              ; Control PAD mode
    dc.l $000053C8              ; EXIT ???

DETOUR_UPDATE_OPTION_TEXT_HANDLER:
    movea.l (.table-DETOUR_UPDATE_OPTION_TEXT_HANDLER-2,PC,D1.w),A0
    jmp (A0)
.table
    dc.l $000055F2 ; Game level
    dc.l $00005638 ; Music test
    dc.l $0000564C ; Sound test
    dc.l UPDATE_STRAFE_OPTION ; Strafe Mode
    dc.l $00005660 ; Control PAD Mode
    dc.l $000055F2 ; EXIT ???

UPDATE_STRAFE_OPTION:
    move.w #$1F0E,(RAM_TEXT_DRAW_POSITION)
    move.w (RAM_STRAFE_ENABLED),D1
    asl.w #$2,D1
    movea.l (.table-*-2,PC,D1),A1
    jmp FUNCTION_DRAW_TEXT
.table
    dc.l STRAFE_OPTION_VALUE_OFF
    dc.l STRAFE_OPTION_VALUE_ON

STRAFE_OPTION_VALUE_ON:
    dc.b " On", $00
STRAFE_OPTION_VALUE_OFF:
    dc.b "Off", $00

    org $5366
    lea TEXT_TABLE,A1

    org $55F5 ; Change vertical position of currently set difficulty value
    dc.b $05

    org $563B ; Change vertical position of currently set music track
    dc.b $08

    org $564F ; Change vertical position of currently set SFX
    dc.b $0B

    org $566B ; Change vertical position of currently set A function
    dc.b $11

    org $567B ; Change vertical position of currently set B function
    dc.b $13

    org $568B ; Change vertical position of currently set C function
    dc.b $15

    org $573C  ; Change vertical cursor positions
    dc.w $0300 ; Game level
    dc.w $0480 ; Music test
    dc.w $0600 ; Sound test
    dc.w $0900 ; Control PAD mode
    dc.w $0C00 ; EXIT (unchanged, just for completeness sake)

    org $5434
    cmpi.w #NEW_MAX_SETTINGS_INDEX,(RAM_CURRENT_MENU_SELECTION) ; Ensures user can press A on EXIT to exit

    org $54C0
    jmp DETOUR_LEFT_HANDLER

    org $555E
    jmp DETOUR_RIGHT_HANDLER

    org $55D8
    jmp DETOUR_UPDATE_OPTION_TEXT_HANDLER

    org $56DE
    move.w #NEW_MAX_SETTINGS_INDEX,(RAM_CURRENT_MENU_SELECTION) ; If user goes up on lowest selection return to new highest selection

    org $56F0
    cmpi.w #NEW_MAX_SETTINGS_INDEX+1,(RAM_CURRENT_MENU_SELECTION) ; If user exceeds new highest selection return to lowest selection

    org $5730
    jmp DETOUR_CURSOR_POSITION_TABLE