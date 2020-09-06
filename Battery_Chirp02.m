function Main = Battery_Chirp02(SMU_Name, Battery, V_Bias, Str_Add)

C = Battery.Capacity;
VMax = Battery.VMax;
VMin = Battery.VMin;
IMax = C * Battery.IMaxRatio;
durat = 30*60; % use 15 min as default
I_Compliance = 100e-3;
No_Points = 2500;
End_Point = 2488;
if V_Bias > VMax
    error('Defined voltage is too high')
elseif V_Bias < VMin
    error('Defined voltage is too low')
elseif I_Compliance > IMax
    error('Current compliance largert than the max allowed current')
end
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

% preparation of chirp signal
Chirp_Ts = durat/No_Points; % maximum size of signal is 1000 (use the highest resolution)
t = 0:Chirp_Ts:durat; % chirp takes about 30 min
y = chirp(t,2/10000,durat,1/50,'linear',90); %
y = 0.01 * y; % scale the signal in a small range ()
y = [y(1:End_Point),0];
y = V_Bias + y; % make the chirp around the defined bias
list = regexprep(num2str(y),'\s+',','); % list of chirp data in a string form separated with ,

% setting the channel
fprintf(SMU,':SOUR1:FUNC:MODE VOLT'); % it is a voltage source
fprintf(SMU,':SOUR1:VOLT:MODE LIST'); % an arbitrary signal
fprintf(SMU,sprintf(':SOUR1:LIST:VOLT %s', list)); % setting the sampling time
fprintf(SMU,':SENS1:REM ON'); % 4wire measurement
fprintf(SMU,':FORM:ELEM:SENS VOLT,CURR,TIME'); % store only voltage, current values and time

fprintf(SMU,sprintf(':SENS1:CURR:PROT %d',I_Compliance));

fprintf(SMU,':TRIG:TRAN:SOUR TIM'); % triggers are time based
fprintf(SMU,sprintf(':TRIG:TRAN:COUN %d', End_Point+1)); % Number of triggers 
fprintf(SMU,sprintf(':TRIG:TRAN:TIM %d', Chirp_Ts)); % setting the sampling time
fprintf(SMU,sprintf(':TRIG:TRAN:DEL %d', 0.1*Battery.Ts));

fprintf(SMU,':TRIG:ACQ:SOUR TIM'); % triggers are time based
fprintf(SMU,sprintf(':TRIG:ACQ:COUN %d', End_Point+1)); % Number of triggers 
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
    Points = query(SMU,':TRAC1:POIN:ACT?');
    Points = str2num(Points); % convert it to a number (from string)
    if Points >= 1 % to avoide problem in the beginning
        Data_Temp = query(SMU,sprintf(':TRAC1:DATA? %d,%d',Points-1,1));
        Data_Temp = str2num(Data_Temp); % convert to number
        
        % updating the figures
        addpoints(Voltage_Fig,Data_Temp(3),Data_Temp(1));
        addpoints(Current_Fig,Data_Temp(3),Data_Temp(2));
        drawnow
    end
    if Points >= End_Point+1
        Chirp_Complete = true;
    end
    pause(Chirp_Ts) % wait for the duration of one sample
end

fprintf(SMU,':ABOR:ACQ (@1)'); % abort data collection
Main.TEnd = datetime;
disp(strcat('Chirp around', {' '}, num2str(V_Bias), '[V] FINISHED at:', {' '}, datestr(Main.TEnd)))
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