" Vim syntax file
" Language:	Gtd

if version < 600
	syntax clear
elseif exists("b:current_syntax")
	finish
endif

syntax sync fromstart
syntax spell toplevel

if g:gtd#tag_lines_count == 0
	syntax region gtdTags start=/\%1l/ end=/^\s*$/ contains=@NoSpell,gtdTitle,gtdContext,gtdStatus,gtdHashtag
else
	execute 'syntax region gtdTags start=/\%1l/ end=/\%(^$\)\|\%'.eval(g:gtd#tag_lines_count+1).'l/ contains=@NoSpell,gtdTitle,gtdContext,gtdStatus,gtdHashtag'
endif
syntax match gtdTitle /\%1l^=.*/ fold contained contains=@Spell,gtdAttachedFiles
syntax match gtdContext /^@\S\+$/ contained
syntax match gtdStatus /^!\S\+$/ contained
syntax match gtdHashtag /^#\S\+$/ contained
syntax match gtdAttachedFiles / \zs\[\*\]$/ contained

syntax match gtdHeader /^#\{1,6} .*/
syntax keyword gtdTodo TODO WAITING SOMEDAY SCHEDULED DONE

highlight def link gtdTitle Special
highlight def link gtdContext Directory
highlight def link gtdStatus WarningMsg
highlight def link gtdHashtag Keyword
highlight def link gtdAttachedFiles Underlined

highlight def link gtdHeader Title
highlight def link gtdTodo Todo

let b:current_syntax = "gtd"

