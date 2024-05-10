function stddev_dim,x,d
  ; x is a multidimension array
  ; d is the dimension over which to calculate the standard deviation
  ;  d can be no less than 1 (to reference the first dimension)
  if n_elements(d) eq 0 || d eq 0 then begin
    n=n_elements(x)
    d=0
    return,stddev(x)
  endif
  s=size(x,/dim)
  if d gt n_elements(s) then message,'dimension out of range'
  N = double(s[d-1])

  ; since stev=sqrt(variance)
  ; variance = (1/N)*SUM[( x - <x> )^2]
  ;          = (1/N)*{SUM[x^2]} - <x>^2 by splitting the sum into two and
  ;                                     sub for <x>^2
  ; equivalently, use the unbiased estimator of population variance
  ;  (for large N, these should approach the same value)
  ; variance = (1/[N-1])*SUM[( x - <x> )^2]
  ; when using the sample to derive the mean <x>
  ; therefore, variance = (1/[N-1])*{SUM(x^2)} - (1/[N*(N-1)])*{SUM(x)}^2
  ; define convenient variables for IDL code
  ;                     = x2_term - x1_term

  x1_term  = total( x,   d, /double) ; SUM(x)
  x1_term *= x1_term                 ; {SUM(x)}^2
  x1_term /= double(N*N - N)         ; (1/[N*(N-1)])*{SUM(x)}^2
  x2_term  = total( double(x)*double(x), d, /double) / (N - 1.d0) 
  variance = x2_term - x1_term
  badval = where(variance lt 0.d0,n_badval)
  if n_badval gt 0 then begin
     print,'STDDEV_DIM - WARNING: '+strtrim(n_badval,2)+' variances are less than 0, filling with 0'
     variance[badval]=0.d0
     ; this can happen if the differences exceed the limits of double precision
  endif

  return,sqrt(variance)
end

