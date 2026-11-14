; Isolated wrapper for the maintained BIOS MRCF decoder.
	.386
sysinitseg segment byte public 'system_init' use16
	assume cs:sysinitseg
	org 9320h
	include mrcf.inc
sysinitseg ends
	end
