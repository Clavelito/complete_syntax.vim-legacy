
" Author:      Clavelito <maromomo@hotmail.com>
" Last Change: Thu, 10 Feb 2022 23:16:24 +0900
" License:     https://www.apache.org/licenses/LICENSE-2.0
"
" Description: Keyword completion is performed using syntax highlighting files.
"              It can also be used when syntax off.
"              It is not set to omnifunc. Use CTRL-N and CTRL-P as you would
"              for completion in the current buffer.
"
"              autocmd FileType * CompleteSyntax


if exists('g:loaded_complete_syntax')
  finish
endif
let g:loaded_complete_syntax = 0

command CompleteSyntax call complete_syntax#complete_syntax()
