scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

function! s:CalcMd5(str) abort " {{{1
	let s:V = vital#of('vital')
	let s:Hash = s:V.import('Hash.MD5')

  return s:Hash.sum(a:str)
endfunction
" }}}1

let s:auth_url = 'http://www.rememberthemilk.com/services/auth/'
let s:rest_url = 'https://api.rememberthemilk.com/services/rest/'

let s:V = vital#vital#new()

if !exists('g:rtm_api_key')
  finish
endif

if !exists('g:rtm_secret_key')
  finish
endif

if !exists('g:setting_path')
	finish
endif

" get API signiture
function! rtm#getApiSig(...) abort "{{{1
  let q = ''

  let l:query_params = a:000[0]
  for param in sort(keys(a:000[0]))
    let q .= param . l:query_params[param]
  endfor
  return s:CalcMd5(g:rtm_secret_key.'api_key'.g:rtm_api_key.q)
endfunction
"}}}1

" Get token
function! rtm#getToken() abort "{{{1
	if filereadable(g:setting_path)
		let fp = readfile(g:setting_path)
		return fp[0]
	endif

  let l:query = {}
  let l:query['method'] = 'rtm.auth.getFrob'
  let l:api_sig = rtm#getApiSig(l:query)

	let l:url = s:rest_url . '?method=rtm.auth.getFrob&api_key='.g:rtm_api_key . '&api_sig='.l:api_sig

	let l:res = webapi#http#get(l:url)
  let l:xml = l:res['content']

  let l:dom = webapi#xml#parse(l:xml)
  let l:frob = l:dom.childNode('frob').child[0]

  " auth
  let l:query = {}
	let l:query['perms'] = 'delete'
	let l:query['frob'] = l:frob

	let l:api_sig = rtm#getApiSig(l:query)
  let l:url = s:auth_url . '?api_key='.g:rtm_api_key.'&frob='.l:frob.'&perms=delete'.'&api_sig='.l:api_sig

	call OpenBrowser(s:call_isgd(l:url))

	" echo 'open url and certification ' . s:call_isgd(l:url)
  echo input('enter return key : ')

  " get token
  let l:query = {}
	let l:query['format'] = 'json'
	let l:query['frob'] = l:frob
	let l:query['method'] = 'rtm.auth.getToken'

  let l:api_sig = rtm#getApiSig(l:query)
	let l:url = s:rest_url . '?method=rtm.auth.getToken&api_key='. g:rtm_api_key . '&format=json' . '&frob='.l:frob . '&api_sig='.l:api_sig

  let l:res = webapi#http#get(l:url)
  let l:content = webapi#json#decode(l:res['content'])

	let l:save_file = [ l:content['rsp']['auth']['token'] ]
	call writefile(l:save_file, g:setting_path)

  return l:content['rsp']['auth']['token']
endfunction
" }}}

" Create timeline
function! rtm#createTimelines(token) abort "{{{1
  let l:query = {}
	let l:query['auth_token'] = a:token
	let l:query['format'] = 'json'
	let l:query['method'] = 'rtm.timelines.create'

  let l:api_sig = rtm#getApiSig(l:query)
	let l:url = s:rest_url . '?method=rtm.timelines.create&api_key='.g:rtm_api_key .  '&auth_token='.a:token . '&format=json' . '&api_sig='.l:api_sig
  let l:json = webapi#http#get(l:url)
  let l:content = webapi#json#decode(l:json['content'])

  return l:content.rsp.timeline
endfunction
" }}}1

" Add task
function! rtm#addTask() abort "{{{1

  let l:token = rtm#getToken()

  let l:query = {}
  let l:query['auth_token'] = l:token
  let l:query['format'] = 'json'
  let l:query['name'] = input('set task : ')
  let l:query['method'] = 'rtm.tasks.add'
  let l:query['timeline'] = rtm#createTimelines(l:token)

  let l:api_sig = rtm#getApiSig(l:query)
  let l:url = s:rest_url . '?method=rtm.tasks.add&api_key='.g:rtm_api_key . '&auth_token='.l:token . '&format=json' . '&name='.s:url_encode(l:query['name']) . '&timeline='.l:query['timeline'] . '&api_sig='.l:api_sig
  call webapi#http#get(l:url)

  redraw

  echo 'task added.'
endfunction

function! rtm#addTaskFromBuffer() abort "{{{1

  let l:tasks = getline(0, line("$"))

  call s:do_partial(l:tasks, 0)
endfunction

function! rtm#addTaskFromSelected() abort "{{{1

  let l:tasks = split(s:get_visual_text(), '\n')

  call s:do_partial(l:tasks, 0)
endfunction



