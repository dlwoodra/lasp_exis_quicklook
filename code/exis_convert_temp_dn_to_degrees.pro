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
;    $Id: exis_convert_temp_dn_to_degrees.pro 33372 2012-06-11 19:28:59Z dlwoodra $
;-

;+
; This function converts any EXIS temperature from DN to degrees C using a Steinhart-Hart 
; relation with parameters determined by Darren O'Conner.
; Although this could be used by other procedures, this one was written to provide a
; complete solution for decoding euvsc data.
;
; :Params:
;    x_dn: in, required, type=Integer
;       The data numbers ranging from 0-65535
;
; :Returns:
;    "result" is an array of floating point temperatures in degrees C.
;
;-
function exis_convert_temp_dn_to_degrees, x_dn

; email from Darren march 3, 2010.

; or T = 1 / ( c0 + c1 * x' + c2 * x'^3 ) - c3
c0 = 1.039792559115682d-3
c1 = 2.376268114063773d-4
c2 = 1.610741872588081d-7
c3 = 273.15d0

xprime = alog( (27.d3) * ((2.d^16 / (x_dn+1.d0) ) - 1.d0) )

degrees = 1.d0 / ( c0 + c1*xprime + c2*(xprime^3) ) - c3

return,degrees
end
