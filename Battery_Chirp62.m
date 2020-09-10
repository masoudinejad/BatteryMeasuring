function [Main,Main_Name] = Battery_Chirp(SMU, Battery, V_Bias, Str_Add)

C = Battery.Capacity;
VMax = Battery.VMax;
VMin = Battery.VMin;
IMax = C * Battery.IMaxRatio;
durat = 15*60; % use 15 min as default
I_Compliance = 99e-3;

if V_Bias > VMax
    error('Defined voltage is too high')
elseif V_Bias < VMin
    error('Defined voltage is too low')
elseif I_Compliance > IMax
    error('Current compliance largert than the max allowed current')
end

figure
subplot(2,1,1)
title('Chirp Process')
Voltage_Fig = animatedline('LineStyle','none','Color','k','Marker','x');
ylabel('Voltage [V]')
subplot(2,1,2)
Current_Fig = animatedline('LineStyle','none','Color','k','Marker','x');
ylabel('Current [I]')

fopen(SMU); % connect to the object
pause(0.1)

Error=SMU_Error_Read(SMU); % clearing old errors
fprintf(SMU,'*RST'); % reset the measurement device
% preparation of chirp signal
Chirp_Ts = durat/1000; % maximum size of signal is 1000 (use the highest resolution)
t = 0:Chirp_Ts:durat; % chirp takes about 30 min
y = chirp(t,2/10000,durat,1/50,'linear',90); %
y = 0.01 * y; % scale the signal in a small range ()
y = V_Bias + y; % make the chirp around the defined bias
y = y(1:996); % Signal arrives at initial value at point 996
list = regexprep(num2str(y),'\s+',','); % list of chirp data in a string form separated with ,

% setting the channel
fprintf(SMU,':SOUR1:FUNC:MODE VOLT'); % it is a voltage source
fprintf(SMU,':SOUR1:VOLT:MODE ARB'); % an arbitrary signal
fprintf(SMU,':SOUR1:ARB:FUNC UDEF'); % signal is user defined
fprintf(SMU,':SENS1:REM ON'); % 4wire measurement
fprintf(SMU,':FORM:ELEM:SENS VOLT,CURR,TIME'); % store only voltage, current values and time

fprintf(SMU,sprintf(':SENS1:CURR:PROT %d',I_Compliance));

fprintf(SMU,sprintf(':SOUR1:ARB:VOLT:UDEF %s', list)); % setting the sampling time
fprintf(SMU,sprintf(':SOUR1:ARB:VOLT:UDEF:TIME %d', Chirp_Ts));

fprintf(SMU,':TRIG:ACQ:SOUR TIM'); % triggers are time based
fprintf(SMU,':TRIG:ACQ:COUN 1000'); % Number of triggers
fprintf(SMU,sprintf(':TRIG:ACQ:TIM %d', Chirp_Ts)); % setting the sampling time

% ------- Trace buffer -------
fprintf(SMU,':TRAC1:FEED:CONT NEV'); % Disable write Buffer (cant be cleared in next mode)
fprintf(SMU,':TRAC1:CLE'); % Clears trace buffer
fprintf(SMU,':TRAC1:FEED SENS'); % Specifies data to feed
fprintf(SMU,':TRAC1:FEED:CONT NEXT'); % Enables write Buffer

fprintf(SMU,':OUTPUT1 ON'); % turn on the channel
fprintf(SMU,':INIT (@1)'); % trigger
Main.TStart = datetime; % start time of the main
disp(strcat('A chirp around', {' '}, num2str(V_Bias), '[V] STARTED at:', {' '}, datestr(Main.TStart)))

Chirp_Complete = false;
while ~Chirp_Complete % as long as the cycle is not complete do:
    fprintf(SMU,':TRAC1:POIN:ACT?'); % what number is the last reading?
    Points = fscanf(SMU,'%c'); % get the number
    Points = str2num(Points); % convert it to a number (from string)
    if Points >= 1 % to avoide problem in the beginning
        fprintf(SMU,sprintf(':TRAC1:DATA? %d,%d',Points-1,1)); % give me the last reading
        Data_Temp = fscanf(SMU,'%c'); % get the reading
        Data_Temp = str2num(Data_Temp); % convert to number
        
        % updating the figures
        addpoints(Voltage_Fig,Data_Temp(3),Data_Temp(1));
        addpoints(Current_Fig,Data_Temp(3),Data_Temp(2));
        drawnow
    end
    if Points >= 996
        Chirp_Complete = true;
    end
    pause(Chirp_Ts) % wait for the duration of one sample
end

fprintf(SMU,':ABOR:ACQ (@1)'); % abort data collection
Main.TEnd = datetime;
disp(strcat('Chirp around', {' '}, num2str(V_Bias), '[V] FINISHED at:', {' '}, datestr(Main.TEnd)))
fprintf(SMU,':OUTP1 OFF');
fprintf(SMU,':FETC:ARR? (@1)'); % send me the data
pause(0.1)
VI_Raw = fscanf(SMU,'%c'); % read all stored data
Main.Error=SMU_Error_Read(SMU); % get errors

fclose(SMU);
% save data temporary
Date_Str = datestr(Main.TEnd,'yymmdd_HHMM');
% Temp_Name = strcat('Temp_Ch_',Date_Str);
% SaveWithNumber(Temp_Name, VI_Raw)

VI_Raw = str2num(VI_Raw); % convert VI data to number
VI_Raw=vec2mat(VI_Raw,3); % separate voltage and current data

% store VI data into a table
V=VI_Raw(:,1);
I=VI_Raw(:,2);
Time = VI_Raw(:,3);
VI=table(Time,V,I);
VI.Properties.VariableUnits = {'Second','V','A'};
Main.VI=VI;
Main_Name = strcat('M',Date_Str,'_Ch');
if ~exist(Str_Add, 'dir')
    mkdir(Str_Add)
end
SaveWithNumber(strcat(Str_Add,'\',Main_Name), Main)