pro write_data_to_the_file, lun, array, rowformat=rowformat

  ;yd_to_ymd,time_rec.yd, year, month, day
  ;timestamp=string(year, form='(i4.4)') + '-' + $
  ;          string(month,form='(i2.2)') + '-' + $
  ;          string(day,  form='(i2.2)') + 'T' + $
  ;          time_rec.hms+'Z' ; 24 chars
  ;printf,lun,timestamp,array,$
  ;       form='(a'+strtrim(strlen(timestamp),2) + ',' + $
  ;       strtrim(n_elements(array),2)+'(x,e14.7))'

  if size(rowformat,/type) ne 0 then format=rowformat else format='e14.7'
  n_arr = n_elements(array)
  if n_arr eq 1 then form='('+format+')' else $
     form='('+format+','+strtrim(n_arr-1,2)+'(x,'+format+'))'
  printf, lun, array, form=form

return
end


pro open_and_write_header, file, lun, array, header=header, rowformat=rowformat, numrows=numrows

  ; open the file and et a lun
  openw,lun,file,/get
  printf,lun,';Created: '+systime()
  printf,lun,';Author: Don Woodraska'
  printf,lun,';Identifier: '+(strsplit(file_basename(file),'.',/extract))[0]
  printf,lun,';NumberOfDataColumns: '+strtrim(n_elements(array),2)
  if size(numrows,/type) ne 0 then printf,lun,';NumberOfRows: '+strtrim(numrows,2)
  if size(header,/type) ne 0 then $
     for i=0,n_elements(header)-1 do printf, lun, ';Comment- '+header[i]
  printf,lun,';record={data:dblarr('+strtrim(n_elements(array),2)+')}'
  if size(rowformat,/type) ne 0 then format=rowformat else format='e14.7'
  n_arr = n_elements(array)
  if n_arr eq 1 then fullformat='('+format+')' else $
     fullformat='('+format+','+strtrim(n_arr-1,2)+'(x,'+format+'))'
  printf,lun,';format='+fullformat
  ;printf,lun,';format=('+strtrim(n_elements(array),2)+'(x,'+format+'))'
  printf,lun,';end_of_header'
return
end


pro write_to_generic_output_file, file, array, filename=filename, comment=comment, header=header, rowformat=rowformat

  ; rowformat is e14.7 by default, override with a string for one
  ; number, all numbers are the same format

  ; array is of form [n_rows, n_columns] (or [n_rows])
  ; reader converts to structure[n_rows].data[n_columns] (or structure[n_rows].data)

  if size(comment,/type) ne 0 then header=comment ; use comment to override header for compatibility with write_dat
  if size(array,/type) eq 0 and size(filename,/type) ne 0 then begin
     ; write_dat compatibility
     array = transpose(file) ; 1st arg is data
     file  = filename
  endif

  ; determine dimensions
  sz = size(array)
  n_dims = sz[0]
  dims = sz[1:n_dims] ; array of dimensions

  ; always write one record at a time
  if n_dims eq 1 then begin
      ; 1-d array (one number per row)
     for i=0L,n_elements(array)-1 do begin
        if i eq 0 then open_and_write_header, file, lun, array[i], header=header, rowformat=rowformat, numrows=n_elements(array)

     ; now write the actual data array
        write_data_to_the_file, lun, array[i], rowformat=rowformat
     endfor
  endif else begin
     if n_dims eq 2 then begin
        ; 2-d array
        for i=0L,n_elements(array[*,0])-1 do begin

           arr = reform(array[i,*])     ; first row

           if i eq 0 then open_and_write_header, file, lun, arr, header=header, rowformat=rowformat, numrows=n_elements(array[*,0])

           ; now write the actual data array
           write_data_to_the_file, lun, arr, rowformat=rowformat
        endfor
     endif else begin
        ; 3+ dimensions
        print,'ERROR: input array has too many dimensions to be represented in a 2d-table'
        help,array
        stop
     endelse
  endelse


  close,lun
  free_lun,lun

return
end
