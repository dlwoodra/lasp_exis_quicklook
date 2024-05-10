pro plot_euvsc_count_image, euvsc_rec

common plot_euvsc_count_image_cal, euvsc, sig, window_id, last_scale

return

n_keep = 256

; choose scale by factor of two
scale = 2L
;scale = (euvsc_rec.cal.integtime + 1) ; seconds
;
;stop

img=fltarr(512,n_keep*scale)
col_fg = '000000'xUL
col_bg = 'ffffff'xUL

if size(euvsc,/type) eq 0 then begin
   window_id = get_window_id('EMI-EUVS-C_Count_Image')
   euvsc = euvsc_rec
   wset,window_id
   plot,[0,511],[0,n_keep/scale],/nodata,xr=[0,511],xs=1,yr=[0,n_keep/scale - 1],ys=1, xtit='pixel #',background=col_bg,color=col_fg
   loadct,39
endif else begin
  if n_elements(euvsc) lt n_keep then begin
    euvsc = [euvsc_rec,euvsc] ;add new to front, in reverse-time order
  endif else begin
    ;rotate the elements and overwrite the first (oldest)
    euvsc=shift(euvsc,1)
    euvsc[0] = euvsc_rec
  endelse
endelse

dsec = (euvsc.time.df - euvsc[0].time.df)*86400.

; if the window is not open then bailout
if window_exists(window_id) ne 1 then goto,bailout

wset,window_id

; copy data into image
;for i=0,scale-1 do $
;   img[*, i : n_elements(euvsc)/scale > i : scale] = euvsc.data
;cnt=0L
for i=0,n_elements(euvsc)-1 do begin
   for j=0,scale-1 do begin
;   for j=0,0 do begin
      img[*, i*scale + j] = euvsc[i].data
;      cnt++
   endfor
endfor

device,get_decomp=old_decomp
device,decomp=0
;tvscl, hist_equal(img),60,40
plot,[0,511],[0,n_keep/scale],/nodata,xr=[0,511],xs=1,yr=[0,n_keep/scale - 1],ys=1, xtit='pixel #',background=col_bg,color=col_fg,/noerase
tvscl, hist_equal(img),0,0,/data
device,decomp=old_decomp
plot,[0,511],[0,n_keep/scale],/nodata,xr=[0,511],xs=1,yr=[0,n_keep/scale - 1],ys=1, xtit='pixel #',background=col_bg,color=col_fg,/noerase
;stop

bailout:
return
end
