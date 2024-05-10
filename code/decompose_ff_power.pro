;+
; Decompose the flatfield LED power status register based on FPGA spec 110933A
;-
function decompose_ff_power, ff_cal_struct

result=ff_cal_struct

result.pwr_enable = result.power and '1'xb ; LSB
result.pri_red    = ishft(result.power,-3) and '1'xb ; 0=LED2, 1=LED1
; the concept of primary and redundant is opposite for EUVS-C
result.channel    = ishft(result.power,-1) and '3'xb ; 0=euvsc1, 1=euvsb, 2=euvsa, 3=xrs

result.english='Off'
if result.pwr_enable eq 1 then begin
   case result.channel + (result.pri_red*4L) of 
      0: result.english='C1'
      1: result.english='B-Red'
      2: result.english='A-Red'
      3: result.english='X-Red'
      4: result.english='C2'
      5: result.english='B-Pri'
      6: result.english='A-Pri'
      7: result.english='X-Pri'
   endcase
   ;if result.pri_red eq 0 then $
   ;   result.english = result.english + 'Red' else $
   ;   result.english = result.english + 'Pri'
endif

return,result
end
