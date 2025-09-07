; Build params: ------------------------------------------------------------------------------

CHEATS set 0
SIX_BUTTON_SUPPORT set 1
MED_PRO_VOLUME_REDUCTION set 0

; Constants: ---------------------------------------------------------------------------------
	TRACK_MAX_INDEX:				equ 25
	DEATH_TRACK_ID:					equ 22

	MD_PLUS_OVERLAY_PORT:			equ $0003F7FA
	MD_PLUS_CMD_PORT:				equ $0003F7FE
	MD_PLUS_RESPONSE_PORT:			equ $0003F7FC

	RESET_VECTOR_ORIGINAL:			equ $000046CC

	OFFSET_RESET_VECTOR:			equ $00000004
	OFFSET_SOUND_REQUEST_Z80_BUS:   equ $00000F06
	OFFSET_AFTER_CONTROLLER_READ:	equ $000012AC
	OFFSET_START_PLAY_CALL:			equ $00005494
	OFFSET_MOVEMENT_TURN_CODE:		equ $00008AB8
	OFFSET_LOSE_HURT_FUNCTION:		equ $00008E5E
	OFFSET_HANDLE_SOUND_COMMAND:	equ $00030364

	RAM_BUTTON_STATE:					equ $FF2928
	RAM_CONFIGURED_SHOOT_BUTTON_BIT:	equ $FF3FA3
	RAM_STRAFE_LOCK: 					equ $FF8F03
	RAM_TURN_DIRECTION: 				equ $FF8F26
	RAM_TRACK_PLAY_LIST:				equ $FFF002

	; Own RAM values:
	RAM_FADE_OUT_PLAY_TRACK_NUMBER: equ $FFFF50
	RAM_MUSIC_STOPPED:				equ $FFFF51
	RAM_FADE_OUT_COUNTER:			equ $FFFF52
	RAM_SIX_BUTTON_STATE:			equ $FFFF54

	REGISTER_CNT1_DATA:		equ $A10003
	REGISTER_Z80_BUS_REQ:	equ $A11100 

	INTERNAL_SOUND_COMMAND_PLAY_MUSIC:	 			equ $01
	INTERNAL_SOUND_COMMAND_STOP_FADE_OUT_MUSIC:		equ $02
	INTERNAL_SOUND_COMMAND_FADE_OUT_PLAY_MUSIC: 	equ $03
	INTERNAL_SOUND_COMMAND_TOGGLE_PAUSE_MUSIC:		equ $04

	TRACK_01:						equ $00  ; 01 - Mad Dog 			(Stage 1)
	TRACK_02:						equ $01  ; 02 - sKILL				(Stage 4)
	TRACK_03:						equ $02  ; 03 - Encounter			(Stage 3)
	TRACK_04:						equ $03  ; 04 - Mad Stalker			(Stage 2)
	TRACK_05:						equ $04  ; 05 - On Tactics 	 		(Stage 5)
	TRACK_06:						equ $05  ; 06 - Boiling Point 		(Stage 6 / Boss [1 for PS1, all for PCE])
	TRACK_07:						equ $06  ; 07 - Crash Beat			(Last Boss)
	TRACK_08:						equ $07  ; 08 - Artemis City 2142 	(Opening 1) 
	TRACK_09:						equ $08  ; 09 - Aftermath			(Stage 3 end cutscene - Missing in PCE sountrack?)
	TRACK_10:						equ $09  ; 10 - A Solution			(Ending) 
	TRACK_11:						equ $0A  ; 11 - Omega Drivin'		(Player Select)
	TRACK_STOP:						equ $0B
	; Extended version tracks:
	TRACK_12:						equ $0C  ; 12 - Climax				[Stage 6-1]
	TRACK_13:						equ $0D  ; 13 - Core/Escape 		[Boss 6 for PS1, Stage 6-2 for PCE]
	TRACK_14:						equ $0E	 ; 14 - Rising Dog			[Boss 2][PS1 only]
	TRACK_15:						equ $0F	 ; 15 - Silpheed			[Boss 3][PS1 only]
	TRACK_16:						equ $10	 ; 16 - Prisoner Beta		[Boss 4][PS1 only]
	TRACK_17:						equ $11	 ; 17 - Kamui				[Boss 5][PS1 only]

