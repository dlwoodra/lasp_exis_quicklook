pro make_diode_def_struct, euvsa, euvsb

; 3/15/13 Don Woodraska Initial creation

rec = { channel:'EUVS-A',diode_description:'',$
        Diode_name:'',$
        group:'dark',$
        tlm_index:0L, $         ; telemetry order
        cathode_number:0L,$     ; same as quicklok plots
        wavelength_nm:0. }

euvsa=replicate(rec,24)
euvsb=euvsa


euvsa.diode_description = $
   ['a1_dark1',$
    'a2-256-1','a3-256-2','a4-256-3','a5-256-4','a6-256-5',$
    'a13-284-1','a14-284-2','a15-284-3','a16-284-4','a17-284-5',$
    'a24-dark2',$
    'a23-304-1','a22-304-2','a21-304-3top','a20-304-4bottom','a19-304-5','a18-304-6',$
    'a12-256-11','a11-256-10','a10-256-9','a9-256-8','a8-256-7','a7-256-6']
euvsa[1:5].group='256 group'
euvsa[18:23].group='256 group'
euvsa[6:10].group='284 group'
euvsa[12:17].group='304 group'
euvsa.tlm_index = lindgen(24)
;euvsa.cathode_number=[0, 1,2,3,4,5, 23,22,21,20,19,18, 6,7,8,9,10, 17,16,15,14,13,12, 11]+1L
euvsa.cathode_number=[1, 2,3,4,5,6, 13,14,15,16,17, 24, 23,22,21,20,19,18, 12,11,10,9,8,7] ; Fixed 7/24/13
euvsa.diode_name='A'+strtrim([1,2,3,4,5,6,13,14,15,16,17,24,23,22,21,20,19,18,12,11,10,9,8,7],2)
euvsa.wavelength_nm = $
   [100., $
    243.95, 245.99, 248.04, 250.09, 252.15, $
    279.86, 282.00, 284.15, 286.30, 288.46, $
    400.,$
    308.29, 306.07, 303.87, 303.87, 301.67, 299.47, $
    264.62, 262.53, 260.44, 258.36, 256.28, 254.21 $
   ]/10.
;EUVS-A:
;256A diodes: 243.95, 245.99, 248.04, 250.09, 252.15, 254.21, 256.28, 258.36, 260.44, 262.53, 264.62
;284A diodes: 279.86, 282.00, 284.15, 286.30, 288.46
;304A diodes: 299.47, 301.67, 303.87 (split pixel), 306.07, 308.29


euvsb.channel = 'EUVS-B'
euvsb.diode_description = $
   ['b2-140-6','b3-140-5','b4-140-4','b5-140-3','b6-140-2','b7-140-1',$
    'b13-121-6','b14-121-5','b15-121-4top','b16-121-3bottom','b17-121-2','b18-121-1',$
    'b24-dark2',$
    'b23-117-1','b22-117-2','b21-117-3','b20-117-4','b19-117-5', $
    'b12-133-5','b11-133-4','b10-133-3','b9-133-2','b8-133-1',$
    'b1-dark1']
euvsb[0:5].group='140 group'
euvsb[6:11].group='121 group'
euvsb[13:17].group='117 group'
euvsb[18:22].group='133 group'
euvsb.tlm_index = lindgen(24)
;euvsb.cathode_number=[12,13,14,15,16,17, 11,10,9,8,7,6, 18,19,20,21,22, 5,4,3,2,1,0, 23]+1L
euvsb.cathode_number=[2,3,4,5,6,7, 13,14,15,16,17,18, 24, 23,22,21,20,19, 12,11,10,9,8, 1] ; Fixed 7/24/13
euvsb.wavelength_nm=[ $
                 1418.78, 1410.47, 1402.16, 1393.85, 1385.53, 1377.22, $
                 1223.69, 1219.48, 1215.27, 1215.27, 1211.06, 1206.85, $
                 1000., $
                 1167.00, 1171.21, 1175.42, 1179.64, 1183.85, $
                 1326.26, 1330.47, 1334.67, 1338.87, 1343.07, $
                 1500. $                  
                 ]/10.

;EUVS-B:
;1175A diodes: 1167.00, 1171.21, 1175.42, 1179.64, 1183.85
;1216A diodes: 1206.85, 1211.06, 1215.27 (split pixel), 1219.48, 1223.69
;1335A diodes: 1326.26, 1330.47, 1334.67, 1338.87, 1343.07
;1405A diodes: 1377.22, 1385.53, 1393.85, 1402.16, 1410.47, 1418.78

return
end