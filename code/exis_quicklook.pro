; docformat = 'rst'

;+
; :Author:
;   Don Woodraska
;
; :Copyright:
;    Copyright 2012 The Regents of the University of Colorado.
;    All rights reserved. This software was developed at the
;    University of Colorado's Laboratory for Atmospheric and 
;    Space Physics. 
;
; :Version:
;    $Id: exis_quicklook.pro 81638 2019-05-24 13:55:21Z dlwoodra $
;
;-


;forward_function dataserverSocketIsOn;, dataTimeStampToStr ;, getNewImageAction

;+
; Tries to setup the socket connection if needed, returns success=1(connected) or failure=0(not connected).
; Uses hte Dataserver_common common block for the socket_un and hostname variables. If the connection is
; refused the socket_lun is set to -1, an invalid lun
;
; :Params:
;    just_made_connection: out, optional, type=int
;
; :Returns:
;   success=1 (connected) or failure=0 (not connected)
;
;-
function dataserverSocketIsOn, just_made_connection

common DataServer_common, socket_lun, hostname

proc_name = 'dataserverSocketIsOn: '
just_made_connection = 0

if n_elements( hostname ) eq 0 then return, 0
if strlen( hostname ) eq 0 then return, 0

need_to_open_socket = 0
if n_elements( socket_lun ) eq 0 then begin
  need_to_open_socket = 1
endif else if socket_lun eq -1 then begin
  need_to_open_socket = 1
endif

if need_to_open_socket then begin
  on_ioerror, CONNECTION_REFUSED
  
  ;Bug Note:  On Mac OS X, if timeouts are 0.1, works same as on Sun OS.
  ;If 0.01, readu blocks for many seconds, then finally unblocks, flooding 
  ;the app with a huge buffer of packets.
  
  ; DLW 12/01/08 Modified port per Steve's email
  ;socket, socket_lun, hostname, 5021, /RAWIO, /GET_LUN, read_timeout=0.1, write_timeout=0.1
  port_number = 7653 ; changed port for slimer OIS sep 13, 2011
  socket, socket_lun, hostname, port_number, /RAWIO, /GET_LUN, read_timeout=0.1, write_timeout=0.1
  goto, CONNECTION_ACCEPTED
CONNECTION_REFUSED:
  socket_lun = -1
  print, 'Client connection refused by ' + hostname + '.'
  return, 0
CONNECTION_ACCEPTED:
  print, 'Connection accepted.'
  just_made_connection = 1
  return, 1
endif

return, 1
END


;+
; Reads as many packets as are present on the OIS socket, and discards
; non EXIS packets.  Decomposes EXIS packets into IDL structures using the
; decompose_* routines
;
; :Params:
;    packets : out, required, type=bytarr
;      length of bytarr is the full CCSDS packet length
;    n_packets : out, required
;      the number of packet that was read in this procedure call until the buffer became empty
;
; :Keywords:
;    do_plots : in, optional, type=boolean
;      use keyword to enable all plot windows (disabled by default)
;      Opposite of no_plots in exis_quicklook
;    do_files : in, optional, type=boolean
;      use keyword to enable output to all files (disabled by default)
;      Opposite of no_files in exis_quicklook
;    do_darkxrs : in, optional, type=boolean
;      use keyword to enable dark subtraction in the xrs target plot (disabled by default)
;      Opposite of no_darkxrs in exis_quicklook
;    zeroUTepoch : in, optional, type=boolean
;      Use this keyword to revert to the old (incorrect) epoch of Jan 1, 2000 at 0:00:00 UT. If this keyword is not provided, then the correct epoch is used (Jan 1, 2000 at 12:00:00 UT).
;    laser : in, optional, type=boolean
;      use keyword durign ELF testing when the laser is in use. Setting this flag will replace the last EUVS-C (sigma) plot with a zoom in of the laser line
;
; :Uses:
;    dataServerSocketIsOn
;    sendCmdToDataServer
;    readPacketFromDataServer
;    make_pri_hdr, update_pkt_count, make_sec_hdr
;    make_time_rec, make_user_flags
;    decompose_tdrift, plot_status_1, write_to_tdrift_file
;    decompose_sps, plot_sps, plot_spectrum_dn, write_to_sps_file
;    decompose_xrs, plot_xrs, write_to_xrs_file
;    decompose_euvsab, plot_euvsa, write_to_euvsa_file
;    plot_euvsb, write_to_euvsb_file 
;    decompose_euvsc_data, decompose_euvsc, plot_euvsc, write_to_euvsc_file
;
;-
pro getExisPacketsFromSocket, packets, n_packets, do_plots=do_plots, do_files=do_files,do_darkxrs=do_darkxrs, zeroUTepoch=zeroUTepoch,laser=laser

@gpds_defines.pro

common getExisPacketsFromSocket_cal, euvsa_rec, euvsb_rec, sps_rec, $
   euvsc_rec, time_rec, xrs_rec, tdrift_rec, cal_is_ready
common create_plots_windows_cal, wlist, window_ids
common last_packet_times, pkt_time_df

if size(pkt_time_df,/type) eq 0 then begin
   ; second elapsed since last packet received
   pkt_time_df={sps:-1.d6, euvsc:-1.d6, euvsa:-1.d6, euvsb:-1.d6, xrs:-1.d6}
endif

