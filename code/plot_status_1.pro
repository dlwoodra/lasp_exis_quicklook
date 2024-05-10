pro plot_status_1, xrs_rec, euvsa_rec, euvsb_rec, euvsc_rec, sps_rec

common temperature_conv_cal, temperature_C
common plot_status_1_cal, lasttime ;, $
;   lastspstime_sod, lastxrstime_sod, lasteuvsatime_sod, lasteuvsbtime_sod, $
;   lasteuvsctime_sod

if size(lasttime,/type) eq 0 then begin
   lasttime = -1
;   lastspstime_sod=' '
;   lastxrstime_sod=' '
;   lasteuvsatime_sod=' '
;   lasteuvsbtime_sod=' '
;   lasteuvsctime_sod=' '
endif

if size(temperature_C,/type) eq 0 then temperature_c = reform((read_goes_l0b_file(getenv('exis_cal_data')+'/exis_temperature.cal')).data)

;
; if at least 2 seconds has elapsed, then update the plot
;
thistime = (sps_rec.time.sod > xrs_rec.time.sod > $
            euvsa_rec.time.sod > euvsb_rec.time.sod > $
            euvsc_rec.time.sod)

if abs(lasttime - thistime) lt 2. then return
;
; note that more frequent updates could happen near the UT day boundary
;

;
; set timestamp to this update time
;
lasttime = thistime

window_set, 'STATUS-1'
erase ; redraw everything every time
!p.multi=0

p_orig=!p
d_orig=!d

; get the current font in use
device,get_current_font=orig_font
;set a device font
;device,set_font='7x14'
device,set_font='7x14bold'
;device,set_font='6x13' ; use for bare NUC
font=0 ; not true type, 0=device

; 5 columns defined using ..._xpos, many rows defined as maxrows
;;;; maxrows = float(23)
;; Changed (TE 30-AUG-2013) to allow for EUVS-C2 temperature
maxrows = float(30)
ypos=reverse((findgen(maxrows)+1.)/(maxrows+1.))

thexpos=findgen(5)/5.1 + 0.02
sps_xpos = thexpos[0] ;0.03


; define colors
FFcolor='cc0000'xUL
greenco='008800'xUL
grayco='aaaaaa'xUL
yellowco='77dddd'xUL
redco   = 'fe'xUL

exismode=['Failsafe','Normal','Diag','Safe']

co=0
spson = 1
if abs(sps_rec.time.sod - thistime) ge 64 or fix(sps_rec.asic.pwrstatus) eq 0 then begin
   co=grayco
   spson = 0
endif
;lastspstime_sod = sps_rec.time.sod
row=0
xyouts,font=font,/norm,sps_xpos,ypos[row++],'SPS',charsize=1.5

xyouts,font=font,/norm,sps_xpos,ypos[row++],sps_rec.time.hms,charsize=1.25,co=co
tvalco=co
if spson eq 1 then begin
   if fix(sps_rec.sec_hdr.uf.timevalid) eq 1 then tvalco = greenco else tvalco=redco
endif
xyouts,font=font,/norm,sps_xpos,ypos[row++],'UFTimeValid: '+strtrim(fix(sps_rec.sec_hdr.uf.timevalid),2),charsize=1.25,co=tvalco
pwrABstr='A' & if sps_rec.sec_hdr.uf.exispowerab eq 0b then pwrABstr='B'
xyouts,font=font,/norm,sps_xpos,ypos[row++],'UFPowerAB:  '+strtrim(fix(sps_rec.sec_hdr.uf.exispowerab),2)+' '+pwrABstr,charsize=1.25,co=co
xyouts,font=font,/norm,sps_xpos,ypos[row++],'FM: '+strtrim(fix(sps_rec.sec_hdr.uf.fm),2),charsize=1.25,co=co
xyouts,font=font,/norm,sps_xpos,ypos[row++],'ConfigID: '+strtrim(long(sps_rec.sec_hdr.uf.configid),2),charsize=1.25,co=co

runctrlco=co  ;assume OK
runctrlstr=' '
if spson eq 1 then begin
   if sps_rec.asic.runctrl eq 1 then begin
      runctrlco=greenco         ;assume OK
      runctrlstr=' Sci'
   endif
   if sps_rec.asic.runctrl eq 2 then begin
      runctrlco=yellowco
      runctrlstr=' Cal'
   endif
endif
xyouts,font=font,/norm,sps_xpos,ypos[row++],'RunCtrl: '+strtrim(fix(sps_rec.asic.runctrl),2)+runctrlstr,charsize=1.25,co=runctrlco
pwrstatco=co
if spson eq 1 then begin
   pwrstatco=greenco
   if fix(sps_rec.asic.pwrstatus) ne 3 then pwrstatco=redco
endif
xyouts,font=font,/norm,sps_xpos,ypos[row++],'PwrStatus: '+strtrim(fix(sps_rec.asic.pwrstatus),2),charsize=1.25,co=pwrstatco
itimeco=co
if spson eq 1 then begin
   itimeco=yellowco
   if fix(sps_rec.asic.integtime) eq 0 then itimeco=greenco
