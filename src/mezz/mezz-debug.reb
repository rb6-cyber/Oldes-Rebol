REBOL [
	System: "REBOL [R3] Language Interpreter and Run-time Environment"
	Title: "REBOL 3 Mezzanine: Debug"
	Rights: {
		Copyright 2012 REBOL Technologies
		REBOL is a trademark of REBOL Technologies
	}
	License: {
		Licensed under the Apache License, Version 2.0
		See: http://www.apache.org/licenses/LICENSE-2.0
	}
]

dt: delta-time: function [
	{Delta-time - returns the time it takes to evaluate the block.}
	block [block!]
][
	start: stats/timer
	do block
	stats/timer - start
]

dp: delta-profile: func [
	{Delta-profile of running a specific block.}
	block [block!]
	/local start end adjust
][
	; first count adjustments for empty code
	adjust: copy end: stats/profile 
	do [] 
	stats/profile 
	foreach [key num] adjust [
		set key end/:key - num
	]
	adjust/timer: 0:0:0
	; and now count real stats
	start: copy end: stats/profile 
	do block 
	stats/profile 
	foreach [key num] start [
		set key end/:key - num - adjust/:key
	]
	start
]

speed?: function [
	"Returns approximate speed benchmarks [eval cpu memory file-io]."
	/no-io "Skip the I/O test"
	/times "Show time for each test"
][
	result: copy []
	foreach block [
		[
			loop 100'000 [
				; measure more than just loop func
				; typical load: 1 set, 2 data, 1 op, 4 trivial funcs
				x: 1 * index? back next "x"
				x: 1 * index? back next "x"
				x: 1 * index? back next "x"
				x: 1 * index? back next "x"
			]
			calc: [100'000 / secs / 100] ; arbitrary calc
		][
			tmp: make binary! 500'000
			insert/dup tmp "abcdefghij" 50000
			loop 10 [
				random tmp
				decompress compress tmp 'zlib 'zlib
			]
			calc: [(length? tmp) * 10 / secs / 1900]
		][
			repeat n 40 [
				change/dup tmp to-char n 500'000
			]
			calc: [(length? tmp) * 40 / secs / 1024 / 1024]
		][
			unless no-io [
				write file: %tmp-junk.txt "" ; force security request before timer
				tmp: make string! 32000 * 5
				insert/dup tmp "test^/" 32000
				loop 100 [
					write file tmp
					read file
				]
				delete file
				calc: [(length? tmp) * 100 * 2 / secs / 1024 / 1024]
			]
		]
	][
		recycle
		secs: now/precise
		calc: 0
		do block
		secs: to decimal! difference now/precise secs
		append result to integer! do calc
		if times [append result secs]
	]
	result
]
