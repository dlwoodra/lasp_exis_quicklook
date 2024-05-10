; docformat = 'rst'

;+
;  Define constants and structures for the GOES EXIS GPDS.
;  All structured/constants are global in scope.
;
; :Categories:
;     Header
;
; :Examples:
;     @gpds_defines.pro
;
; :History: Change History::
;    11/24/08 DLW Original file creation to support SW-PDPR demo.
;    01/20/10 DLW Update for version 9 telemetry changes.
;    11/05/10 DLW Update for version 12 major telemetry changes.
;    11/29/10 DLW Update for version 13 telemetry changes.
;    10/10/11 DLW Update for version 15 telemetry changes (14 had error).
;
; :Version:
;    $Id: gpds_defines.pro 78098 2017-03-13 18:04:23Z dlwoodra $
;
;-

;
; IDL include files cannot have loops
;

;
;  10) Define standard status codes
;
OK_STATUS = 0
BAD_PARAMS = -1
BAD_FILE_DATA = -2

;
;  20) Define SW version variables
;
;EXIS_TLM_VERSION = 8 ; 20090909
;EXIS_TLM_VERSION = 11 ; 20100120
;EXIS_TLM_VERSION = 12 ; 20101104
;EXIS_TLM_VERSION = 13 ; 20101129
EXIS_TLM_VERSION = 15 ; 20111121

EXIS_GPDS_VERSION_STR = '001'
EXIS_DP_VERSION_MAJOR = '01'
EXIS_DP_VERSION_MINOR = '01'
EXIS_SW_VERSION = EXIS_DP_VERSION_MAJOR+'.'+EXIS_DP_VERSION_MINOR

FM_DESIGNATOR = 0b

OPEN_DOOR_POSITION = 31b
CLOSE_DOOR_POSITION = 0b
PRIMARY_SCIENCE_FILTER_POSITION = 3b
FULL_SCIENCE_FILTER_POSITIONS = [3b, 6b, 15b, 21b, 24b, 39b, 42b, 51b,$
                                57b, 60b, 75b, 78b, 84b, 93b, 105b]
DARK_EUVSA_FILTER_POSITION  = 0b
DARK_EUVSB_FILTER_POSITION  = 12b
DARK_EUVSC1_FILTER_POSITION = 66b
DARK_EUVSC2_FILTER_POSITION = 30b

;
;  25) Define APIDs
;
NUM_EUVSC_APIDS = 8
SPS_APID    = '03a0'xu
XRS_APID    = '03a1'xu
EUVS_A_APID = '03a2'xu
EUVS_B_APID = '03a3'xu
EUVS_C_APID = '03b0'xu + uindgen(NUM_EUVSC_APIDS) ; 03b0-03b7
TIME_DRIFT_APID='038c'xu

SC_PVA_APID      = 384 ; Attitude and Orbit Telemetry
SC_ANG_RATE_APID = 385 ; Angular Rate Telemetry
; Eclipse 173
; Yaw flip 164
; Solar array current 163

;
;  30) Define CCSDS pri and sec structures
;
PRI_HDR_LEN = 6u  ; 6 byte primary header
SEC_HDR_LEN = 13u ; 13 byte secondary header
;SEC_HDR_LEN = 10u ; 10 byte secondary header
CCSDS_PRI_HDR = { CCSDS_PRI_HDR, $
                  ver_num: 0b, $       ;  3-bits 000b
                  type: 0b, $          ;  1 bit  0b
                  sec_hdr_flag: 1b, $  ;  1 bit  (1 dec)
                  apid: 0u, $          ; 11-bits varies with source
                  seq_flag: 3b, $      ;  2-bits (3 dec) '11'b
                  pkt_seq_count: 0u, $ ; 14-bits incrementing
                  pkt_len: 0u $        ; 16-bits (n_bytes - 1)
                }

USERFLAGS_STRUCTURE_RECORD = { USERFLAGS_STRUCTURE, $
                  TimeValid:1b, $ ; MSB bit (#0)
                  FSWBootRam:1b, $ ; bit#1 0=boot, 1=RAM
                  ExisPowerAB:1b, $ ; bits#2-3 0=sideB, 1=sideA, 2,3=both (BAD)
                  ExisMode:1b, $ ; bits#4-7 (lookup defs)
                  FM:'ff'xb, $ ; flight model number 1-4, sim='ff' (8 bits)
                  configID:0U } ; configuration ID (16 bits)

CCSDS_SEC_HDR = { CCSDS_SEC_HDR, $
                  day:0UL, $        ; 24-bits, days since epoch (Jan 1, 2000)
                  millisec: 0UL, $  ; 32-bits (milliseconds)
                  microsec: 0u, $   ; 16 bits (microseconds)
                  userflags: 0UL, $  ; all 32-bits used in version 12 11/04/10
                  uf:USERFLAGS_STRUCTURE_RECORD $
                } ;refer to GIRD453 (3.2.5.7.4 time code format)
                ;  fill: 0b, $       ; unused 8-bits
                ;  userflags: 0UL $  ; 32-bits of unknown user flags
                ;} ;refer to GIRD453 (3.2.5.7.4 time code format)

           