endif
xyouts,font=font,/norm,sps_xpos,ypos[row++],'IntTime: '+strtrim(fix(sps_rec.asic.integtime),2),charsize=1.25,co=itimeco
invalco=co
if spson eq 1 then begin
   invalco=redco
   if long(sps_rec.fsw.invalidflags) eq 0 then invalco=greenco
endif
xyouts,font=font,/norm,sps_xpos,ypos[row++],'InvalFlag: '+strtrim(long(sps_rec.fsw.invalidflags),2),charsize=1.25,co=invalco

dco=co
if spson eq 1 then begin
   dco=greenco
   if sps_rec.fsw.detchg_cnt lt 5 then dco=yellowco
endif
xyouts,font=font,/norm,sps_xpos,ypos[row++],'DetChgCnt: '+strtrim(long(sps_rec.fsw.detchg_cnt),2),charsize=1.25,co=dco

fco=co
if spson eq 1 then begin
   fco = greenco
   if sps_rec.fsw.fovflags ne 0 then fco=yellowco
   if sps_rec.fsw.fovflags ge 128 then fco=grayco
endif
xyouts,font=font,/norm,sps_xpos,ypos[row++],'FOVFlags: '+strtrim(fix(sps_rec.fsw.fovflags),2),charsize=1.25,co=fco
;xyouts,font=font,/norm,sps_xpos,ypos[row++],'X_E_Mode: '+strtrim(fix(sps_rec.fsw.xrseuvsmode),2),charsize=1.25,co=co

modeco=co ; assume default
if spson eq 1 then begin
   if sps_rec.sec_hdr.uf.exismode eq 1 then modeco=greenco else modeco=yellowco
endif
xyouts,font=font,/norm,sps_xpos,ypos[row++],'UFEXIS_Mode: '+exismode[fix(sps_rec.sec_hdr.uf.exismode)],charsize=1.2,co=modeco

temp=temperature_c[sps_rec.temperature]
tempco=co
if spson eq 1 then begin
   if temp gt 0 and temp lt 25 then tempco=greenco else tempco=yellowco
   if temp lt -30 or temp gt 40 then tempcp=redco
endif
xyouts,font=font,/norm,sps_xpos,ypos[row++],'Temp_C: '+strtrim(string(temperature_C[sps_rec.temperature],form='(f9.2)'),2),charsize=1.2,co=tempco




instrmode=['Normal','Cal','Diag','Safe']

; XRS
xrs_xpos = thexpos[1] ;0.20

co=0
xrson=1
if abs(xrs_rec.time.sod - thistime) ge 64 or fix(xrs_rec.asic.pwrstatus) eq 0 then begin
   co=grayco
   xrson=0
endif
;lastxrstime_sod = xrs_rec.time.sod

row=0
xyouts,font=font,/norm,xrs_xpos,ypos[row++],'XRS',charsize=1.5
xyouts,font=font,/norm,xrs_xpos,ypos[row++],xrs_rec.time.hms,charsize=1.25,co=co
xyouts,font=font,/norm,xrs_xpos,ypos[row++],'UFTimeValid: '+strtrim(fix(xrs_rec.sec_hdr.uf.timevalid),2),charsize=1.25,co=co
pwrABstr='A' & if xrs_rec.sec_hdr.uf.exispowerab eq 0b then pwrABstr='B'
xyouts,font=font,/norm,xrs_xpos,ypos[row++],'UFPowerAB:  '+strtrim(fix(xrs_rec.sec_hdr.uf.exispowerab),2)+' '+pwrABstr,charsize=1.25,co=co
xyouts,font=font,/norm,xrs_xpos,ypos[row++],'FM: '+strtrim(fix(xrs_rec.sec_hdr.uf.fm),2),charsize=1.25,co=co
xyouts,font=font,/norm,xrs_xpos,ypos[row++],'ConfigID: '+strtrim(long(xrs_rec.sec_hdr.uf.configid),2),charsize=1.25,co=co

runctrlco=co  ;assume OK
runctrlstr=' '
if xrson eq 1 then begin
   if xrs_rec.asic.runctrl eq 1 then begin
      runctrlco=greenco         ;assume OK
      runctrlstr=' Sci'
   endif
   if xrs_rec.asic.runctrl eq 2 then begin
      runctrlco=yellowco
      runctrlstr=' Cal'
   endif
endif
xyouts,font=font,/norm,xrs_xpos,ypos[row++],'RunCtrl: '+strtrim(fix(xrs_rec.asic.runctrl),2)+runctrlstr,charsize=1.25,co=runctrlco
pwrstatco=co
if xrson eq 1 then begin
   pwrstatco=greenco
   if fix(xrs_rec.asic.pwrstatus) ne 15 then pwrstatco=redco
endif
xyouts,font=font,/norm,xrs_xpos,ypos[row++],'PwrStatus: '+strtrim(fix(xrs_rec.asic.pwrstatus),2),charsize=1.25,co=pwrstatco
itimeco=co
if xrson eq 1 then begin
   itimeco=yellowco
   if fix(xrs_rec.asic.integtime) eq 3 then itimeco=greenco
endif
xyouts,font=font,/norm,xrs_xpos,ypos[row++],'IntTime: '+strtrim(fix(xrs_rec.asic.integtime),2),charsize=1.25,co=itimeco
invalco=co
if xrson eq 1 then begin
   invalco=redco
   if long(xrs_rec.fsw.invalidflags) eq 0 then invalco=greenco
