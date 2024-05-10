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
;    $Id: decompose_euvsc_data.pro 47263 2013-08-22 23:29:37Z dlwoodra $
;
;-

;+
; This procedure takes a byte array buffer as input, the euvsc structure
; as output and the packet apid as an input index. It creates the 16-bit
; raw data and decodes it to allow negative numbers in the decoded_data array.
;
;
; :Params:
;    buf: in, required, type=bytarr
;      byte array from the packet
;    euvsc_rec: out, required, type=structure
;      structure for EUVS-C defined in gpds_defines.pro
;    index: in, required, type=long
;      an integer from 0 to 7 used to identify the location of the data in 
;      the data array
;
;-
pro decompose_euvsc_data, buf, euvsc_rec, index

  common decompose_euvsc_data, a, b, lo, hi

  if size(a,/type) eq 0 then begin
     a = lindgen(8)*64L
     b = a+63L
     lo = 20                    ;byte 32 in packet
     hi = lo + 127
  endif

  euvsc_rec.data[a[index]:b[index]] = ishft( uint( buf[lo:hi:2] ), 8) + uint(buf[lo+1:hi+1:2])

  someOffsetUniqueToEachDetector = 2048L

  tmp = long(euvsc_rec.data[a[index]:b[index]]) ; step 1) - convert to 32-bit signed int
  tmp += someOffsetUniqueToEachDetector ; step 2) - add an offset
  tmp = tmp mod 65536 ; step 3) - calculate modulus with 2^16
  tmp -= someOffsetUniqueToEachDetector ; step 4) - subtract the offset used in step 2

  euvsc_rec.decoded_data[a[index]:b[index]] = tmp

return
end
