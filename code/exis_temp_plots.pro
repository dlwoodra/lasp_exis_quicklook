; docformat = 'rst'

;+
; This file contains all of the functions/procedures to produce up to the minute
; temperature plots of any/all of the EXIS instruments.
;
; Differences/changes from plot_temperatures.pro:
; *  This routine displays the last temperature/rate value in the legend.
; *  This routine uses JD to plot the time axis to avoid crashes at day boundaries.
; *  This routine does not take any inputs like plot_temperatues, meaning it
;    cannot plot a specified hour or year/day.
; *  This routine plots just symbols, without connecting lines, to avoid the
;    random line jumps as instuments are turned on/off.
; *  This routine runs with one, none, or any of the instruments powered on.
; *  Maximum y-range limits of +/- 0.2 are hard coded for the rate plots to avoid
;    large y-scales when instruments are first powered on.  When rates are in the
;    range of +/- 0.2, the y-range limits are scaled to the range of the data.
; *  The color scheme is a little different for the various instruments.
;
; :Author:
;    Randy Meisner
;
; :Copyright:
;    Copyright 2014 The Regents of the University of Colorado.
;    All rights reserved.  this software was developed at the
;    University of Colorado's Laboratory for Atmospheric and
;    Space Physics.
;
; :Version:
;    $Id: exis_temp_plots.pro 27163 2014-03-31 14:43 meisner $
;
;-

;+
; Calculate the rate of change
;
; :Params:
;    array : in, required, type="float array"
;            An array of values used to calculate the rate of change
;    smoothvalue : in, required, type=integer
;            The number of samples to smooth, also used to multiply
;            to obtain the proper rate units (denominator). For 1 Hz
;            temperature samples in degrees, use a value of 60 to get
;            units of degrees/minute.
;-
FUNCTION exis_rate_of_change, array, smoothvalue

IF(n_elements(array) LT smoothvalue+2) THEN BEGIN
   print, 'Warning: Not enough values to calculate rate of change'
   return, array*0
ENDIF

data = deriv(reform(array)) ; 3-point derivative

; replace last value
data[n_elements(data)-1] = data[n_elements(data)-2]
; replace first value 8/18/16 DLW
data[0] = data[1]

data = (smooth(data, smoothvalue, /edge_trunc)*float(smoothvalue))

; replace last n values (minute)
;data[n_elements(data)-smoothvalue:n_elements(data)-1] = $
;   data[n_elements(data)-smoothvalue]
; replace only last 10 seconds or at least the last 20 values 9/21/16 DLW
;data[n_elements(data)-((smoothvalue/6)>20):n_elements(data)-1] = $
;   data[n_elements(data)-smoothvalue]

; 20160926 Randy Meisner
; Replace the last half of the filter width values with the value at
; (filter width)/2, or at least the last 20 values

data[n_elements(data)-((smoothvalue/2)>20):n_elements(data)-1] = $
   data[n_elements(data)-(smoothvalue/2)]

; replace oldest data 8/18/16 DLW
data[0:1] = data[2]

RETURN, data

END

;+
; Calculate the Julian date of the EXIS data.
;
; :Params:
;    data : in, required, type="structure"
;           The data structure array returned when reading in EXIS data
;           using one of the read_goes_*.pro functions.
;
; :Uses:
;    yd_to_jd.pro
;-
FUNCTION exis_jd, data

secperday = 86400.0d0

IF(size(data, /type) NE 8) THEN return, -1

rtn = yd_to_jd(data.time_yd) + data.time_sod/secperday

RETURN, rtn

END

;+
; Use read_goes_l0b_file.pro to read in the files provided in the input.
;
; :Params:
;    fnames : in, required, type="string"
;       Uses read_goes_l0b_file.pro to read EXIS data in from the input file
;       names.  If none of the files input are found, a value of -1 is returned.
;
; :Uses:
;    read_goes_l0b_file.pro
;-
FUNCTION read_exis_data, fnames

rtn = -1

; the first file name in the list should be the current hour of data, read it first

IF(file_test(fnames[0])) THEN BEGIN
   IF(file_lines(fnames[0]) GT 10) THEN BEGIN
      
      fdata = read_goes_l0b_file(fnames[0], status)
      IF(status NE -1) THEN rtn = fdata
      
   ENDIF
ENDIF

; read in previous hours of data, if they exist

FOR i = 1, n_elements(fnames)-1 DO BEGIN
   
   f = file_search(getenv('exis_data_l0b'), fnames[i], count = count)
   
   IF(count GT 0) THEN BEGIN
      FOR j = 0, count-1 DO BEGIN 
         fdata = -1
         fdata = read_goes_l0b_file(f[j])
         IF(size(fdata, /type) EQ 8) THEN BEGIN
            IF(size(rtn, /type) EQ 8) THEN rtn = [rtn, fdata] ELSE rtn = fdata
         ENDIF
      ENDFOR
   ENDIF
   
ENDFOR

RETURN, rtn

END

;+
; Determine the current hour's file name, and the previous 2 hours file names.
;
; :Params:
;    inst : in, required, type="string"
;           The EXIS instrument for which to create file names (xrs,
;           euvsa/b/c, sps).
;
; :Keywords:
;    yd : in, optional, type=double
;      allows the user to specify a different date/time to display
;      format is yyyyddd.fff. Need to include hours as a day fraction (fff).
;-
FUNCTION exis_recent_filenames, inst, yd=yd

