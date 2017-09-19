
function! s:GtdFormulaOperatorPrecedenceHelper(formula)
	let l:formula = substitute(a:formula, '^\s*\(.\{-}\)\s*$', '\1', '')
	let l:formula = substitute(l:formula, '\([()]\)', '\1\1\1', 'g')
	let l:formula = substitute(l:formula, '\s*+\s*', '))+((', 'g')
	let l:formula = substitute(l:formula, '\s\+', ') (', 'g')
	return '(('.l:formula.'))'
endfunction

function! gtd#formula#Parser(formula)
	return s:GtdFormulaParser(
		\ s:GtdFormulaListConvert(
			\ s:GtdFormulaOperatorPrecedenceHelper(a:formula)
			\ )
		\ )
endfunction

function! s:GtdFormulaParser(formula)

	let [ l:c_idx, l:br_match, l:brackets ] = [ 0, 0, 0 ]
	let l:formula_len = len(a:formula)
	while l:c_idx < l:formula_len
		if a:formula[l:c_idx] == '('
			let l:br_match += 1
		elseif a:formula[l:c_idx] == ')'
			let l:br_match -= 1
		endif

		if l:br_match == 0
			break
		else
			let l:brackets = 1
		endif

		let l:c_idx += 1
	endwhile

	if l:brackets == 1
		if l:c_idx == l:formula_len-1
			return s:GtdFormulaParser(
				\ a:formula[1:l:c_idx-1]
				\ )
		else
			let l:operator = get(a:formula, l:c_idx+1)
			if l:operator == '+' || l:operator == ' '
				return [
					\ l:operator,
					\ s:GtdFormulaParser(
						\ a:formula[0:l:c_idx]
						\ ),
					\ s:GtdFormulaParser(
						\ a:formula[l:c_idx+2:]
						\ )
					\ ]
			endif
		endif
	else
		return get(a:formula, 0)
	endif

endfunction

function! gtd#formula#ToString(formula)
	if type(a:formula) == v:t_string
		return a:formula
	else
		if a:formula[0] == '+'
			return gtd#formula#ToString(a:formula[1])
				\ .' + '
				\ .gtd#formula#ToString(a:formula[2])
		elseif a:formula[0] == ' '
			let [ l:brackets_left, l:brackets_right ] = [ 0, 0 ]

			if type(a:formula[1]) != v:t_string && a:formula[1][0] == '+'
				let l:brackets_left = 1
			endif

			if type(a:formula[2]) != v:t_string && a:formula[2][0] == '+'
				let l:brackets_right = 1
			endif

			let l:left = gtd#formula#ToString(a:formula[1])
			if l:brackets_left == 1
				let l:left = '('.l:left.')'
			endif

			let l:right = gtd#formula#ToString(a:formula[2])
			if l:brackets_right == 1
				let l:right = '('.l:right.')'
			endif

			return l:left.' '.l:right
		endif
	endif
endfunction

function! s:GtdFormulaListConvert(formula)
	let [ l:formula_list, l:c_idx, l:atom_pending ] = [ [], 0, '' ]

	while l:c_idx < strlen(a:formula)
		if index([ '(', ')', '+', ' ' ], a:formula[l:c_idx]) >= 0
			if !empty(l:atom_pending)
				let l:formula_list += [ l:atom_pending ]
				let l:atom_pending = ''
			endif
			let l:formula_list += [ a:formula[l:c_idx] ]
		else
			let l:atom_pending .= a:formula[l:c_idx]
		endif
		let l:c_idx += 1
	endwhile

	if !empty(l:atom_pending)
		let l:formula_list += [ l:atom_pending ]
	endif

	return l:formula_list
endfunction

function! gtd#formula#AtomUseful(formula, operator, atom)
	if type(a:formula) == v:t_string
		return a:formula != a:atom
	endif

	if a:operator == a:formula[0]
		return gtd#formula#AtomUseful(a:formula[1], a:operator, a:atom)
			\ && gtd#formula#AtomUseful(a:formula[2], a:operator, a:atom)
	else
		return gtd#formula#AtomUseful(a:formula[1], a:operator, a:atom)
			\ || gtd#formula#AtomUseful(a:formula[2], a:operator, a:atom)
	endif
endfunction

