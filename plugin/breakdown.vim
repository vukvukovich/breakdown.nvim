if exists('g:loaded_breakdown')
  finish
endif
let g:loaded_breakdown = 1

command! Breakdown lua require('breakdown').breakdown()
