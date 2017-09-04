" Vim syntax file
" Language:	Gtd

if version < 600
	syntax clear
elseif exists("b:current_syntax")
	finish
endif

syntax match gtdResultsFormula /^[^ ].*$/
syntax match gtdResultsResult /^ .*$/ contains=gtdResultsResultKey,gtdResultsResultTitle,gtdResultsResultAttached
syntax match gtdResultsResultKey /^ \zs\d\{8}_\d\{6}/ contained
syntax match gtdResultsResultTitle / \[[\* ]\] \zs.*/ contained
syntax match gtdResultsResultAttached / \[\zs\*\ze\] / contained

highlight def link gtdResultsFormula Title
highlight def link gtdResultsResultKey Keyword
highlight def link gtdResultsResultTitle Normal
highlight def link gtdResultsResultAttached Underlined

let b:current_syntax = "gtd-results"