fnames = -1

jdhr = dblarr(4)
ymd = strarr(4)
hr = strarr(4)

hrday = 1.0d0/24.0d0            ; 1 hr fraction of a day

; current time
if size(yd,/type) eq 0 then jd = systime(/jul, /utc) else jd=yd_to_jd(yd)
caldat, jd, month, day, year, hour, minute, second

; current hour of day
jdhr[0] = julday(month, day, year, hour, 0.0, 0.0)

; previous 2 hours from current hour of day
jdhr[1] = jdhr[0] - hrday
jdhr[2] = jdhr[0] - (2*hrday)

; get ymd for current and previous 3 hours
ymd[0] = strcompress(long(jd_to_yd(jdhr[0])), /remove_all)
ymd[1] = strcompress(long(jd_to_yd(jdhr[1])), /remove_all)
ymd[2] = strcompress(long(jd_to_yd(jdhr[2])), /remove_all)

; get hour of current and previous 3 hours
caldat, jdhr[0], month, day, yr, hour, minute, second
IF(hour LT 10) THEN hr[0] = '0' + strcompress(hour, /remove_all) ELSE $
   hr[0] = strcompress(hour, /remove_all)

caldat, jdhr[1], month, day, yr, hour, minute, second
IF(hour LT 10) THEN hr[1] = '0' + strcompress(hour, /remove_all) ELSE $
   hr[1] = strcompress(hour, /remove_all)

caldat, jdhr[2], month, day, yr, hour, minute, second
IF(hour LT 10) THEN hr[2] = '0' + strcompress(hour, /remove_all) ELSE $
   hr[2] = strcompress(hour, /remove_all)


; form EXIS file names of current and previous 2 hours
FOR i = 0, n_elements(inst)-1 DO BEGIN
   
   FOR j = 0, 2 DO BEGIN
      fname = inst[i] + '_' + ymd[j] + '_' + hr[j] + '_*.txt'
      IF(size(fnames, /type) EQ 7) THEN fnames = [fnames, fname] ELSE fnames = fname
   ENDFOR
   
ENDFOR

RETURN, fnames

END


;+
; Exis_temp_plots generates 4 plots, in one window, of zones 1 & 2 thermistor
; temperatures (degrees) and their rate of change (degrees/minute).
;
; :Keywords:
;    yd : in, optional, type=double
;      allows the user to specify a different date/time to display
;      format is yyyyddd.fff. Need to include hours as a day fraction (fff).
;
; :Uses:
;    exis_convert_temp_dn_to_degrees.pro
;
; :Examples:
;    ::
;    IDL> exis_temp_plots
;    IDL> exis_temp_plots, yd=2016093.d0 + 6./24. ; 6 UT on day 93
;    from 2016
;
;-
PRO exis_temp_plots, help=help, yd=yd

window, 2, xsize = 1000, ysize = 800
!p.multi = [0, 2, 2]

ps = 2                          ; plot symbol
ss = 0.15                       ; symsize to use

inst = ['xrs', 'euvsa', 'euvsb', 'euvsc', 'sps']
ninst = n_elements(inst)

