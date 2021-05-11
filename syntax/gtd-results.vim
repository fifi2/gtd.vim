" Vim syntax file
" Language:	Gtd

if version < 600
	syntax clear
elseif exists("b:current_syntax")
	finish
endif

syntax match gtdResultsFormula /^.*\[\d\+ notes\?\]$/ contains=gtdResultsCount
syntax match gtdResultsCount / \zs\[\d\+ notes\?\]$/
syntax match gtdResultsResult /^\zs\d\{8}_\d\{6} .*$/ contains=gtdResultsResultKey,gtdResultsResultTitle,gtdResultsResultAttached
syntax match gtdResultsResultKey /^\zs\d\{8}_\d\{6}/ contained conceal cchar=-
syntax match gtdResultsResultTitle /\d\{8}_\d\{6} \zs.* \[[\* ]\]/ contained
syntax match gtdResultsResultAttached / \[\zs\*\ze\]/ contained

highlight def link gtdResultsFormula Title
highlight def link gtdResultsCount Number
highlight def link gtdResultsResultKey Keyword
highlight def link gtdResultsResultTitle Normal
highlight def link gtdResultsResultAttached Underlined
highlight Conceal ctermbg=NONE ctermfg=NONE guibg=NONE guifg=NONE

let b:current_syntax = "gtd-results"

