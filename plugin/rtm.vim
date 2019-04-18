scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

if !exists(':RtmAddTask')
	command! RtmAddTask call rtm#addTask()
endif

if !exists(':RtmAddTaskFromBuffer')
	command! RtmAddTaskFromBuffer call rtm#addTaskFromBuffer()
endif

if !exists(':RtmAddTaskFromSelected')
	command! -range RtmAddTaskFromSelected call rtm#addTaskFromSelected()
endif

if !exists(':RtmGetAllTasks')
	command! RtmGetAllTasks call rtm#getAllTasks()
endif

if !exists(':RtmGetAllLists')
	command! RtmGetAllLists call rtm#getAllLists()
endif

if !exists(':RtmGetSpecifiedList')
	command! RtmGetSpecifiedList call rtm#getSpecifiedList()
endif

" test
let &cpo = s:save_cpo
unlet s:save_cpo
