;;;
;;; 1hz.m4
;;;
;;; I went through a brief face when I tried "Racing the Beam", 
;;; which is basically learning how to program the Atari 2600.
;;; This machine first came out in 1977, and had a 6507, the
;;; poorer sibling of the common 6502 from that era.  The Atari
;;; 2600 (also known as the Video Computing System, or VCS) had
;;; just 128 bytes of RAM, and the baseline cartridges just 2K
;;; of ROM.  It also had essentially no framebuffer: the background
;;; playfield was just a 40 bit shift register, and it had a
;;; two player registers which were clocked out by a custom chip 
;;; called the TIA (the Television Interface Adapter).  
;;;
;;; On such a machine, Pong is pretty simple, but doing things
;;; that are more sophisticated can be quite difficult.   It is 
;;; amazing how skilled programmers created games which would
;;; have been unimaginable by the machine creators.
;;;
;;; Back to the 1Hz challenge...
;;;
;;; Around 2006, the Dutch design firm Buro Vormkrijgers
;;; created a clock that told the time by playing a game of Pong.
;;; The paddles would move up and down and when minutes and 
;;; hours were incremented, the appropriate side would "lose",
;;; so that the score recorded the time.   In 2010, I was 
;;; interested in maybe doing another project using the 
;;; Atari 2600, so I decided that I would go ahead and implement
;;; my own version of the Pong Clock using the Atari 2600 as
;;; base hardware.   
;;;
;;; Fast forwarding to 2025, I heard about the Hackaday 
;;; 1Hz challenge, and thought that it might be fun to dust off
;;; this code, and repackage it with a few bug fixes.  The ball
;;; should hit the paddle at a precise 1Hz interval, except when
;;; the minutes or hours are incremented.  It is designed for 
;;; use on the NTSC versions, counting the 60 frames per second,
;;; and automatically find tunes the speed of the ball to maintain
;;; a 60hz update rate.
;;;
;;; I've also decided to make some minor tweaks.  The original
;;; code told time in 0-23 hour format, which seems less desirable
;;; to me.  I also wanted to fix the score update (in 
;;; previous versions it incremented the minute/hour before the 
;;; miss was displayed.   I hope to get that sorted out in 
;;; this version.




	.include "vcs.h"
	.org $80
	.space RESTARTDUR	1
	.space TIME_FRAME 	1
	.space GLIDER_IDX	1

	.space BEEPDUR	  	1

	.space BALLDY	  2
	.alias BALLDYL	  BALLDY
	.alias BALLDYH	  BALLDY+1

	.space BALLY	  2
	.alias BALLYL	  BALLY
	.alias BALLYH	  BALLY+1

	.space BALLDX	  2
	.alias BALLDXL	  BALLDX
	.alias BALLDXH	  BALLDX+1

	.space TITLE_TIME 	2
	.alias DISPLAY_INTRO    300	;;; frames to display intro. (300 == 5s)
	.space TOP0	  	1
	.space TOP1	  	1
	.space BOT0	  1
	.space BOT1	  1
	.space TOPBALL	  1
	.space BOTBALL	  1
	.space TOPTMP	  1
	.space BOTTMP	  1

	.space TMP	  2
	.alias TMPL	  TMP
	.alias TMPH	  TMP+1

	.space BALLX	  2
	.alias BALLXL	  BALLX
	.alias BALLXH	  BALLX+1

	.space RAND	  2
	.alias RANDL	  RAND
	.alias RANDH	  RAND+1

	.space DIGIT0	  2
	.space DIGIT1 	  2
	.space DIGIT2	  2
	.space DIGIT3 	  2

	.space TIME_SEC	  1
	.space TIME_MIN	  1
	.space TIME_HR	  1
        ;;; TIME_HR2 is the display version of TIME_HR
        .space TIME_HR2   1

	.space TCNT	  1
	.space MISS0	  1
	.space MISS1	  1
	.space NOISE	  1

        ;;;
        ;;; Updated in 2025... 
        ;;; Port A on the VCS can be configured to output as well
        ;;; as input.  JOY_{RIGHT,LEFT,DOWN,UP} below are for 
        ;;; the P0 joystick.  Normally, both joystick ports
        ;;; are configured for input, but you can configure 
        ;;; the two joystick ports as outputs as well.  I 
        ;;; decided to configure one of them the P1 joystick
        ;;; to be outputs, and to drive the outputs up at a 
        ;;; 1Hz rate...
        ;;;
	.alias JOY_RIGHT	%10000000
	.alias JOY_LEFT		%01000000
	.alias JOY_DOWN		%00100000
	.alias JOY_UP		%00010000

	.space JOYTIMEOUT 0
	
	.space GLIDER_X		1
	.space GLIDER_Y		1
	.space COLOR_BG		1
	.space COLOR_PADDLE	1
	.space COLOR_BALL	1
	.space COLOR_SCORE	1
	.space COLOR_BORDER	1

	.org $F800

fineAdjustBegin:
	.byte %01110000	;;; Left 7 
	.byte %01100000	;;; Left 6
	.byte %01010000	;;; Left 5
	.byte %01000000	;;; Left 4
	.byte %00110000	;;; Left 3
	.byte %00100000	;;; Left 2
	.byte %00010000	;;; Left 1
	.byte %00000000	;;; No movement.
	.byte %11110000	;;; Right 1
	.byte %11100000	;;; Right 2
	.byte %11010000	;;; Right 3
	.byte %11000000	;;; Right 4
	.byte %10110000	;;; Right 5
	.byte %10100000	;;; Right 6
	.byte %10010000	;;; Right 7

.alias fineadjusttable fineAdjustBegin-241

define(`doball', `;;; DOBALL
	lda #0
	cpy $2
	bcs +
	cpy $1
	bcc +
	lda #2
*	
	sta $3')
	
main:
	sei
	cld
	ldx #0	
	txa
	tay
*	dex
	txs
	pha
	bne -

	lda #$8c	
	sta colupf
	lda #$80
	sta colubk

	; missiles are the same color as the players...
	lda #$0f
	sta colup0
	lda #$0f
	sta colup1

	lda #<DISPLAY_INTRO
	sta TITLE_TIME
	lda #>DISPLAY_INTRO
	sta TITLE_TIME+1


	lda #80
	sta GLIDER_X
	sta GLIDER_Y
	lda #0
	sta GLIDER_IDX

	lda #%00000111
	sta nusiz0

	lda #1
	sta RANDL
	sta RANDH

        ;;;
        ;;; Time is in the range of 00:00 to 23:59, which
        ;;; we will then (potentially) shift to 12 hour 
        ;;; time for display based the switch settings...
        ;;; 
	lda #0
	sta TIME_FRAME
        sta TIME_SEC
        sta TIME_MIN
        sta TIME_HR


titlekernel:
	lda #2
*
	sta wsync
	sta vsync
	lda #$F0		; -1 in high nybble
	sta hmm0
	lda #$10		; +1 in high nybble
	sta hmm1
	sta wsync
	sta hmove
	sta wsync
	sta vsync

dovblank:
	lda #45
	sta tim64t

	ldx #0			; position the glider...
	lda GLIDER_X
	jsr PosObject

* 	lda intim
	bne -
	sta wsync
	sta vblank

playfield:
	ldy #35
*
	tya
	lsr
	lsr
	lsr
	and #3
	clc
	adc GLIDER_IDX
	adc GLIDER_IDX
	adc GLIDER_IDX
	adc GLIDER_IDX
	tax
	lda glider0, x
	sta wsync
	sta grp0
	dey
	bne -

;; title loop
	ldx #15
resety:
	ldy #8
titleloop:
	sta wsync
	lda PFDATA0L-1,X
	sta PF0
	lda PFDATA1L-1,X
	sta PF1
	lda PFDATA2L-1,X
	sta PF2
	nop
	nop
	nop
	nop
	nop
	nop
	lda PFDATA0R-1,X
	sta PF0
	lda PFDATA1R-1,X
	sta PF1
	lda PFDATA2R-1,X
	sta PF2
	dey
	bne titleloop
	dex
	beq titledone
	jmp resety
titledone:
        lda #0
        sta PF0
        sta PF1
        sta PF2

	ldy #36
*
	dey
	sta wsync
	bne -

	lda #$42
	sta vblank
overscan:
	lda #35
	sta tim64t

	inc TIME_FRAME
	lda TIME_FRAME
	CMP #12
	bcc +
	lda #0
	sta TIME_FRAME
	ldx GLIDER_IDX
	inx
	txa 
	and #3
	sta GLIDER_IDX
*

*	lda intim
	bne -
	sta wsync

	lda TITLE_TIME
	bne +
	dec TITLE_TIME+1
*	dec TITLE_TIME
	lda TITLE_TIME
	ora TITLE_TIME+1
	beq pong
	jmp titlekernel

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pong:
        ;;;
        ;;; Configure P1 joystick as outputs...
        ;;;
        lda #15
        sta swacnt

        ; zero out the play field
        lda #0
        sta PF0
        sta PF1
        sta PF2
	; play field is reversed, missiles are quadruple wide.
	; D4-D5 = 10 
	; D2 = 1 means ball goes in front of players.
	lda #%00100101		
	sta ctrlpf

	lda #2
	sta enam0
	sta enam1

	lda #40
	sta TOP0
	clc
	adc #40
	sta BOT0
	lda #80
	sta TOP1
	clc
	adc #40
	sta BOT1

	;;; set up the ball positions...

	lda #77			; in X
	sta BALLXH
	lda #0
	sta BALLXL

	lda #2			; and X velocity
	sta BALLDXH
	lda #$c
	sta BALLDXL


	lda #0			; and Y
	sta BALLYL
        lda #80	
	sta BALLYH

	lda #0
	sta BALLDYL
	sta BALLDYH

	lda #2
	sta enam0
	sta enam1
	sta enabl

	lda #0
	sta BEEPDUR

pongkernel:

	lda #2		; vsync
*
	sta wsync
	sta vsync
	lda #0
	sta wsync
	; position...
	sta cxclr
	sta hmclr
	sta wsync
	sta vsync

	lda #45		; vblank
	sta tim64t

	;;; position the paddles horizontally...

	ldx #0
	lda #61		; 80-24+5
	jsr PosObject

	ldx #1
	lda #69		; 80-16+5
	jsr PosObject

	ldx #2
	lda #23		; 16 + 5
	jsr PosObject

	ldx #3
	lda #149	; 160-16+5
	jsr PosObject

	lda RESTARTDUR		;;; don't move the ball if we are restarting.
	bne skip_miss_check

	; now, handle the ball...
	lda BALLXL
	clc
	adc BALLDXL
	sta BALLXL
	lda BALLXH
	adc BALLDXH
	sta BALLXH
	ldx #4
	jsr PosObject

	;;; might as well handle the miss...
	;;; unless we are already restarting.

	ldx #0
	lda BALLXH
	cmp #6
	bcs not_left
	jsr reset_ball
	stx MISS0
	jmp not_right
not_left:
	cmp #159
	bcc not_right
	jsr reset_ball
	stx MISS1
not_right:

skip_miss_check:

	sta wsync
	sta HMOVE

	;;; okay, here's some vblank processing.

	lda RESTARTDUR
	bne skip_y_update

	lda BALLDYL
	clc
	adc BALLYL
	sta BALLYL
	lda BALLDYH
	adc BALLYH
	sta BALLYH


	lda BALLYH
	clc
	adc #4
	sta BOTBALL
	sec
	sbc #8
	sta TOPBALL


	;;; okay, if the ball's velocity is positive, we 
	;;; will update the position of player one, if negative,
	;;; then player two...

	lda #0
	sta NOISE

	lda BALLDXH
	cmp #$80
	bcs + 		;;; branch if negative (right to left)
		
	;;; right to left...
	lda MISS1
	beq track
	lda #60
	sta NOISE
	jmp track
*
	lda MISS0
	beq track
	lda #60
	sta NOISE

track:
	ldx #0
	lda BALLDXH
	cmp #$80
	bcs +
	inx
*
	;;; okay, load the accumulator with the position i'm tracking
	;;; if the miss flags are set appropriately, the generate a 
	;;; phantom position...

	lda BALLYH
	clc
	adc NOISE
	cmp #160
	bcc +
	lda BALLYH
	sec
	sbc NOISE
*
	clc
	adc #20
	cmp #176
	bcc +
	lda #176
*
	sta BOT0, x
	sec
	sbc #40
	bcs +
	lda #41
	sta BOT0, x 
	lda #1
*
	sta TOP0, x

skip_y_update:

	lda #%00000010
	sta nusiz0
	sta nusiz1

	;;; read the bw/color switch

	lda #%1000
	bit swchb
	beq loadbw

	lda #$c0
	sta COLOR_BG
	lda #$3f
	sta COLOR_PADDLE
	sta COLOR_BALL
	lda #$f
	sta COLOR_SCORE
	lda #$c4
	sta COLOR_BORDER
	
	jmp +

loadbw:
	lda #0
	sta COLOR_BG
	lda #$f
	sta COLOR_PADDLE
	sta COLOR_BALL
	lda #$f
	sta COLOR_SCORE
	lda #4
	sta COLOR_BORDER

* 	;;;
	;;; initialize the color registere..

	lda #0
	sta colubk
	lda COLOR_SCORE
	sta colup0
	sta colup1
	lda COLOR_BALL
	sta colupf

*	;;; wait for the end of the vblank...
	lda intim
	bne -
	sta wsync
	sta vblank
	sta HMCLR

	ldy #7
*
	lda (DIGIT3),y
	sta grp0
	lda (DIGIT2),y
	sta grp1
	lda (DIGIT1),y
	tax
	lda (DIGIT0),y
	nop
	nop
	nop
	nop
	nop
	nop
	stx grp0
	sta grp1
	sta wsync

	lda (DIGIT3),y
	sta grp0
	lda (DIGIT2),y
	sta grp1
	lda (DIGIT1),y
	tax
	lda (DIGIT0),y
	nop
	nop
	nop
	nop
	nop
	nop
	stx grp0
	sta grp1
	sta wsync

	dey
	bne -

	;;; reset the center line position
	sty grp0
	sty grp1
	lda #69
	ldx #0
	jsr PosObject

	;;; adjust timing...
	lda COLOR_BORDER
	sta wsync
	sta HMOVE	
	sta wsync
	sta colubk

	lda #%00100101
	sta nusiz0
	sta nusiz1

	ldy #175
	dey
	sta wsync
	doball(TOP0, BOT0, enam0) 
	doball(TOPBALL, BOTBALL, enabl) 
	doball(TOP1, BOT1, enam1) 
	dey
	sta wsync
	doball(TOP0, BOT0, enam0) 
	doball(TOPBALL, BOTBALL, enabl) 
	doball(TOP1, BOT1, enam1) 
	dey
	sta wsync
	doball(TOP0, BOT0, enam0) 
	doball(TOPBALL, BOTBALL, enabl) 
	doball(TOP1, BOT1, enam1) 
	lda #0
	dey
	lda COLOR_BG
	sta wsync
	sta colubk

pfloop:
	;;; make the centerline...
	tya
	and #1
	sta grp0

	doball(TOPBALL, BOTBALL, enabl) 
	doball(TOP0, BOT0, enam0) 
	doball(TOP1, BOT1, enam1) 

	dey

	sta wsync
	cpy #3
	bne pfloop

	lda COLOR_BORDER
	sta colubk
	doball(TOP0, BOT0, enam0) 
	doball(TOPBALL, BOTBALL, enabl) 
	doball(TOP1, BOT1, enam1) 
	dey
	sta wsync
	doball(TOP0, BOT0, enam0) 
	doball(TOPBALL, BOTBALL, enabl) 
	doball(TOP1, BOT1, enam1) 

	lda #0
	sta wsync
	sta grp0
	sta enabl
	sta enam0
	sta enam1
	sta wsync
	sta colubk

	lda #35		; overscan
	sta tim64t

	;;;
	inc TCNT
	lda cxm0fb
	and #%01000000
	beq +
	lda #0
	sta TCNT
*
	lda cxm1fb
	and #%01000000
	beq time_adjusted
	
	lda TCNT
	cmp #61		; sixty ticks per second.
	bcc try_too_fast

	lda balldxl
	clc
	adc #1
	sta balldxl
	lda balldxh
	adc #0
	sta balldxh
	jmp time_adjusted
try_too_fast:
	cmp #60
	bcs time_adjusted

	lda balldxl
	sec
	sbc #1
	sta balldxl
	lda balldxh	
	sbc #0
	sta balldxh

time_adjusted:

	;;;
	;;; if we hit one of the paddles, we ...

	; do the collision detection...
	lda cxm0fb
	ora cxm1fb
	and #%01000000
	beq no_collisions
	lda #5

	;;; generate a sound....
	sta BEEPDUR
	lda #%00000100
	sta audc0
	lda #19
	sta audf0
	lda #$f
	sta audv0

	;;; reverse the ball direction...
	lda #0
	sec
	sbc BALLDXL
	sta BALLDXL
	lda #0
	sbc BALLDXH
	sta BALLDXH

	jsr random_y_velocity
no_collisions:

	lda BALLYH
	cmp #174
	bcc no_bounce_top
	
	lda BALLDYH 		;;; if our direction is negative
	cmp #$80
	bcs no_bounce_top	;;; don't worry...
	jsr bounce		;;; reverse our velocity otherwise.
no_bounce_top:
	lda BALLYH		
	cmp #8
	bcs no_bounce_bottom
	lda BALLDYH		;;; if our direction is positive...
	cmp #$80		
	bcc no_bounce_bottom	;;; don't worry
	jsr bounce		;;; otherwise, reverse our velocity
no_bounce_bottom:

	
	; and keep generating the beep
	ldy BEEPDUR
	beq +
	dey 
	sty BEEPDUR
	bne +
	sty audv0
*

	jsr restart

	;;; update the frame counter, a use for 
	;;; BCD arithmetic!
	sed

        ;;; 
        ;;; Output a 250ms pulse every 1s
        ;;;
        lda TIME_FRAME
        cmp #$15                ;;; 250ms
        bcs +
        lda #15                 ;;; turn on all the player 1 bits
        sta swcha
        bcc ++
*
        lda #0
        sta swcha
*
        
	ldx #0			;;; a handy zero...


        ;;; handle 
	lda TIME_FRAME		;;; get the frame
	clc
	adc #1
	sta TIME_FRAME
	cmp #$60
	bcc time_done

	stx TIME_FRAME
	lda TIME_SEC
	clc
	adc #1
	sta TIME_SEC
	cmp #$60
	bcc time_done
	
	stx TIME_SEC		;;; overflowed.
	lda #1
	sta MISS0
	lda TIME_MIN
	clc
	adc #1
	sta TIME_MIN
	cmp #$60
	bcc time_done
	
	stx TIME_MIN		;;; overflowed.
	lda #1
	sta MISS1	
	lda TIME_HR
	clc
	adc #1
	sta TIME_HR
	cmp #$24
	bcc time_done
	stx TIME_HR

time_done:
        cld

	;;; update the digit pointers...
	lda TIME_MIN
	and #$F
	tax
	lda digit_table_low, x
	sta DIGIT0
	lda digit_table_high,x
	sta DIGIT0+1
	
	lda TIME_MIN
	lsr
	lsr
	lsr
	lsr
	tax
	lda digit_table_low, x
	sta DIGIT1
	lda digit_table_high,x
	sta DIGIT1+1

        ;;;
        ;;; handle the military/civilian
        ;;; time conversion
        ;;; if the P0 difficulty is set, then 
        ;;; go in 12 hour time, else 24 hour

        lda TIME_HR
        sta TMP

        lda SWCHB
        and #$40
        beq display_hour

        ;;; modify the TMP hour digit

        sed
        lda TMP
        cmp #$13
        bcc +
        sec
        sbc #12
*
        cmp #0
        bne +
        lda #$12
*
        sta TMP
        cld

display_hour:
        ;;; fetch the computed digit
        lda TMP

        ;;; display the time

	and #$F
	tax
	lda digit_table_low, x
	sta DIGIT2
	lda digit_table_high,x
	sta DIGIT2+1
	
        ;;; and restore it...
        lda TMP
	lsr
	lsr
	lsr
	lsr
	tax
	lda digit_table_low, x
	sta DIGIT3
	lda digit_table_high,x
	sta DIGIT3+1

	;;; okay, now read the joystick to update the hours and minutes...
	ldy JOYTIMEOUT
	beq check_joysticks
	dey
	sty JOYTIMEOUT
	jmp joysticks_done

check_joysticks:

	sed

	ldy #20

	lda #JOY_RIGHT
	bit swcha
	bne ++
	lda TIME_MIN
	clc
	adc #1
	cmp #$60
	bcc +
	lda #0
*
	sta TIME_MIN
	sty JOYTIMEOUT

*	lda #JOY_LEFT
	bit swcha
	bne ++
	lda TIME_MIN
	sec
	sbc #1
	bpl +
	lda #$59
*
	sta TIME_MIN
	sty JOYTIMEOUT
*
	lda #JOY_UP
	bit swcha
	bne ++
	lda TIME_HR
	clc
	adc #1
	cmp #$24
	bcc +
	lda #$00
*
	sta TIME_HR
	sty JOYTIMEOUT
*
	lda #JOY_DOWN
	bit swcha
	bne ++
	lda TIME_HR
	sec
	sbc #1
	bpl +
	lda #$23
* 	sta TIME_HR
	sty JOYTIMEOUT

*
	cld

joysticks_done:

*	lda intim
	bne -
	sta wsync

	jmp pongkernel

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
random:
	lda RANDL
	clc
	adc RANDL
	sta RANDL
	lda RANDH
	adc RANDH
	sta RANDH
	bpl +
	lda RANDL
	eor #%00000001
	sta RANDL
	lda RANDH
	eor #%11000000
	sta RANDH
*
	lda RANDL
	rts

reset_ball:
	lda #60
	sta RESTARTDUR
	lda #%00000111
	sta audc1
	lda #83
	sta audf1
	lda #$f
	sta audv1
	lda #$ff
	sta BALLXH
	sta BALLYH
	rts

random_y_velocity:
	;;; and give a newy velocity
	jsr random
	asl
	sta BALLDYL
	bcc pos_dy
	lda #$ff
	sta BALLDYh
	bcs +
pos_dy:
	lda #0
	sta BALLDYh
*
	asl BALLDYL
	rol BALLDYh
	asl BALLDYL
	rol BALLDYh
	rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	
	.advance $FE00
	.include "glider.h"
	.include "pfdata.h"
	.include "digits.plain.h"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Clever code purloined from 
;;; http://www.atariage.com/forums/topic/47639-session-24-some-nice-code/
;;;
;;; It's actually significantly brilliant.  On entry, the A contains 
;;; the desired horizontal position, the X contains which object we
;;; are supposed to move.  It burns a scanline by doing a single 
;;; store to wsync.
;;;
;;; Values for X:
;;;	0 = Player 0
;;;     1 = Player 1
;;;     2 = Missile 0
;;;	3 = Missile 1
;;;     4 = Ball
;;;
;;; According to the documentation, A isn't really the position (0-160),
;;; you have to add +7 to the position.  But I find that the offset in
;;; stella is +5.  I haven't done the cycle counting to figure it out,
;;; but I've had good luck trusting stella, so that's what I'm going
;;; with.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PosObject:
	sta wsync
	sec
*	sbc #15
	bcs -
	tay
	lda fineadjusttable,y
	sta hmp0,x
	sta resp0,x
	rts

;;;
;;; reverse the ball's vertical direction.
;;;
bounce:
	lda #0
	sec
	sbc BALLDYL
	sta BALLDYL
	lda #0
	sbc BALLDYH
	sta BALLDYH

	lda #5
	sta BEEPDUR
	lda #%00000100
	sta audc0
	lda #29
	sta audf0
	lda #$f
	sta audv0
	rts

restart:
	lda RESTARTDUR
	beq +
	dec RESTARTDUR
	bne +
	lda #0
	sta audv1
	lda #80
	sta BALLXH
	sta BALLYH
	lda #2
	sta BALLDXH
	lda #$c
	sta BALLDXL
	jmp random_y_velocity
*
	rts

	.ascii "Copyright 2010-2025, Mark VandeWettering"

	.advance $FFFA
	.word main
	.word main	
	.word main
