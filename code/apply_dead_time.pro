function apply_dead_time, rawdata

gdata = float(rawdata) / (1.-(float(rawdata)*1.e-7))

return,gdata
end
