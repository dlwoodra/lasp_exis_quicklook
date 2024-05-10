pro extract_ncdf_packets, netcdf, packetfile

print,'extract_ncdf_packets: converting netcdf file to tlm packet file'

; read the netcdf data file
read_netcdf, netcdf, data

; write the packet data as a binary telemetry only
openw,lun,/get,packetfile
writeu, lun, data.exis_space_packet_data
close,lun
free_lun,lun

return
end