WHILE(1) DO BEGIN
   
                                ; get file names of recent hours
   xrs_fnames = exis_recent_filenames('xrs', yd=yd)
   euvsa_fnames = exis_recent_filenames('euvsa',yd=yd)
   euvsb_fnames = exis_recent_filenames('euvsb',yd=yd)
   euvsc_fnames = exis_recent_filenames('euvsc',yd=yd)
   sps_fnames = exis_recent_filenames('sps',yd=yd)
   
                                ; prepend latest hour file name to each
   xrs_fnames = [getenv('exis_data_quicklook') + '/latest_xrs_hour.txt', xrs_fnames]
   euvsa_fnames = [getenv('exis_data_quicklook') + '/latest_euvsa_hour.txt', euvsa_fnames]
   euvsb_fnames = [getenv('exis_data_quicklook') + '/latest_euvsb_hour.txt', euvsb_fnames]
   euvsc_fnames = [getenv('exis_data_quicklook') + '/latest_euvsc_hour.txt', euvsc_fnames]
   sps_fnames = [getenv('exis_data_quicklook') + '/latest_sps_hour.txt', sps_fnames]
   
                                ; read data for each instrument
   xrs_data = read_exis_data(xrs_fnames)
   euvsa_data = read_exis_data(euvsa_fnames)
   euvsb_data = read_exis_data(euvsb_fnames)
   euvsc_data = read_exis_data(euvsc_fnames)
   sps_data = read_exis_data(sps_fnames)
   
                                ; get JD for each dataset
   xrs_jd = -1   & plot_xrs = 0
   euvsa_jd = -1 & plot_euvsa = 0
   euvsb_jd = -1 & plot_euvsb = 0
   euvsc_jd = -1 & plot_euvsc = 0
   sps_jd = -1   & plot_sps = 0
   
   IF(size(xrs_data, /type) EQ 8 and n_elements(xrs_data) gt 60) THEN BEGIN
      plot_xrs = 1
      xrs_jd = exis_jd(xrs_data)
   ENDIF

   IF(size(euvsa_data, /type) EQ 8 and n_elements(euvsa_data) gt 60) THEN BEGIN
      plot_euvsa = 1
      euvsa_jd = exis_jd(euvsa_data)
   ENDIF
   
   IF(size(euvsb_data, /type) EQ 8 and n_elements(euvsb_data) gt 60) THEN BEGIN
      plot_euvsb = 1
      euvsb_jd = exis_jd(euvsb_data)
   ENDIF
   
   IF(size(euvsc_data, /type) EQ 8 and n_elements(euvsc_data) gt 60) THEN BEGIN
      plot_euvsc = 1
      euvsc_jd = exis_jd(euvsc_data)
   ENDIF
   
   IF(size(sps_data, /type) EQ 8 and n_elements(sps_data) gt 60) THEN BEGIN
      plot_sps = 1
      sps_jd = exis_jd(sps_data)
   ENDIF
   
                                ; sort the data and time according to JD
                                ; extract values to plot
                                ; compute rates of change
   IF(plot_xrs) THEN BEGIN
      
      xrs_jd = exis_jd(xrs_data)
      
      xrs_sort = sort(xrs_jd)
      xrs_data = xrs_data(xrs_sort)
      
      xrs_jd = xrs_jd(xrs_sort)
      xrs_asic1 = exis_convert_temp_dn_to_degrees(xrs_data.asic1temp_dn)
      xrs_asic2 = exis_convert_temp_dn_to_degrees(xrs_data.asic2temp_dn)
      xrs_casehtr = exis_convert_temp_dn_to_degrees(xrs_data.casehtrtemp_dn)
      
      xrs_dasic1 = exis_rate_of_change(xrs_asic1, 60)
      xrs_dasic2 = exis_rate_of_change(xrs_asic2, 60)
      xrs_dcasehtr = exis_rate_of_change(xrs_casehtr, 60)
      
   ENDIF
   
   IF(plot_euvsa) THEN BEGIN
      
      euvsa_jd = exis_jd(euvsa_data)
      
      euvsa_sort = sort(euvsa_jd)
      euvsa_data = euvsa_data[euvsa_sort]
      
      euvsa_jd = euvsa_jd[euvsa_sort]
      euvsa_temps = exis_convert_temp_dn_to_degrees(euvsa_data.atemp_dn)
      euvsa_dtemps = exis_rate_of_change(euvsa_temps, 60)
      
   ENDIF
   
   IF(plot_euvsb) THEN BEGIN
      
      euvsb_jd = exis_jd(euvsb_data)
      
      euvsb_sort = sort(euvsb_jd)
      euvsb_data = euvsb_data[euvsb_sort]
      
      euvsb_jd = euvsb_jd[euvsb_sort]
      euvsb_temps = exis_convert_temp_dn_to_degrees(euvsb_data.atemp_dn)
      euvsb_dtemps = exis_rate_of_change(euvsb_temps, 60)
      
   ENDIF
   
   IF(plot_sps) THEN BEGIN
      
      sps_jd = exis_jd(sps_data)
      
      sps_sort = sort(sps_jd)
      sps_data = sps_data[sps_sort]
      
      sps_jd = sps_jd[sps_sort]
      sps_temps = exis_convert_temp_dn_to_degrees(sps_data.spstemp_dn)
      sps_dtemps = exis_rate_of_change(sps_temps, 240)
      
   ENDIF
   
   
   IF(plot_euvsc) THEN BEGIN
      
      euvsc_jd = exis_jd(euvsc_data)
      
      euvsc_sort = sort(euvsc_jd)
      euvsc_data = euvsc_data[euvsc_sort]
      
      euvsc_jd = euvsc_jd[euvsc_sort]
      euvsc_casehtr = exis_convert_temp_dn_to_degrees(euvsc_data.euvschtrtemp_dn)
      euvsc_dcasehtr = exis_rate_of_change(euvsc_casehtr, 12)
      
      euvsc1_temps = exis_convert_temp_dn_to_degrees(euvsc_data.c1temp_dn)
      euvsc2_temps = exis_convert_temp_dn_to_degrees(euvsc_data.c2temp_dn)
      
      euvsc1_dtemps = exis_rate_of_change(euvsc1_temps, 12)
      euvsc2_dtemps = exis_rate_of_change(euvsc2_temps, 12)
      
   ENDIF
   
                                ; PLOT THE DATA, IF AVAILABLE
   
                                ; setup colors
   
   colors = [15570276, $        ; cornflower blue
             13688896, $        ; turquoise
             14524637, $        ; plum
             65280, $           ; green
             65535, $           ; yellow
             255]               ; red
   
   
   hr = 1.0d0/24.0d0

   if size(yd,/type) eq 0 then sysjd=systime(/jul) else sysjd=yd_to_jd(yd)
   xlabel = 'Hours in ' + strcompress(long(jd_to_yd(sysjd)))
   ;xrng = [systime(/jul)-(2*hr), systime(/jul)]
   xrng = [sysjd-(2*hr), sysjd]
   ld = label_date(date_format = '%H:%I')   
   
                                ; Zone 1 plots
   label = 'Zone 1'
   ylabel = 'Degrees C'
   
   IF(plot_xrs OR plot_euvsa OR plot_euvsb OR plot_sps) THEN BEGIN
      
                                ; Temperatures
      
      ymin = 1000.0 & ymax = -1000.0


      ; only use the last 100 values for finding limits
      IF(plot_xrs) THEN BEGIN
         oldlim = ( n_elements(xrs_asic1) - 100L ) > 0L
         ymin = min([ymin, min(xrs_asic1[oldlim:*]), min(xrs_asic2[oldlim:*]), min(xrs_casehtr[oldlim:*])])
         ymax = max([ymax, max(xrs_asic1[oldlim:*]), max(xrs_asic2[oldlim:*]), max(xrs_casehtr[oldlim:*])])
      ENDIF
      
      IF(plot_euvsa) THEN BEGIN
         oldlim = ( n_elements(euvsa_temps) - 100L ) > 0L
         ymin = min([ymin, min(euvsa_temps[oldlim:*])])
         ymax = max([ymax, max(euvsa_temps[oldlim:*])])
      ENDIF
      
      IF(plot_euvsb) THEN BEGIN
         oldlim = ( n_elements(euvsb_temps) - 100L ) > 0L
         ymin = min([ymin, min(euvsb_temps[oldlim:*])])
         ymax = max([ymax, max(euvsb_temps[oldlim:*])])
      ENDIF
      
      IF(plot_sps) THEN BEGIN
         oldlim = ( n_elements(sps_temps) - 400L ) > 0L
         ymin = min([ymin, min(sps_temps[oldlim:*])])
         ymax = max([ymax, max(sps_temps[oldlim:*])])
      ENDIF
      
      plot, [0, 1], [ymin, ymax], /nodata, xrange = xrng, yrange = [ymin, ymax], $
         xtickformat = 'label_date', xtickunits = 'time', title = label, $
         xtitle = xlabel, ytitle = ylabel
      
      xratio = (!x.crange[1]-!x.crange[0])/40.
      yratio = (!y.crange[1]-!y.crange[0])/40.
      
      oplot,!x.crange[0]*[1,1],[-30.,-273.],co='fe'x,thick=4 ; red low for XRS (Limit)
      oplot,!x.crange[0]*[1,1],[36.,1000], co='fe'x,thick=4 ; red high for XRS (Limit)
      oplot,!x.crange[0]*[1,1],[-5.,-30],co='eeee'x,thick=4 ; yellow low for XRS (Limit)
      oplot,!x.crange[0]*[1,1],[25.,36], co='eeee'x,thick=4 ; yellow high for XRS (Limit)
      
      IF(plot_xrs) THEN BEGIN
         step=1
         if n_elements(xrs_jd) gt 100 then step=10
         oplot, xrs_jd[0:*:step], xrs_asic1[0:*:step], psym = ps, symsize = ss
         oplot, xrs_jd[0:*:step], xrs_asic2[0:*:step], color = colors[0], psym = ps, symsize = ss
         oplot, xrs_jd[0:*:step], xrs_casehtr[0:*:step], color = colors[1], psym = ps, symsize = ss
         xyouts, !x.crange[0]+1*xratio, !y.crange[1]-2*yratio, $
            'XRSasic1 '+strcompress(xrs_asic1[n_elements(xrs_asic1)-1]), $
            /data, charsize = 1.1
         xyouts, !x.crange[0]+15*xratio, !y.crange[1]-2*yratio, $
            'XRSasic2 '+strcompress(xrs_asic2[n_elements(xrs_asic2)-2]), $
            /data, charsize = 1.1, color = colors[0]
         xyouts, !x.crange[0]+30*xratio, !y.crange[1]-2*yratio, $
            'CaseHtr '+strcompress(xrs_casehtr[n_elements(xrs_casehtr)-1]), $
            /data, charsize = 1.1, color = colors[1]
      ENDIF ELSE BEGIN
         xyouts, !x.crange[0]+1*xratio, !y.crange[1]-2*yratio, 'XRSasic1 NO DATA', $
            /data, charsize = 1.1
         xyouts, !x.crange[0]+15*xratio, !y.crange[1]-2*yratio, 'XRSasic2 NO DATA', $
            /data, charsize = 1.1, color = colors[0]
         xyouts, !x.crange[0]+30*xratio, !y.crange[1]-2*yratio, 'CaseHtr NO DATA', $
            /data, charsize = 1.1, color = colors[1]
      ENDELSE
      
      IF(plot_euvsa) THEN BEGIN
         step=1
         if n_elements(euvsa_jd) gt 100 then step=10
         oplot, euvsa_jd[0:*:step], euvsa_temps[0:*:step], color = colors[2], psym = ps, symsize = ss*4
         xyouts, !x.crange[0]+1*xratio, !y.crange[1]-4*yratio, $
            'EUVSA '+strcompress(euvsa_temps[n_elements(euvsa_temps)-1]), $
            /data, charsize = 1.1, color = colors[2]
      ENDIF ELSE BEGIN
         xyouts, !x.crange[0]+1*xratio, !y.crange[1]-4*yratio, 'EUVSA NO DATA', $
            /data, charsize = 1.1, color = colors[2]
      ENDELSE
      
      IF(plot_euvsb) THEN BEGIN
         step=1
         if n_elements(euvsb_jd) gt 100 then step=10
         oplot, euvsb_jd[0:*:step], euvsb_temps[0:*:step], color = colors[3], psym = ps, symsize = ss
         xyouts, !x.crange[0]+15*xratio, !y.crange[1]-4*yratio, $
            'EUVSB '+strcompress(euvsb_temps[n_elements(euvsb_temps)-1]), $
            /data, charsize = 1.1, color = colors[3]
      ENDIF ELSE BEGIN
         xyouts, !x.crange[0]+15*xratio, !y.crange[1]-4*yratio, 'EUVSB NO DATA', $
            /data, charsize = 1.1, color = colors[3]
      ENDELSE
      
      IF(plot_sps) THEN BEGIN
         step=1
         if n_elements(sps_jd) gt 100 then step=40
         oplot, sps_jd[0:*:step], sps_temps[0:*:step], color = colors[4], psym = ps, symsize = ss
         xyouts, !x.crange[0]+30*xratio, !y.crange[1]-4*yratio, $
            'SPS '+strcompress(sps_temps[n_elements(sps_temps)-1]), $
            /data, charsize = 1.1, color = colors[4]
      ENDIF ELSE BEGIN
         xyouts, !x.crange[0]+30*xratio, !y.crange[1]-4*yratio, 'SPS NO DATA', $
            /data, charsize = 1.1, color = colors[4]
      ENDELSE
      
                                ; Rates
      ylabel = 'Degrees/Minute'
      ymin = 1000.0 & ymax = -1000.0
      
      IF(plot_xrs) THEN BEGIN
         oldlim = ( n_elements(xrs_dasic1) - 100L ) > 0L
         ymin = min([ymin, min(xrs_dasic1[oldlim:*]), min(xrs_dasic2[oldlim:*]), min(xrs_dcasehtr[oldlim:*])])
         ymax = max([ymax, max(xrs_dasic1[oldlim:*]), max(xrs_dasic2[oldlim:*]), max(xrs_dcasehtr[oldlim:*])])
      ENDIF
      
      IF(plot_euvsa) THEN BEGIN
         oldlim = ( n_elements(euvsa_dtemps) - 100L ) > 0L
         ymin = min([ymin, min(euvsa_dtemps[oldlim:*])])
         ymax = max([ymax, max(euvsa_dtemps[oldlim:*])])
      ENDIF
      
      IF(plot_euvsb) THEN BEGIN
         oldlim = ( n_elements(euvsb_dtemps) - 100L ) > 0L
         ymin = min([ymin, min(euvsb_dtemps[oldlim:*])])
         ymax = max([ymax, max(euvsb_dtemps[oldlim:*])])
      ENDIF
      
      IF(plot_sps) THEN BEGIN
         oldlim = ( n_elements(sps_dtemps) - 400L ) > 0L
         ymin = min([ymin, min(sps_dtemps[oldlim:*])])
         ymax = max([ymax, max(sps_dtemps[oldlim:*])])
      ENDIF

      print,'ymin/max=',ymin,ymax
      
      IF(ymin LT -0.2) THEN ymin = -0.2
      IF(ymax GT 0.2) THEN ymax = 0.2
      
      ymin = ymin < (-0.02)
      ymax = ymax > (0.02)

      plot, [0, 1], [ymin, ymax], /nodata, xrange = xrng, yrange = [ymin, ymax], $
         xtickformat = 'label_date', xtickunits = 'time', title = label, $
         xtitle = xlabel, ytitle = ylabel
      
      oplot, !x.crange, [0.01, 0.01], linestyle = 1, color = colors[3]
      oplot, !x.crange, [0, 0], linestyle = 1
      oplot, !x.crange, [-0.01, -0.01], linestyle = 1, color = colors[3]
      
      xratio = (!x.crange[1]-!x.crange[0])/40.
      yratio = (!y.crange[1]-!y.crange[0])/40.
      
      IF(plot_xrs) THEN BEGIN
         step=1
         if n_elements(xrs_jd) gt 100 then step=10
         oplot, xrs_jd[0:*:step], xrs_dasic1[0:*:step], psym = ps, symsize = ss
         oplot, xrs_jd[0:*:step], xrs_dasic2[0:*:step], color = colors[0], psym = ps, symsize = ss
         oplot, xrs_jd[0:*:step], xrs_dcasehtr[0:*:step], color = colors[1], psym = ps, symsize = ss
         xyouts, !x.crange[0]+1*xratio, !y.crange[1]-2*yratio, $
            'XRSasic1 '+strcompress(xrs_dasic1[n_elements(xrs_dasic1)-1]), $
            /data, charsize = 1.1
         xyouts, !x.crange[0]+15*xratio, !y.crange[1]-2*yratio, $
            'XRSasic2 '+strcompress(xrs_dasic2[n_elements(xrs_dasic2)-2]), $
            /data, charsize = 1.1, color = colors[0]
         xyouts, !x.crange[0]+30*xratio, !y.crange[1]-2*yratio, $
            'CaseHtr '+strcompress(xrs_dcasehtr[n_elements(xrs_dcasehtr)-1]), $
            /data, charsize = 1.1, color = colors[1]
         
         val = xrs_dasic1[n_elements(xrs_dasic1)-1]
         IF(abs(val) LE 0.01) THEN print, 'XRS ASIC 1 is stable: ', val ELSE $
            print, 'XRS ASIC 1 is NOT stable: ', val
         
         val = xrs_dasic2[n_elements(xrs_dasic2)-2]
         IF(abs(val) LE 0.01) THEN print, 'XRS ASIC 2 is stable: ', val ELSE $
            print, 'XRS ASIC 2 is NOT stable: ', val
         
         val = xrs_dcasehtr[n_elements(xrs_dcasehtr)-1]
         IF(abs(val) LE 0.01) THEN print, 'XRS HTR is stable: ', val ELSE $
            print, 'XRS HTR is NOT stable: ', val
         
      ENDIF ELSE BEGIN
         xyouts, !x.crange[0]+1*xratio, !y.crange[1]-2*yratio, 'XRSasic1 NO DATA', $
            /data, charsize = 1.1
         xyouts, !x.crange[0]+15*xratio, !y.crange[1]-2*yratio, 'XRSasic2 NO DATA', $
            /data, charsize = 1.1, color = colors[0]
         xyouts, !x.crange[0]+30*xratio, !y.crange[1]-2*yratio, 'CaseHtr NO DATA', $
            /data, charsize = 1.1, color = colors[1]
      ENDELSE
      
      IF(plot_euvsa) THEN BEGIN
         step=1
         if n_elements(euvsa_jd) gt 100 then step=10
         oplot, euvsa_jd[0:*:step], euvsa_dtemps[0:*:step], color = colors[2], psym = ps, symsize = ss*4
         xyouts, !x.crange[0]+1*xratio, !y.crange[1]-4*yratio, $
            'EUVSA '+strcompress(euvsa_dtemps[n_elements(euvsa_dtemps)-1]), $
            /data, charsize = 1.1, color = colors[2]
         
         val = euvsa_dtemps[n_elements(euvsa_dtemps)-1]
         IF(abs(val) LE 0.01) THEN print, 'EUVS-A is stable: ', val ELSE $
            print, 'EUVS-A is NOT stable: ', val
         
      ENDIF ELSE BEGIN
         xyouts, !x.crange[0]+1*xratio, !y.crange[1]-4*yratio, 'EUVSA NO DATA', $
            /data, charsize = 1.1, color = colors[2]
      ENDELSE
      
      IF(plot_euvsb) THEN BEGIN
         step=1
         if n_elements(euvsb_jd) gt 100 then step=10
         oplot, euvsb_jd[0:*:step], euvsb_dtemps[0:*:step], color = colors[3], psym = ps, symsize = ss
         xyouts, !x.crange[0]+15*xratio, !y.crange[1]-4*yratio, $
            'EUVSB '+strcompress(euvsb_dtemps[n_elements(euvsb_dtemps)-1]), $
            /data, charsize = 1.1, color = colors[3]
         
         val = euvsb_dtemps[n_elements(euvsb_dtemps)-1]
         IF(abs(val) LE 0.01) THEN print, 'EUVS-B is stable: ', val ELSE $
            print, 'EUVS-B is NOT stable: ', val
         
      ENDIF ELSE BEGIN
         xyouts, !x.crange[0]+15*xratio, !y.crange[1]-4*yratio, 'EUVSB NO DATA', $
            /data, charsize = 1.1, color = colors[3]
      ENDELSE
      
      IF(plot_sps) THEN BEGIN
         step=1
         if n_elements(sps_jd) gt 100 then step=40
         oplot, sps_jd[0:*:step], sps_dtemps[0:*:step], color = colors[4], psym = ps, symsize = ss
         xyouts, !x.crange[0]+30*xratio, !y.crange[1]-4*yratio, $
            'SPS '+strcompress(sps_dtemps[n_elements(sps_dtemps)-1]), $
            /data, charsize = 1.1, color = colors[4]
         
         val = sps_dtemps[n_elements(sps_dtemps)-1]
         IF(abs(val) LE 0.01) THEN print, 'SPS is stable: ', val ELSE $
            print, 'SPS is NOT stable: ', val
         
      ENDIF ELSE BEGIN
         xyouts, !x.crange[0]+30*xratio, !y.crange[1]-4*yratio, 'SPS NO DATA', $
            /data, charsize = 1.1, color = colors[4]
      ENDELSE
      
   ENDIF ELSE BEGIN
                                ; Temperatures
      
      plot, [0, 1], [10, 20], /nodata, xrange = xrng, yrange = [20, 25], $
         xtickformat = 'label_date', xtickunits = 'time', title = label, $
         xtitle = xlabel, ytitle = ylabel
      
      xratio = (!x.crange[1]-!x.crange[0])/40.
      yratio = (!y.crange[1]-!y.crange[0])/40.
      
      xyouts, !x.crange[0]+1*xratio, !y.crange[1]-2*yratio, 'XRSasic1 NO DATA', $
         /data, charsize = 1.1
      xyouts, !x.crange[0]+15*xratio, !y.crange[1]-2*yratio, 'XRSasic2 NO DATA', $
         /data, charsize = 1.1, color = colors[0]
      xyouts, !x.crange[0]+30*xratio, !y.crange[1]-2*yratio, 'CaseHtr NO DATA', $
         /data, charsize = 1.1, color = colors[1]
      
      xyouts, !x.crange[0]+1*xratio, !y.crange[1]-4*yratio, 'EUVSA NO DATA', $
         /data, charsize = 1.1, color = colors[2]
      xyouts, !x.crange[0]+15*xratio, !y.crange[1]-4*yratio, 'EUVSB NO DATA', $
         /data, charsize = 1.1, color = colors[3]
      xyouts, !x.crange[0]+30*xratio, !y.crange[1]-4*yratio, 'SPS NO DATA', $
         /data, charsize = 1.1, color = colors[4]
      
                                ; Rates
      ylabel = 'Degrees/Minute'
      
      plot, [0, 1], [-0.1, 0.1], /nodata, xrange = xrng, yrange = [-0.1, 0.1], $
         xtickformat = 'label_date', xtickunits = 'time', title = label, $
         xtitle = xlabel, ytitle = ylabel
      
      xratio = (!x.crange[1]-!x.crange[0])/40.
      yratio = (!y.crange[1]-!y.crange[0])/40.
      
      oplot, !x.crange, [0.01, 0.01], linestyle = 1, color = colors[3]
      oplot, !x.crange, [0, 0], linestyle = 1
      oplot, !x.crange, [-0.01, -0.01], linestyle = 1, color = colors[3]
      
      xyouts, !x.crange[0]+1*xratio, !y.crange[1]-2*yratio, 'XRSasic1 NO DATA', $
         /data, charsize = 1.1
      xyouts, !x.crange[0]+15*xratio, !y.crange[1]-2*yratio, 'XRSasic2 NO DATA', $
         /data, charsize = 1.1, color = colors[0]
      xyouts, !x.crange[0]+30*xratio, !y.crange[1]-2*yratio, 'CaseHtr NO DATA', $
         /data, charsize = 1.1, color = colors[1]
      xyouts, !x.crange[0]+1*xratio, !y.crange[1]-4*yratio, 'EUVSA NO DATA', $
         /data, charsize = 1.1, color = colors[2]
      xyouts, !x.crange[0]+15*xratio, !y.crange[1]-4*yratio, 'EUVSB NO DATA', $
         /data, charsize = 1.1, color = colors[3]
      xyouts, !x.crange[0]+30*xratio, !y.crange[1]-4*yratio, 'SPS NO DATA', $
         /data, charsize = 1.1, color = colors[4]
      
      
      
   ENDELSE
   
                                ; Zone 2 plots
   label = 'Zone 2'
   ylabel = 'Degrees'
   
   IF(plot_euvsc) THEN BEGIN
                                ; Temperatures
      ymin = 1000.0 & ymax = -1000.0
      
      oldlim = ( n_elements(euvsc1_temps) - 100L ) > 0L
      ymin = min([ymin, min(euvsc_casehtr[oldlim:*]), min(euvsc1_temps[oldlim:*]), min(euvsc2_temps[oldlim:*])])
      ymax = max([ymax, max(euvsc_casehtr[oldlim:*]), max(euvsc1_temps[oldlim:*]), max(euvsc2_temps[oldlim:*])])
      
      plot, xrng, [ymin, ymax], /nodata, xrange = xrng, yrange = [ymin, ymax], $
         xtickformat = 'label_date', xtickunits = 'time', title = label, $
         xtitle = xlabel, ytitle = ylabel
      
      oplot,!x.crange[0]*[1,1],[-25.,-273],co='fe'x,thick=4 ; red  low for C (Test Limit)
      oplot,!x.crange[0]*[1,1],[ 35.,1000],co='fe'x,thick=4 ; red high for C (Test Limit)
      oplot,!x.crange[0]*[1,1],[-15., -25],co='eeee'x,thick=4 ; yellow  low for C (Test Limit)
      oplot,!x.crange[0]*[1,1],[  8.,  35],co='eeee'x,thick=4 ; yellow high for C (Test Limit)
      
      xratio = (!x.crange[1]-!x.crange[0])/40.
      yratio = (!y.crange[1]-!y.crange[0])/40.
      
      step=1
      if n_elements(euvsc_jd) gt 100 then step=2
      oplot, euvsc_jd[0:*:step], euvsc_casehtr[0:*:step], psym = ps, symsize = ss
      oplot, euvsc_jd[0:*:step], euvsc1_temps[0:*:step], color = colors[0], psym = ps, symsize = ss
      oplot, euvsc_jd[0:*:step], euvsc2_temps[0:*:step], color = colors[1], psym = ps, symsize = ss
      
      xyouts, !x.crange[0]+1*xratio, !y.crange[1]-2*yratio, $
         'EUVSC Htr '+strcompress(euvsc_casehtr[n_elements(euvsc_casehtr)-1]), $
         /data, charsize = 1.1
      xyouts, !x.crange[0]+15*xratio, !y.crange[1]-2*yratio, $
         'EUVSC1 '+strcompress(euvsc1_temps[n_elements(euvsc1_temps)-1]), $
         /data, charsize = 1.1, color = colors[0]
      xyouts, !x.crange[0]+30*xratio, !y.crange[1]-2*yratio, $
         'EUVSC2 '+strcompress(euvsc2_temps[n_elements(euvsc2_temps)-1]), $
         /data, charsize = 1.1, color = colors[1]
      
                                ; Rates
      ylabel = 'Degrees/Minute'
      
      ymin = 1000.0 & ymax = -1000.0
      
      oldlim = ( n_elements(euvsc1_dtemps) - 100L ) > 0L
      ymin = min([ymin, min(euvsc_dcasehtr[oldlim:*]), min(euvsc1_dtemps[oldlim:*]), min(euvsc2_dtemps[oldlim:*])])
      ymax = max([ymax, max(euvsc_dcasehtr[oldlim:*]), max(euvsc1_dtemps[oldlim:*]), max(euvsc2_dtemps[oldlim:*])])
      
      IF(ymin LT -0.2) THEN ymin = -0.2
      IF(ymax GT 0.2) THEN ymax = 0.2
      ymin = ymin < (-0.02)
      ymax = ymax > (0.02)
      
      plot, xrng, [ymin, ymax], /nodata, xrange = xrng, yrange = [ymin, ymax], $
         xtickformat = 'label_date', xtickunits = 'time', title = label, $
         xtitle = xlabel, ytitle = ylabel

      oplot, !x.crange, [0.01, 0.01], linestyle = 1, color = colors[3]
      oplot, !x.crange, [0, 0], linestyle = 1
      oplot, !x.crange, [-0.01, -0.01], linestyle = 1, color = colors[3]
      
      xratio = (!x.crange[1]-!x.crange[0])/40.
      yratio = (!y.crange[1]-!y.crange[0])/40.
      
      oplot, euvsc_jd[0:*:step], euvsc_dcasehtr[0:*:step], psym = ps, symsize = ss
      oplot, euvsc_jd[0:*:step], euvsc1_dtemps[0:*:step], color = colors[0], psym = ps, symsize = ss
      oplot, euvsc_jd[0:*:step], euvsc2_dtemps[0:*:step], color = colors[1], psym = ps, symsize = ss
      
      xyouts, !x.crange[0]+1*xratio, !y.crange[1]-2*yratio, $
         'EUVSC Htr '+strcompress(euvsc_dcasehtr[n_elements(euvsc_dcasehtr)-1]), $
         /data, charsize = 1.1
      xyouts, !x.crange[0]+15*xratio, !y.crange[1]-2*yratio, $
         'EUVSC1 '+strcompress(euvsc1_dtemps[n_elements(euvsc1_dtemps)-1]), $
         /data, charsize = 1.1, color = colors[0]
      xyouts, !x.crange[0]+30*xratio, !y.crange[1]-2*yratio, $
         'EUVSC2 '+strcompress(euvsc2_dtemps[n_elements(euvsc2_dtemps)-1]), $
         /data, charsize = 1.1, color = colors[1]
      
      val = euvsc_dcasehtr[n_elements(euvsc_dcasehtr)-1]
      IF(abs(val) LE 0.01) THEN print, 'EUVS-C HTR is stable: ', val ELSE $
         print, 'EUVS-C HTR is NOT stable: ', val
      
      val = euvsc1_dtemps[n_elements(euvsc1_dtemps)-1]
      IF(abs(val) LE 0.01) THEN print, 'EUVS-C1 is stable: ', val ELSE $
         print, 'EUVS-C1 is NOT stable: ', val
      
      val = euvsc2_dtemps[n_elements(euvsc2_dtemps)-1]
      IF(abs(val) LE 0.01) THEN print, 'EUVS-C2 is stable: ', val ELSE $
         print, 'EUVS-C2 is NOT stable: ', val
      
   ENDIF ELSE BEGIN
                                ; Temperatures
      plot, [0, 1], [-15, 10], /nodata, xrange = xrng, yrange = [-15, 10], $
         xtickformat = 'label_date', xtickunits = 'time', title = label, $
         xtitle = xlabel, ytitle = ylabel
      
      xratio = (!x.crange[1]-!x.crange[0])/40.
      yratio = (!y.crange[1]-!y.crange[0])/40.
      
      xyouts, !x.crange[0]+1*xratio, !y.crange[1]-2*yratio, 'EUVSC Htr NO DATA', $
         /data, charsize = 1.1
      xyouts, !x.crange[0]+15*xratio, !y.crange[1]-2*yratio, 'EUVSC1 NO DATA', $
         /data, charsize = 1.1, color = colors[0]
      xyouts, !x.crange[0]+30*xratio, !y.crange[1]-2*yratio, 'EUVSC2 NO DATA', $
         /data, charsize = 1.1, color = colors[1]
      
                                ; Rates
      ylabel = 'Degrees/Minute'
      
      plot, [0, 1], [-0.1, 0.1], /nodata, xrange = xrng, yrange = [-0.1, 0.1], $
         xtickformat = 'label_date', xtickunits = 'time', title = label, $
         xtitle = xlabel, ytitle = ylabel
      
      xratio = (!x.crange[1]-!x.crange[0])/40.
      yratio = (!y.crange[1]-!y.crange[0])/40.
      
      oplot, !x.crange, [0.01, 0.01], linestyle = 1, color = colors[3]
      oplot, !x.crange, [0, 0], linestyle = 1
      oplot, !x.crange, [-0.01, -0.01], linestyle = 1, color = colors[3]
      
      xyouts, !x.crange[0]+1*xratio, !y.crange[1]-2*yratio, 'EUVSC Htr NO DATA', $
         /data, charsize = 1.1
      xyouts, !x.crange[0]+15*xratio, !y.crange[1]-2*yratio, 'EUVSC1 NO DATA', $
         /data, charsize = 1.1, color = colors[0]
      xyouts, !x.crange[0]+30*xratio, !y.crange[1]-2*yratio, 'EUVSC2 NO DATA', $
         /data, charsize = 1.1, color = colors[1]
      
   ENDELSE
   
   print, ''
   print, 'Wait 60 seconds...', format = '(a, $)'
   wait, 30
   print, '30 more seconds...'
   wait, 30
   
ENDWHILE

RETURN

END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; End of 'exis_temp_plots.pro'.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