endif
xyouts,font=font,/norm,xrs_xpos,ypos[row++],'InvalFlag: '+strtrim(long(xrs_rec.fsw.invalidflags),2),charsize=1.25,co=invalco

dco=co
if xrson eq 1 then begin
   dco=greenco
   if xrs_rec.fsw.detchg_cnt lt 5 then dco=yellowco
endif
xyouts,font=font,/norm,xrs_xpos,ypos[row++],'DetChgCnt: '+strtrim(long(xrs_rec.fsw.detchg_cnt),2),charsize=1.25,co=dco
fco=co
if xrson eq 1 then begin
   fco=greenco
   if xrs_rec.fsw.fovflags ne 0 then fco=yellowco
   if xrs_rec.fsw.fovflags ge 128 then fco=grayco
endif
xyouts,font=font,/norm,xrs_xpos,ypos[row++],'FOVFlags: '+strtrim(fix(xrs_rec.fsw.fovflags),2),charsize=1.25,co=fco

modeco=co ; assume OK
xrsmode=ishft(xrs_rec.fsw.xrseuvsmode,-4) and '3'xU
if xrson eq 1 then begin
   modeco=greenco
   if xrsmode eq 2 then modeco=yellowco
   if xrsmode eq 3 then modeco=redco
endif
xyouts,font=font,/norm,xrs_xpos,ypos[row++],'XRS_Mode: '+instrmode[xrsmode],charsize=1.25,co=modeco
ffchgco=co
ffon=0
thisFFcolor=0
if xrson eq 1 then begin
   ffchgco=greenco
   ; is ff on for XRS?
   if xrs_rec.ff.channel eq 3 or xrs_rec.ff.channel eq 7 then begin
      ffon=1
      thisFFcolor=FFcolor
      if long(xrs_rec.fsw.ffchg_cnt) lt 256 then ffchgco=greenco else ffchgco=redco
   endif
endif
xyouts,font=font,/norm,xrs_xpos,ypos[row++],'FFChgCnt: '+strtrim(long(xrs_rec.fsw.ffchg_cnt),2),charsize=1.25,co=ffchgco
xyouts,font=font,/norm,xrs_xpos,ypos[row++],'FFPwrSel: '+strtrim(long(xrs_rec.ff.power),2),charsize=1.25,co=co

xyouts,font=font,/norm,xrs_xpos,ypos[row++],'FFstring: '+strtrim(xrs_rec.ff.english,2),charsize=1.25,co=thisFFcolor

;if xrs_rec.ff.pwr_enable eq 0 then $
;   xyouts,font=font,/norm,xrs_xpos,ypos[row++],'FFstring: '+strtrim(xrs_rec.ff.english,2),charsize=1.25,co=co else $
;      xyouts,font=font,/norm,xrs_xpos,ypos[row++],'FFstring: '+strtrim(xrs_rec.ff.english,2),charsize=1.25,co=thisFFcolor

xyouts,font=font,/norm,xrs_xpos,ypos[row++],'FFLevel: '+strtrim(long(xrs_rec.ff.level),2),charsize=1.25,co=thisFFcolor

temp = temperature_C[xrs_rec.asic1temp]
tempco = co
if xrson eq 1 then begin
   if temp gt 0 and temp lt 25 then tempco=greenco else tempco=yellowco
   if temp lt -30 or temp gt 36 then tempco=redco
endif
xyouts,font=font,/norm,xrs_xpos,ypos[row++],'a1Temp_C: '+strtrim(string(temperature_C[xrs_rec.asic1temp],form='(f9.2)'),2),charsize=1.2,co=tempco
;;;;;;; Added ASIC 2 temperature (TE 6-SEP-2013) ;;;;;;;
temp = temperature_C[xrs_rec.asic2temp]
tempco = co
if xrson eq 1 then begin
   if temp gt 0 and temp lt 25 then tempco=greenco else tempco=yellowco
   if temp lt -30 or temp gt 36 then tempco=redco
endif
xyouts,font=font,/norm,xrs_xpos,ypos[row++],'a2Temp_C: '+strtrim(string(temperature_C[xrs_rec.asic2temp],form='(f9.2)'),2),charsize=1.2,co=tempco

; EUVS-A
euvsa_xpos = thexpos[2] ;0.37

co=0
euvsaon=1
if abs(euvsa_rec.time.sod - thistime) ge 64 or fix(euvsa_rec.asic.pwrstatus) eq 0 then begin
   co=grayco
   euvsaon=0
endif
;lasteuvsatime_sod = euvsa_rec.time.sod