function! s:do_partial(partial, timer, ...) 

  let l:token = rtm#getToken()

  let l:query = {}
  let l:query['auth_token'] = l:token
  let l:query['format'] = 'json'
  let l:query['name'] = a:partial[0]
  let l:query['method'] = 'rtm.tasks.add'
  let l:query['timeline'] = rtm#createTimelines(l:token)

  let l:api_sig = rtm#getApiSig(l:query)
  let l:url = s:rest_url . '?method=rtm.tasks.add&api_key='.g:rtm_api_key . '&auth_token='.rtm#getToken() . '&format=json' . '&name='.s:url_encode(l:query['name']) . '&timeline='.l:query['timeline'] . '&api_sig='.l:api_sig
  call webapi#http#get(l:url)
  echo l:query['name']

  if len(a:partial) > 1
    call timer_start(500, function('s:do_partial', [a:partial[1:]]))
  endif

  redraw

  echo 'task added.'
endfunction

"}}}

 "ビジュアルモードで選択中のテクストを取得する {{{
function! s:get_visual_text()
    try
        " ビジュアルモードの選択開始/終了位置を取得
        let pos = getpos('')
        normal `<
        let start_line = line('.')
        let start_col = col('.')
        normal `>
        let end_line = line('.')
        let end_col = col('.')
        call setpos('.', pos)

        let tmp = @@
        silent normal gvy
        let selected = @@
        let @@ = tmp
        return selected
    catch
        return ''
    endtry
endfunction
" }}}


" Get all tasks
function! rtm#getAllTasks() abort " {{{
	let l:token = rtm#getToken()

  let l:query = {}
  let l:query['auth_token'] = l:token
  let l:query['format'] = 'json'
  let l:query['method'] = 'rtm.tasks.getList'
  let l:query['timeline'] = rtm#createTimelines(l:token)

  let l:api_sig = rtm#getApiSig(l:query)
  let l:url = s:rest_url . '?method='.l:query['method'].'&api_key='.g:rtm_api_key . '&auth_token='.l:token . '&format=json' .  '&timeline='.l:query['timeline'] . '&api_sig='.l:api_sig
  echo webapi#http#get(l:url)

endfunction
" }}}

" Get all lists
function! rtm#getAllLists() abort " {{{
	let l:token = rtm#getToken()

  let l:query = {}
  let l:query['auth_token'] = l:token
  let l:query['format'] = 'json'
  let l:query['method'] = 'rtm.lists.getList'
  let l:query['timeline'] = rtm#createTimelines(l:token)

  let l:api_sig = rtm#getApiSig(l:query)
  let l:url = s:rest_url . '?method='.l:query['method'].'&api_key='.g:rtm_api_key . '&auth_token='.l:token . '&format=json' .  '&timeline='.l:query['timeline'] . '&api_sig='.l:api_sig
  let l:res = webapi#http#get(l:url)
  let l:content = webapi#json#decode(l:res['content'])

	return l:content.rsp.lists.list
endfunction
" }}}

" Get specified list
function! rtm#getSpecifiedList() abort " {{{
	let l:token = rtm#getToken()

  let l:query = {}
  let l:query['auth_token'] = l:token
	let l:query['filter'] = 'status:incomplete'
  let l:query['format'] = 'json'

  let l:task_lists = rtm#getAllLists()
	let l:list_name = '.a'
  let l:query['list_id'] = s:extractListId(l:task_lists, l:list_name)

  let l:query['method'] = 'rtm.tasks.getList'
  let l:query['timeline'] = rtm#createTimelines(l:token)

  let l:api_sig = rtm#getApiSig(l:query)
  let l:url = s:rest_url . '?method='.l:query['method'].'&api_key='.g:rtm_api_key . '&auth_token='.l:token . '&filter=' . l:query['filter'] . '&format=json' .  '&list_id='.l:query['list_id'] . '&timeline='.l:query['timeline'] . '&api_sig='.l:api_sig
  let l:res = webapi#http#get(l:url)
  let l:content = webapi#json#decode(l:res['content'])

	echo l:content
endfunction
" }}}

" Get list's id
function! s:extractListId(task_lists, list_name) abort
 	let s:List = s:V.import('Data.List')

	let l:specific_list = s:List.filter(a:task_lists, "v:val.name == '". a:list_name . "'")
	return l:specific_list[0].id
endfunction

" Call is.gd API to shorten a URL.
function! s:call_isgd(url) "{{{1
	redraw

	echo "Sending request to is.gd..."
	let url = 'https://is.gd/api.php?longurl='.s:url_encode(a:url)
	let res = webapi#http#get(url)

	return res.content
endfunction
" }}}1

" URL-encode a string.
function! s:url_encode(str) "{{{1
	return substitute(a:str, '[^a-zA-Z0-9_.~-]', '\=s:url_encode_char(submatch(0))', 'g')
endfunction

function! s:url_encode_char(c)
	let utf = iconv(a:c, &encoding, "utf-8")
	if utf == ""
		let utf = a:c
	endif
	let s = ""
	for i in range(strlen(utf))
		let s .= printf("%%%02X", char2nr(utf[i]))
	endfor
	return s
endfunction
"}}}1

let &cpo = s:save_cpo
unlet s:save_cpo
