" --------------------------------------------------------------------
" This plugin was inspired and based on Steve Losh's interesting words
" .vimrc config https://www.youtube.com/watch?v=xZuy4gBghho
" --------------------------------------------------------------------

let s:interestingWordsGUIColors = ['#F93442', '#FF8C00', '#FFE101', '#AAE21F', '#61CAA0', '#7259CB']
let s:interestingWordsTermColors = ['154', '121', '211', '137', '214', '222']

let g:interestingWordsGUIColors = exists('g:interestingWordsGUIColors') ? g:interestingWordsGUIColors : s:interestingWordsGUIColors
let g:interestingWordsTermColors = exists('g:interestingWordsTermColors') ? g:interestingWordsTermColors : s:interestingWordsTermColors

let s:hasBuiltColors = 0

let s:interestingWords = []
let s:interestingModes = []
let s:mids = {}
let s:recentlyUsed = []

function! ColorWordIndex(word, mode, n)
  if !(s:hasBuiltColors)
    call s:buildColors()
  endif

  let mid = 595129 + a:n
  let s:interestingWords[a:n] = a:word
  let s:interestingModes[a:n] = a:mode
  let s:mids[a:word] = mid

  call s:apply_color_to_word(a:n, a:word, a:mode, mid)
endfunction

function! s:apply_color_to_word(n, word, mode, mid)
  let case = '\C'
  if a:mode == 'v'
    let pat = case . '\V\zs' . escape(a:word, '\') . '\ze'
  else
    let pat = case . '\V\<' . escape(a:word, '\') . '\>'
  endif

  try
    call matchadd("InterestingWord" . (a:n + 1), pat, 1, a:mid)
  catch /E801/      " match id already taken.
  endtry
endfunction

function! UncolorWord(word)
  let index = index(s:interestingWords, a:word)

  if (index > -1)
    let mid = s:mids[a:word]

    silent! call matchdelete(mid)
    let s:interestingWords[index] = 0
    unlet s:mids[a:word]
  endif
endfunction

function! s:getmatch(mid) abort
  return filter(getmatches(), 'v:val.id==a:mid')[0]
endfunction

function! InterestingWordsIndex(mode, n) range
  if a:mode == 'v'
    let currentWord = s:get_visual_selection()
  else
    let currentWord = expand('<cword>') . ''
  endif
  if !(len(currentWord))
    return
  endif
  if (index(s:interestingWords, currentWord) == -1)
    call ColorWordIndex(currentWord, a:mode, a:n)
  else
    call UncolorWord(currentWord)
  endif
endfunction

function! s:get_visual_selection()
  " Why is this not a built-in Vim script function?!
  let [lnum1, col1] = getpos("'<")[1:2]
  let [lnum2, col2] = getpos("'>")[1:2]
  let lines = getline(lnum1, lnum2)
  let lines[-1] = lines[-1][: col2 - (&selection == 'inclusive' ? 1 : 2)]
  let lines[0] = lines[0][col1 - 1:]
  return join(lines, "\n")
endfunction

function! UncolorAllWords()
  for word in s:interestingWords
    " check that word is actually a String since '0' is falsy
    if (type(word) == 1)
      call UncolorWord(word)
    endif
  endfor
endfunction

function! s:uiMode()
  " Stolen from airline's airline#init#gui_mode()
  return ((has('nvim') && exists('$NVIM_TUI_ENABLE_TRUE_COLOR') && !exists("+termguicolors"))
     \ || has('gui_running') || (has("termtruecolor") && &guicolors == 1) || (has("termguicolors") && &termguicolors == 1)) ?
      \ 'gui' : 'cterm'
endfunction

" initialise highlight colors from list of GUIColors
" initialise length of s:interestingWord list
" initialise s:recentlyUsed list
function! s:buildColors()
  if (s:hasBuiltColors)
    return
  endif
  let ui = s:uiMode()
  let wordColors = (ui == 'gui') ? g:interestingWordsGUIColors : g:interestingWordsTermColors
  " select ui type
  " highlight group indexed from 1
  let currentIndex = 1
  for wordColor in wordColors
    execute 'hi! def InterestingWord' . currentIndex . ' ' . ui . 'bg=' . wordColor . ' ' . ui . 'fg=Black'
    call add(s:interestingWords, 0)
    call add(s:interestingModes, 'n')
    let currentIndex += 1
  endfor
  let s:hasBuiltColors = 1
endfunc

if !exists('g:interestingWordsDefaultMappings') || g:interestingWordsDefaultMappings != 0
    let g:interestingWordsDefaultMappings = 1
endif

if g:interestingWordsDefaultMappings && !hasmapto('<Plug>InterestingWords')
    vnoremap <silent> <leader>1 :call InterestingWordsIndex('v', 0)<cr>
    vnoremap <silent> <leader>2 :call InterestingWordsIndex('v', 1)<cr>
    vnoremap <silent> <leader>3 :call InterestingWordsIndex('v', 2)<cr>
    vnoremap <silent> <leader>4 :call InterestingWordsIndex('v', 3)<cr>
    vnoremap <silent> <leader>5 :call InterestingWordsIndex('v', 4)<cr>
    vnoremap <silent> <leader>6 :call InterestingWordsIndex('v', 5)<cr>
    nnoremap <silent> <leader>K :call UncolorAllWords()<cr>
endif
