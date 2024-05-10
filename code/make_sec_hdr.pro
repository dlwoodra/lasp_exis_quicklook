function make_sec_hdr, array_in

@gpds_defines.pro
array = ulong(array_in) ; work with 32-bit data types
; array has length of 10
if n_elements(array) ne SEC_HDR_LEN then begin
   print,'ERROR: make_sec_hdr has incorrect data length for secondary header'
endif

struct = CCSDS_SEC_HDR
struct.day      = ishft(array[0],16) + ishft(array[1],8) + array[2]
struct.millisec = ishft(array[3],24) + ishft(array[4],16) + $
                  ishft(array[5],8) + array[6]
struct.microsec = uint(ishft(array[7],8) + array[8])

struct.userflags = ishft(array[9],24) + ishft(array[10],16) + $
                  ishft(array[11],8) + array[12]

struct.uf.TimeValid = ishft(array[9],-7) ; MSB bit
struct.uf.FSWBootRam = ishft(array[9],-6) and '1'xb ; 2nd MSB bit
struct.uf.ExisPowerAB = ishft(array[9],-4) and '3'xb ; 2 LSB bits in top nibble
struct.uf.ExisMode = array[9] and '0F'xb ; 4 LSB bits
struct.uf.fm = array[10]
struct.uf.configID = uint(ishft(array[11],8) + array[12])

return,struct
end
