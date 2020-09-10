% This function applies the desired current till the end point is reached
% afterwards it continoue as a voltage source till the defined current
% reached
% CAUTION: <<<<<<< Use only for charging >>>>>>>
function Main = Battery_CCV_C(SMU_Name, Battery, Direction, Rate, Ts, End_Current, Str_Add)
% Use this function only for fully charging
C = Battery.Capacity;
VMax = Battery.VMax;
VMin = Battery.VMin;

switch  Direction
    case 'charge'
        Current_Direction = 1;
        Final_Voltage = VMax;
        Name_Extra = 'C';
    case 'discharge'
        Current_Direction = -1;
        Final_Voltage = VMin;
        Name_Extra = 'D';
    otherwise
        error('wrong state for the battery')
end

Desired_Current = Current_Direction * C * Rate; % finding the current value
if abs(Desired_Current)> Battery.IMaxRatio * C
    error('to high current value')
end
%% prepare online plotting
close all
figure
subplot(2,1,1)
title('Constant Current Process with steady end voltage (Current)')
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
fprintf(SMU,sprintf(':SOUR1:CURR %d',0)); % setting the current value
fprintf(SMU,sprintf(':SOUR1:CURR:TRIG %d',0)); % setting the current value after trigger
fprintf(SMU,':SOUR1:CURR:RANG:AUTO 1');
fprintf(SMU,sprintf(':SENS1:VOLT:PROT %d',VMax)); % setting the maximum allowed voltage
fprintf(SMU,':SENS1:REM ON'); % 4wire measurement
fprintf(SMU,':FORM:ELEM:SENS VOLT,CURR,TIME'); % store only voltage, current values
fprintf(SMU,':TRIG:ACQ:SOUR TIM'); % triggers are time based
fprintf(SMU,':TRIG:ACQ:COUN INF'); % Number of triggers
fprintf(SMU,sprintf(':TRIG:ACQ:TIM %d', Ts)); % setting the sampling time
% fprintf(SMU,sprintf(':TRIG:TRAN:DEL %d', 0.1*Ts));
% ------- Trace buffer -------
fprintf(SMU,':TRAC1:FEED:CONT NEV'); % Disable write Buffer (cant be cleared in next mode)
fprintf(SMU,':TRAC1:CLE'); % Clears trace buffer
fprintf(SMU,':TRAC1:FEED SENS'); % Specifies data to feed
fprintf(SMU,':TRAC1:FEED:CONT NEXT'); % Enables write Buffer

fprintf(SMU,':OUTPUT1 ON'); % turn on the channel
fprintf(SMU,':INIT (@1)'); % trigger
Main.TStart = datetime; % start time of the main

disp(strcat('A', {' '}, Direction, ' CCV_C process STARTED at:', {' '}, datestr(Main.TStart)))

tic
while toc <= 20*Ts % Measure first 20 samples with zero current
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
fprintf(SMU,sprintf(':SOUR1:CURR %d',Desired_Current)); % setting the current value after trigger

Main_Complete = false;
while ~Main_Complete % as long as the cycle is not complete do:
    Points = query(SMU,':TRAC1:POIN:ACT?');
    Points = str2num(Points); % convert it to a number (from string)
    if Points>=1 % to avoide problem in the beginning
        Data_Temp = query(SMU,sprintf(':TRAC1:DATA? %d,%d',Points-1,1));
        Data_Temp = str2num(Data_Temp); % convert to number
        
        % updating the figures
        addpoints(Voltage_Fig,Data_Temp(3),Data_Temp(1));
        addpoints(Current_Fig,Data_Temp(3),Data_Temp(2));
        drawnow
        
        if (Current_Direction == -1) && (Data_Temp(1) <= Final_Voltage) % for a discharge cycle
            Main_Complete =true;
        end
        
        if (Current_Direction == 1) && (Data_Temp(1) >= Final_Voltage) % for a charge cycle
            Main_Complete =true;
        end
    end
    pause(Ts) % wait for the duration of one sample    
end
Last_Current = Data_Temp(2);% store last current value

while Last_Current > End_Current
    Points = query(SMU,':TRAC1:POIN:ACT?');
    Points = str2num(Points); % convert it to a number (from string)
    Data_Temp = query(SMU,sprintf(':TRAC1:DATA? %d,%d',Points-1,1));
    Data_Temp = str2num(Data_Temp); % convert to number
    
    % updating the figures
    addpoints(Voltage_Fig,Data_Temp(3),Data_Temp(1));
    addpoints(Current_Fig,Data_Temp(3),Data_Temp(2));
    drawnow
    Last_Current = Data_Temp(2); % store last current value
    pause(Ts)
end

fprintf(SMU,':ABOR:ACQ (@1)'); % abort data collection
Main.TEnd = datetime;
disp(strcat(Direction, ' CCV_C process FINISHED at:', {' '}, datestr(Main.TEnd)))
fprintf(SMU,':OUTP1 OFF');

Main.Error = query(SMU,':SYST:ERR:ALL?'); % get errors
pause(1)
Main.VI = Bat_SMU_Data_Import(SMU);
fclose(SMU); % End of work at the SMU -------------------------------------

Main.Battery = Battery;
Main = orderfields(Main, {'Battery', 'VI', 'Error', 'TStart', 'TEnd'});

Date_Str = datestr(Main.TEnd,'yymmdd_HHMM');
Main_Name = strcat('M',Date_Str,'_B',num2str(Battery.Item),'_CCV_C_',Name_Extra,'_',num2str(abs(floor(1000*Desired_Current))),'mA');

SaveM([Str_Add,filesep,Main_Name], Main);