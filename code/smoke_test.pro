pro smoke_test

; run this procedure from the quicklook code directory
exis_quicklook,'./EXIS1_2013_050_16_00_59_raw_record',/no_files,/ois

; the data file shows some SURF calibration data on XRS

; this test shows that it either works or it does not

; it gets rather monotonous, so interrupt with control-c once the 
; data appears to stablilize

return
end