n_packets = 0
packets = 0
if dataserverSocketIsOn( just_made_connection) then begin
   if just_made_connection then begin
      print, 'Sending command to packet server...'
      sendCmdToDataServer, [time_drift_apid, sps_apid, xrs_apid, euvs_a_apid, euvs_b_apid, euvs_c_apid], success
      ;sendCmdToDataServer, 0, success
      print, 'success = ', strtrim( success,2)
   endif
   packet = -1

   ; init structures
   if size(cal_is_ready,/type) eq 0 then begin
      sps_rec = exis_sps_sci
      xrs_rec = exis_xrs_sci
      euvsa_rec = exis_euvsab_sci
      euvsb_rec = exis_euvsab_sci
      euvsc_rec = exis_euvsc_sci ; a new structure, assume data is read much faster than 0.25 sec
      time_rec  = exis_time_rec
      tdrift_rec= exis_timedrift
      cal_is_ready = 1
   endif

   while 1 do begin
    ;Read packets from the socket until there aren't any left.
      readPacketFromDataServer, buf
      if n_elements( buf ) eq 0 then break
      if n_elements( buf ) lt pri_hdr_len + sec_hdr_len - 1 then begin
         print,'ERROR: received malformed packet of length ',n_elements(buf)
         print,buf,form='('+n_elements(buf)+'(x,z2.2))'
      endif
      ; EXIS packets all have this primary header
      pri_hdr = make_pri_hdr( buf[0:pri_hdr_len-1] )
      if n_elements( buf ) lt pri_hdr_len + sec_hdr_len - 1 then begin
         print,'ERROR: malformed packet:'
         help,pri_hdr,/str
      endif

      ; track packet stats
      update_pkt_count, pri_hdr, do_plots=do_plots

      ; EXIS packets all have this secondary header
      base = pri_hdr_len + sec_hdr_len
      sec_hdr = make_sec_hdr( buf[pri_hdr_len:(base)-1] ) ;a struct

      make_time_rec, sec_hdr, time_rec, zeroUTepoch=zeroUTepoch

      ; known_apid is only used to check if the FM is correct
      ; we don't need to use all APIDs here, so one EUVS-C is enough
      known_apid = [sps_apid, xrs_apid, euvs_a_apid, euvs_b_apid,$
                    euvs_c_apid[7], time_drift_apid]


      ;known_apid=[928,929,930,931,944,945,946,947,948,949,950,951]
      ;known_name=["SPS","XRS","EUVS-A","EUVS-B","EUVS-C","EUVS-C","EUVS-C","EUVS-C","EUVS-C","EUVS-C","EUVS-C","EUVS-C","TDRIFT"]
      ; These are all known packets
      ; apid:33, name:isis_an
      ; apid:34, name:isis_em
      ; apid:147, name:sc_pkt
      ; apid:896, name:evtmsg
      ; apid:898, name:bfast
      ; apid:899, name:rfast
      ; apid:900, name:bmed
      ; apid:901, name:rmed
      ; apid:902, name:bslow
      ; apid:903, name:rslow
      ; apid:904, name:bsystem
      ; apid:905, name:rsystem
      ; apid:906, name:dump
      ; apid:907, name:dwell
      ; apid:908, name:tm_drft
      ; apid:909, name:memory
      ; apid:910, name:table
      ; apid:912, name:det
      ; apid:913, name:idac
      ; apid:928, name:sps
      ; apid:929, name:xrs
      ; apid:930, name:euvsa
      ; apid:931, name:euvsb
      ; apid:944, name:euvsc0
      ; apid:945, name:euvsc1
      ; apid:946, name:euvsc2
      ; apid:947, name:euvsc3
      ; apid:948, name:euvsc4
      ; apid:949, name:euvsc5
      ; apid:950, name:euvsc6
      ; apid:951, name:euvsc7

      make_user_flags, sec_hdr, user_flags
    ;  print,pri_hdr.apid

      ;
      ; check flight model number against environment variable
      ;
      wcheck=where(pri_hdr.apid eq known_apid,count)
      if count eq 1 and getenv('exis_type') ne 'etu' then $
         check_tlm_env_fm_consistency, pri_hdr.apid, user_flags.fm_designator, do_files=do_files


     ; check packet times for age
     ; erase stale plot windows
      if pri_hdr.apid eq 1280 or pri_hdr.apid eq 33 then begin
         ; do not compare/update times for zero packet times
      endif else begin
         for itag=0L,n_tags(pkt_time_df)-1 do begin
            if abs(time_rec.df - pkt_time_df.(itag)) gt 64 then begin
              ; found old stuff
               for jwin = 0,n_elements(window_ids.(itag))-1 do begin
                  wset,window_ids.(itag)[jwin]
                  erase
                  xyouts,/normal,align=.5,.5,.5,'No recent data'
                  ; now set to current time so it's cleared infrequently
                  pkt_time_df.(itag) = time_rec.df
               endfor
            endif
         endfor
      endelse


      status = 0

      ;print,long(pri_hdr.apid)
      case pri_hdr.apid of
         time_drift_apid: begin
         ;print,'TIMEDRIFT packet read'
            ; copy common use substructures
            tdrift_rec.pri_hdr = pri_hdr
            tdrift_rec.sec_hdr = sec_hdr
            tdrift_rec.time = time_rec
            ;extract data
            decompose_tdrift, buf, tdrift_rec

            ;   ; plot
            if keyword_set(do_plots) then begin
               ; plot_tdrift, stdrift_rec
               ; update status_1
               plot_status_1, xrs_rec, euvsa_rec, euvsb_rec, euvsc_rec, sps_rec;, do_files=do_files
            endif
            ; now save the tdrift_rec data
            if keyword_set(do_files) then write_to_tdrift_file, tdrift_rec
         end
         sps_apid: begin
            ;print,'SPS packet read'
            ; copy common use substructures
            sps_rec.pri_hdr = pri_hdr
            sps_rec.sec_hdr = sec_hdr
            sps_rec.time = time_rec
            ;extract data
            decompose_sps, buf, sps_rec

            ; plot
            if keyword_set(do_plots) then begin
               plot_sps, sps_rec, sps_rec.temperature, do_files=do_files
               plot_spectrum_dn, xrs_rec, euvsa_rec, euvsb_rec, sps_rec
            endif
            ; now save the sps_rec data
            if keyword_set(do_files) then write_to_sps_file, sps_rec
         end
         xrs_apid: begin
            ;print,'XRS packet read'
            ; copy common use substructures
            xrs_rec.pri_hdr = pri_hdr
            xrs_rec.sec_hdr = sec_hdr
            xrs_rec.time = time_rec
            ; extract data
            decompose_xrs, buf, xrs_rec, user_flags=user_flags, do_darkxrs=do_darkxrs

            ; plot
            if keyword_set(do_plots) then begin
               plot_xrs, xrs_rec, xrs_rec.asic1Temp, do_darkxrs=do_darkxrs, do_files=do_files
               plot_spectrum_dn, xrs_rec, euvsa_rec, euvsb_rec, sps_rec
              ; call plot_status_2
               plot_status_2, xrs_rec, euvsa_rec, euvsb_rec, euvsc_rec, sps_rec, tdrift_rec
            endif
            ; now save the xrs_rec data
            if keyword_set(do_files) then write_to_xrs_file, xrs_rec
         end
         euvs_a_apid: begin
            ;print,'EUVS-A packet read'
            ; copy common use substructures
            euvsa_rec.pri_hdr = pri_hdr
            euvsa_rec.sec_hdr = sec_hdr
            euvsa_rec.time = time_rec

            ; extract data
            decompose_euvsab, buf, euvsa_rec

            ; plot
            if keyword_set(do_plots) then begin
               plot_euvsa, euvsa_rec, euvsa_rec.aTemp
               plot_spectrum_dn, xrs_rec, euvsa_rec, euvsb_rec, sps_rec
            endif
            ; now save the euvsab_rec data
            if keyword_set(do_files) then write_to_euvsa_file, euvsa_rec
         end
         euvs_b_apid: begin
            ;print,'EUVS-B packet read'
            ; copy common use substructures
            euvsb_rec.pri_hdr = pri_hdr
            euvsb_rec.sec_hdr = sec_hdr
            euvsb_rec.time = time_rec
            decompose_euvsab, buf, euvsb_rec, /euvsb

            if keyword_set(do_plots) then begin
               plot_euvsb, euvsb_rec, euvsb_rec.bTemp
               plot_spectrum_dn, xrs_rec, euvsa_rec, euvsb_rec, sps_rec
            endif
            ; now save the euvsab_rec data
            if keyword_set(do_files) then write_to_euvsb_file, euvsb_rec
         end
         euvs_c_apid[0]: begin
            ; copy common use substructures
            euvsc_rec.pri_hdr = pri_hdr
            euvsc_rec.sec_hdr = sec_hdr
            euvsc_rec.time = time_rec
            ; sci.data is a uintarr, buf is a bytarr
            ;euvsc_rec.data[a[0]:b[0]] = ishft( uint( buf[lo:hi:2] ), 8) + uint(buf[lo+1:hi+1:2])
            decompose_euvsc_data, buf, euvsc_rec, 0 ;just the diodes
            decompose_euvsc, buf, euvsc_rec ; get the rest of the packet
         end
         euvs_c_apid[1]: begin
            decompose_euvsc_data, buf, euvsc_rec, 1 ; just the diodes
            ;euvsc_rec.data[a[1]:b[1]] = ishft( uint( buf[lo:hi:2] ), 8) + uint(buf[lo+1:hi+1:2])
         end
         euvs_c_apid[2]: begin
            decompose_euvsc_data, buf, euvsc_rec, 2 ; just the diodes
            ;euvsc_rec.data[a[2]:b[2]] = ishft( uint( buf[lo:hi:2] ), 8) + uint(buf[lo+1:hi+1:2])
         end
         euvs_c_apid[3]: begin
            decompose_euvsc_data, buf, euvsc_rec, 3 ; just the diodes
            ;euvsc_rec.data[a[3]:b[3]] = ishft( uint( buf[lo:hi:2] ), 8) + uint(buf[lo+1:hi+1:2])
         end
         euvs_c_apid[4]: begin
            decompose_euvsc_data, buf, euvsc_rec, 4 ; just the diodes
            ;euvsc_rec.data[a[4]:b[4]] = ishft( uint( buf[lo:hi:2] ), 8) + uint(buf[lo+1:hi+1:2])
         end
         euvs_c_apid[5]: begin
            decompose_euvsc_data, buf, euvsc_rec, 5 ; just the diodes
            ;euvsc_rec.data[a[5]:b[5]] = ishft( uint( buf[lo:hi:2] ), 8) + uint(buf[lo+1:hi+1:2])
         end
         euvs_c_apid[6]: begin
            decompose_euvsc_data, buf, euvsc_rec, 6 ; just the diodes
            ;euvsc_rec.data[a[6]:b[6]] = ishft( uint( buf[lo:hi:2] ), 8) + uint(buf[lo+1:hi+1:2])
         end
         euvs_c_apid[7]: begin
            if pri_hdr.pkt_seq_count ne euvsc_rec.pri_hdr.pkt_seq_count then begin
               print,'WARNING: euvsc out of order, pri_hdr.pkt_seq_count changed OR partial integration received'
               euvsc_rec.pri_hdr = pri_hdr
               euvsc_rec.sec_hdr = sec_hdr
               euvsc_rec.time = time_rec
               decompose_euvsc, buf, euvsc_rec ; get the rest of the packet
            endif

            decompose_euvsc_data, buf, euvsc_rec, 7 ; just the diodes
            ;euvsc_rec.data[a[7]:b[7]] = ishft( uint( buf[lo:hi:2] ), 8) + uint(buf[lo+1:hi+1:2])

            if keyword_set(do_plots) then plot_euvsc, euvsc_rec, laser=laser
            ; now save the euvsc_rec data
            if keyword_set(do_files) then write_to_euvsc_file, euvsc_rec
         end
         else: print,'.',format='(A1,$)'