row=0
xyouts,font=font,/norm,euvsa_xpos,ypos[row++],'EUVS-A',charsize=1.5
xyouts,font=font,/norm,euvsa_xpos,ypos[row++],euvsa_rec.time.hms,charsize=1.25,co=co
xyouts,font=font,/norm,euvsa_xpos,ypos[row++],'UFTimeValid: '+strtrim(fix(euvsa_rec.sec_hdr.uf.timevalid),2),charsize=1.25,co=co
pwrABstr='A' & if euvsa_rec.sec_hdr.uf.exispowerab eq 0b then pwrABstr='B'
xyouts,font=font,/norm,euvsa_xpos,ypos[row++],'UFPowerAB:  '+strtrim(fix(euvsa_rec.sec_hdr.uf.exispowerab),2)+' '+pwrABstr,charsize=1.25,co=co
xyouts,font=font,/norm,euvsa_xpos,ypos[row++],'FM: '+strtrim(fix(euvsa_rec.sec_hdr.uf.fm),2),charsize=1.25,co=co
xyouts,font=font,/norm,euvsa_xpos,ypos[row++],'ConfigID: '+strtrim(long(euvsa_rec.sec_hdr.uf.configid),2),charsize=1.25,co=co

runctrlco=co  ;assume OK
runctrlstr=' '
if euvsaon eq 1 then begin
   if euvsa_rec.asic.runctrl eq 1 then begin
      runctrlco=greenco         ;assume OK
      runctrlstr=' Sci'
   endif
   if euvsa_rec.asic.runctrl eq 2 then begin
      runctrlco=yellowco
      runctrlstr=' Cal'
   endif
endif
xyouts,font=font,/norm,euvsa_xpos,ypos[row++],'RunCtrl: '+strtrim(fix(euvsa_rec.asic.runctrl),2)+runctrlstr,charsize=1.25,co=runctrlco
pwrstatco=co
if euvsaon eq 1 then begin
   pwrstatco=greenco
   if fix(euvsa_rec.asic.pwrstatus) ne 15 then pwrstatco=redco
endif
xyouts,font=font,/norm,euvsa_xpos,ypos[row++],'PwrStatus: '+strtrim(fix(euvsa_rec.asic.pwrstatus),2),charsize=1.25,co=pwrstatco
itimeco=co
if euvsaon eq 1 then begin
   itimeco=yellowco
   if fix(euvsa_rec.asic.integtime) eq 3 then itimeco=greenco
endif
xyouts,font=font,/norm,euvsa_xpos,ypos[row++],'IntTime: '+strtrim(fix(euvsa_rec.asic.integtime),2),charsize=1.25,co=itimeco
invalco=co
if euvsaon eq 1 then begin
   invalco=redco
   if long(euvsa_rec.fsw.invalidflags) eq 0 then invalco=greenco
endif
xyouts,font=font,/norm,euvsa_xpos,ypos[row++],'InvalFlag: '+strtrim(long(euvsa_rec.fsw.invalidflags),2),charsize=1.25,co=invalco

dco=co
if euvsaon eq 1 then begin
   dco=greenco
   if euvsa_rec.fsw.detchg_cnt lt 5 then dco=yellowco
endif
xyouts,font=font,/norm,euvsa_xpos,ypos[row++],'DetChgCnt: '+strtrim(long(euvsa_rec.fsw.detchg_cnt),2),charsize=1.25,co=dco
fco=co
if euvsaon eq 1 then begin
   fco=greenco
   if euvsa_rec.fsw.fovflags ne 0 then fco=yellowco
   if euvsa_rec.fsw.fovflags ge 128 then fco=grayco
endif
xyouts,font=font,/norm,euvsa_xpos,ypos[row++],'FOVFlags: '+strtrim(fix(euvsa_rec.fsw.fovflags),2),charsize=1.25,co=fco

modeco=co ; assume OK
euvsmode=(euvsa_rec.fsw.xrseuvsmode) and '3'xU
if euvsaon eq 1 then begin
   modeco=greenco
   if euvsmode eq 2 then modeco=yellowco
   if euvsmode eq 3 then modeco=redco
endif
xyouts,font=font,/norm,euvsa_xpos,ypos[row++],'EUVS_Mode: '+instrmode[euvsmode],charsize=1.25,co=modeco

ffchgco=co
ffon=0
thisFFcolor=0
if euvsaon eq 1 then begin
   ffchgco=greenco
   ; is ff on for EUVSA?
   if euvsa_rec.ff.channel eq 2 or euvsa_rec.ff.channel eq 6 then begin
      ffon=1
      thisFFcolor=FFcolor
      if long(euvsa_rec.fsw.ffchg_cnt) lt 256 then ffchgco=greenco else ffchgco=redco
   endif
endif

xyouts,font=font,/norm,euvsa_xpos,ypos[row++],'FFChgCnt: '+strtrim(long(euvsa_rec.fsw.ffchg_cnt),2),charsize=1.25,co=ffchgco
xyouts,font=font,/norm,euvsa_xpos,ypos[row++],'FFPwrSel: '+strtrim(long(euvsa_rec.ff.power),2),charsize=1.25,co=co

xyouts,font=font,/norm,euvsa_xpos,ypos[row++],'FFstring: '+strtrim(euvsa_rec.ff.english,2),charsize=1.25,co=thisFFcolor

;if euvsa_rec.ff.pwr_enable eq 0 then $
;   xyouts,font=font,/norm,euvsa_xpos,ypos[row++],'FFstring: '+strtrim(euvsa_rec.ff.english,2),charsize=1.25,co=co else $
;      xyouts,font=font,/norm,euvsa_xpos,ypos[row++],'FFstring: '+strtrim(euvsa_rec.ff.english,2),charsize=1.25,co=thisFFcolor

