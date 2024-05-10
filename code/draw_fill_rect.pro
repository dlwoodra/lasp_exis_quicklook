pro draw_fill_rect, x, y, width, color=color

hw=width*0.5
tx=[x-hw,x-hw,x+hw,x+hw]
ty=[!y.crange[0],y,y,!y.crange[0]]
polyfill, tx, ty, color=color,/data

return
end
