function [T,RH] = SHT_conversion(iT,iRH)

% constants
d1 = -39.66;    % interpolated for 3.3V
d2 = 0.01;      % for 14bit
C1 = -2.0468; 
C2 = 0.0367; 
C3 =-0.0000015955;
T1 = 0.01; 
T2 = 0.00008;

% temperature conversion
T = d1 + d2 .* iT;

% humidity conversion
rh_lin = C3.*iRH.^2 + C2.*iRH + C1;
RH = (T-25).*(T1+T2.*iRH)+rh_lin;
