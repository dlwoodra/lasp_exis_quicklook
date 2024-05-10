;
; $Id: convert_fm1_sps_xy_to_alpha_beta.pro 35662 2012-09-13 22:11:32Z dlwoodra $
;
pro convert_fm1_sps_xy_to_alpha_beta, x, y, alpha, beta, $
                                      arcmin=arcmin, arcsec=arcsec

; x and y are normalized coordinates ranging from -1.0 to +1.0

;
; FM1 coefficients
; coefficients from SPS_cal_report_4degCruciform_16Feb2012.pdf (DLW)
;
alpha = 0.0353534d0 + y*(-3.41195d0) ; phi (+/- defined from newport stage)
beta = -0.00587391d0 + x*(-3.42534d0) ; theta

; alpha and beta have units of degrees
if keyword_set(arcmin) then begin
   alpha *= 60.
   beta *= 60.
endif
if keyword_set(arcsec) then begin
   alpha *= 3600.
   beta *= 3600.
endif

return
end
