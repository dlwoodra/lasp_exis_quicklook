function make_pri_hdr, array_in

@gpds_defines.pro
array = uint(array_in) ;work with 16-bit data types
; array has length of 6
if n_elements(array) ne PRI_HDR_LEN then begin
   print,'ERROR: make_pri_hdr has incorrect data length for primary header'
endif

struct = CCSDS_PRI_HDR
struct.ver_num      = byte(ishft(array[0],-5))
struct.type         = byte(ishft(array[0],-4) and '1'b)
struct.sec_hdr_flag = byte(ishft(array[0],-3) and '1'b)

struct.apid          = ishft(array[0] and '111'b, 8) + array[1]

struct.seq_flag     = byte(ishft(array[2],-6) and '11'b)
struct.pkt_seq_count = ishft(array[2] and '111111'b, 8) + array[3]

struct.pkt_len       = ishft(array[4], 8) + array[5]

return,struct
end
