; docformat = 'rst'

;+
; Calculates smoothed rate of change of input array of floats
;
; :Author:
;    Don Woodraska, S. Mueller
;
; :Copyright:
;    Copyright 2012 The Regents of the University of Colorado.
;    All rights reserved. This software was developed at the
;    University of Colorado's Laboratory for Atmospheric and
;    Space Physics.
;
; :Version:
;    $Id: plot_temperatures.pro 48663 2013-10-07 23:19:13Z dlwoodra $
;-
;+
; Calculate the rate of change
;
; :Params:
;     array : in, required, type="float array"
;             An array of values used to calculate the rate of change
;     smoothvalue: in, required, type=integer
;             The number of samples to smooth, also used to multiply
;             to obtain the proper rate units (denominator). For 1 Hz
;             temperature samples in degrees, use a value of 60 to get
;             units of degrees/minute.
;             
; :Returns:
;   Array of floats representing smoothed 1st-order derivatives of input array
;-
function calc_rate_of_change, array, smoothvalue

  if n_elements(array) lt smoothvalue then begin
    print,'Warning: Not enough values to calculate rate of change'
    return,array*0.
  endif

  data = deriv(reform(array))
  ; replace last value with 2nd-to-last value (value supplied by deriv() is junk)
  data[n_elements(data)-1] = data[n_elements(data)-2]
  data[0] = data[1]

  data = (smooth(data,smoothvalue,/edge_trunc)*float(smoothvalue))
  ; replace last n values
  ;data[n_elements(data)-smoothvalue:n_elements(data)-1] = data[n_elements(data)-smoothvalue]
  data[n_elements(data)-((smoothvalue/6) > 2):n_elements(data)-1] = data[n_elements(data)-smoothvalue]

  ; replace oldest data, too
  data[0:1] = data[2]

  return,data
end