; Overrides: ---------------------------------------------------------------------------------

	org OFFSET_RESET_VECTOR
	dc.l DETOUR_RESET_VECTOR

	if CHEATS
		org OFFSET_LOSE_HURT_FUNCTION
		nop
		nop
	endif

	org OFFSET_HANDLE_SOUND_COMMAND
	jsr DETOUR_HANDLE_SOUND_COMMAND

	org OFFSET_SOUND_REQUEST_Z80_BUS
	jsr DETOUR_SOUND_REQUEST_Z80_BUS
	nop

	if SIX_BUTTON_SUPPORT
		org OFFSET_AFTER_CONTROLLER_READ
		jsr DETOUR_READ_6_BUTTON

		org OFFSET_MOVEMENT_TURN_CODE
		jsr DETOUR_MOVEMENT
		nop
	endif

; Detours: -----------------------------------------------------------------------------------

	org $00100000

DETOUR_RESET_VECTOR:
	move.w	#$1300,D0
	jsr WRITE_MD_PLUS_FUNCTION

	if MED_PRO_VOLUME_REDUCTION
		move.w $A130D4,D0
		andi.w #$FFF0,D0
		cmpi.w #$55A0,D0
		bne .notMegaEverdrivePro					; Since the Mega Everdrive PRO does not have volume adjustment options,
		move.w #$15C8,D0							; manually detect it and set the volume to ~80%
		jsr WRITE_MD_PLUS_FUNCTION
.notMegaEverdrivePro
	endif

	incbin	"intro.bin"								; Show MD+ intro screen
	jmp		RESET_VECTOR_ORIGINAL					; Return to game's original entry point

	if SIX_BUTTON_SUPPORT
DETOUR_MOVEMENT:
		move D0,-(A7)
		move.b RAM_CONFIGURED_SHOOT_BUTTON_BIT,D0
		btst D0,RAM_SIX_BUTTON_STATE
		bne .strafe
		move.b D1,($26,A6)
.strafe
		move.w ($24,A6),D2
		move (A7)+,D0
		rts

DETOUR_READ_6_BUTTON:
		movem D0/D1/D2,-(A7)
		or.b D6,D7
		not.b D7
		move.w	A6,D0
		cmpi.b #$03,D0
		bne .secondControllerRead
		move.b #$0,REGISTER_CNT1_DATA			; Cycle 3
		nop
		nop
		move.b #$40,REGISTER_CNT1_DATA			; Cycle 4
		nop
		nop
		move.b #$0,REGISTER_CNT1_DATA			; Cycle 5
		nop
		nop
		move.b REGISTER_CNT1_DATA,D0
		cmpi.b #%00110000,REGISTER_CNT1_DATA	; Check for 6 Button controller id
		beq .isSixButtonController
		clr.b D0
		bra .notSixButtonController
.isSixButtonController
		nop
		nop
		move.b #$40,REGISTER_CNT1_DATA			; Cycle 6
		nop
		nop
		move.b REGISTER_CNT1_DATA,D0
		not D0
		andi.b #$7,D0
		lsl.b #$4,D0
												; Swap bits so they are arranged like ABC in D7
		move.b  D0,D1							; copy original byte
		and.b   #$10,D1							; isolate bit 4
		lsl.b   #1,D1							; move bit 4 to bit 5 position
		move.b  D0,D2
		and.b   #$20,D2							; isolate bit 5
		lsr.b   #1,D2							; move bit 5 to bit 4 position
		and.b   #$CF,D0							; 11001111 -> clear bits 5 and 4
		or.b    D1,D0							; Insert swapped bits
		or.b    D2,D0

.notSixButtonController
		move.b D0,RAM_SIX_BUTTON_STATE
		or.b D0,D7								; Copy six button state into D7 to mirror controls onto XYZ
.secondControllerRead
		move.b (A5),D6
		movem (A7)+,D0/D1/D2
		rts
	endif

