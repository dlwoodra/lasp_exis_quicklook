; docformat = 'rst'

;+
; :Author:
;   Don Woodraska
;
; :Copyright:
;    Copyright 2012 The Regents of the University of Colorado.
;    All rights reserved. This software was developed at the
;    University of Colorado's Laboratory for Atmospheric and 
;    Space Physics. 
;
; :Version:
;    $Id: apply_gain.pro 70723 2015-11-26 22:00:16Z dlwoodra $
;
;-


;+
; Converts DN into current for FM1. Hard coded conversions are included.
; FM2 values are from one temperature only, and have not been updated.
; 
;
; :Params:
;    rawdata : in, required, type=lonarr
;      detector DN values (integer types bigger than uint are OK)
;    temperature_DN : in, required, type=uint
;      the corresponding thermistor DN value for the detector
;
; :Keywords:
;    sps : in, optional, type=boolean
;      use keyword to use conversions for SPS
;      imples rawdata has 6 elements
;    xrs : in, optional, type=boolean
;      use keyword to use conversions for XRS
;      imples rawdata has 12 elements
;    euvsa : in, optional, type=boolean
;      use keyword to use conversions for EUVS-A
;      imples rawdata has 24 elements
;    euvsb : in, optional, type=boolean
;      use keyword to use conversions for EUVS-B
;      imples rawdata has 24 elements
;
; :Uses:
;    read_goes_l0b_file
;
;-
function apply_gain, rawdata, temperature_DN, sps=sps, xrs=xrs, euvsa=euvsa, euvsb=euvsb

common apply_gain_cal, temperature_C, xrsgain, $
   euvsagain, euvsbgain

thistype = strupcase(getenv('exis_type'))
if thistype eq 'SIM' then thistype='FM1' ; treat sim like FM1

gcdata = float(rawdata) ; define output corrected data

; load the common block data if necessary
if size(temperature_C,/type) eq 0 then begin
   temperature_C = (read_goes_l0b_file(getenv('exis_cal_data')+'/exis_temperature.cal')).data
   lowcasethistype=strlowcase(thistype)
   xrsgain = (read_goes_l0b_file(getenv('exis_cal_data')+'/exis_'+lowcasethistype+'_xrs_gain.cal')).data
   euvsagain = (read_goes_l0b_file(getenv('exis_cal_data')+'/exis_'+lowcasethistype+'_euvsa_gain.cal')).data
   euvsbgain = (read_goes_l0b_file(getenv('exis_cal_data')+'/exis_'+lowcasethistype+'_euvsb_gain.cal')).data
endif


