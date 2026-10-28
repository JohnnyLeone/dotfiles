" Verify mapped user input, including SafeState events used by the plugin.
call assert_true(has_key(maparg('<C-i>', 'n', 0, 1), 'callback'))
call assert_match('NERDTreeToggle', maparg('<C-n>', 'n'))
call setline(1, 'cat cat dog')
normal! gg0
function! CheckSelection(timer)
  call assert_equal(2, luaeval("require('multicursor-nvim').numCursors()"))
  call nvim_input('ciw')
  call timer_start(30, function('ChangeText'))
endfunction
function! ChangeText(timer)
  call nvim_input("fox\<Esc>")
  call timer_start(30, function('CheckEdit'))
endfunction
function! CheckEdit(timer)
  call assert_equal('fox fox dog', getline(1))
  call nvim_input("\<Esc>")
  call timer_start(30, function('FinishTest'))
endfunction
function! FinishTest(timer)
  call assert_equal(1, luaeval("require('multicursor-nvim').numCursors()"))
  if !empty(v:errors)
    for message in v:errors
      echomsg message
    endfor
    cquit
  endif
  qa!
endfunction
call nvim_input("\<C-i>")
call timer_start(30, function('CheckSelection'))
call timer_start(5000, {-> execute('cquit')})