;print, 'Received unwanted APID=' + strtrim( pri_hdr.apid, 2) + '!'
      endcase
      if status ne 0 then begin
         print,'printing error state message'
         print, !error_state.msg
         continue
      endif
;      packets = (size( packets, /TYPE) eq 2) ? ptr_new( packet) : [packets, ptr_new( packet)]
      n_packets = n_packets + 1

   endwhile


   if n_packets gt 0 then $
      print, 'getExisPacketsFromSocket read ' + strtrim( n_packets,2) + ' packets.'
endif
END


;+
; Read the packets one at a time from the specified file. Only desired EXIS packets are decomposed.
;
; :Keywords:
;    do_plots : in, optional, type=boolean
;      use keyword to enable all plot windows (disabled by default)
;      Opposite of no_plots in exis_quicklook
;    do_files : in, optional, type=boolean
;      use keyword to enable output to all files (disabled by default)
;      Opposite of no_files in exis_quicklook
;    ois_file : in, optional, type=boolean
;      set keyword to indicate the packetfile is an OIS 'raw record' file, not from the data simulator
;    do_darkxrs : in, optional, type=boolean
;      use keyword to enable dark subtraction in the xrs target plot (disabled by default)
;      Opposite of no_darkxrs in exis_quicklook
;    zeroUTepoch : in, optional, type=boolean
;      Use this keyword to revert to the old (incorrect) epoch of Jan 1, 2000 at 0:00:00 UT. If this keyword is not provided, then the correct epoch is used (Jan 1, 2000 at 12:00:00 UT).
;    laser : in, optional, type=boolean
;      use keyword durign ELF testing when the laser is in use. Setting this flag will replace the last EUVS-C (sigma) plot with a zoom in of the laser line
;    slowFileReplay   : in, optional, type=boolean
;      set this keyword to pause this many seconds when each SPS packet is decomposed in the pkt_file. This has no effect
;      unless reading data from from a file.
;
;  :Params:
;     pkt_file: in, optional, type=string
;       Pass in a fully qualified pathname to a binary telemetry file for (re)processing.
;       Note that OIS raw record files insert a 32-bit ground-receipt timestamp before each packet, 
;       so use /ois_file to read those files properly.
;
;-
pro getExisPacketsFromFile, packets, n_packets, pkt_file, do_plots=do_plots, do_files=do_files,ois_file=ois_file,do_darkxrs=do_darkxrs, zeroUTepoch=zeroUTepoch,laser=laser,slowFileReplay=slowFileReplay
common getExisPacketsFromFile, lun

@gpds_defines.pro

open_file=0 ; assume file is previously opened

if size(lun,/type) eq 0 then open_file=1 ; if undefined, open file for reading

