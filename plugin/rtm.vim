scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

if !exists(':RtmAddTask')
  " add command
	command! RtmAddTask call rtm#addTask()
endif

let &cpo = s:save_cpo
unlet s:save_cpo
