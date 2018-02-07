% script to plot real-time profiles from sumo data
% Before using this scrip you have to setup the connection...
% 1. open port on listening machine (where you want to plot data), e.g.:
%  nc -v -l -p 1234 > ~/Desktop/realtime_sumo.data
% 2. conncet GCS (e.g via ethernet) to listening machine and stream data:
% tail --lines=100 -f ~/paparazzi/var/logs/18_02_05__00_00_00.data | pv -b | nc -v 10.42.43.1 1234
% 3. run realtime_plot_sumo.m in matlab (cancel when you want to start a new plot or done)
% Troubleshooting:
% - you might have to change nc to netcat depending on which you have installed
% - works also via wifi - just check the ip (ifconfig) on the listening machine
% - if the incoming connection is blocked by the firewall add a new rule: sudo ufw allow in 1234/tcp


file = '~/Desktop/realtime_sumo.data';



figure
subplot 131, xlim('auto'), ylim('auto'), ylabel 'z [m]', xlabel 'T [degC]', hold on
subplot 132, xlim('auto'), ylim('auto'), ylabel 'z [m]', xlabel 'potT [degC]', hold on
subplot 133, xlim('auto'), ylim('auto'), ylabel 'z [m]', xlabel 'RH [perc]', hold on
% subplot 234, xlim('auto'), ylim('auto'), ylabel 'z [m]', xlabel 'WS [m/s]', hold on
% subplot 235, xlim([-180, 180]), ylim('auto'), ylabel 'z [m]', xlabel 'WD [deg]', hold on
% subplot 236, xlim('auto'), ylim('auto'), ylabel 'y [m]', xlabel 'x [m]'; colorbar, hold on
z =[]; T_TMP=[]; TRH_SHT=[]; UV=[NaN,NaN]; TS=[]; ii=0;
%%
while 1
    ii=ii+1;
tic
%[~,p] = grep('-s -i', 'GPS', file);                                        % find lines containing data matching GPS
[~,str]=unix(sprintf('tail -n 100 %s | grep GPS',file));
try 
    str=strsplit(str,'\n'); str=str{end-1};
    z = strsplit(str);
%     x = str2double(z{5})/100;
%     y = str2double(z{6})/100;
    z = str2double(z{9})/1000;
catch 
end
toc

%[~,p] = grep('-s -i', 'TMP_STATUS', file);                                 % find lines containing data matching TMP 
% [~,str]=unix(sprintf('tail -n 100 %s | grep TMP_STATUS',file));
% try
%     str=strsplit(str,'\n'); str=str{end-1};
%     T_TMP = strsplit(str); 
%     T_TMP = str2double(T_TMP{5});
% catch
% end

%[~,p] = grep('-s -i', 'SHT_STATUS', file);                                 % find lines containing data matching SHT
[~,str]=unix(sprintf('tail -n 100 %s | grep SHT_STATUS',file));
try
    str=strsplit(str,'\n'); str=str{end-1};
    TRH_SHT = strsplit(str);
    TRH_SHT = [str2double(TRH_SHT{7}),str2double(TRH_SHT{6})];
catch
end

% %[~,p] = grep('-s -i', 'WIND_INFO_RET', file);                              % find lines containing data matching WIND
% [~,str]=unix(sprintf('tail -n 100 %s | grep WIND_INFO_RET',file));
% try
%     str=strsplit(str,'\n'); str=str{end-1};
%     UV = strsplit(str);
%     UV = [str2double(UV{4}),str2double(UV{5})];
% catch
% end
% 
% [~,str]=unix(sprintf('tail -n 100 %s | grep MLX_STATUS',file));
% try
%     str=strsplit(str,'\n'); str=str{end-1};
%     TS = strsplit(str);
%     TS = str2double(TS{7});
% catch
% end


try
subplot 131
plot(T_TMP,z,'r.', TRH_SHT(1),z,'b.')
subplot 132
plot(T2PT(T_TMP+273.15,1000,z,0)-273.15,z,'b.')
subplot 133
plot(TRH_SHT(2),z,'b.')
% subplot 234
% plot(norm(UV),z,'b.')
% subplot 235
% plot(atan2d(-UV(1),-UV(2)),z,'b.')
% subplot 236
% scatter(x,y,z,TS),
% if ii==1, colorbar; 
% elseif ii==59, ii=0;
% end
catch
end

time=toc;
if time<=1, pause(.99-time), end
toc
end