if open_file eq 1 then begin
  ; is it compressed with gzip
  if strmid(pkt_file,strlen(pkt_file)-2,2) eq 'gz' then gz=1 else gz=0
  filename = pkt_file ;'tmpdata'
  openr, lun, filename, /get_lun, compress=gz
endif
n_packets = 0
packets = 0

if eof( lun) then begin
  close, lun
  lun = -1
endif
if lun eq -1 then return

; init structures
sps_rec = exis_sps_sci
xrs_rec = exis_xrs_sci
euvsa_rec = exis_euvsab_sci
euvsb_rec = exis_euvsab_sci
euvsc_rec = exis_euvsc_sci
time_rec  = exis_time_rec
tdrift_rec= exis_timedrift
sc_pva_rec = sc_pva
      
while not eof(lun) do begin

   ; ois record files have a 4 byte time stamp between packets, skip it
   if keyword_set(ois_file) then begin
     junktime = bytarr(4)
     readu, lun, junktime, transfer_count=junk_bytes_read
   endif
   
   ; read the ccsds primary header
   header_buf = bytarr( pri_hdr_len )
   readu, lun, header_buf, transfer_count=bytes_read
   ; read the rest of the packet
   bytes_to_read = ishft( uint( header_buf[4]), 8) + uint( header_buf[5] ) + 1u
   data_buf = bytarr( bytes_to_read )
   readu, lun, data_buf, transfer_count=bytes_read
   if bytes_read ne bytes_to_read then begin
      print, "ERROR: Didn't read bytes requested! eof?"
   endif
   buf = [header_buf, data_buf]

   ; EXIS packets all have this primary header
   pri_hdr = make_pri_hdr( buf[0:pri_hdr_len-1] )

   ; track packet stats
   update_pkt_count, pri_hdr, do_plots=do_plots

   ; EXIS packets all have this secondary header
   base = pri_hdr_len + sec_hdr_len
   sec_hdr = make_sec_hdr( buf[pri_hdr_len:(base)-1] ) ;a struct
   
   make_time_rec, sec_hdr, time_rec, zeroUTepoch=zeroUTepoch
   make_user_flags, sec_hdr, user_flags
   
   ;
   ; check flight model number against environment variable
   ;
   check_tlm_env_fm_consistency, user_flags.fm_designator, do_files=do_files

   status = 0

   case pri_hdr.apid of
      time_drift_apid: begin
         ;print,'TIMEDRIFT packet read'
            ; copy common use substructures
         tdrift_rec.pri_hdr = pri_hdr
         tdrift_rec.sec_hdr = sec_hdr
         tdrift_rec.time = time_rec
            ;extract data
         decompose_tdrift, buf, tdrift_rec

         ;   ; plot
         ;if keyword_set(do_plots) then begin
         ;   plot_tdrift, tdrift_rec
         ;endif
         ; now save the tdrift_rec data
         if keyword_set(do_files) then write_to_tdrift_file, tdrift_rec
      end
      sps_apid: begin
            ;print,'SPS packet read'
            ; copy common use substructures

         if size(slowFileReplay,/type) ne 0 then wait, (0.>slowFileReplay)<0.2
         ;if keyword_set(slowFileReplay) then wait,0.25

         sps_rec.pri_hdr = pri_hdr
         sps_rec.sec_hdr = sec_hdr
         sps_rec.time = time_rec
            ;extract data
         decompose_sps, buf, sps_rec

            ; plot
         if keyword_set(do_plots) then begin
            plot_sps, sps_rec, sps_rec.temperature, do_files=do_files
            ;plot_spectrum_dn, xrs_rec, euvsa_rec, euvsb_rec, sps_rec
         endif
         ; now save the sps_rec data
         if keyword_set(do_files) then write_to_sps_file, sps_rec
      end
      xrs_apid: begin
            ;print,'XRS packet read'
            ; copy common use substructures
         xrs_rec.pri_hdr = pri_hdr
         xrs_rec.sec_hdr = sec_hdr
         xrs_rec.time = time_rec
            ; extract data
         decompose_xrs, buf, xrs_rec, user_flags=user_flags, do_darkxrs=do_darkxrs

            ; plot
         if keyword_set(do_plots) then begin
            plot_xrs, xrs_rec, xrs_rec.asic1Temp, do_darkxrs=do_darkxrs, do_files=do_files
            ; update "spectrum"
            plot_spectrum_dn, xrs_rec, euvsa_rec, euvsb_rec, sps_rec, do_files=do_files
            ; update status_1
            plot_status_1, xrs_rec, euvsa_rec, euvsb_rec, euvsc_rec, sps_rec
            ; call plot_status_2
            plot_status_2, xrs_rec, euvsa_rec, euvsb_rec, euvsc_rec, sps_rec, tdrift_rec

         endif
         ; now save the xrs_rec data
         if keyword_set(do_files) then write_to_xrs_file, xrs_rec
      end
      euvs_a_apid: begin
            ;print,'EUVS-A packet read'
            ; copy common use substructures
         euvsa_rec.pri_hdr = pri_hdr
         euvsa_rec.sec_hdr = sec_hdr
         euvsa_rec.time = time_rec
            ; extract data
         decompose_euvsab, buf, euvsa_rec

            ; plot
         if keyword_set(do_plots) then plot_euvsa, euvsa_rec, euvsa_rec.aTemp
         ;; update "spectrum"
         ;plot_spectrum_dn, xrs_rec, euvsa_rec, euvsb_rec, sps_rec
         ; now save the euvsab_rec data
         if keyword_set(do_files) then write_to_euvsa_file, euvsa_rec
      end
      euvs_b_apid: begin
            ;print,'EUVS-B packet read'
            ; copy common use substructures
         euvsb_rec.pri_hdr = pri_hdr
         euvsb_rec.sec_hdr = sec_hdr
         euvsb_rec.time = time_rec
         decompose_euvsab, buf, euvsb_rec, /euvsb

         if keyword_set(do_plots) then plot_euvsb, euvsb_rec, euvsb_rec.bTemp
         ;; update "spectrum"
         ;plot_spectrum_dn, xrs_rec, euvsa_rec, euvsb_rec, sps_rec
         ; now save the euvsab_rec data
         if keyword_set(do_files) then write_to_euvsb_file, euvsb_rec
      end
      euvs_c_apid[0]: begin
            ; copy common use substructures
         euvsc_rec.pri_hdr = pri_hdr
         euvsc_rec.sec_hdr = sec_hdr
         euvsc_rec.time = time_rec
            ; sci.data is a uintarr, buf is a bytarr
            ;euvsc_rec.data[a[0]:b[0]] = ishft( uint( buf[lo:hi:2] ), 8) + uint(buf[lo+1:hi+1:2])
         decompose_euvsc_data, buf, euvsc_rec, 0 ;just the diodes
         decompose_euvsc, buf, euvsc_rec         ; get the rest of the packet
      end
      euvs_c_apid[1]: begin
         decompose_euvsc_data, buf, euvsc_rec, 1 ; just the diodes
            ;euvsc_rec.data[a[1]:b[1]] = ishft( uint( buf[lo:hi:2] ), 8) + uint(buf[lo+1:hi+1:2])
      end
      euvs_c_apid[2]: begin
         decompose_euvsc_data, buf, euvsc_rec, 2 ; just the diodes
            ;euvsc_rec.data[a[2]:b[2]] = ishft( uint( buf[lo:hi:2] ), 8) + uint(buf[lo+1:hi+1:2])
      end
      euvs_c_apid[3]: begin
         decompose_euvsc_data, buf, euvsc_rec, 3 ; just the diodes
            ;euvsc_rec.data[a[3]:b[3]] = ishft( uint( buf[lo:hi:2] ), 8) + uint(buf[lo+1:hi+1:2])
      end
      euvs_c_apid[4]: begin
         decompose_euvsc_data, buf, euvsc_rec, 4 ; just the diodes
            ;euvsc_rec.data[a[4]:b[4]] = ishft( uint( buf[lo:hi:2] ), 8) + uint(buf[lo+1:hi+1:2])
      end
      euvs_c_apid[5]: begin
         decompose_euvsc_data, buf, euvsc_rec, 5 ; just the diodes
            ;euvsc_rec.data[a[5]:b[5]] = ishft( uint( buf[lo:hi:2] ), 8) + uint(buf[lo+1:hi+1:2])
      end
      euvs_c_apid[6]: begin
         decompose_euvsc_data, buf, euvsc_rec, 6 ; just the diodes
            ;euvsc_rec.data[a[6]:b[6]] = ishft( uint( buf[lo:hi:2] ), 8) + uint(buf[lo+1:hi+1:2])
      end
      euvs_c_apid[7]: begin
         if pri_hdr.pkt_seq_count ne euvsc_rec.pri_hdr.pkt_seq_count then begin
            print,'WARNING: euvsc out of order, pri_hdr.pkt_seq_count changed OR partial integration received'
            euvsc_rec.pri_hdr = pri_hdr
            euvsc_rec.sec_hdr = sec_hdr
            euvsc_rec.time = time_rec
            decompose_euvsc, buf, euvsc_rec ; get the rest of the packet
         endif
         
         decompose_euvsc_data, buf, euvsc_rec, 7 ; just the diodes
            ;euvsc_rec.data[a[7]:b[7]] = ishft( uint( buf[lo:hi:2] ), 8) + uint(buf[lo+1:hi+1:2])

         if keyword_set(do_plots) then plot_euvsc, euvsc_rec, laser=laser, do_files=do_files
         ; now save the euvsc_rec data
         if keyword_set(do_files) then write_to_euvsc_file, euvsc_rec
      end
      sc_pva_apid: begin ; 384
            ; copy common use substructures
         sc_pva_rec.pri_hdr = pri_hdr
         sc_pva_rec.sec_hdr = sec_hdr
         sc_pva_rec.time = time_rec
         decompose_pva384, buf, sc_pva_rec

         ;if keyword_set(do_plots) then plot_euvsb, euvsb_rec, euvsb_rec.bTemp
         ;; now save the euvsab_rec data
         ;if keyword_set(do_files) then write_to_euvsb_file, euvsb_rec
      end
      sc_ang_rate_apid: begin ; 385 10 Hz with 10 samples each
      end
      else: ; print,'.',format='(A1,$)'
