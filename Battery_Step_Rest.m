function [Main,End_Reached] = Battery_Step_Rest(SMU_Name, Battery, Direction, Current_level, Str_Add)
%% initialisations
Init_Time = 60; % initial time before starting application of steps
Time_level = 60*15; % duration of the step application 
Rest_Time = 4000;% 1 Rest time to stabilise the battery after the step
Battery.Ts = (Init_Time+Time_level+Rest_Time)/90000; % ~77 ms

switch  Direction
    case 'charge'
        Current_Direction = 1;
        Name_Extra = 'C';
    case 'discharge'
        Current_Direction = -1;
        Name_Extra = 'D';
    otherwise
        error('wrong state for the battery')
end

%% prepare online plotting
close all
figure
subplot(2,1,1)
title('Single Pulse Process')
Voltage_Fig = animatedline('LineStyle','none','Color','k','Marker','.');
ylabel('Voltage [V]')
grid on
subplot(2,1,2)
Current_Fig = animatedline('LineStyle','none','Color','k','Marker','.');
ylabel('Current [I]')
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
fprintf(SMU,':SOUR1:CURR:RANG:AUTO ON');
fprintf(SMU,':SOUR1:VOLT:RANG:AUTO ON');
fprintf(SMU,sprintf(':SENS1:VOLT:PROT %d',Battery.VMax)); % setting the maximum allowed voltage

fprintf(SMU,':SENS1:REM ON'); % 4wire measurement
fprintf(SMU,':FORM:ELEM:SENS VOLT,CURR,TIME'); % store only voltage, current values
fprintf(SMU,':TRIG:ACQ:SOUR TIM'); % triggers are time based
fprintf(SMU,':TRIG:ACQ:COUN INF'); % Number of triggers
fprintf(SMU,sprintf(':TRIG:ACQ:TIM %d', Battery.Ts)); % setting the sampling time
fprintf(SMU,sprintf(':TRIG:TRAN:DEL %d', 0.1*Battery.Ts));
% ------- Trace buffer -------
fprintf(SMU,':TRAC1:FEED:CONT NEV'); % Disable write Buffer (cant be cleared in next mode)
fprintf(SMU,':TRAC1:CLE'); % Clears trace buffer
fprintf(SMU,':TRAC1:FEED SENS'); % Specifies data to feed
fprintf(SMU,':TRAC1:FEED:CONT NEXT'); % Enables write Buffer

fprintf(SMU,':OUTPUT1 ON'); % turn on the channel
fprintf(SMU,':INIT (@1)'); % trigger
fprintf(SMU,':TRIG:TRAN (@1)');

Main.TStart = datetime; % start time of the main
disp(strcat('A Single Pulse Process STARTED at:', {' '}, datestr(Main.TStart)))
%% Measuring stable condition in the beginning
tic
while toc <= Init_Time % 1 min initial stable condition
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
    pause(Battery.Ts) % wait for the duration of one sample
end
%% Apply the current step and wait to stabilize
fprintf(SMU,sprintf(':SOUR1:CURR %d',Current_Direction*abs(Current_level))); % setting the current value
disp(strcat('Application of step STARTED at:', {' '}, datestr(datetime)))
End_Reached = false;
tic
while toc <= Time_level
    Points = query(SMU,':TRAC1:POIN:ACT?');
    Points = str2num(Points); % convert it to a number (from string)
    if Points>=1 % to avoide problem in the beginning
        Data_Temp = query(SMU,sprintf(':TRAC1:DATA? %d,%d',Points-1,1));
        Data_Temp = str2num(Data_Temp); % convert to number
        
        % updating the figures
        addpoints(Voltage_Fig,Data_Temp(3),Data_Temp(1));
        addpoints(Current_Fig,Data_Temp(3),Data_Temp(2));
        drawnow
        
        % break the process if max voltage is reached
        if strcmp(Direction,'charge') && Data_Temp(1)>= Battery.VMax
            End_Reached = true; % the limit voltage is reached
            Remained_Time = Time_level - toc; % to use this time as extra rest
            break % stop charging
        end
        % break the process if min voltage (cut-off) is reached
        if strcmp(Direction,'discharge') && Data_Temp(1)<= Battery.VMin
            End_Reached = true; % the limit voltage is reached
            Remained_Time = Time_level - toc; % to use this time as extra rest
            break % stop discharging
        end
    end
    pause(Battery.Ts) % wait for the duration of one sample
end
%% Remove the current step and wait to stabilize
fprintf(SMU,sprintf(':SOUR1:CURR %d',0)); % setting the current value to zero
fprintf(SMU,':SOUR1:CURR:RANG:AUTO:LLIM MIN'); % high accuracy measuring
disp(strcat('Application of step FINISHED at:', {' '}, datestr(datetime)))
if End_Reached 
    Rest_Time = Rest_Time + Remained_Time; % increase the rest time to the max possible
end
tic
while toc <= Rest_Time
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
    pause(Battery.Ts) % wait for the duration of one sample
end
%% end of single step experiment
fprintf(SMU,':ABOR:ACQ (@1)'); % abort data collection
Main.TEnd = datetime;
disp(strcat('Single Pulse Process FINISHED at:', {' '}, datestr(Main.TEnd)))
fprintf(SMU,':OUTP1 OFF');

Main.Error = query(SMU,':SYST:ERR:ALL?'); % get errors
pause(1)
Main.VI = Bat_SMU_Data_Import(SMU);
fclose(SMU); % End of work at the SMU -------------------------------------

Main.Battery = Battery;
Main = orderfields(Main, {'Battery', 'VI', 'Error', 'TStart', 'TEnd'});

Date_Str = datestr(Main.TEnd,'yymmdd_HHMM');
Main_Name = strcat('M',Date_Str,'_B',num2str(Battery.Item),'_SS_',Name_Extra,'_',num2str(abs(floor(1000*Current_level))),'mA');

if ~exist(strcat('Data\',Str_Add), 'dir')
    mkdir(strcat('Data\',Str_Add))
end
if ~exist(strcat('Fig\',Str_Add), 'dir')
    mkdir(strcat('Fig\',Str_Add))
end

SaveWithNumber(strcat('Data\',Str_Add,'\',Main_Name), Main)
savefig(strcat('Fig\',Str_Add,'\',Main_Name))