scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

if !exists(':RtmAddTask')
	command! RtmAddTask call rtm#addTask()
endif

if !exists(':RtmGetAllTasks')
	command! RtmGetAllTasks call rtm#getAllTasks()
endif

if !exists(':RtmGetAllLists')
	command! RtmGetAllLists call rtm#getAllLists()
endif



" test
let &cpo = s:save_cpo
unlet s:save_cpo