;if abs(float(sec_hdr.millisec) - lastpkttime) gt 2. then begin
;         print, 'Received unwanted APID=' + strtrim( pri_hdr.apid, 2) + '!'
;         lastpkttime = float(sec_hdr.millisec)
;      endif
   endcase

endwhile

close,lun
free_lun,lun
tmp=temporary(lun) ; undefine lun

; show packet stats
update_pkt_count, 0, /print_stats, do_plots=do_plots

if status ne 1 then begin
  print, !error_state.msg
  return
endif

END


;+
; Reads a single CCSDS packet from OIS dataserver socket.
; Non-blocking - if no data is present, returns.
;
; Outputs:  packet          - Upon success, a bytarr containing the packet.
;                             Upon failure, undefined.  Check with:
;                             if n_elements( packet) gt 0 then ...
;
;           socket_is_up    - Set to 1 if the socket is up, 0 if down.
;
;-
pro readPacketFromDataServer, packet, socket_is_up=socket_is_up

common DataServer_common, socket_lun, hostname

@gpds_defines.pro

proc_name = 'readPacketFromDataServer: '

;Undefine output argument 'packet', so that n_elements( packet) returns 0.
;This is how the caller can tell if a packet was read or not.

if n_elements( packet) gt 0 then junk = size( temporary( packet))

socket_is_up = dataserverSocketIsOn()
if not socket_is_up then return

packet_header = bytarr( pri_hdr_len )
on_ioerror, READ_FAILED
;print,'preparing to read from socket'
readu, socket_lun, packet_header, transfer_count=bytes_read
;print,'read '+strtrim(bytes_read,2),' bytes from socketlun '+strtrim(socket_lun,2)
;print,packet_header,form='('+strtrim(bytes_read,2)+'z2.2)'
READ_FAILED:
case bytes_read of
  0: return
    
  pri_hdr_len: begin
    ;length = PktDcmp_getUnsignedInteger( packet_header, 4, 2) + 1 ;remaining bytes in packet
    length = ishft( uint( packet_header[4]), 8) + uint( packet_header[5] ) + 1u
;    apid = ishft(packet_header[0] and '111'b, 8) + packet_header[1]
;    if apid eq 1280 or apid eq 33 then length += 7 ; add 7 magic bytes to fix an ISIS packet length error
;    ; 1280 is '500'x and 33 is '21'x these are ISIS packets malformed on FSDE2
    data = bytarr( length)
  end
  
  else: begin
    print, proc_name, 'Error reading from socket!  Closing connection...'
    close, socket_lun
    socket_lun = -1
    socket_is_up = 0
    ;notifySocketIsDown
    return
  end
endcase

on_ioerror, READ_FAILED2
bytes_read = 0
readu, socket_lun, data, transfer_count=bytes_read
;print,'read '+strtrim(bytes_read,2),' bytes from socketlun '+strtrim(socket_lun,2)
;print,data,form='('+strtrim(bytes_read,2)+'z2.2)'
READ_FAILED2:
case bytes_read of
    
  n_elements( data): begin
    packet = [packet_header, data]
    return
  end
  
  else: begin
    print, proc_name, 'Error reading from socket!  Closing connection...'
    close, socket_lun
    socket_lun = -1
    socket_is_up = 0
    ;notifySocketIsDown
    return
  end
