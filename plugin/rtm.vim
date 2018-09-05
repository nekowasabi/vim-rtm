scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

if !exists(':RtmAddTask')
	command! RtmAddTask call rtm#addTask()
endif

" test
let &cpo = s:save_cpo
unlet s:save_cpo
