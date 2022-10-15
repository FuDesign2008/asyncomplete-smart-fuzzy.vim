# asyncomplete-smart-fuzzy.vim

> Smart-case fuzzy filter for asyncomplete

## Smart-Case

The asyncomplete.vim use `matchfuzzypos` to support fuzzy compeletion (see https://github.com/prabirshrestha/asyncomplete.vim/issues/137), but `matchfuzzypos` does not support smart-case, so this plugin add smart-case fuzzy completion.

Filtering is "smart-case" sensitive; if you are
typing only lowercase letters, then it's case-insensitive. If your input
contains uppercase letters, then the uppercase letters in your query must
match uppercase letters in the completion strings (the lowercase letters still
match both).

<table>
<tbody>
<tr>
  <th>matches</th>
  <th>foo</th>
  <th>fOo</th>
</tr>
<tr>
  <th>foo</th>
  <td>✔️</td>
  <td>❌</td>
</tr>
<tr>
  <th>fOo</th>
  <td>✔️</td>
  <td>✔️</td>
</tr>
</tbody>

## Usage

1. Just install this vim plugin
    - Need `matchfuzzypos()` support in vim, run `exists('*matchfuzzypos')` or `help matchfuzzypos` to see more.
2. Enjoy **smart-case** completion
