;+
; NAME:
;   get_next_yyyydoy
;
; PURPOSE:
;   provide mechanism for calculating the next yyyydoy that
;   handles year boundaries and leap years
;
; CATEGORY:
;   Library
;
; CALLING SEQUENCE:
;   nyyyydoy = get_next_yyyydoy(yyyydoy [,ndays])
;
; INPUTS:
;   yyyydoy = current year and day-of-year
;   ndays = default is 1, number of days to go forward
;
; OUTPUTS:
;   nyyyydoy is returned in year day-of-year format
;
; COMMON BLOCKS:
;   none
;
; RESTRICTIONS:
;   yyyydoy is assumed to be good when it is passed!
;
; PROCEDURE:
;   1) Separate year and doy from input parameter
;   2) Make initial guess at nyear and ndoy
;   3) Correct for year boundary including leap years
;   4) Calculate and return nyyyydoy
;
; MODIFICATION HISTORY:
; 01/09/02 Don Woodraska Original File Creation
;
; $Log: get_next_yyyydoy.pro,v $
; Revision 3.0  2011/03/22 15:24:54  dlwoodra
; version_3.0_commit
;
; Revision 2.0  2010/06/23 18:10:51  dlwoodra
; version_2.0_commit
;
; Revision 1.1.1.1  2009/05/28 21:58:01  evesdp
; Imported Sources
;
; Revision 7.0  2004/07/08 23:02:52  turkk
; commit of version 7.0
;
; Revision 6.1  2004/06/15 22:32:25  turkk
; added ndays keyword
;
; Revision 7.1  2004/02/20 17:48:36  dlwoodra
; added ndays keyword
;
; Revision 7.0  2003/03/18 20:33:28  dlwoodra
; commit for version 7.0
;
; Revision 6.0  2002/09/12 15:32:35  dlwoodra
; update to 6.0
;
; Revision 5.1  2002/09/12 15:02:37  dlwoodra
; update from main
;
; Revision 5.20  2002/09/06 23:21:33  see_sw
; commit of version 5.0
;
; Revision 4.0  2002/05/29 18:10:00  see_sw
; Release of version 4.0
;
; Revision 3.0  2002/02/01 18:55:26  see_sw
; version_3.0_commit
;
; Revision 1.1  2002/01/15 23:45:01  dlwoodra
; first commit
;
;
; idver='$Id: get_next_yyyydoy.pro,v 3.0 2011/03/22 15:24:54 dlwoodra Exp $'
;-

function get_next_yyyydoy,yyyydoy_in, ndays ;ndays=ndays

;assumes yyyydoy is valid
;returns next yyyydoy, nyyyydoy
;ndays defaults to 1 (next day)

if size(yyyydoy_in,/type) eq 0 then begin
    ;use current date
    date=bin_date(systime(/utc))
    ymd_to_yd,date[0],date[1],date[2],yyyydoy_in
endif

if size(ndays,/type) eq 0 then n=1L else n=long(ndays)
i=1L
yyyydoy=yyyydoy_in

while i le n do begin
;
;   1) Separate year and doy from input parameter
;
    year=fix(yyyydoy/1000)
    doy=yyyydoy mod year

;
;   2) Make initial guess at nyear and ndoy
;
    ndoy=doy+1
    nyear=year

;
;   3) Correct for year boundary including leap years
;
    if ndoy gt 365 then begin
        if year mod 4 eq 0 then begin
        ;leap year
            if ndoy gt 366 then begin
                nyear=nyear+1
                ndoy=1
            endif else begin
            ; do nothing
            endelse
        endif else begin
        ;not a leap year
            ndoy=1
            nyear=nyear+1
        endelse
    endif

;
;   4) Calculate and return nyyyydoy
;
    yyyydoy=nyear*1000L + ndoy
    i=i+1L
endwhile

return,yyyydoy

end

