pro make_limits

lim_rec={rlo:0., ylo:0., yhi:0., rhi:0.}
lim = { xrs:replicate(lim_rec,12), $
        sps:replicate(lim_rec,6), $
        euvsa:replicate(lim_rec,24), $
        euvsb:replicate(lim_rec,24), $
        euvsc:replicate(lim_rec,512) }

;default limits (DN at default integration rates)
; RED LOW
val=10.
lim.xrs.rlo   = val
lim.sps.rlo   = 0. ; never get red lo for SPS
lim.euvsa.rlo = val
lim.euvsb.rlo = val
lim.euvsc.rlo = val

; YELLOW LOW
val=12.
lim.xrs.ylo   = val
lim.sps.ylo   = 1.
lim.euvsa.ylo = val
lim.euvsb.ylo = val
lim.euvsc.ylo = val

; YELLOW HIGH
asicmaxpersecond = 1.e6 - 11000. ; 1 MHz with 11 ms dead time
val = (asicmaxpersecond - 1.) * 0.9 ; within 10% of max possible
lim.xrs.yhi   = val
lim.sps.yhi   = (250000. - 11000.)*.90 ; 90% assume 4Hz integration rate
lim.euvsa.yhi = val
lim.euvsb.yhi = val
lim.euvsc.yhi = (2.^16-1.)*0.9 ;within 10% of max possible

; RED HIGH
val = (asicmaxpersecond - 1.) - 100. ;within 100 of max possible
lim.xrs.rhi   = val
lim.sps.rhi   = (250000. - 11000.) - 100. ; assume 4Hz integration rate
lim.euvsa.rhi = val
lim.euvsb.rhi = val
lim.euvsc.rhi = 2.^16 - 1. - 2048. ;within 2048 of max possible

save,file='limits.sav',lim

stop
return
end