xyouts,font=font,/norm,euvsa_xpos,ypos[row++],'FFLevel: '+strtrim(long(euvsa_rec.ff.level),2),charsize=1.25,co=thisFFcolor


xyouts,font=font,/norm,euvsa_xpos,ypos[row++],'Door_Stat: '+strtrim(fix(euvsa_rec.exis_mech.doorstatus),2),charsize=1.25,co=co
door_pos=''
doorco=co
if euvsaon eq 1 then begin
   doorco = yellowco
   door_pos = ' Undefined'
   if euvsa_rec.exis_mech.doorposition eq 0 then begin
      door_pos = ' CLOSED'
      doorco = redco
   endif
   if euvsa_rec.exis_mech.doorposition eq 31 then begin
      door_pos=' OPEN'
      doorco = greenco
   endif
endif
xyouts,font=font,/norm,euvsa_xpos,ypos[row++],'Door_Pos: '+strtrim(fix(euvsa_rec.exis_mech.doorposition),2)+door_pos,charsize=1.25,co=doorco

xyouts,font=font,/norm,euvsa_xpos,ypos[row++],'Filter_Stat: '+strtrim(fix(euvsa_rec.exis_mech.filterstatus),2),charsize=1.25,co=co

filterpos=0
filterposstr=''
filtername=''
filterco=co
if euvsaon eq 1 then begin
   filterpos = fix(euvsa_rec.exis_mech.filterposition)
   filterposstr = convert_filterstepnumber_to_afilter( filterpos, name=filtername )
   filterco = greenco
   if filtername eq 'A-DARK' then filterco=FFcolor
endif
xyouts,font=font,/norm,euvsa_xpos,ypos[row++],'AFilter: '+strtrim(filterpos,2)+' '+strtrim(filtername,2),charsize=1.25,co=filterco
xyouts,font=font,/norm,euvsa_xpos,ypos[row++],'Filter_Pos: '+strtrim(fix(euvsa_rec.exis_mech.filterposition),2),charsize=1.25,co=co
temp = temperature_C[euvsa_rec.atemp]
tempco = co
if euvsaon eq 1 then begin
   if temp gt -5 and temp lt 25 then tempco=greenco else tempco=yellowco
   if temp lt -30 or temp gt 36 then tempco=redco
endif
xyouts,font=font,/norm,euvsa_xpos,ypos[row++],'aTemp_C: '+strtrim(string(temperature_C[euvsa_rec.atemp],form='(f9.2)'),2),charsize=1.2,co=tempco

; EUVS-B
euvsb_xpos = thexpos[3] ;0.54

co=0
euvsbon=1
if abs(euvsb_rec.time.sod - thistime) ge 64 or fix(euvsb_rec.asic.pwrstatus) eq 0 then begin
   co=grayco
   euvsbon=0
endif
;lasteuvsbtime_sod = euvsb_rec.time.sod

row=0
xyouts,font=font,/norm,euvsb_xpos,ypos[row++],'EUVS-B',charsize=1.5
xyouts,font=font,/norm,euvsb_xpos,ypos[row++],euvsb_rec.time.hms,charsize=1.25,co=co
xyouts,font=font,/norm,euvsb_xpos,ypos[row++],'UFTimeValid: '+strtrim(fix(euvsb_rec.sec_hdr.uf.timevalid),2),charsize=1.25,co=co
pwrABstr='A' & if euvsb_rec.sec_hdr.uf.exispowerab eq 0b then pwrABstr='B'
xyouts,font=font,/norm,euvsb_xpos,ypos[row++],'UFPowerAB:  '+strtrim(fix(euvsb_rec.sec_hdr.uf.exispowerab),2)+' '+pwrABstr,charsize=1.25,co=co
xyouts,font=font,/norm,euvsb_xpos,ypos[row++],'FM: '+strtrim(fix(euvsb_rec.sec_hdr.uf.fm),2),charsize=1.25,co=co
xyouts,font=font,/norm,euvsb_xpos,ypos[row++],'ConfigID: '+strtrim(long(euvsb_rec.sec_hdr.uf.configid),2),charsize=1.25,co=co

runctrlco=co  ;assume OK
runctrlstr=' '
if euvsbon eq 1 then begin
   if euvsb_rec.asic.runctrl eq 1 then begin
      runctrlco=greenco         ;assume OK
      runctrlstr=' Sci'
   endif
   if euvsb_rec.asic.runctrl eq 2 then begin
      runctrlco=yellowco
      runctrlstr=' Cal'
   endif
endif

xyouts,font=font,/norm,euvsb_xpos,ypos[row++],'RunCtrl: '+strtrim(fix(euvsb_rec.asic.runctrl),2)+runctrlstr,charsize=1.25,co=runctrlco
pwrstatco=co
if euvsbon eq 1 then begin
   pwrstatco=greenco
   if fix(euvsb_rec.asic.pwrstatus) ne 15 then pwrstatco=redco