;
;  40) Define EUVS-C structure
;
;EUVS_C_DATA_ARR_LEN = 1024u ; 512*2 bytes + ?? eng? ;;; NUMBER OF BYTES
NUM_EUVS_C_DIODES_PER_INTEG = 512L
NUM_EUVS_C_DIODES_PER_PACKET = 64L
NUM_EUVS_C_ENG_BYTES = 0u
EUVS_C_DATA_ARR_LEN = uint(2*NUM_EUVS_C_DIODES_PER_PACKET + $
                           NUM_EUVS_C_ENG_BYTES) ; 64*2 bytes + ?? eng?

EXIS_EUVS_C_PKT = { EXIS_EUVS_C_PKT, $
                    hdr_arr: bytarr(PRI_HDR_LEN), $
                    hdr: CCSDS_PRI_HDR, $
                    sec_hdr_arr: bytarr(SEC_HDR_LEN), $ ;P-Field only (no T-field)
                    sec_hdr: CCSDS_SEC_HDR, $
                    yyyydoy: 0L, $ ; 7-digit year and day of year (1-366)
                    yyyymmdd: 0L, $ ; 8-digit year, month, day
                    sod:0.0d, $    ; seconds of day

                    data_arr: bytarr(EUVS_C_DATA_ARR_LEN), $
                    ;data: uintarr(64) $ ;8 packets with 64-diodes
                    data: uintarr(NUM_EUVS_C_DIODES_PER_PACKET), $ ;1 packet with 512-diodes

                    ModeReg:  '01110111'b, $ ; 7 used bits - pixelmode:01,adcmode:11,unused0,scanmode:1,flushcnt:11
                    ControlStatReg: 1b, $ ; 1 bit - set is continuous
                    PwrStatus:      5b, $ ; 4 bits - LSB c2power,c1power,select,enable (5=c1, 11=c2)
                    IntegTime:      7b, $ ; 2 seconds is default

                    deadTime: 0b, $ ; 3 bits, time between readout and flush (25 ms units), non-zero for readout-noise
                    ff_power: 0b, $
                    ff_level: 0u, $

                    ifBoardTemp: 44000u, $
                    fpgaTemp: 44001u, $

                    pwrSupplyTemp: 44002u, $
                    caseHtrTemp: 44003u, $

                    euvscHtrTemp: 44004u, $
                    c1Temp: 23734u, $ ; range is -20 to +8 (16700 to 37240)

                    c2Temp: 23735u, $
                    adcTemp: 44007u, $

                    slitTemp: 44008u, $

                    invalid_flags:0b, $
                    detChg_cnt:65535u, $
                    ffChg_cnt:65535u, $

                    door_status:32b, $
                    ; bit#7: moving (yes=1, no=0) discard if moving
                    ; bit#6: ccw=1 (cw=0) don't care
                    ; bit#5: known=1 (unknown=0 discard if unknown)
                    ; bit#4: abs=1 (rel=0) don't care
                    ; bit#3-0: idle=0 discard all other operation states
                                        
                    filter_status:32b, $
                    ; bit#7: moving (yes=1, no=0) discard if moving
                    ; bit#6: ccw=1 (cw=0) don't care
                    ; bit#5: known=1 (unknown=0 discard if unknown)
                    ; bit#4: abs=1 (rel=0) don't care
                    ; bit#3-0: idle=0 discard all other operation states

                    door_pos: OPEN_DOOR_POSITION, $
                    filter_pos: PRIMARY_SCIENCE_FILTER_POSITION, $
                    
                    xrs_euvs_mode: 0b, $
                    fovFlags: 0b $
}
EXIS_EUVS_C_PKT.hdr.pkt_len = 185L - 1 - PRI_HDR_LEN ; n bytes - 1 - pri hdr