endcase
END


;+
; Send a command to the OIS data server requesting the server send us
; packets with the specified APID's. Not used since we now use an OIS multisocket.
;
; Notes:
; 1) This structure, converted to binary, is sent to the OIS data server.
;    The 2-byte length field gives the length of the message in bytes, not counting the
;    length field itself.
;    The 2-byte action  field is set to 0 for the "add apids" command.
;    The remainder of the message are one or more 2-byte apids.  The data server will send
;    the client packets which have these apids.
;
;    cmd = {length  : 2 + N*2, $   ;2 bytes
;           action  : 0,       $   ;2 bytes
;           apids   : intarr(N)}   ;2*N bytes
;-
pro sendCmdToDataServer, requested_apids, success

common DataServer_common, socket_lun, hostname

proc_name = 'sendCmdToDataServer: '
debug = 1
success = 0
if not dataserverSocketIsOn() or n_elements( requested_apids) lt 1 then return

length = fix( 2 + n_elements( requested_apids) * 2)
byte_arr = [fix( swap_endian( length, /SWAP_IF_LITTLE_ENDIAN), 0, 2, type=1), $
            fix( 0,                                            0, 2, type=1)]

for i=0,n_elements( requested_apids)-1 do begin
  apid = swap_endian( fix( requested_apids[i]), /SWAP_IF_LITTLE_ENDIAN)
  byte_arr = [byte_arr, fix( apid, 0, 2, type=1)]
endfor

on_ioerror, WRITE_FAILED
writeu, socket_lun, byte_arr, transfer_count=bytes_written
WRITE_FAILED:
if bytes_written eq n_elements( byte_arr) then begin
  success = 1
  if debug then begin
    print, proc_name, 'Wrote ' + strtrim( bytes_written, 2) + '-byte message:'
  endif
endif else begin
  success = 0
  if debug then print, proc_name, 'Write failed!'
  close, socket_lun
  socket_lun = -1
endelse
END




;+
; Closes the socket if it's open
;-
pro closeSocket
common DataServer_common, socket_lun, hostname
if n_elements( socket_lun) gt 0 then begin
  if socket_lun ne -1 then begin
    close, socket_lun
    socket_lun = -1
  endif
endif
END


;+
; Sets hostname in socket routines common block.
;
; :Params:
;   hostname_in: in, required, type=string
;    The host name as a string.
;
;-
pro setHostname, hostname_in
common DataServer_common, socket_lun, hostname
hostname = hostname_in
END




;+
; Returns the ID for the window with the name matching the windowtitle.
;
; :Params:
;    windowtitle: in, required, type=string
;      This is the title of the window to find.
;
; :Returns:
;    The window ID is calculated and returned. IDL starts numbering windows at 32.
; 
;-
function get_window_id, windowtitle

common create_plots_windows_cal, wlist
return, (where(windowtitle eq wlist))[0] + 32
end

