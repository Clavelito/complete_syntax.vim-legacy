
" Author:      Clavelito <maromomo@hotmail.com>
" Last Change: Fri, 14 Aug 2026 09:36:00 +0900
" Version:     0.5-legacy
" License:     http://www.apache.org/licenses/LICENSE-2.0
"
" Description: Keyword completion is performed using syntax highlighting files.
"              It can also be used when syntax off.
"              It is not set to omnifunc. Use CTRL-N and CTRL-P as you would
"              for completion in the current buffer.

if exists('g:loaded_complete_syntax') && g:loaded_complete_syntax
  finish
endif
let g:loaded_complete_syntax = 1

let s:cpo_save = &cpo
set cpo&vim

function complete_syntax#complete_syntax()
  if !empty(s:FileReadableList())
    augroup CompleteSyntax
      autocmd!
      autocmd BufEnter * call <SID>SelectCompleteBuffer(1)
    augroup END
    call s:SetMap()
  endif
endfunction

let s:temp_dir = !empty(getenv('TEMP')) && isdirectory(getenv('TEMP')) ? getenv('TEMP') : '/tmp'
let s:runtime_path = split(&runtimepath, ',')
let s:beginpt = '^\s*syn\=\%(tax\)\=\s\+keyword\s\+\S\+'
let s:sourcept = '^\s*runtime!\=\s\+syntax/\([a-z0-9]\+[.]vim\)\s*$'
let s:complete_syntax_pid = '#'. getpid()
let s:lasttype = ''

function s:SetMap()
  inoremap <buffer> <C-P> <C-R>=<SID>SelectCompleteBuffer()<CR><Esc>a<C-P>
  inoremap <buffer> <C-N> <C-R>=<SID>SelectCompleteBuffer()<CR><Esc>a<C-N>
  call s:SelectCompleteBuffer(1)
endfunction

function s:CompleteSyntaxFile()
  if empty(&filetype)
    return ''
  endif
  let bname = s:complete_syntax_pid. &filetype
  let save_dir = getcwd()
  exec 'silent lcd '. s:temp_dir
  if !bufexists(bname) && &modifiable && &ft != 'qf' && &ft != 'netrw'
    let bufnr = bufadd(bname)
    call setbufvar(bufnr, '&swapfile', 0)
    silent call bufload(bufnr)
    let sum = 0
    for fn in s:FileReadableList()
      let lines = s:GetWordsList(fn)
      call setbufline(bufnr, sum + 1, lines)
      let sum += len(lines)
    endfor
    call setbufvar(bufnr, 'complete', s:complete_syntax_pid)
  endif
  exec 'silent lcd '. save_dir
  call s:SelectCompleteBuffer()
endfunction

function s:GetWordsList(path)
  let wordlist = []
  let sum = 1
  let flag = 0
  for line in readfile(a:path)
    if line =~# s:beginpt
      call extend(wordlist, s:ParseLine(line, s:beginpt))
      let flag = sum + 1
    elseif flag == sum && line =~ '^\s*\\'
      call extend(wordlist, s:ParseLine(line, '^\s*\\'))
      let flag = sum + 1
    elseif line =~# s:sourcept
      let rtp = substitute(a:path, '[^/]\+$', '', '')
      let path2 = substitute(line, s:sourcept, rtp. '\1', '')
      if filereadable(path2)
        call extend(wordlist, s:GetWordsList(path2))
      endif
    endif
    let sum += 1
  endfor
  return wordlist
endfunction

function s:ParseLine(line, pt)
  let str = substitute(a:line, a:pt
        \. '\|\s\%(nextgroup\|containedin\)=\S\+'
        \. '\|\s\%(skipempty\|skipwhite\|skipnl\|contained\)\>', '', 'g')
  let str = substitute(str, '\s\(\S\+\)\[\(\S\+\)\]', ' \1 \1\2', 'g')
  return split(str)
endfunction

function s:SelectCompleteBuffer(...)
  if a:0 && s:lasttype == &filetype
    return ''
  endif
  let s:lasttype = &filetype
  let compbufpt = s:complete_syntax_pid. &filetype. '$'
  let flag = 0
  for dict in getbufinfo()
    if s:VariableCompleteExists(dict)
      if dict['name'] =~# compbufpt
        call setbufvar(dict['bufnr'], '&buflisted', 1)
        let flag = 1
      else
        call setbufvar(dict['bufnr'], '&buflisted', 0)
      endif
      if empty(getbufvar(dict['bufnr'], '&buftype'))
        call setbufvar(dict['bufnr'], '&buftype', 'nofile')
      endif
      if !empty(dict['windows'])
        call setbufvar(dict['bufnr'], '&hidden', 1)
        bnext
        call s:SelectCompleteBuffer(1)
      endif
    endif
  endfor
  if !flag && !a:0
    call s:CompleteSyntaxFile()
    iunmap <buffer> <C-P>
    iunmap <buffer> <C-N>
  endif
  return ''
endfunction

function s:FileReadableList()
  let flist = []
  let fname = []
  for rtp in s:runtime_path
    if isdirectory(rtp. '/syntax/'. &filetype)
      let fname = split(glob(rtp. '/syntax/'. &filetype. '/*.vim'), '\n')
    endif
    call add(fname, rtp. '/syntax/'. &filetype. '.vim')
    for fn in fname
      if filereadable(fn)
        call add(flist, fn)
      endif
    endfor
  endfor
  return flist
endfunction

function s:VariableCompleteExists(dict)
  return has_key(a:dict['variables'], 'complete')
        \ && a:dict['variables']['complete'] == s:complete_syntax_pid
endfunction

let &cpo = s:cpo_save
unlet s:cpo_save
" vim: sw=2 et
