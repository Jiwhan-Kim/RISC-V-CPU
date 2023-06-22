#!/bin/zsh

iverilog -o test ./tb.v

vvp test -vcd

open -a gtkwave test.vcd