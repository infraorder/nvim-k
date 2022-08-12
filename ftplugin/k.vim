setl sw=1 ts=1 sts=1 inc=^\\l cms=/%s inde=KIndent(v:lnum)
fu!KIndent(l)
 let p=prevnonblank(v:lnum-1)|let s=getline(p)
 if s=~'[(\[{] *\(/.*\)\=$'|retu indent(p)+1|en
 if s=~'[)\]}] *\(/.*\)\=$'|retu 0|en
 let n=len(s)|let i=0|let t=[]
 wh i<n
  let c=s[i]
  if    c=='"'                   |let i+=1|wh i<n&&s[i]!='"'|let i+=1+(s[i]=='\')|endw
  elsei c=='/'&&(!i||s[i-1]==' ')|break
  elsei c=~'[([{]'               |cal add(t,i+1)
  elsei c=~'[)\]}]'              |if len(t)>0|cal remove(t,-1)|en
  en
  let i+=1
 endw
 retu len(t)?t[-1]:indent(p)
endf

nmap <buffer> <CR> <plug>(k_eval_line)
xmap <buffer> <CR> <plug>(k_eval_range)
nmap <buffer> <Leader>kf <plug>(k_eval_file)
nmap <buffer> <Leader>kc <plug>(k_clear_after_line)
nmap <buffer> <Leader>kC <plug>(k_clear_file)
xmap <buffer> <Leader>kc <plug>(k_clear_range)
xmap <buffer> <Leader>ks <plug>(start_repl)
nmap <buffer> <Leader>kt <plug>(k_constant_eval)
