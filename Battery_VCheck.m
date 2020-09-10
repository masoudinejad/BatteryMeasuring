% This function checks the OCV of the battery
function VoltageLevel = Battery_VCheck(SMU_Name)
Ts = 0.01;
%% prepare online plotting
close all
figure
subplot(2,1,1)
title('Battery Voltage check')
Voltage_Fig = animatedline('LineStyle','none','Color','b','Marker','.');
ylabel('Voltage [V]')
grid on
subplot(2,1,2)
Current_Fig = animatedline('LineStyle','none','Color','b','Marker','.');
ylabel('Current [A]')
xlabel('Time [s]')
grid on
%% setting the SMU
SMU = visa_connector(SMU_Name); % build the visa object
fopen(SMU); % Start working at the SMU ------------------------------------
pause(0.1)
query(SMU,':SYST:ERR:ALL?'); % clearing old errors
fprintf(SMU,'*RST'); % reset the measurement device

% set the SMU as a current source with the desired values
fprintf(SMU,':SOUR1:FUNC:MODE CURR'); % it is a current source
fprintf(SMU,':SOUR1:CURR:MODE FIX');
fprintf(SMU,':SOUR1:CURR:RANG:AUTO ON');
fprintf(SMU,sprintf(':SOUR1:CURR %d',0)); % setting the current value
fprintf(SMU,sprintf(':SOUR1:CURR:TRIG %d',0)); % setting the current value after trigger
fprintf(SMU,sprintf(':SENS1:VOLT:PROT %d',4.2)); % setting the maximum allowed voltage
fprintf(SMU,':SENS1:REM ON'); % 4wire measurement
fprintf(SMU,':FORM:ELEM:SENS VOLT,CURR,TIME'); % store only voltage, current values
fprintf(SMU,':TRIG:ACQ:SOUR TIM'); % triggers are time based
fprintf(SMU,':TRIG:ACQ:COUN INF'); % Number of triggers
fprintf(SMU,sprintf(':TRIG:ACQ:TIM %d', Ts)); % setting the sampling time

% ------- Trace buffer -------
fprintf(SMU,':TRAC1:FEED:CONT NEV'); % Disable write Buffer (cant be cleared in next mode)
fprintf(SMU,':TRAC1:CLE'); % Clears trace buffer
fprintf(SMU,':TRAC1:FEED SENS'); % Specifies data to feed
fprintf(SMU,':TRAC1:FEED:CONT NEXT'); % Enables write Buffer

fprintf(SMU,':OUTPUT1 ON'); % turn on the channel
fprintf(SMU,':INIT (@1)'); % trigger
Main.TStart = datetime; % start time of the main

disp(strcat('A Voltage check STARTED at:', {' '}, datestr(Main.TStart)))

tic
while toc <= 30 % Measure first 100 samples with zero current
    Points = query(SMU,':TRAC1:POIN:ACT?');
    Points = str2num(Points); % convert it to a number (from string)
    if Points>=1 % to avoide problem in the beginning
        Data_Temp = query(SMU,sprintf(':TRAC1:DATA? %d,%d',Points-1,1));
        Data_Temp = str2num(Data_Temp); % convert to number
        
        % updating the figures
        addpoints(Voltage_Fig,Data_Temp(3),Data_Temp(1));
        addpoints(Current_Fig,Data_Temp(3),Data_Temp(2));
        drawnow
    end
    pause(Ts) % wait for the duration of one sample
end

fprintf(SMU,':ABOR:ACQ (@1)'); % abort data collection
Main.TEnd = datetime;
disp(strcat('Battery Voltage check FINISHED at:', {' '}, datestr(Main.TEnd)))
fprintf(SMU,':OUTP1 OFF');

query(SMU,':SYST:ERR:ALL?'); % get errors
pause(1)
VI = Bat_SMU_Data_Import(SMU);
fclose(SMU); % End of work at the SMU -------------------------------------

% VoltageLevel = median(VI.V);
VoltageLevel = trimmean(VI.V,20);
