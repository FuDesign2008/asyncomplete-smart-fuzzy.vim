
function! s:get_upper_letters(str)
    let l:start = 0
    let l:letters = []
    let l:result = matchstrpos(a:str, '\C[A-Z]', l:start)
    while l:result[1] != -1
        call add(l:letters, l:result[0])
        let l:start = l:result[2]
        let l:result = matchstrpos(a:str, '\C[A-Z]', l:start)
    endwhile

    let l:letters = uniq(l:letters)
    return l:letters
endfunction

" @param {string[]} letters
" @return {string}
function! s:convert_to_pattern(letters)
    if len(a:letters) == 0
        return ''
    endif
    let l:reg = '\C'
    for l:item in a:letters
        " C-style veriable  A-Za-z0-9_
        " css class name like class-name
        let l:reg = l:reg . '[a-zA-Z0-9_:#-]*' . l:item
    endfor
    return l:reg
endfunction

" @param {Options} options
" @inteferce Options {
"   typed: String #?
" }
"
" @param {Record<string, Match>} matches
"
" @inteferce CompleteItem {  # @see :help complete-items
"   word: String
" }
" @inteferce Match {
"    startcol: Integer
"    items: CompleteItem[]
"}
function! s:sort_by_fuzzy_preprocessor(options, matches) abort
    let l:items = []
    let l:startcols = []
    for [l:source_name, l:matches] in items(a:matches)
        let l:startcol = l:matches['startcol']
        let l:base = a:options['typed'][l:startcol - 1:]
        if empty(l:base)
            for l:item in l:matches['items']
                call add(l:items, l:item)
                let l:startcols += [l:startcol]
            endfor
        else

            let l:uppers = s:get_upper_letters(l:base)
            let l:pattern = s:convert_to_pattern(l:uppers)
            let l:pattern_valid = strlen(l:pattern) > 0
            for l:item in matchfuzzypos(l:matches['items'], l:base, {'key':'word'})[0]
                if l:pattern_valid
                    let l:word = get(l:item, 'word', '')
                    let l:upper_match = matchstrpos(l:word, l:pattern)
                    if l:upper_match[1] != -1
                        call add(l:items, l:item)
                        let l:startcols += [l:startcol]
                    endif
                else
                    call add(l:items, l:item)
                    let l:startcols += [l:startcol]
                endif
            endfor
        endif
    endfor

    let a:options['startcol'] = min(l:startcols)
    call asyncomplete#preprocess_complete(a:options, l:items)
endfunction

if exists('*matchfuzzypos')
    let g:asyncomplete_preprocessor = [function('s:sort_by_fuzzy_preprocessor')]
else
    echomsg 'asyncomplete-smart-fuzzy.vim needs matchfuzzypos().'
endif

