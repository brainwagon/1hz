;;;
;;; digits
digit_zero:
	.byte %00000000
	.byte %11111110
	.byte %11000110
	.byte %11000110
	.byte %11000110
	.byte %11000110
	.byte %11111110
	.byte %00000000
digit_one:
	.byte %00000000
	.byte %00000110
	.byte %00000110
	.byte %00000110
	.byte %00000110
	.byte %00000110
	.byte %00000110
	.byte %00000000
digit_two:
	.byte %00000000
	.byte %01111110
	.byte %01100000
	.byte %01100000
	.byte %01111110
	.byte %00000110
	.byte %01111110
	.byte %00000000
digit_three:
	.byte %00000000
	.byte %01111110
	.byte %00000110
	.byte %00000110
	.byte %01111110
	.byte %00000110
	.byte %01111110
	.byte %00000000
digit_four:
	.byte %00000000
	.byte %00000110
	.byte %00000110
	.byte %00000110
	.byte %01111110
	.byte %01100110
	.byte %01100110
	.byte %00000000
digit_five:
	.byte %00000000
	.byte %01111110
	.byte %00000110
	.byte %00000110
	.byte %01111110
	.byte %01100000
	.byte %01111110
	.byte %00000000
digit_six:
	.byte %00000000
	.byte %01111110
	.byte %01100110
	.byte %01100110
	.byte %01111110
	.byte %01100000
	.byte %01111110
	.byte %00000000
digit_seven:
	.byte %00000000
	.byte %00000110
	.byte %00000110
	.byte %00000110
	.byte %00000110
	.byte %00000110
	.byte %01111110
	.byte %00000000
digit_eight:
	.byte %00000000
	.byte %01111110
	.byte %01100110
	.byte %01100110
	.byte %01111110
	.byte %01100110
	.byte %01111110
	.byte %00000000
digit_nine:
	.byte %00000000
	.byte %01111110
	.byte %00000110
	.byte %00000110
	.byte %01111110
	.byte %01100110
	.byte %01111110
	.byte %00000000

digit_table_low:
	.byte <digit_zero
	.byte <digit_one
	.byte <digit_two
	.byte <digit_three
	.byte <digit_four
	.byte <digit_five
	.byte <digit_six
	.byte <digit_seven
	.byte <digit_eight
	.byte <digit_nine

digit_table_high:
	.byte >digit_zero
	.byte >digit_one
	.byte >digit_two
	.byte >digit_three
	.byte >digit_four
	.byte >digit_five
	.byte >digit_six
	.byte >digit_seven
	.byte >digit_eight
	.byte >digit_nine
	