;
;   50) Define XRS structure
;
NUM_XRS_DIODES = 12L ; 12 diodes in A & B
XRS_RAW_DATA_LEN = NUM_XRS_DIODES * 4L ; number of bytes
EXIS_XRS_PKT = { EXIS_XRS_PKT, $
                 hdr_arr: bytarr(PRI_HDR_LEN), $
                 hdr: CCSDS_PRI_HDR, $
                 sec_hdr_arr: bytarr(SEC_HDR_LEN), $ ;P-Field only (no T-field)
                 sec_hdr: CCSDS_SEC_HDR, $
                 yyyydoy: 0L, $     ; 7-digit year and day of year (1-366)
                 yyyymmdd: 0L, $    ; 8-digit year, month, day
                 sod:0.0d, $        ; seconds of day
                 data_arr: bytarr(XRS_RAW_DATA_LEN), $
                 data:    ulonarr(NUM_XRS_DIODES), $
                 offsets: uintarr(NUM_XRS_DIODES), $

                 ; data & offsets
                 RunCtrl:     1b, $ ; run control register, 1=science, 2=cal (gain)
                 SciMode:     1b, $ ; science mode register
                 PwrStatus:  15b, $ ; power status register
                 IntegTime:   3b, $ ; integ time register

                 ff_power: 0b, $ ; 4-LSB bits bit#3=LED set1/2, bit#2-1=C,B,A,XRS(11b), bit#0=on/off
                 ff_level: 0u, $ ; stimLampOutput

                 ifBoardTemp:   44000u, $
                 fpgaTemp:      44001u, $
                 pwrSupplyTemp: 44002u, $

                 caseHtrTemp: 44003u, $
                 
                 asic1Temp: 44004u, $ ; range is -20 to +20 (16700 to 45070)
                 asic2Temp: 44005u, $
                 filterTemp:  44006u, $
                 magnetTemp:  44007u, $
                 
                 invalid_flags:0b, $
                 ; 1=int_time truncated (discard)
                 ; 2=flatfield chirp warning (discard)
                 ; 4=EDAC single bit err (ignore, fixed in hardware)
                 ; 8=EDAC multiple bit error (discard packet, data is corrupted somewhere)

                 detChg_cnt:65535u, $
                 ; detChg_cnt changes when runcntrl changes, discard all data less than 2, sticks at 65535
                 ffChg_cnt:65535u, $

                 ;asicCalRamp:0b, $ ; ignore, settable by ops so can't trust it
                 ;asicCalCyclesRemaining:0u, $

                 asicSciVDAC: 0u, $
                 asicCalVMin: 0u, $
                 asicCalVMax: 0u, $

                 calVstepUp:7b, $
                 calTstepUp:0b, $
                 calVstepDown:0b, $
                 calTstepDown:0b, $

                 xrs_euvs_mode:0b, $
                 fovFlags:0b $
                 ; 0x80= Unknown (discard)
                 ; 0x08= eclipse imminent or in progress(carry)
                 ; 0x04= lunar transit imminent or in progress (carry)
                 ; 0x02= planet transit (carry)
                 ; 0x01= offpoint maneuver
                 ; 0x00= normal solar observation
                 
               }
EXIS_XRS_PKT.hdr.pkt_len = 120L - 1 - PRI_HDR_LEN ; n bytes - 1

;
;   55) Define SPS structure
;
NUM_SPS_DIODES = 6L ; 4 diodes and 2 unused ASIC spaces
SPS_RAW_DATA_LEN = NUM_SPS_DIODES * 4L ; number of bytes
EXIS_SPS_PKT = { EXIS_SPS_PKT, $
                 hdr_arr: bytarr(PRI_HDR_LEN), $
                 hdr: CCSDS_PRI_HDR, $
                 sec_hdr_arr: bytarr(SEC_HDR_LEN), $ ;P-Field only (no T-field)
                 sec_hdr: CCSDS_SEC_HDR, $
                 yyyydoy: 0L, $     ; 7-digit year and day of year (1-366)
                 yyyymmdd: 0L, $    ; 8-digit year, month, day
                 sod:0.0d, $        ; seconds of day

                 data_arr: bytarr(SPS_RAW_DATA_LEN), $
                 data: ulonarr(NUM_SPS_DIODES), $
                 offsets: uintarr(NUM_SPS_DIODES), $

                 ; data and offsets
                 RunCtrl:    1b, $ ; 1=science, 2=cal (gain) (discard values with 2)
                 SciMode:    1b, $ ; 1=continuous mode, 0=only one integration (ignore)
                 PwrStatus:  3b, $ ; bit#1=power enable, bit#0=power good (ignore)
                 IntegTime:  0b, $ ; quarter second counter 0.25-64 seconds

                 ifBoardTemp:   44000u, $ ; range is 16700 ~ -20C to 49345 ~ +28C
                 fpgaTemp:      44001u, $
                 pwrSupplyTemp: 44002u, $
                 caseHtrTemp: 44003u, $

                 temperature: 44004u, $ ; sps temperature range is 16700 ~ -20C to 49345 ~ +28C

                 invalid_flags:0b, $ 
                 ; 1=int_time truncated (discard)
                 ; 2=flatfield chirp warning (discard)
                 ; 4=EDAC single bit err (ignore, fixed in hardware)
                 ; 8=EDAC multiple bit error (discard packet, data is corrupted somewhere)
                 
                 detChg_cnt:65535u, $
                 ; changes when runcntrl changes, discard all data less than 2, sticks at 65535

                 ;asicCalRamp:0b, $ ; select=0 (no cal), 1=1pA, 2=2pA, 3=3pA, 4=4pA ignore all
                 ;asicCalCyclesRemaining:0u, $
                 
                 asicSciVDAC: 0u, $
                 asicCalVMin: 0u, $
                 asicCalVMax: 0u, $

                 calVstepUp:7b, $
                 calTstepUp:0b, $
                 calVstepDown:0b, $
                 calTstepDown:0b, $

                 xrs_euvs_mode:0b, $
                 fovFlags:0b $ 
                 ; 0x80= Unknown (discard)
                 ; 0x08= eclipse imminent or in progress(carry)
                 ; 0x04= lunar transit imminent or in progress (carry) 
                ; 0x02= planet transit (carry)
                 ; 0x01= offpoint maneuver
                 ; 0x00= normal solar observation
               }