;+
; Returns 1 (true) if the window exists. When a user closes a window, it no longer exists.
;-
function window_exists, window_id
  ; return 1 if the window exists (wasn't closed by user)
device,window_state=wstate
return, wstate[window_id]
end

;+
; Set the window with the name matching the windowtitle for plotting.
; This is directly used by plotting procedures to ensure the window
; is open before writing to it.
;-
pro window_set, window_name

; get the ID
window_id = get_window_id(window_name)
; create it if it doesn't exist
if window_exists(window_id) ne 1 then create_plot_windows, window_name
; set it as the active window to receive graphics
wset,window_id

return
end


;+
; Create all of the possible output windows, and setup a common block of window names and IDs
;
;  :Params:
;     one_window_title: in, optional, type=string
;       You can recreate just one window by passing in the title, after all of them have been initialized.
;-
pro create_plot_windows, one_window_title
common create_plots_windows_cal, wlist, window_ids

; define window titles and locations
wlist=['EUVS-C', $ ; 0
       'EUVS-A', $ ; 1
       'EUVS-B', $ ; 2
       'XRS_Target', $ ; 3
       'XRS', $        ; 4
       'SPS_Target', $ ; 5
       'Spectrum', $     ; 6
       'EMI-EUVS-C_Sigma', $       ; 7
       ;'EMI-EUVS-C_Count_Image', $ ; 8
       ;'EMI-EUVS-C_Stdev_Image', $ ; 9
       'EUVS-A_Cathodes', $ ; 8
       'EUVS-B_Cathodes', $ ; 9
       'EMI-SPS-ASIC', $   ; 10
       'EMI-XRS-ASIC', $   ; 11
       'EMI-EUVSA-ASIC', $   ; 12
       'EMI-EUVSB-ASIC', $     ; 13
       'STATUS-1', $ ; 14
       'STATUS-2', $ ; 15
       'STATUS-3' $ ; 16
      ]

window_ids={sps:[5,10]+32, $
            euvsc:[0,7]+32, $
            euvsa:[1,8,12]+32, $
            euvsb:[2,9,13]+32, $
            xrs:[3,4,11]+32 }

; xpos, ypos are the lower left corner of the window
; ypos=832 and ysize=320 mean 1152 is the vertical dimension of the screen
; xpos=2896 and xsize=1200 mean 4096

wcmd=[   "window,/free,tit=wlist[0],  xs=500,  ys=480, xpos=1208, ypos=0", $ ; EUVS-C
         "window,/free,tit=wlist[1],  xs=400,  ys=320, xpos=2048, ypos=832", $ ; EUVS-A
         "window,/free,tit=wlist[2],  xs=400,  ys=320, xpos=2460, ypos=832", $ ; EUVS-B
         "window,/free,tit=wlist[3],  xs=400,  ys=400, xpos=628,  ypos=35", $ ; XRS_Target
         "window,/free,tit=wlist[4],  xs=320,  ys=320, xpos=1718, ypos=834", $ ; XRS
         "window,/free,tit=wlist[5],  xs=640,  ys=320, xpos=935,  ypos=35", $ ; SPS_Target 7/19/13 doubled width
         "window,/free,tit=wlist[6],  xs=700,  ys=800, xpos=20,    ypos=355", $ ; Spectrum
         "window,/free,tit=wlist[7],  xs=320,  ys=600, xpos=1718, ypos=0", $ ; EMI-EUVS-C_Sigma
         ;"window,8,tit=wlist[8],  xs=590,  ys=590, xpos=710,  ypos=564", $ ; EMI-EUVS-C-Count_Image
         ;"window,9,tit=wlist[9],  xs=590,  ys=590, xpos=1300, ypos=564", $ ; EMI-EUVS-C-Stdev_Image
         "window,/free,tit=wlist[8],xs=800,  ys=400, xpos=2896,   ypos=50", $ ; EUVS-A_Cathodes
         "window,/free,tit=wlist[9],xs=800,  ys=400, xpos=2896,   ypos=500", $ ; EUVS-B_Cathodes
         "window,/free,tit=wlist[10],xs=260,  ys=600, xpos=2618, ypos=35", $ ; EMI-SPS-ASIC
         "window,/free,tit=wlist[11],xs=560,  ys=600, xpos=2048, ypos=35", $ ; EMI-XRS-ASIC
         "window,/free,tit=wlist[12],xs=1200, ys=540, xpos=2896, ypos=35", $ ; EMI-EUVSA-ASIC
         "window,/free,tit=wlist[13],xs=1200, ys=540, xpos=2896, ypos=652", $ ; EMI-EUVSB-ASIC
         "window,/free,tit=wlist[14],xs=720,  ys=470, xpos=740,    ypos=700", $ ; STATUS-1
         "window,/free,tit=wlist[15],xs=1020,  ys=500, xpos=750,    ypos=300", $ ; STATUS-2
         "window,/free,tit=wlist[16],xs=240,  ys=600, xpos=10,    ypos=300" $ ; STATUS-3
     ]

if size(one_window_title,/type) ne 0 then begin
   ; recreate the one window for the window title that was passed in
   id=where(wlist eq one_window_title[0],n_id)
   if n_id eq 1 then begin
      tmp=execute(wcmd[id[0]]) 
   endif else begin
      print,'ERROR: create_plot_windows - invalid window id'
   endelse
   return
endif

if size(windowtitle,/type) eq 0 then begin
   ; setup all windows
   for i=0,n_elements(wcmd)-1 do tmp=execute(wcmd[i])
endif else begin
   ;setup just one window
   x=where(windowtitle eq wlist,n_x)
   device,window_state=ws
   if n_x eq 1 then begin
      if ws[x[0]] eq 0 then begin
         tmp=execute(wcmd[x[0]])
      endif else print,'window is already open'
   endif
endelse
return
end


;+
; exis_quicklook is the  main entry point to the EXIS quicklook program.
;   (modified from aim_img_viewer.pro)
; The purpose of this code is to read EXIS data packets from OIS socket, and display images/plots
;   in real-time.  The program reads packets with certain APID's (see gpds_defines.pro).  When a packet
;   from EXIS arrives, it's content is deomposed. Packets can come in any order. 
; Has been tested under Solaris 10, OS X 10.5.7, and RHEL 5.3 in IDL 7, 7.1, 8, and 8.1.
;
; :Keywords:
;    host: in, optional, type=string
;      set to the hostname or ip address where OIS is running
;    no_plots: in, optional, type=boolean
;      use keyword to disable all plot windows (enabled by default)
;    no_files : in, optional, type=boolean
;      use keyword to disable output to all files (enabled by default)
;    ois_file : in, optional, type=boolean
;      set keyword to indicate the packetfile is an OIS 'raw record' file, not from the data simulator
;    no_darkxrs : in, optional, type=boolean
;      use keyword to disable dark subtraction for XRS pointing angle plots (enabled by default)
;    zeroUTepoch : in, optional, type=boolean
;      Use this keyword to revert to the old (incorrect) epoch of Jan 1, 2000 at 0:00:00 UT. If this keyword is not provided, then the correct epoch is used (Jan 1, 2000 at 12:00:00 UT).
;    laser : in, optional, type=boolean
;      use keyword durign ELF testing when the laser is in use. Setting this flag will replace the last EUVS-C (sigma) plot with a zoom in of the laser line
;    LCR   : in, optional, type=boolean
;      set this keyword to reread the pkt_file over and over
;    slowFileReplay   : in, optional, type=float
;      set this keyword to pause this many seconds when each SPS packet is decomposed in the pkt_file. This has no effect
;      unless reading data from from a file.
;
;  :Params:
;     pkt_file: in, optional, type=string
;       Pass in a fully qualified pathname to a binary telemetry file containing CCSDS packets for (re)processing.
;       Note that OIS raw record files insert a 32-bit ground-receipt timestamp before each packet, 
;       so use /ois_file to read those files properly.
;
; :History: 08/31/09 DLW  Works with GOES-R EXIS.
;    Don Woodraska, modified from Steve Monk's cips_data_vewer.pro
;    DLW 12/01/08 Moved exis_quicklook code to bottom to force compilation of all routines
;
; :Version:
;    $Id: exis_quicklook.pro 81638 2019-05-24 13:55:21Z dlwoodra $
;
; :Examples:
;    IDL> exis_quicklook [,packetfile][, host=["goesr1"|"carina"|"snoe"|"staypuft"][, /no_plots][, /no_files][,/ois_file][,/no_darkxrs][,/zeroUTepoch][,/LCR][,/slowFileReplay]'
;
; :Uses:
;    getExisPacketsFromSocket
;    getExisPacketsFromFile
;    cleanup_quicklook_dir
;    setHostname
;-
pro exis_quicklook, host=ois_host_name, no_plots=no_plots, no_files=no_files, pkt_file,ois_file=ois_file,no_darkxrs=no_darkxrs, zeroUTepoch=zeroUTepoch,laser=laser, LCR=LCR, slowFileReplay=slowFileReplay

common exis_quicklook,exis_type

if strlen(getenv('exis_type')) lt 3 then begin
   print,'ERROR: No environment setup'
   print,'at the unix prompt type '
   print,' source setup_exis.csh (or similar command)'
   exit
endif


exis_type = strupcase(getenv('exis_type'))

do_plots=1 ; default is to make plots
if keyword_set(no_plots) then do_plots=0

do_files=1 ; default is to save data in files
if keyword_set(no_files) then do_files=0

;
; Move any files from the quicklook directory before starting
;
if do_files eq 1 then cleanup_quicklook_dir


do_darkxrs=1 ; default is to apply a dark correction to the xrs target plot
if keyword_set(no_darkxrs) then do_darkxrs=0

if do_plots ne 0 then begin

   create_plot_windows

endif

device, decomposed=1,retain=2
if !p.color ne 0 then begin
   !p.background=!p.color
   !p.color=0
endif

if keyword_set(LCR) eq 1 then begin
   ; NEW 3/27/18 deprecate exis_copy script
   LCRsearchdir=getenv('searchdir')
   nccount=0
   ncpatt='/?R_EXIS-L0_*nc'
   while nccount eq 0 do begin
     ncfilelist=file_search(LCRsearchdir+ncpatt,count=nccount)
     print,'waiting 5 seconds'
     wait,5
   endwhile
   ncfilelist = ncfilelist[sort(ncfilelist)]
   lastncfile = ncfilelist[nccount-1]
   extract_ncdf_packets, lastncfile, pkt_file
   getExisPacketsFromFile, packets, n_packets, pkt_file, do_plots=do_plots, do_files=do_files,slowFileReplay=slowFileReplay
   filewaitcounter=0L

   while ( 1 eq 1 ) do begin
      ; get a filelist
     ncfilelist=file_search(LCRsearchdir+ncpatt,count=nccount)
     ; sort it
     ncfilelist = ncfilelist[sort(ncfilelist)]
     ; if this is IDL v 8.5.1 or newer then we can use file_modtime()
     ; to calculate the age in seconds
     ; age=file_modtime(ncfilelist) - systime(1) ; negative numbers 
     tmp=where(ncfilelist eq lastncfile)
     if tmp[0] eq n_elements(ncfilelist)-1 then begin
        filewaitcounter++
        print,'waiting '+strtrim(filewaitcounter,2)+'*10 seconds to look for the next file'
        wait,10
     endif else begin
        wait, 5 
        tmp=where(ncfilelist eq lastncfile) ; one last lookbefore processing
        ; run each tlm file in order one at a time until all are processed
        for i=tmp[0]+1,n_elements(ncfilelist)-1 do begin
           lastncfile = ncfilelist[i] ; next file in the list
           print,'reading '+lastncfile
           extract_ncdf_packets, lastncfile, pkt_file
           getExisPacketsFromFile, packets, n_packets, pkt_file, do_plots=do_plots, do_files=do_files,slowFileReplay=slowFileReplay
        endfor
        filewaitcounter=0L
     endelse
   endwhile
   ; this is the end of the LCR stuff
endif

; not LCR file processing, proceed as normal
if size(pkt_file,/type) eq 7 then begin
   ; read from the file
   getExisPacketsFromFile, packets, n_packets, pkt_file, do_plots=do_plots, do_files=do_files,ois_file=ois_file,do_darkxrs=do_darkxrs, zeroUTepoch=zeroUTepoch, laser=laser, slowFileReplay=slowFileReplay
   flush,101,102,103,104,105
   ; do not do any data filing if no_files is set
   if keyword_set(no_files) then return else cleanup_quicklook_dir
   return
endif

;print,'make sure you start OIS on a sparc CPU (no binary exists for x86)'
;print,' snoe> cd /home/dlwoodra/projects/goes/ois/run'
;print,' snoe> ( ./ois -m primary -h snoe -c ./goesr_ois_config.txt ) >& ois.log'
;print,''
;print,' then write packets to the socket (sparc)'
;print,' snoe> ./WriteToSocket -p 0.001 2001 SERVER < ./tmpdata'


title = 'EXIS Image Viewer'

;ois_host = (!version.os eq 'sunos') ? getenv( 'HOST') : string( ' ', format='(A20)')

if keyword_set(ois_host_name) eq 0 then begin
   ;print,'********************************************************'
   ;print,'USAGE: IDL> exis_quicklook [,filename][, host=["goesr1","snoe","staypuft","slimer"]][, /no_plots][, /no_files]'
   ;print,' you must specify the host that is running OIS'
   ;print,'********************************************************'
   print,''
   wait,5

   default_host='goesr-tr2-nuc1'
   print,' trying default host of '+default_host
   print,''
   ois_host_name = default_host ; set a default

   ; host was not provided, try to guess based on this hostname
   thishostname=getenv('HOST')
   case thishostname of
      'goesr-tr2-dp1': ois_host_name='goesr-tr2-nuc1' ; ESTE2
      'utixo': ois_host_name='egon.lasp.colorado.edu' ; ESTE3
      'venti': ois_host_name='slimer.lasp.colorado.edu' ; ESTE4
      'veles': ois_host_name='winston.lasp.colorado.edu' ; FSDE2
      else:
   endcase

endif

lc_ois_host_name = strlowcase(ois_host_name)
case 1 of
   stregex('staypuft',lc_ois_host_name,/bool): ois_host = 'staypuft' ; 10.247.10.160
   stregex('egon',lc_ois_host_name,/bool): ois_host = 'egon'
   stregex('venkman',lc_ois_host_name,/bool): ois_host = 'venkman'
   stregex('carina',lc_ois_host_name,/bool): ois_host = 'carina.lasp.colorado.edu' 
   stregex('snoe',  lc_ois_host_name,/bool): ois_host = 'snoe.lasp.colorado.edu'
   stregex('slimer',  lc_ois_host_name,/bool): ois_host = 'slimer.lasp.colorado.edu'
   stregex('opsray',  lc_ois_host_name,/bool): ois_host = 'opsray.lasp.colorado.edu'
   stregex('zuul',  lc_ois_host_name,/bool): ois_host = 'zuul.lasp.colorado.edu'
   stregex('goes1g',  lc_ois_host_name,/bool): ois_host = 'goes1g.lasp.colorado.edu'
else: begin
   ;print,'WARNING: server specified is not a routine server'
   print,' trying to continue using '+lc_ois_host_name
   ois_host = lc_ois_host_name
   end
endcase


;Close the socket if it's open.
closeSocket

;Set hostname.
setHostname, ois_host


; read from the socket
cnt=0L
zero_read_cnt = 0L
while 1 do begin
    ;print, 'Calling getExisPacketsFromSocket...'
   t1 = systime(1)
   getExisPacketsFromSocket, packets, n_packets, do_plots=do_plots, do_files=do_files,do_darkxrs=do_darkxrs, zeroUTepoch=zeroUTepoch,laser=laser
   ;getExisPacketsFromFile, packets, n_packets  ;for testing

   if cnt mod 10 then flush,101,102,103,104,105
    
   t2 = systime(1)
   delay_in_seconds = (t2 - t1) ; > 0.5
   ;delay_in_seconds = 0.0
   ;print,'exis_quicklook: timer_event duration was ',delay_in_seconds

   ; Automatically try to reconnect after no_packet_received_limit is reached
   no_packet_received_limit = 100
   if n_packets eq 0 then begin
     ;wait,0.002
     wait, 1
     ; no packets read, increment zero_read_cnt
     zero_read_cnt++
     if zero_read_cnt gt no_packet_received_limit then begin
       ; close the connection to OIS and try to reconnect
       print,'ERROR: no packets read for 100 attempts, trying to reconnect'
       closeSocket
       wait,10
       zero_read_cnt = 0L ; reset the counter
     endif
   endif else begin
     wait,0.001          ; wait,delay_in_seconds
     zero_read_cnt = 0L  ; reset the counter
   endelse
endwhile

; use labels to cleanly exit, and file away all the open quicklook files
cleanup:
quicklook_filing:
; do not do any data filing if no_files is set
if keyword_set(no_files) then return else cleanup_quicklook_dir

return

END