endif
xyouts,font=font,/norm,euvsb_xpos,ypos[row++],'PwrStatus: '+strtrim(fix(euvsb_rec.asic.pwrstatus),2),charsize=1.25,co=pwrstatco
itimeco=co
if euvsbon eq 1 then begin
   itimeco=yellowco
   if fix(euvsb_rec.asic.integtime) eq 3 then itimeco=greenco
endif
xyouts,font=font,/norm,euvsb_xpos,ypos[row++],'IntTime: '+strtrim(fix(euvsb_rec.asic.integtime),2),charsize=1.25,co=itimeco
invalco=co
if euvsbon eq 1 then begin
   invalco=redco
   if long(euvsb_rec.fsw.invalidflags) eq 0 then invalco=greenco
endif
xyouts,font=font,/norm,euvsb_xpos,ypos[row++],'InvalFlag: '+strtrim(long(euvsb_rec.fsw.invalidflags),2),charsize=1.25,co=invalco

dco=co
if euvsbon eq 1 then begin
   dco=greenco
   if euvsb_rec.fsw.detchg_cnt lt 5 then dco=yellowco
endif
xyouts,font=font,/norm,euvsb_xpos,ypos[row++],'DetChgCnt: '+strtrim(long(euvsb_rec.fsw.detchg_cnt),2),charsize=1.25,co=dco
fco=co
if euvsbon eq 1 then begin
   fco=greenco
   if euvsb_rec.fsw.fovflags ne 0 then fco=yellowco
   if euvsb_rec.fsw.fovflags ge 128 then fco=grayco
endif
xyouts,font=font,/norm,euvsb_xpos,ypos[row++],'FOVFlags: '+strtrim(fix(euvsb_rec.fsw.fovflags),2),charsize=1.25,co=fco

modeco=co ; assume OK
euvsmode=(euvsb_rec.fsw.xrseuvsmode) and '3'xU
if euvsbon eq 1 then begin
   modeco=greenco
   if euvsmode eq 2 then modeco=yellowco
   if euvsmode eq 3 then modeco=redco
endif
xyouts,font=font,/norm,euvsb_xpos,ypos[row++],'EUVS_Mode: '+instrmode[euvsmode],charsize=1.25,co=modeco

ffchgco=co
ffon=0
thisFFcolor=0
if euvsbon eq 1 then begin
   ffchgco=greenco
   ; is ff on for EUVSB?
   if euvsb_rec.ff.channel eq 1 or euvsb_rec.ff.channel eq 5 then begin
      ffon=1
      thisFFcolor=FFcolor
      if long(euvsb_rec.fsw.ffchg_cnt) lt 256 then ffchgco=greenco else ffchgco=redco
   endif
endif

xyouts,font=font,/norm,euvsb_xpos,ypos[row++],'FFChgCnt: '+strtrim(long(euvsb_rec.fsw.ffchg_cnt),2),charsize=1.25,co=ffchgco
xyouts,font=font,/norm,euvsb_xpos,ypos[row++],'FFPwrSel: '+strtrim(long(euvsb_rec.ff.power),2),charsize=1.25,co=co

xyouts,font=font,/norm,euvsb_xpos,ypos[row++],'FFstring: '+strtrim(euvsb_rec.ff.english,2),charsize=1.25,co=thisFFcolor

;if euvsb_rec.ff.channel eq 1 then thisFFcolor=FFcolor else thisFFcolor=co
;if euvsb_rec.ff.pwr_enable eq 0 then $
;   xyouts,font=font,/norm,euvsb_xpos,ypos[row++],'FFstring: '+strtrim(euvsb_rec.ff.english,2),charsize=1.25,co=co else $
;      xyouts,font=font,/norm,euvsb_xpos,ypos[row++],'FFstring: '+strtrim(euvsb_rec.ff.english,2),charsize=1.25,co=thisFFcolor

xyouts,font=font,/norm,euvsb_xpos,ypos[row++],'FFLevel: '+strtrim(long(euvsb_rec.ff.level),2),charsize=1.25,co=thisFFcolor


xyouts,font=font,/norm,euvsb_xpos,ypos[row++],'Door_Stat: '+strtrim(fix(euvsb_rec.exis_mech.doorstatus),2),charsize=1.25,co=co
door_pos=''
doorco=co
if euvsbon eq 1 then begin
   doorco = yellowco
   door_pos = ' Undefined'
   if euvsb_rec.exis_mech.doorposition eq 0 then begin
      door_pos = ' CLOSED'
      doorco = redco
   endif
   if euvsb_rec.exis_mech.doorposition eq 31 then begin
      door_pos=' OPEN'
      doorco = greenco
   endif
endif
if euvsb_rec.exis_mech.doorposition eq 31 then door_pos=' OPEN'
xyouts,font=font,/norm,euvsb_xpos,ypos[row++],'Door_Pos: '+strtrim(fix(euvsb_rec.exis_mech.doorposition),2)+door_pos,charsize=1.25,co=doorco

xyouts,font=font,/norm,euvsb_xpos,ypos[row++],'Filter_Stat: '+strtrim(fix(euvsb_rec.exis_mech.filterstatus),2),charsize=1.25,co=co


filterpos=0
filterposstr=''
filtername=''
filterco=co
if euvsbon eq 1 then begin
   filterpos = fix(euvsb_rec.exis_mech.filterposition)
   filterposstr = convert_filterstepnumber_to_afilter( filterpos, name=filtername )
   filterco = greenco
   if filtername eq 'B-DARK' then filterco=FFcolor