EXIS_SPS_PKT.hdr.pkt_len = 79L - 1 -PRI_HDR_LEN ; n bytes - 1

;
;   60) Define EUVS-A structure
;
NUM_EUVS_A_DIODES = 24L; 24 diodes in A & B
EUVS_A_RAW_DATA_LEN = NUM_EUVS_A_DIODES * 4L ; number of bytes
EXIS_EUVS_A_PKT = { EXIS_EUVS_A_PKT, $
                    hdr_arr: bytarr(PRI_HDR_LEN), $
                    hdr: CCSDS_PRI_HDR, $
                    sec_hdr_arr: bytarr(SEC_HDR_LEN), $ ;P-Field only (no T-field)
                    sec_hdr: CCSDS_SEC_HDR, $
                    yyyydoy: 0L, $ ; 7-digit year and day of year (1-366)
                    yyyymmdd: 0L, $ ; 8-digit year, month, day
                    sod:0.0d, $     ; seconds of day

                    data_arr: bytarr(EUVS_A_RAW_DATA_LEN), $
                    data: ulonarr(NUM_EUVS_A_DIODES), $
                    offsets: uintarr(NUM_EUVS_A_DIODES), $

                    ; data and offsets

                    RunCtrl:     1b, $ ; 1=science, 2=cal (gain) (discard values with 2)
                    SciMode:     1b, $ ; 1=continuous mode, 0=only one integration (ignore)
                    ;PwrStatus:   3b, $ ; bit#1=power enable, bit#0=power good (ignore)
                    PwrStatus:   15b, $ ; bit#1=power enable, bit#0=power good (ignore) 5-8-15 DLW Updated for Proper PwrStatus Value
                    IntegTime:   3b, $

                    ff_power: 0b, $ ; 4-LSB bits bit#3=LED set1/2, bit#2-1=C,B,A,XRS(11b), bit#0=on/off
                    ff_level: 0u, $

                    ifBoardTemp:   44000u, $
                    fpgaTemp:      44001u, $
                    pwrSupplyTemp: 44002u, $

                    caseHtrTemp: 44003u, $

                    aTemp: 44004u, $ ; range -20 to +20 (16700 to 45070)
                    bTemp: 44005u, $

                    slitTemp: 44006u, $
                 
                    invalid_flags:0b, $
                    detChg_cnt:65535u, $
                    ffChg_cnt:65535u, $

                    asicSciVDAC: 0u, $
                    asicCalVMin: 0u, $
                    asicCalVMax: 0u, $

                    calVstepUp:7b, $
                    calTstepUp:0b, $
                    calVstepDown:0b, $
                    calTstepDown:0b, $
                    
                    door_status:   32b, $ 
                    ; bit#7: moving (yes=1, no=0) discard if moving
                    ; bit#6: ccw=1 (cw=0) don't care
                    ; bit#5: known=1 (unknown=0 discard if unknown)
                    ; bit#4: abs=1 (rel=0) don't care
                    ; bit#3-0: idle=0 discard all other operation states
                    
                    filter_status: 32b, $
                    ; bit#7: moving (yes=1, no=0) discard if moving
                    ; bit#6: ccw=1 (cw=0) don't care
                    ; bit#5: known=1 (unknown=0 discard if unknown)
                    ; bit#4: abs=1 (rel=0) don't care
                    ; bit#3-0: idle=0 discard all other operation states

                    door_pos:   OPEN_DOOR_POSITION, $
                    filter_pos: PRIMARY_SCIENCE_FILTER_POSITION, $

                    xrs_euvs_mode:0b, $
                    fovFlags:0b $ 
                    ; 0x80= Unknown (discard)
                    ; 0x08= eclipse imminent or in progress(carry)
                    ; 0x04= lunar transit imminent or in progress (carry)
                    ; 0x02= planet transit (carry)
                    ; 0x01= offpoint maneuver
                    ; 0x00= normal solar observation
               }
EXIS_EUVS_A_PKT.hdr.pkt_len = 182L - 1 - PRI_HDR_LEN ; n bytes - 1

;
;   70) Define EUVS-B structure
;
NUM_EUVS_B_DIODES   = NUM_EUVS_A_DIODES
EUVS_B_RAW_DATA_LEN = EUVS_A_RAW_DATA_LEN
EXIS_EUVS_B_PKT     = EXIS_EUVS_A_PKT
;EXIS_EUVS_B_PKT.hdr.pkt_len = SEC_HDR_LEN + EUVS_B_RAW_DATA_LEN - 1
EXIS_EUVS_B_PKT.hdr.pkt_len = EXIS_EUVS_A_PKT.hdr.pkt_len ;same as EUVS-A




