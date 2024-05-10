;
;  DLW 10/11/05
;   filename is the fully qualified path of the output file
;     (should end with .png)
;   image is optional
;
pro write_pngfile,filename,image

if n_params() lt 1 then begin
    print,' USAGE: IDL> write_pngfile,filename [,image]'
    print,'  if filename is not present then this message is printed'
    print,'  if image is specified, then it is dumped to the PNG file'
    print,'   otherwise, the screen content is grabbed (b/w swapped) and dumped instead'
    return
endif

device,get_decomposed=orig_decomp

pngfile = filename

if size(image,/type) ne 0 then begin
    ; dump the image array to the png file
    write_png,pngfile,uint(image)
endif else begin
      ;grab the window contents
    device,pseudo=8,decomposed=0
    if !D.N_COLORS GT 256 then begin
        if !ORDER EQ 1 then image=TVRD(TRUE=3,/ORDER) else image=TVRD(TRUE=3)
        pseudoimage=transpose(image,[2,0,1])
    endif else begin
        if !ORDER EQ 1 then pseudoImage=TVRD(/ORDER) else pseudoImage=TVRD()
    endelse
    TVLCT, r, g, b, /GET
    ;swap black and white
    n_c=n_elements(r)-1
    tmp=r[0]  &  r[0]=r[n_c]  &  r[n_c]=tmp
    tmp=g[0]  &  g[0]=g[n_c]  &  g[n_c]=tmp
    tmp=b[0]  &  b[0]=b[n_c]  &  b[n_c]=tmp
    
    write_png, filename, pseudoImage, r, g, b

endelse
print,'Wrote image to ',pngfile

device,decomp=orig_decomp

return
end
