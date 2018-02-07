function [iT,iRH] = SHT_wrong2raw(T,RH_wrong)

% constants
d1 = -39.66;    % interpolated for 3.3V
d2 = 0.01;      % for 14bit
C1 = -4.0; 
C2 = 0.0405; 
C3 =-0.0000028;
T1 = 0.01; 
T2 = 0.00008;
T3 = T-25;
a = C3;
b = T2*T3 + C2;
c = T3*T1 + C1 - RH_wrong;

% temperature conversion
iT = round((T - d1 )./ d2);

% humidity conversion
iRH = round((-b + sqrt(b.^2-4.*a.*c))./2./a);