case thistype OF
   ; NO temperature dependence in ETU
   'ETU': begin
      if keyword_set(sps) then begin
         gc = [68.5707, 69.1799, 65.7046, 65.117, 65., 65.]
      endif
      if keyword_set(xrs) then $
         gc = [9.6868, 10.7187, 9.1748, 10.5539, 8.4755, 9.2929, $
               8.2751, 6.2236, 7.0572, 8.1842, 5.9672, 7.0892]
      ; mapping for ETU (*** NOT FLIGHT! ***)
      if keyword_set(euvsa) then $
         gc = [8.4402, 9.2309, 8.922, 9.8974, 9.9887, 9.6071, $
               7.9758, 8.6540, 8.5439, 7.3545, 7.8723, 7.5, $
               8.6991, 10.8999,7.7800, 9.5679, 8.8281, 9.8280, $
               8.8546, 10.2636,7.9736, 8.8861, 9.1404, 9.3924]
      if keyword_set(euvsb) then $
         gc = [8.8952, 8.3631, 8.3348, 7.7635, 8.4141, 6.7731, $
               8.2786, 7.6970, 6.9350, 7.4614, 7.0126, 8.6385, $
               11.2198,9.6298,10.0442, 8.0982, 6.9550, 9.9504, $
               6.6661, 7.5070, 8.0079, 6.7584, 8.1287, 7.4884]

      for i=0L,n_elements(gc)-1 do gcdata[i,*] = rawdata[i,*] * gc[i]
      return,gcdata
   end
   'FM1': begin

      if keyword_set(sps) then begin
         ; no temperature dependence for FM1 SPS
         ; precision resistors are just guesses
         ;gc = [296.9998689, 289.940531, 286.449731, 303.778297, 290.,290.]
         
         ; gc set to updated values 21 Nov 2012 by Randy Meisner
         ; received in email from Rick Kohnert
         
         gc = [298.6501304, 294.0980859, 287.378693, 306.6934257, 290.,290.]
         
         for i=0L,n_elements(gc)-1 do gcdata[i,*] = rawdata[i,*] * gc[i]
         return,gcdata
      endif

      if keyword_set(xrs) then begin
         gc = dblarr(12)+10 ; one gain for each diode
         gc[*] = reform(xrsgain[1:*,temperature_dn]) * 1e15 ; convert amps to femtoamps

         for i=0L,n_elements(gc)-1 do gcdata[i,*] = rawdata[i,*] * gc[i]
         return,gcdata
      endif

      if keyword_set(euvsa) then begin
         gc = dblarr(24)+10 ; one gain for each diode
         gc[*] = reform(euvsagain[1:*,temperature_dn]) * 1e15 ; convert amps to femtoamps
         for i=0L,n_elements(gc)-1 do gcdata[i,*] = rawdata[i,*] * gc[i]
         return,gcdata
      endif

      if keyword_set(euvsb) then begin
         gc = dblarr(24)+10 ; one gain for each diode
         gc[*] = reform(euvsbgain[1:*,temperature_dn]) * 1e15 ; convert amps to femtoamps
         for i=0L,n_elements(gc)-1 do gcdata[i,*] = rawdata[i,*] * gc[i]
         return,gcdata
      endif
      
   end

   'FM2': BEGIN
      
      if keyword_set(sps) then begin
         ; no temperature dependence for FM2 SPS
         ; precision resistors are just guesses
         ; 30 Jan 2013, SPS gains set to values for 15c in spreadsheet SPS_FM2_ASIC_GAIN_Vs_Temp
         gc = [288.8270526, 278.1329434, 286.6113387, 285.6158038, 300.,300.]
         for i=0L,n_elements(gc)-1 do gcdata[i,*] = rawdata[i,*] * gc[i]
         return,gcdata
      ENDIF
      
      
      if keyword_set(xrs) then begin
         gc = dblarr(12)+10 ; one gain for each diode
         gc[*] = reform(xrsgain[1:*,temperature_dn]) * 1e15 ; convert amps to femtoamps
         for i=0L,n_elements(gc)-1 do gcdata[i,*] = rawdata[i,*] * gc[i]
         return,gcdata
      ENDIF

      if keyword_set(euvsa) then BEGIN
         gc = dblarr(24)+10 ; one gain for each diode
         gc[*] = reform(euvsagain[1:*,temperature_dn]) * 1e15 ; convert amps to femtoamps
         for i=0L,n_elements(gc)-1 do gcdata[i,*] = rawdata[i,*] * gc[i]
         return,gcdata
      endif

      if keyword_set(euvsb) then BEGIN
         gc = dblarr(24)+10 ; one gain for each diode
         gc[*] = reform(euvsbgain[1:*,temperature_dn]) * 1e15 ; convert amps to femtoamps
         for i=0L,n_elements(gc)-1 do gcdata[i,*] = rawdata[i,*] * gc[i]
         return,gcdata
      endif
      
   end
   
   'FM3': BEGIN
      
      if keyword_set(sps) then begin
         ; no temperature dependence for FM2 SPS
         ; precision resistors are just guesses
         ; 
         ; 30 Jan 2013, SPS gains set to values for 15c in spreadsheet SPS_FM3_ASIC_GAIN_Vs_Temp
         
         gc = [283.4928766, 276.4460748, 302.241912, 290.8680222, 300.,300.]
         
         for i=0L,n_elements(gc)-1 do gcdata[i,*] = rawdata[i,*] * gc[i]
         return,gcdata
      ENDIF
      
      
      if keyword_set(xrs) then begin
         ; table updated april 30, 2013

         ; new table has tlm order, no re-arrangement is necessary
         gc = dblarr(12)+10 ; one gain for each diode
         gc[*] = reform(xrsgain[1:*,temperature_dn]) * 1e15 ; convert amps to femtoamps

         for i=0L,n_elements(gc)-1 do gcdata[i,*] = rawdata[i,*] * gc[i]
         return,gcdata
      endif

      if keyword_set(euvsa) then BEGIN         
         gc = dblarr(24)+10 ; one gain for each diode
         gc[*] = reform(euvsagain[1:*,temperature_dn]) * 1e15 ; convert amps to femtoamps
         for i=0L,n_elements(gc)-1 do gcdata[i,*] = rawdata[i,*] * gc[i]
         return,gcdata
      endif

      if keyword_set(euvsb) then BEGIN         
         gc = dblarr(24)+10 ; one gain for each diode
         gc[*] = reform(euvsbgain[1:*,temperature_dn]) * 1e15 ; convert amps to femtoamps
         for i=0L,n_elements(gc)-1 do gcdata[i,*] = rawdata[i,*] * gc[i]
         return,gcdata
      endif
      
   END
   
   'FM4': BEGIN
      
      if keyword_set(sps) then begin
         ; no temperature dependence for FM2 SPS
         ; precision resistors are just guesses
         ; 
         ; 10/16/13 Incorporated 15c gains from SPS_FM4_ASIC_GAIN_Vs_Temp.xlsx
         ; FM4
         gc = [274.2569585, 273.1237068, 270.0327594, 281.9557553, 300., 300.]
         
         for i=0L,n_elements(gc)-1 do gcdata[i,*] = rawdata[i,*] * gc[i]
         return,gcdata
      ENDIF
      
      
      if keyword_set(xrs) then begin
         gc = dblarr(12)+10 ; one gain for each diode
         gc[*] = reform(xrsgain[1:*,temperature_dn]) * 1e15 ; convert amps to femtoamps
         for i=0L,n_elements(gc)-1 do gcdata[i,*] = rawdata[i,*] * gc[i]
         return,gcdata
      endif

      if keyword_set(euvsa) then BEGIN
         gc = dblarr(24)+10 ; one gain for each diode
         gc[*] = reform(euvsagain[1:*,temperature_dn]) * 1e15 ; convert amps to fem
         for i=0L,n_elements(gc)-1 do gcdata[i,*] = rawdata[i,*] * gc[i]
         return,gcdata
      endif

      if keyword_set(euvsb) then BEGIN
         gc = dblarr(24)+10 ; one gain for each diode
         gc[*] = reform(euvsbgain[1:*,temperature_dn]) * 1e15 ; convert amps to fem
         for i=0L,n_elements(gc)-1 do gcdata[i,*] = rawdata[i,*] * gc[i]
         return,gcdata
      endif
      
   END
   
   'SPARE': begin
   END
   
endcase


return,gcdata
end