;
; science structures
;
; common use structures
ff_cal = { power: 0b, level:0u, pwr_enable:0b, pri_red:0b, channel:0b, english:'Off' } ;xrs, euvsab, euvs_c
; power is broken into pwr_enable, pri_red and channel indicator
; 0=euvsc, 1=euvsa, 2=euvsb, 3=xrs

fsw = { invalidFlags:0b, detChg_cnt:0u, ffChg_cnt:0u, xrsEuvsMode:0b, fovFlags:0b }

;ASIC cal record
exis_cal_rec = { SciVDAC:0u, CalVMin:0u, CalVMax:0u, $
                 calVstepUp:0u, calTstepUp:0u, calVstepDown:0u, calTstepDown:0u }

asic_rec = { runCtrl:0b, SciMode:0b, pwrStatus:0b, integTime:0b, $
             cal:exis_cal_rec } ;sps,xrs,euvsab
c_reg = { ModeReg:0b, ControlStatReg:0b, pwrStatus:0b, integTime:0b, deadTime:0b} ;euvs_c

exis_mech = { doorStatus:0b, filterStatus:0b, doorPosition:0b, filterPosition:0b }

exis_time_rec = {exis_time_rec, yd:0L, sod:0.d0, df:0.d0, microSecondsSinceEpoch:0ULL, hms:' ' } ;derived from sec_hdr (all)

exis_sps_sci = { pri_hdr:CCSDS_pri_hdr, $
                 sec_hdr:CCSDS_sec_hdr, $                  ;standard headers
                 diodes:lonarr(NUM_SPS_DIODES), offset:intarr(NUM_SPS_DIODES), $
                 current:fltarr(NUM_SPS_DIODES), $
                 asic:asic_rec, $
                 fsw:fsw, $
                 ifBoardTemp:0u, fpgaTemp:0u, pwrSupplyTemp:0u, caseHtrTemp:0u,  $
                 temperature:0u, $
                 time:exis_time_rec $ ;derived info
               }

exis_xrs_sci = { pri_hdr:CCSDS_pri_hdr, $
                 sec_hdr:CCSDS_sec_hdr, $                  ;standard headers
                 diodes:lonarr(NUM_XRS_DIODES), offset:intarr(NUM_XRS_DIODES), $
                 current:fltarr(NUM_XRS_DIODES), $ ; gain & inttime factors
                 signal:fltarr(NUM_XRS_DIODES), $ ; dark subtracted
                 asic:asic_rec, $
                 fsw:fsw, $
                 ff:ff_cal, $
                 ifBoardTemp:0u, fpgaTemp:0u, pwrSupplyTemp:0u, caseHtrTemp:0u,  $
                 asic1Temp:0u, $
                 asic2Temp:0u, $
                 filterTemp:0u, magnetTemp:0u, $
                 time:exis_time_rec $ ;derived info
               }

exis_euvsab_sci = { pri_hdr:CCSDS_pri_hdr, $
                    sec_hdr:CCSDS_sec_hdr, $    ;standard headers
                    diodes:lonarr(NUM_EUVS_A_DIODES), offset:intarr(NUM_EUVS_A_DIODES), $
                    current:fltarr(NUM_EUVS_A_DIODES), $
                    asic:asic_rec, $
                    fsw:fsw, $
                    ff:ff_cal, $
                  ;  door_status:0b, $
                  ;  filter_status:0b, $
                  ;  door_pos:0b, $
                  ;  filter_pos:0b, $
                    ifBoardTemp:0u, fpgaTemp:0u, pwrSupplyTemp:0u, caseHtrTemp:0u, $
                    aTemp:0u, $
                    bTemp:0u, slitTemp:0u, $
                    exis_mech: exis_mech, $
                    time:exis_time_rec $ ;derived info
                  }

EXIS_EUVSC_SCI = { pri_hdr: CCSDS_PRI_HDR, $
                   sec_hdr: CCSDS_SEC_HDR, $
                   reg:c_reg, $
                   ;integTime:0b, $ ; in cal
                  ; door_status:0b, $
                  ; filter_status:0b, $
                  ; door_pos:0b, $
                  ; filter_pos:0b, $
                   ifBoardTemp:0u, fpgaTemp:0u, pwrSupplyTemp:0u, caseHtrTemp:0u, $
                   euvsCHtrTemp:0u, $
                   c1Temp:0u, $
                   c2Temp:0u, $
                   adcTemp:0u, $
                   slitTemp:0u, $
                   time:exis_time_rec, $
                   fsw:fsw, $
                   ff:ff_cal, $
                   exis_mech: exis_mech, $
;                   xrsEuvsMode:0b, $ ; in fsw
;                   fovFlags:0b, $
                   decoded_data:lonarr(NUM_EUVS_C_DIODES_PER_INTEG), $ ; 512 32-bit signed numbers
                   data: uintarr(NUM_EUVS_C_DIODES_PER_INTEG) $ ;512 16-bit numbers

}

