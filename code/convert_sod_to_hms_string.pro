function convert_sod_to_hms_string, sod

; sod is a double input

; create integer millisecond of day
nms = round(sod*1000L) ; round to the nearest millisecond

intSecInDay = long(nms) / 1000L ; integer seconds of day

hh = string(intSecInDay / (3600L),form='(i2.2)')
mm = string((intSecInDay mod (3600L)) / 60L,form='(i2.2)')
ss = string(intSecInDay mod 60L,form='(i2.2)')
; milliseconds as integer
sss = '.'+string(nms mod 1000L,form='(i3.3)') ; string

hms = hh+':'+mm+':'+ss+sss

return,hms
end
