function [Main,UV_Reached] = Battery_PhyNodeLoadSignle(SMU_Name, Battery,Str_Add)
Ts_Load = 6*25e-3;
Ts_Measure = 50e-3;
SamplesPerCycle = 60/Ts_Measure;
NoSamples = floor(95000/SamplesPerCycle)*SamplesPerCycle; % a complete cycle is 60 sec.
%% prepare online plotting
close all
figure
subplot(2,1,1)
title('Chirp Process')
Voltage_Fig = animatedline('LineStyle','none','Color','k','Marker','.');
ylabel('Voltage [V]')
grid on
subplot(2,1,2)
Current_Fig = animatedline('LineStyle','none','Color','k','Marker','.');
ylabel('Current [A]')
xlabel('Time [s]')
grid on
%% setting the SMU
SMU = visa_connector(SMU_Name); % build the visa object
fopen(SMU); % Start working at the SMU ------------------------------------
pause(0.1)
query(SMU,':SYST:ERR:ALL?'); % clearing old errors
fprintf(SMU,'*RST'); % reset the measurement device
%% Build the desired curve
load('PhyNodeLoads.mat')
Current = -PhyNodeLoads.Current;
list = regexprep(num2str(Current'),'\s+',','); % list of chirp data in a string form separated with ,
%% setting the channel
fprintf(SMU,':SOUR1:FUNC:MODE CURR'); % it is a voltage source
fprintf(SMU,':SOUR1:CURR:MODE LIST'); % an arbitrary signal
fprintf(SMU,sprintf(':SOUR1:LIST:CURR %s', list)); % setting the sampling time
fprintf(SMU,':SENS1:REM ON'); % 4wire measurement
fprintf(SMU,':FORM:ELEM:SENS VOLT,CURR,TIME'); % store only voltage, current values and time

fprintf(SMU,sprintf(':SENS1:VOLT:PROT %d', Battery.VMax));

fprintf(SMU,':TRIG:TRAN:SOUR TIM'); % triggers are time based
fprintf(SMU,':TRIG:TRAN:COUN MAX'); % Number of triggers
fprintf(SMU,sprintf(':TRIG:TRAN:TIM %d', Ts_Load)); % setting the sampling time
% fprintf(SMU,sprintf(':TRIG:TRAN:DEL %d', 0.1*Battery.Ts));

fprintf(SMU,':TRIG:ACQ:SOUR TIM'); % triggers are time based
fprintf(SMU,':TRIG:ACQ:COUN MAX'); % Number of triggers
fprintf(SMU,sprintf(':TRIG:ACQ:TIM %d', Ts_Measure)); % setting the sampling time

% ------- Trace buffer -------
fprintf(SMU,':TRAC1:FEED:CONT NEV'); % Disable write Buffer (cant be cleared in next mode)
fprintf(SMU,':TRAC1:CLE'); % Clears trace buffer
fprintf(SMU,':TRAC1:FEED SENS'); % Specifies data to feed
fprintf(SMU,':TRAC1:FEED:CONT NEXT'); % Enables write Buffer

fprintf(SMU,':OUTPUT1 ON'); % turn on the channel
fprintf(SMU,':INIT (@1)'); % trigger
Main.TStart = datetime; % start time of the main
disp(strcat('A Phynode load test STARTED at:', {' '}, datestr(Main.TStart)))

BufferFull = false;
UV_Reached = false;
while ~BufferFull && ~UV_Reached% as long as the buffer is not full do:
    Points = query(SMU,':TRAC1:POIN:ACT?');
    Points = str2num(Points); % convert it to a number (from string)
    if Points >= 1 % to avoide problem in the beginning
        Data_Temp = query(SMU,sprintf(':TRAC1:DATA? %d,%d',Points-1,1));
        Data_Temp = str2num(Data_Temp); % convert to number
        
        % updating the figures
        addpoints(Voltage_Fig,Data_Temp(3),Data_Temp(1));
        addpoints(Current_Fig,Data_Temp(3),Data_Temp(2));
        drawnow
        if Data_Temp(1) <= Battery.VMin
            UV_Reached = true;
        end
    end
    if Points > NoSamples - 5 % to assure no new cycle starts at the end
        BufferFull = true;
    end
    
    pause(Ts_Measure) % wait for the duration of one sample
end

fprintf(SMU,':ABOR (@1)'); % abort data collection
Main.TEnd = datetime;
disp(strcat('Phynode load test FINISHED at:', {' '}, datestr(Main.TEnd)))
fprintf(SMU,':OUTP1 OFF');

Main.Error = query(SMU,':SYST:ERR:ALL?'); % get errors
pause(1)
Main.VI = Bat_SMU_Data_Import(SMU);
fclose(SMU); % End of work at the SMU -------------------------------------

Main.Battery = Battery;
Main = orderfields(Main, {'Battery', 'VI', 'Error', 'TStart', 'TEnd'});

Date_Str = datestr(Main.TEnd,'yymmdd_HHMM');
Main_Name = strcat('M',Date_Str,'_B',num2str(Battery.Item),'_Ch');

if ~exist(strcat('Data\',Str_Add), 'dir')
    mkdir(strcat('Data\',Str_Add))
end
if ~exist(strcat('Fig\',Str_Add), 'dir')
    mkdir(strcat('Fig\',Str_Add))
end

SaveWithNumber(strcat('Data\',Str_Add,'\',Main_Name), Main)
savefig(strcat('Fig\',Str_Add,'\',Main_Name))