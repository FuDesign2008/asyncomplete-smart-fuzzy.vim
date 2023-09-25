
if &compatible || exists('g:asyncomplete_smart_fuzzy_loaded')
    finish
endif
let g:asyncomplete_smart_fuzzy_loaded = 1
let s:save_cpo = &cpoptions
set cpoptions&vim

if exists('g:asf_min_num_of_chars_for_completion') == 0
    let g:asf_min_num_of_chars_for_completion = 2
endif


" @param {string} base
" @return {string}
function! s:convert_base_to_pattern(base)
    let length = strlen(a:base)

    if length == 0
        return ''
    endif

    let hasUpper = match(a:base, '\C[A-Z]')
    if hasUpper == 0
        return ''
    endif

    let index = 0

    let l:reg = '\C^'

    while index < length
        let theChar = strpart(a:base, index, 1)
        if match(theChar, '\C[a-z0-9_:#$-]') > -1
            " C-style veriable  A-Za-z0-9_
            " css class name like class-name
            " $ for $el
            let l:reg = l:reg . '[a-z0-9_:#$-]*' . theChar
        elseif match(theChar, '\C[A-Z]') > -1
            let l:reg = l:reg . '[a-zA-Z0-9_:#$-]*' . theChar
        endif
        let index += 1
    endwhile

    return l:reg
endfunction


function! s:is_file_like(matches)
    let matchResult = get(a:matches, 'file', {})
    if empty(matchResult)
        return 0
    endif
    let items = get(matchResult, 'items', [])
    let l:count = len(items)
    return l:count > 0 ? 1 : 0
endfunction

" @param {Options} options
" @inteferce Options {
"   typed: String #?
" }
"
" @param {Record<string, Match>} matches
"
" @inteferce CompleteItem {  # @see :help complete-items
"   word: string
"   kind: string  single letter indicating the type of completion # @see :help complete-item-kind
" }
" @inteferce Match {
"    startcol: Integer
"    items: CompleteItem[]
"}
function! s:sort_by_fuzzy_preprocessor(options, matches) abort
    let l:items = []
    let l:startcols = []
    let l:should_sort = 0
    let superWeights = {}
    let asyncompleteLspSuperWeightValue = 10000
    let superWeightValue = 1000
    let superSourceNames = []

    if s:is_file_like(a:matches)
        let superWeights.file = superWeightValue
        call add(superSourceNames, 'file')
    endif

    for [l:source_name, l:matches] in items(a:matches)
        let l:startcol = l:matches['startcol']
        let l:base = a:options['typed'][l:startcol - 1:]
        " echomsg 'source_name: ' . l:source_name
        " echomsg 'startcol: ' . l:startcol
        " echomsg 'base: ' . l:base
        " echomsg 'typed: ' . a:options['typed']
        " echomsg 'matches: ' . join(l:matches.items, ', ')

        if stridx(l:source_name, 'asyncomplete_lsp_') > -1
            let sourceSuperWeight = asyncompleteLspSuperWeightValue
        else
            let sourceSuperWeight = get(superWeights, l:source_name, 0)
        endif

        if index(superSourceNames, l:source_name) > -1 || strlen(l:base) >= g:asf_min_num_of_chars_for_completion
            let l:pattern = s:convert_base_to_pattern(l:base)
            let l:pattern_valid = strlen(l:pattern) > 0
            let l:fuzzy_match = matchfuzzypos(l:matches['items'], l:base, {'key':'word'})
            let l:fuzzy_match_items = l:fuzzy_match[0]
            let l:fuzzy_match_weight = l:fuzzy_match[2]
            " echomsg 'pattern' . l:pattern

            let l:fuzzy_index = 0
            for l:item in l:fuzzy_match_items
                if l:pattern_valid
                    let l:word = get(l:item, 'word', '')
                    let l:smart_match = match(l:word, l:pattern)
                    if l:smart_match != -1
                        let l:item['weight'] = sourceSuperWeight +  l:fuzzy_match_weight[l:fuzzy_index]
                        let l:should_sort = 1
                        call add(l:items, l:item)
                        let l:startcols += [l:startcol]
                    endif
                else
                    let l:item['weight'] = sourceSuperWeight +  l:fuzzy_match_weight[l:fuzzy_index]
                    let l:should_sort = 1
                    call add(l:items, l:item)
                    let l:startcols += [l:startcol]
                endif

                let l:fuzzy_index += 1
            endfor
        endif
    endfor

    let a:options['startcol'] = min(l:startcols)

    if l:should_sort
        let l:items = sort(l:items, {a, b -> b['weight'] - a['weight']})
    endif

    call asyncomplete#preprocess_complete(a:options, l:items)
endfunction

if exists('*matchfuzzypos')
    let g:asyncomplete_preprocessor = [function('s:sort_by_fuzzy_preprocessor')]
else
    echomsg 'asyncomplete-smart-fuzzy.vim needs matchfuzzypos().'
endif

let &cpoptions = s:save_cpo
