 ; $Id: make_user_flags.pro 32836 2012-05-11 00:54:53Z dlwoodra $
 
 pro make_user_flags, sec_hdr, user_flags

  common make_user_flags_cal, user_flags_rec
  if size(user_flags,/type) eq 0 then begin
     user_flags_rec={time_status:0b, boot_ram:0b, pwr_status:0b, mode:0b, fm_designator:0b, config_id:0u}
  endif

  a=sec_hdr.userflags

  user_flags_rec.time_status   = byte(ishft(a,-31)) and '1'xb
  user_flags_rec.boot_ram      = byte(ishft(a,-30)) and '1'xb
  user_flags_rec.pwr_status    = byte(ishft(a,-28)) and '3'xb
  user_flags_rec.mode          = byte(ishft(a,-24)) and 'F'xb
  user_flags_rec.fm_designator = byte(ishft(a,-16)) and 'FF'xb
  user_flags_rec.config_id     = ishft(byte(ishft(a,-8)) and 'FF'xb,8) + $
                                 (a and 'FF'xb)

  user_flags=user_flags_rec

return
end