; Define the ABI/Spacecraft packets
SC_PVA = { SC_PVA, $
           pri_hdr_arr: bytarr(PRI_HDR_LEN), $
           pri_hdr: CCSDS_PRI_HDR, $
           sec_hdr_arr: bytarr(SEC_HDR_LEN), $ ;P-Field only (no T-field)
           sec_hdr: CCSDS_SEC_HDR, $
           yyyydoy: 0L, $           ; 7-digit year and day of year (1-366)
           yyyymmdd: 0L, $          ; 8-digit year, month, day
           sod:0.0d, $              ; seconds of day
           time:exis_time_rec, $    ;derived info
           sc_quaternion: fltarr(4), $
           postime: CCSDS_SEC_HDR, $ ; position time stamp
           sc_position: fltarr(3), $
           sc_velocity: fltarr(3) $
         }

;
;   80) Define Time Drift Structure
;
td_rec = { TIMEDRIFT_RECORD, localTimeState:0b, $
           pendDay:0L, pendMillisec:0UL, pendMicrosec:0u, $
           freewheelCnt:0u, spwLinkRxTimeTick:0b, $
           lastDay:0l, lastMillisec:0UL, lastMicrosec:0u, $
           scTimeMsgNotRecvdCnt:0b, scTimeCodeNotRecvdCnt:0b, $
           spwLinkRxTimePrevMaxMicrosec:0UL }
EXIS_TIMEDRIFT = { EXIS_TIMEDRIFT, $
                   hdr_arr: bytarr(PRI_HDR_LEN), $
                   PRI_hdr: CCSDS_PRI_HDR, $
                   sec_hdr_arr: bytarr(SEC_HDR_LEN), $ ;P-Field only (no T-field)
                   sec_hdr: CCSDS_SEC_HDR, $
                   yyyydoy: 0L, $   ; 7-digit year and day of year (1-366) from sec hdr
                   yyyymmdd: 0L, $  ; 8-digit year, month, day
                   sod:0.0d, $      ; seconds of day
                   td:replicate(td_rec,5), $ ; 5 1-second samples per packet
                   time:exis_time_rec $     ;derived info
                 }
EXIS_TIMEDRIFT.pri_hdr.pkt_len = 160L - 1 - PRI_HDR_LEN ; n bytes - 1 - pri hdr