DETOUR_SOUND_REQUEST_Z80_BUS:
	move.w D0,-(A7)
	clr.w D0
	move.b RAM_FADE_OUT_PLAY_TRACK_NUMBER,D0
	tst.b D0
	beq .noFadeOut
	subi.w #$1,RAM_FADE_OUT_COUNTER
	bne .noFadeOut
	ori.w #$1200,D0
	jsr WRITE_MD_PLUS_FUNCTION
	clr.b RAM_FADE_OUT_PLAY_TRACK_NUMBER
.noFadeOut
	move.w (A7)+,D0
	move.w #$100,REGISTER_Z80_BUS_REQ
	rts

DETOUR_HANDLE_SOUND_COMMAND:
	lea RAM_TRACK_PLAY_LIST.l,A0
	movem.l D0/D2,-(A7)
	move.w #$1300,D0
	move.w D1,D2
	lsr.w #8,D2
	cmpi.b #INTERNAL_SOUND_COMMAND_TOGGLE_PAUSE_MUSIC,D2
	beq .togglePauseMusic
	cmpi.b #INTERNAL_SOUND_COMMAND_FADE_OUT_PLAY_MUSIC,D2
	beq .fadeOutPlayMusic
	cmpi.b #INTERNAL_SOUND_COMMAND_STOP_FADE_OUT_MUSIC,D2
	beq .stopFadeOutMusic
	cmpi.b #INTERNAL_SOUND_COMMAND_PLAY_MUSIC,D2
	beq .playMusic
.functionEnd
	movem.l (A7)+,D0/D2
	rts

.doSoundCommand
	jsr WRITE_MD_PLUS_FUNCTION
.doNothing
	move.b #$0,D1
	bra .functionEnd

.togglePauseMusic
	;movem.l D0-D7/A0-A6,-(A7)					; Take damage on start press
	;jsr $8e04
	;movem.l (A7)+,D0-D7/A0-A6
	;bra .doNothing
	tst.b RAM_MUSIC_STOPPED						; If the music has been stopped fully, do not pause/resume
	bne .doNothing
	cmpi.w #$38E,D3								; If not equal: Pause, if equal: resume
	bne .isPause
	move.w #$1400,D0
	bra .doSoundCommand
.isPause
	tst.b RAM_FADE_OUT_PLAY_TRACK_NUMBER
	beq .doSoundCommand
	move.w #$1200,D0
	or.b RAM_FADE_OUT_PLAY_TRACK_NUMBER,D0
	clr.b RAM_FADE_OUT_PLAY_TRACK_NUMBER
	jsr WRITE_MD_PLUS_FUNCTION
	move.w #$1300,D0
	bra .doSoundCommand

.playMusic
	cmpi.b #TRACK_MAX_INDEX,D1
	bgt .unplayableTrackNumber
	tst.b D1
	beq .unplayableTrackNumber
	move.w #$1200,D0
	or.b D1,D0
.unplayableTrackNumber
	clr.b RAM_MUSIC_STOPPED
	clr.b RAM_FADE_OUT_PLAY_TRACK_NUMBER
	bra .doSoundCommand

.stopFadeOutMusic
	move.b #$1,RAM_MUSIC_STOPPED
	tst.b D1
	beq .noFadeOutStop
	move.b D1,D0
	lsl.b #$4,D0
.noFadeOutStop
	clr.b RAM_FADE_OUT_PLAY_TRACK_NUMBER
	bra .doSoundCommand

.fadeOutPlayMusic
	move.b D1,RAM_FADE_OUT_PLAY_TRACK_NUMBER
	move.w #$1390,D0
	move.w #$10A,RAM_FADE_OUT_COUNTER
	bra .doSoundCommand

; Helper Functions: --------------------------------------------------------------------------

WRITE_MD_PLUS_FUNCTION:
	move.w  #$CD54,(MD_PLUS_OVERLAY_PORT)			; Open interface
	move.w  D0,(MD_PLUS_CMD_PORT)					; Send command to interface
	move.w  #$0000,(MD_PLUS_OVERLAY_PORT)			; Close interface
	rts