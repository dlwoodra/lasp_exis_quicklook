; $Id: check_exis_limits.pro 21451 2010-11-09 01:32:56Z dlwoodra $

pro check_exis_limits, lim, x, co

; check yellow limits first
y = where(lim.ylo ge x or lim.yhi le x, n_y)
if n_y eq 0 then return else $
   co[y] = '99ffff'xUL

;check red limits
r = where(lim.rlo ge x or lim.rhi le x, n_r)
if n_r ne 0 then co[r] = 'ff'xUL

return
end