;
;   90) Define APID146 a TVAC temperature gound packet structure
; ONLY VALID FOR FM1
;
;
EXIS_APID146_PKT = { EXIS_APID146_PKT, $
                     FSW_TLM_OBC_146: 0b, $ ;	UINT	8	0
                     FSW_TLM_CRC_146: 0u, $ ;	UINT	16	8
                     FSW_TLM_OBCSIDE_146: 0b, $ ;	UINT	8	24
                     TC_ABI_LHP_RETURN_1: 0.,$  ;	FLT	32	32
                     TC_ABI_LHP_RETURN_2: 0.,$  ;	FLT	32	64
                     TC_ABI_CCHP1_1: 0.,$       ;	FLT	32	96
                     TC_ABI_CCHP1_2: 0.,$       ;	FLT	32	128
                     TC_ABI_CCHP1_3: 0.,$       ;	FLT	32	160
                     TC_ABI_CCHP2_1: 0.,$       ;	FLT	32	192
                     TC_ABI_CCHP2_2: 0.,$       ;	FLT	32	224
                     TC_ABI_CCHP2_3: 0.,$       ;	FLT	32	256
                     TC_ABI_OPSA1: 0.,$         ;	FLT	32	288
                     TC_ABI_OPSA2: 0.,$         ;	FLT	32	320
                     TC_ABI_OPSA3: 0.,$         ;	FLT	32	352
                     TC_ABI_OPSA4: 0.,$         ;	FLT	32	384
                     TC_ABI_OPSA5: 0.,$         ;	FLT	32	416
                     TC_ABI_OPSA6: 0.,$         ;	FLT	32	448
                     TC_ABI_OPSA7: 0.,$         ;	FLT	32	480
                     TC_ABI_OPSA8: 0.,$         ;	FLT	32	512
                     ; SPARE	FLT	32	544
                     ; SPARE	FLT	32	576
                     ; SPARE	FLT	32	608
                     ; SPARE	FLT	32	640
                     TC_EXIS_EUVS_TOP: 0.,$ ;	FLT	32	672
                     TC_EXIS_EUVS_CHAN_C: 0.,$ ;	FLT	32	704
                     TC_EXIS_EXEB_TOP: 0.,$    ;	FLT	32	736
                     TC_EXIS_EUVS_BAFFLE: 0.,$ ;	FLT	32	768
                     TC_EXIS_XRS_HOUSING: 0.,$ ;	FLT	32	800
                     TC_EXIS_MAGNET: 0.,$      ;	FLT	32	832
                     TC_EXIS_SPS_STIMULUS: 0.,$ ;	FLT	32	864
                     ; SPARE	FLT	32	896
                     ; SPARE	FLT	32	928
                     ; SPARE	FLT	32	960
                     TC_SUVI_STS_CCD_RAD: 0.,$ ;	FLT	32	992
                     TC_SUVI_STS_CEB_RAD: 0.,$ ;	FLT	32	1024
                     TC_SUVI_SEB_PZ: 0.,$      ;	FLT	32	1056
                     TC_SUVI_SEB_MZ: 0.,$      ;	FLT	32	1088
                     TC_SUVI_STS_TEL_FWD: 0.,$ ;	FLT	32	1120
                     TC_SUVI_STS_TEL_AFT: 0.,$ ;	FLT	32	1152
                     TC_SUVI_STS_FAA_HSG: 0.,$ ;	FLT	32	1184
                     TC_SUVI_STS_GTA_FWD: 0.,$ ;	FLT	32	1216
                     TC_GLM_HOPA_1: 0.,$       ;	FLT	32	1248
                     TC_GLM_HOPA_2: 0.,$       ;	FLT	32	1280
                     TC_GLM_DOOR_LID: 0.,$     ;	FLT	32	1312
                     TC_GLM_DR_BEARING: 0.,$   ;	FLT	32	1344
                     TC_GLM_DR_BEARING_BLK: 0.,$ ;	FLT	32	1376
                     TC_GLM_FIBER_OGSE: 0.,$     ;	FLT	32	1408
                     TC_GLM_BAFFLE_BOT: 0.,$     ;	FLT	32	1440
                     TC_GLM_BAFFLE_MID: 0.,$     ;	FLT	32	1472
                     TC_GLM_BAFFLE_TOP: 0.,$     ;	FLT	32	1504
                     ; SPARE	FLT	32	1536
                     TC_SEISS_1: 0.,$ ;	FLT	32	1568
                     TC_SEISS_2: 0.,$ ;	FLT	32	1600
                     TC_SEISS_3: 0.,$ ;	FLT	32	1632
                     TC_SEISS_4: 0.,$ ;	FLT	32	1664
                     TC_SEISS_5: 0.,$ ;	FLT	32	1696
                     TC_SEISS_6: 0.,$ ;	FLT	32	1728
                     ; SPARE	FLT	32	1760
                     ; SPARE	FLT	32	1792
                     ; SPARE	FLT	32	1824
                     ; SPARE	FLT	32	1856
                     hdr_arr: bytarr(PRI_HDR_LEN), $
                     hdr: CCSDS_PRI_HDR, $
                     sec_hdr_arr: bytarr(SEC_HDR_LEN), $ ;P-Field only (no T-field)
                     sec_hdr: CCSDS_SEC_HDR, $
                     pri_hdr:CCSDS_pri_hdr, $
                     ;sec_hdr:CCSDS_sec_hdr, $ ;standard headers
                     time: exis_time_rec, $
                     yyyydoy: 0L, $ ; 7-digit year and day of year (1-366)
                     yyyymmdd: 0L, $ ; 8-digit year, month, day
                     sod:0.0d $      ; seconds of day
                   }
