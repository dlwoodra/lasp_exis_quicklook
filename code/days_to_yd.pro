;+
; NAME:
;  days_to_yd
;
; PURPOSE:
;  Convert days-since-epoch into year-day-of-year format.
;
; CATEGORY:
;  Library
;
; CALLING SEQUENCE:
;  yd=days_to_yd(days [,epoch] [,/DAYNUM])
;
; INPUTS:
;  days : scalar or array (long or double) since an epoch
;
; OPTIONAL INPUTS:
;  epoch : year-day-of-year epoch date (default is 2002001)
;
; KEYWORD PARAMETERS:
;  /DAYNUM : set this keyword if days is an array of day numbers. This
;            treats the epoch day as day number 1. (no day 0).
;            If DAYNUM is not set, then the epoch day is day number 0. 
;
;            If DAYNUM was set in a call to yd_to_days, you need to
;            set it here to convert back properly.
;
; OUTPUTS:
;  yd : returns scalar or array of (long or double) dates in
;       year-day-of-year form.
;
; OPTIONAL OUTPUTS:
;  none
;
; COMMON BLOCKS:
;  none
;
; RESTRICTIONS:
;  There can only be ONE epoch (scalar).
;
;  Dates in yyyydoy.fff format are really only good to ~7 decimal
;  places to the right of the decimal with double precision. This
;  leads to a (conservative) time uncertainty estimate of about a
;  millisecond.
;
;  If argument days contains 0 and /DAYNUM is set, then day #0 is
;  treated as if it was day #1. This non-uniqueness results from a
;  conceptual difference in starting point (a lack of a day number
;  0).
;  See yd_to_days.pro for description of the /DAYNUM keyword.
;
; ROUTINES CALLED:
;  YD_TO_YMD  - converts year-day-of-year into year, month, day
;  YMD_TO_YD  - converts year, month, day into year-day-of-year
;  CALDAT, JULDAY - standard part of IDL distribution
;
; PROCEDURE:
;  1) Check parameters
;  2) Make a julian date from the epoch date
;  3) Convert jd into yd with caldat and ymd_to_yd
;  4) Add the days fraction into yd if DAYNUM not set
;  5) Return the yd
;
; EXAMPLES:
;
;  IDL> help,days_to_yd(1L)
;  <Expression>    DOUBLE    =        2002002.0
;
;  IDL> help,days_to_yd(1L,1980006L) ; GPS activation epoch
;  <Expression>    DOUBLE    =        1980007.0
;
;  IDL> help,days_to_yd(0.5d0)
;  <Expression>    DOUBLE    =        2002001.5
;
; if days represents an array of day numbers, then use /DAYNUM
;  IDL> help,days_to_yd(1L,/DAYNUM)
;  <Expression>    LONG      =      2002001
;
; consider using yd_to_days in conjunction with days_to_yd
; (if the user sets DAYNUM in either function, it should be set in the other)
;
;  IDL> help,days_to_yd(yd_to_days(2002002.8d))
;  <Expression>    DOUBLE    =        2002002.8
;  IDL> help,days_to_yd(yd_to_days(2002002,/DAYNUM),/DAYNUM)
;  <Expression>    LONG      =      2002002
;
; MODIFICATION HISTORY:
;  2-25-03 Don Woodraska Original file creation.
;
;-

function days_to_yd, days, epoch, DAYNUM=DAYNUM

;
; 1) Check parameters
;
yd=-1L

if n_params() eq 1 then epoch=2002001L

if n_params() lt 1 or n_params() gt 2 then goto, bailout

if n_elements(epoch) gt 1 then begin
    print,'ERROR: epoch must be a scalar'
    goto, bailout
endif

;
; 2) Make a julian date from the epoch date
;
yd_to_ymd,double(epoch),eyear,emonth,eday,sod=esod
if keyword_set(DAYNUM) then begin
    ; ref_jd needs to be a long
    ref_jd = julday(emonth, eday, eyear)
    jd = ref_jd + long(days)
    x=where(days gt 0,n_x)
    if n_x gt 0 then jd = jd - 1L
endif else begin
    ; ref_jd need to be double
    ref_jd = double(julday(emonth, eday, eyear)) + (esod/86400.d0)
    jd = ref_jd + days - 0.5d0
endelse

;
; 3) Convert jd into yd
;
caldat, jd, month, day, year
ymd_to_yd, year, month, day, yd

;
; 4) Add the days fraction into yd if DAYNUM not set
;
if not keyword_set(DAYNUM) then yd=yd+(days mod 1.d0) ;fracday

;
; 5) Return the yd
;
return,yd

bailout:
print,''
print,' USAGE:'
print,' yd = days_to_yd( 2 )'
print,'      assumes epoch 2002001'
print,' yd = days_to_yd( 2, 1980006 )'
print,'      returns yd'
print,''
return,-1
end
