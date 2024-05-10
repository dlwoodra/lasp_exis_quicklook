; docformat = 'rst'

;+
; :Author:
;    Don Woodraska
;
; :Copyright:
;    Copyright 2012 The Regents of the University of Colorado.
;    All rights reserved. This software was developed at the
;    University of Colorado's Laboratory for Atmospheric and
;    Space Physics.
; 
; :Version:
;    $Id: decode_euvsc.pro 78954 2017-08-30 22:06:33Z dlwoodra $
;-

;+
; This function decodes the euvsc data into more scientificially useable values
; to support science analysis of testing data. 
;
; :Params:
;    euvsc_in: in, required, type='array of level 0b data structures'
;       The results from a call to read_goes_l0b_file
;
; :Returns:
;    "result" is a new array of structures containing more useful tags.
;
; :Uses:
;    exis_convert_temp_dn_to_degrees
; 
; :Examples:
;    For example, the call to read_goes_l0b_file returns a structure euvsc_in which is used as an argument to this function::
;       IDL> out = decode_euvsc( euvsc_in )
;       IDL> help,out,/str
;       ** Structure <5099018>, 18 tags, length=4264, data length=4244, refs=1:
;       RAW             STRUCT    -> <Anonymous> Array[1]
;       DECODED_DATA    FLOAT     Array[512]
;       EXPOSURE_TIME_SECONDS
;                       FLOAT          0.245480
;       FLUSH_COUNT     BYTE         0
;       PIXEL_MODE      BYTE         0
;       PIXEL_MODE_STRING
;                       STRING    'DataMinusRef'
;       POWER_C1        BYTE         1
;       POWER_C2        BYTE         0
;       IFBOARDTEMP_DEG FLOAT           15.0866
;       FPGATEMP_DEG    FLOAT           15.4411
;       PWRSUPPLYTEMP_DEG
;                       FLOAT           14.5227
;       CASEHTRTEMP_DEG FLOAT           13.7615
;       EUVSCHTRTEMP_DEG
;                       FLOAT           14.1370
;       C1TEMP_DEG      FLOAT           14.2198
;       C2TEMP_DEG      FLOAT           14.2428
;       ADCTEMP_DEG     FLOAT           13.9261
;       FFPOWER_C1      BYTE         0                                
;       FFPOWER_C2      BYTE         0
;
;-
function decode_euvsc, euvsc_in

if size(euvsc_in,/type) ne 8 then begin
   print,'USAGE: decoded_structure = decude_euvsc( euvsc_datastructure_from_l0b_file )'
   return,-1
endif

ntags = n_tags(euvsc_in)
tagnames = tag_names(euvsc_in)

; create a named structure from the input
out_rec = { $ ;euvsc_data, $
          raw: euvsc_in[0], $
          decoded_data: float(euvsc_in[0].data), $
          exposure_time_seconds: 0., $
          flush_count:0b, $
          pixel_mode:0b, $
          pixel_mode_string:'', $
          power_c1: 0b, $
          power_c2: 0b, $
          ifboardtemp_deg: 0., $
          fpgatemp_deg: 0., $
          pwrsupplytemp_deg: 0., $
          casehtrtemp_deg: 0., $
          euvschtrtemp_deg: 0., $
          c1temp_deg: 0., $
          c2temp_deg: 0., $
          adctemp_deg: 0., $
          ffpower_c1: 0b, $
          ffpower_c2: 0b $
          }
out = replicate(out_rec, n_elements(euvsc_in))

;
; copy raw data into the raw substructure
;
for i=0L,ntags-1 do out.raw.(i) = euvsc_in.(i)


;
; decode the diode data to allow negative numbers
;
someOffsetUniqueToEachDetector = 2048L
tmp = long(euvsc_in.data)             ; step 1) - convert to 32-bit signed int
tmp += someOffsetUniqueToEachDetector  ; step 2) - add an offset
tmp = tmp mod 65536                    ; step 3) - calculate modulus with 2^16
tmp -= someOffsetUniqueToEachDetector  ; step 4) - subtract the offset used in step 2
out.decoded_data = temporary(tmp)


;
; convert the registers into actual exposure time in seconds
;
ic = out.raw.cal_integtime         ; integration count register
dc = out.raw.cal_deadtime          ; dead time register
fc = out.raw.cal_modereg and '11'b ; flush count is LSB 2 bits
out.flush_count = fc

out.exposure_time_seconds = 1e-3 * $
                            ( (250.  * (ic + 1)) - $
                              (25.   * (dc + 1)) - $
                              (20.48 * (fc - 1)) ) ; CDRL80 eq 5.16

extra = where(fc eq 3 and dc eq 7,n_extra)
if n_extra gt 0 then out[extra].exposure_time_seconds += 0.25 ; CDRL80 eq. 5.17

;
; pixel mode
;
out.pixel_mode = ishft(out.raw.cal_modereg,-6) ; MSB 2 bits
out.pixel_mode_string = 'DataMinusRef'
datamode=where(out.pixel_mode eq 2,n_datamode)
refmode=where(out.pixel_mode eq 3,n_refmode)
if (n_datamode gt 0) then out[datamode].pixel_mode_string = 'DataOnly'
if (n_refmode gt 0)  then out[refmode].pixel_mode_string  = 'RefOnly'


;
; power_c1 and power_c2
;
power_c1 = where(out.raw.cal_pwrstatus eq 5,  n_power_c1)
power_c2 = where(out.raw.cal_pwrstatus eq 11, n_power_c2)
if n_power_c1 gt 0 then out[power_c1].power_c1 = 1 ; 1 means ON (default is off)
if n_power_c2 gt 0 then out[power_c2].power_c2 = 1


; convert temperatures
out.ifboardtemp_deg   = exis_convert_temp_dn_to_degrees( out.raw.ifboardtemp_dn )
out.fpgatemp_deg      = exis_convert_temp_dn_to_degrees( out.raw.fpgatemp_dn )
out.pwrsupplytemp_deg = exis_convert_temp_dn_to_degrees( out.raw.pwrsupplytemp_dn )
out.casehtrtemp_deg = exis_convert_temp_dn_to_degrees( out.raw.casehtrtemp_dn )
out.euvschtrtemp_deg = exis_convert_temp_dn_to_degrees( out.raw.euvschtrtemp_dn )

out.c1temp_deg = exis_convert_temp_dn_to_degrees( out.raw.c1temp_dn )
out.c2temp_deg = exis_convert_temp_dn_to_degrees( out.raw.c2temp_dn )

out.adctemp_deg = exis_convert_temp_dn_to_degrees( out.raw.adctemp_dn )


;
; LED flatfield power status
;

;
; Updated 8/27/12 DLW to fix bug for C1 led power state
;
; Stim lamp control register definition
;  Stim Lamp power enable = LSB is on/off  (1/0)
;  Stim Lamp select = bits 1-3 are 
;    0=c1, 1=Bred, 2=Ared, 3=Xred, 4=C2, 5=Bpri, 6=Apri, 7=Xpri
;  C1 stim lamp control register = 1 (0001b)
;  C2 stim lamp control register = 9 (1001b)
ffpower_c1 = where(out.raw.ff_power eq 1, n_ffpower_c1) ; 0001b
ffpower_c2 = where(out.raw.ff_power eq 9, n_ffpower_c2) ; 1001b
if n_ffpower_c1 gt 0 then out[ffpower_c1].ffpower_c1 = 1
if n_ffpower_c2 gt 0 then out[ffpower_c2].ffpower_c2 = 1

return,out
end
