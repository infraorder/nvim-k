function! KEvalLine()
    return luaeval(
          \ 'require("k").repl.eval(_A[1] - 1, _A[1])',
          \ [line(".")])
endfunction

function! KEvalRange() range
    return luaeval(
          \ 'require("k").repl.eval(_A[1] - 1, _A[2])',
          \ [a:firstline, a:lastline])
endfunction

function! KConstantEval() range
  return luaeval(
          \ 'require("k").repl.constant_eval()')
endfunction

function! KClearAfterLine()
    return luaeval(
          \ 'require("k").repl.clear(_A[1] - 1, -1)',
          \ [line(".")])
endfunction

function! KClearRange()
    return luaeval(
          \ 'require("k").repl.clear(_A[1] - 1, _A[2])',
          \ [a:firstline, a:lastline])
endfunction

function! KStartRepl()
    return luaeval(
          \ 'require("k").repl.ensure_repl_exists()',
          \ [a:firstline, a:lastline])
endfunction

hi link koutok Comment
hi link kouterr Error

command! KEvalLine call KEvalLine()
command! -range KEvalRange <line1>,<line2>call KEvalRange()
command! KEvalFile :lua require("k").repl.eval(0, -1)

command! KClearAfterLine call KClearAfterLine()
command! KConstantEval call KConstantEval()
command! -range KClearRange <line1>,<line2>call KClearRange()
command! KClearFile :lua require("k").repl.clear(0, -1)

nnoremap <silent> <plug>(k_eval_line) :KEvalLine<CR>
xnoremap <silent> <plug>(k_eval_range) :KEvalRange<CR>
nnoremap <silent> <plug>(k_eval_file) :KEvalFile<CR>

nnoremap <silent> <plug>(k_clear_after_line) :KClearAfterLine<CR>
xnoremap <silent> <plug>(k_clear_range) :KClearRange<CR>
nnoremap <silent> <plug>(k_clear_file) :KClearFile<CR>
nnoremap <silent> <plug>(k_constant_eval) :KConstantEval<CR>
nnoremap <silent> <plug>(start_repl) :KStartRepl<CR>