endif

xyouts,font=font,/norm,euvsb_xpos,ypos[row++],'AFilter: '+strtrim(filterpos,2)+' '+strtrim(filtername,2),charsize=1.25,co=filterco
xyouts,font=font,/norm,euvsb_xpos,ypos[row++],'Filter_Pos: '+strtrim(fix(euvsb_rec.exis_mech.filterposition),2),charsize=1.25,co=co
temp = temperature_C[euvsb_rec.btemp]
tempco = co
if euvsbon eq 1 then begin
   if temp gt -5 and temp lt 25 then tempco=greenco else tempco=yellowco
   if temp lt -30 or temp gt 36 then tempco=redco
endif
xyouts,font=font,/norm,euvsb_xpos,ypos[row++],'bTemp_C: '+strtrim(string(temperature_C[euvsb_rec.btemp],form='(f9.2)'),2),charsize=1.2,co=tempco


; EUVS-C
euvsc_xpos = thexpos[4] ;0.71

co=0
euvscon=1
chpwr = fix(ishft(euvsc_rec.reg.pwrstatus,-2)) ; 1 or 2 for C1 or C2

if abs(euvsc_rec.time.sod - thistime) ge 64  or long(euvsc_rec.reg.pwrstatus and '1'b) eq 0 then begin
   co=grayco
   euvscon=0
endif
;lasteuvsctime_sod = euvsc_rec.time.sod

row=0
xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'EUVS-C',charsize=1.5
xyouts,font=font,/norm,euvsc_xpos,ypos[row++],euvsc_rec.time.hms,charsize=1.25,co=co
xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'UFTimeValid: '+strtrim(fix(euvsc_rec.sec_hdr.uf.timevalid),2),charsize=1.25,co=co

pwrABstr='A' & if euvsc_rec.sec_hdr.uf.exispowerab eq 0b then pwrABstr='B'
xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'UFPowerAB:  '+strtrim(fix(euvsc_rec.sec_hdr.uf.exispowerab),2)+' '+pwrABstr,charsize=1.25,co=co
xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'FM: '+strtrim(fix(euvsc_rec.sec_hdr.uf.fm),2),charsize=1.25,co=co
xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'ConfigID: '+strtrim(long(euvsc_rec.sec_hdr.uf.configid),2),charsize=1.25,co=co

xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'ModeReg: '+strtrim(long(euvsc_rec.reg.modereg),2),charsize=1.25,co=co
if euvscon eq 1 then pwrco=greenco
xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'PwrEnable: '+strtrim(long(euvsc_rec.reg.pwrstatus and '1'b),2),charsize=1.25,co=pwrco

xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'IntTime: '+strtrim(long(euvsc_rec.reg.integtime),2),charsize=1.25,co=co

invalco=co
if euvscon eq 1 then begin
   invalco=redco
   if long(euvsc_rec.fsw.invalidflags) eq 0 then invalco=greenco
endif
xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'InvalFlag: '+strtrim(long(euvsc_rec.fsw.invalidflags),2),charsize=1.25,co=invalco

dco=co
if euvscon eq 1 then begin
   dco=greenco
   if euvsc_rec.fsw.detchg_cnt lt 5 then dco=yellowco
endif
xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'DetChgCnt: '+strtrim(long(euvsc_rec.fsw.detchg_cnt),2),charsize=1.25,co=dco

fco=co
if euvscon eq 1 then begin
   fco=greenco
   if euvsc_rec.fsw.fovflags ne 0 then fco=yellowco
   if euvsc_rec.fsw.fovflags ge 128 then fco=grayco
endif
xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'FOVFlags: '+strtrim(fix(euvsc_rec.fsw.fovflags),2),charsize=1.25,co=fco

modeco=co ; assume OK
euvsmode=(euvsc_rec.fsw.xrseuvsmode) and '3'xU
if euvscon eq 1 then begin
   modeco=greenco
   if euvsmode eq 2 then modeco=yellowco
   if euvsmode eq 3 then modeco=redco
endif
xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'EUVS_Mode: '+instrmode[euvsmode],charsize=1.25,co=modeco

ffchgco=co
ffon=0
thisFFcolor=0
if euvscon eq 1 then begin
   ffchgco=greenco
   ; is ff on for EUVSC?
   ; C1 uses FF0
   ; C2 uses FF4
   if euvsc_rec.ff.pwr_enable eq 1 then begin
      if euvsc_rec.ff.channel eq 0 or euvsc_rec.ff.channel eq 4 then begin
         ffon=1
         thisFFcolor=FFcolor
         
         if (euvsc_rec.ff.channel eq 0 and chpwr eq 2) or (euvsc_rec.ff.channel eq 1 and chpwr eq 1) then begin
            ; wrong combo
            ffchgco=redco
         endif
         if long(euvsc_rec.fsw.ffchg_cnt) lt 256 then ffchgco=greenco else ffchgco=redco
      endif
   endif
endif

xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'FFChgCnt: '+strtrim(long(euvsc_rec.fsw.ffchg_cnt),2),charsize=1.25,co=ffchgco
xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'FFPwrSel: '+strtrim(long(euvsc_rec.ff.power),2),charsize=1.25,co=co

xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'FFstring: '+strtrim(euvsc_rec.ff.english,2),charsize=1.25,co=thisFFcolor

;if euvsc_rec.ff.channel eq 0 then thisFFcolor=FFcolor else thisFFcolor=co
;if euvsc_rec.ff.pwr_enable eq 0 then $
;   xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'FFstring: '+strtrim(euvsc_rec.ff.english,2),charsize=1.25,co=co else $
;      xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'FFstring: '+strtrim(euvsc_rec.ff.english,2),charsize=1.25,co=thisFFcolor

xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'FFLevel: '+strtrim(long(euvsc_rec.ff.level),2),charsize=1.25,co=thisFFcolor

xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'Door_Stat: '+strtrim(fix(euvsc_rec.exis_mech.doorstatus),2),charsize=1.25,co=co


door_pos=''
doorco=co
if euvscon eq 1 then begin
   doorco = yellowco
   door_pos = ' Undefined'
   if euvsc_rec.exis_mech.doorposition eq 0 then begin
      door_pos = ' CLOSED'
      doorco = redco
   endif
   if euvsc_rec.exis_mech.doorposition eq 31 then begin
      door_pos=' OPEN'
      doorco = greenco
   endif
endif

xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'Door_Pos: '+strtrim(fix(euvsc_rec.exis_mech.doorposition),2)+door_pos,charsize=1.25,co=doorco

xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'Filter_Stat: '+strtrim(fix(euvsc_rec.exis_mech.filterstatus),2),charsize=1.25,co=co

filterpos=0
filterposstr=''
filtername=''
filterco=co
if euvscon eq 1 then begin
   filterpos = fix(euvsc_rec.exis_mech.filterposition)
   filterposstr = convert_filterstepnumber_to_afilter( filterpos, name=filtername )
   filterco = greenco
   ;if filtername eq 'C1-DARK' or filtername eq 'C2-DARK' then filterco=FFcolor
   if filtername eq 'C1-DARK' and chpwr eq 1 then filterco=FFcolor
   if filtername eq 'C2-DARK' and chpwr eq 2 then filterco=FFcolor
endif

;chpwr = fix(ishft(euvsc_rec.reg.pwrstatus,-2)) ; 1 or 2 for C1 or C2
xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'AFilter: '+strtrim(filterpos,2)+' '+strtrim(filtername,2),charsize=1.25,co=filterco

xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'Filter_Pos: '+strtrim(filterpos,2),charsize=1.25,co=co

xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'PwrC1C2: C'+strtrim(chpwr,2),charsize=1.25,co=co

temp = temperature_C[euvsc_rec.c1temp]
tempco = co
if euvscon eq 1 then begin
   if temp gt -15 and temp lt 8 then tempco=greenco else tempco=yellowco
   if temp lt -25 or temp gt 35 then tempco=redco
endif
xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'C1Temp_C: '+strtrim(string(temperature_C[euvsc_rec.c1temp],form='(f9.2)'),2),charsize=1.2,co=tempco
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Added EUVS-C2 temperature (TE 30-AUG-2013) ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
temp = temperature_C[euvsc_rec.c2temp]
tempco = co
if euvscon eq 1 then begin
   if temp gt -15 and temp lt 8 then tempco=greenco else tempco=yellowco
   if temp lt -25 or temp gt 35 then tempco=redco
endif
xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'C2Temp_C: '+strtrim(string(temperature_C[euvsc_rec.c2temp],form='(f9.2)'),2),charsize=1.2,co=tempco
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; extra EUVS-C stuff that used to be below SPS
cmode='Data-Ref'
tmp=fix(ishft(euvsc_rec.reg.modereg,-6))
cco=co
if euvscon eq 1 then begin
   if chpwr ne 0 then begin
      cco=greenco
      if tmp eq 2 then begin
         cmode='DataOnly'
         cco=yellowco
      endif
      if tmp eq 3 then begin
         cmode='RefOnly'
         cco=redco
      endif
   endif
endif
xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'CPixlMod: '+cmode,charsize=1.2,co=cco
fc=fix(euvsc_rec.reg.modeReg and '3'xb)
if euvscon eq 1 then begin
   if fc eq 3 then cco=greenco
endif
xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'CFlushCnt: '+strtrim(fc,2),co=cco
if euvscon eq 1 then begin
   if chpwr ne 0 then begin
      if fix(euvsc_rec.reg.deadtime) eq 0 then cco=greenco else cco=redco
   endif
endif
xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'CDeadCnt(Wait): '+strtrim(fix(euvsc_rec.reg.deadtime),2),co=cco
cit=0.250   * float(euvsc_rec.reg.integtime+1.) - $
    (.025   * (euvsc_rec.reg.deadtime+1.)) - $
    (.02048 * (fc-1.))
if euvsc_rec.reg.deadtime eq 7 and fc eq 3 then cit = cit+0.25
xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'CIntTimeSec: '+strtrim(string((cit),form='(f7.4)'),2),charsize=1.2,co=cco


; reset default font
device,set_font=orig_font
!p.font=p_orig.font

;stop
return
end
