function calculate_checksum, arr

;checksum is an 'FF' seeded exclusive OR only over the data protion
; of each packet beginning on byte number 20 (zero-based index)

result='ff'xb

for i=0L,n_elements(arr)-1 do result  XOR=  arr[i]

return,result
end