EXIS_APID146_PKT.hdr.pkt_len = 244L - 1 -PRI_HDR_LEN ; n bytes - 1
;
; FM2 changed apid 145 to have all the EXIS thermistors
; disregard APID146 from now on
; decomposition for apdi 145 based on spreadsheet
; APID_146_145_02122017.xlsx received from Tyler Redick Feb 21, 2017
EXIS_APID145_PKT = { EXIS_APID145_PKT, $
                     FSW_TLM_OBC_145: 0b, $ ;	UINT	8	0
                     FSW_TLM_CRC_145: 0u, $ ;	UINT	16	8
                     FSW_TLM_OBCSIDE_145: 0b, $ ;	UINT	8	24
                     TC_EXIS_SPP_PX1_PY: 0.,$  ;	FLT	32	32
                     TC_EXIS_SPP_PX2_PY: 0.,$  ;	FLT	32	64
                     TC_EXIS_SPP_MZ_PY: 0.,$  ;	FLT	32	96
                     TC_EXIS_SPP_PY1_MZ: 0.,$  ;	FLT	32	128
                     TC_EXIS_SPP_PY1_PZ: 0.,$  ;	FLT	32	160
                     TC_EXIS_EUVS_TOP: 0.,$  ;	FLT	32	92
                     TC_EXIS_EUVS_CHANN_C: 0.,$  ;	FLT	32	224
                     TC_EXIS_EXEB_TOP: 0.,$  ;	FLT	32	256
                     TC_EXIS_EUVS_BAFFLE: 0.,$  ;	FLT	32	288
                     TC_EXIS_XRS_HOUSING: 0.,$  ;	FLT	32	320
                     TC_EXIS_MAGNET: 0.,$  ;	FLT	32	352
                     TC_EXIS_SPS_STIMULUS: 0.,$  ;	FLT	32	384
                     TC_EXIS_TC938: 0.,$  ;	FLT	32	416
                     ; SPARE	FLT	32	448
                     ; SPARE	FLT	32	480
                     TC_SEISS_CAB_HP_Pair_TC601: 0.,$  ;	FLT	32	512
                     TC_SEISS_CAB_HP_Pair_TC602: 0.,$  ;	FLT	32	544
                     TC_SEISS_CAB_PY_TC603: 0.,$  ;	FLT	32	576
                     TC_SEISS_CAB_PY_TC604: 0.,$  ;	FLT	32	608
                     TC_SEISS_CAB_PY_TC605: 0.,$  ;	FLT	32	640
                     TC_SEISS_CAB_MID_TC613: 0.,$  ;	FLT	32	672
                     TC_SEISS_CAB_MID_TC614: 0.,$  ;	FLT	32	704
                     TC_SEISS_CAB_MID_TC615: 0.,$  ;	FLT	32	736
                     TC_SEISS_CAB_MY_TC623: 0.,$  ;	FLT	32	768
                     TC_SEISS_CAB_MY_TC624: 0.,$  ;	FLT	32	800
                     TC_SEISS_CAB_MY_TC625: 0.,$  ;	FLT	32	832
                     TC_SEISS_CAB_PX_SGPS: 0.,$  ;	FLT	32	864
                     TC_SEISS_TC925: 0.,$  ;	FLT	32	896
                     TC_SEISS_TC926: 0.,$  ;	FLT	32	928
                     TC_SEISS_TC927: 0.,$  ;	FLT	32	960
                     ; SPARE	FLT	32	992
                     ; SPARE	FLT	32	1024

                     TC_SUVI_SPP_TEMP5: 0.,$  ;	FLT	32	1056
                     TC_SUVI_SPP_TEMP6: 0.,$  ;	FLT	32	1088
                     TC_SUVI_SPP_TEMP7: 0.,$  ;	FLT	32	1120
                     TC_SUVI_SPP_TEMP8: 0.,$  ;	FLT	32	1152
                     TC_SUVI_SPP_PX3_MY: 0.,$  ;	FLT	32	1184
                     TC_SUVI_SPP_PX3_PY: 0.,$  ;	FLT	32	1216
                     TC_SUVI_SPP_PX4_PY: 0.,$  ;	FLT	32	1248
                     TC_SUVI_SPP_PY2_MZ: 0.,$  ;	FLT	32	1280
                     TC_SUVI_SPP_PY3_MZ: 0.,$  ;	FLT	32	1312
                     TC_SUVI_SPP_PZ_PY: 0.,$  ;	FLT	32	1344
                     TC_SUVI_SPP_PX3_MID: 0.,$  ;	FLT	32	1376
                     TC_SUVI_SPP_PX4_MID: 0.,$  ;	FLT	32	1408
                     TC_SUVI_STS_CCD_RAD: 0.,$  ;	FLT	32	1440
                     TC_SUVI_STS_CEB_RAD: 0.,$  ;	FLT	32	1472
                     TC_SUVI_SEB_EXT_PZ: 0.,$  ;	FLT	32	1504
                     TC_SUVI_SEB_EXT_MZ: 0.,$  ;	FLT	32	1536
                     TC_SUVI_STS_TEL_FWD: 0.,$  ;	FLT	32	1568
                     TC_SUVI_STS_TEL_AFT: 0.,$  ;	FLT	32	1600
                     TC_SUVI_STS_FAA_HSG: 0.,$  ;	FLT	32	1632
                     TC_SUVI_STS_GTA_FWD: 0.,$  ;	FLT	32	1664
                     TC_SUVI_TC935: 0.,$  ;	FLT	32	1696
                     TC_SUVI_TC936: 0.,$  ;	FLT	32	1728
                     TC_SUVI_TC937: 0.,$  ;	FLT	32	1760
                     ; SPARE	FLT	32	1824
                     ; SPARE	FLT	32	1856

                     hdr: CCSDS_PRI_HDR, $
                     sec_hdr_arr: bytarr(SEC_HDR_LEN), $ ;P-Field only (no T-field)
                     sec_hdr: CCSDS_SEC_HDR, $
                     pri_hdr:CCSDS_pri_hdr, $
                     ;sec_hdr:CCSDS_sec_hdr, $ ;standard headers
                     time: exis_time_rec, $
                     yyyydoy: 0L, $ ; 7-digit year and day of year (1-366)
                     yyyymmdd: 0L, $ ; 8-digit year, month, day
                     sod:0.0d $      ; seconds of day
                   }
EXIS_APID145_PKT.hdr.pkt_len = 236L - 1 ; n bytes - 1
;
