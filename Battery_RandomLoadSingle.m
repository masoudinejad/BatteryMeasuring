function [Main,Finish_State] = Battery_RandomLoadSingle(SMU_Name, Battery, Direction, Current_Level, Time_Duration, Str_Add)
%% initialisations
Battery.Ts = 0.1;
Init_Time = 60; % initial time before starting application of steps
Rest_Time_End = 3600;% 1 Hour rest to stabilise the battery
% measurements
ActiveStep_Time = (90000-(Init_Time+Rest_Time_End)*(1/Battery.Ts))/(1/Battery.Ts);

%% prepare online plotting
close all
figure
subplot(2,1,1)
title('Random Dynamic Current Pulse Process')
Voltage_Fig = animatedline('LineStyle','none','Color','b','Marker','.');
ylabel('Voltage [V]')
grid on
subplot(2,1,2)
Current_Fig = animatedline('LineStyle','none','Color','b','Marker','.');
ylim([-36e-3 155e-6]); % limitation according to the signal range
ylabel('Current [A]')
xlabel('Time [s]')
grid on
%% setting the SMU
SMU = visa_connector(SMU_Name); % build the visa object
fopen(SMU); % connect to the object
pause(0.1)
query(SMU,':SYST:ERR:ALL?'); % clearing old errors
fprintf(SMU,'*RST'); % reset the measurement device

% set the SMU as a current source with the desired values
fprintf(SMU,':SOUR1:FUNC:MODE CURR'); % it is a current source
fprintf(SMU,':SOUR1:CURR:MODE FIX');
fprintf(SMU,':SOUR1:CURR:RANG:AUTO ON');
fprintf(SMU,sprintf(':SOUR1:CURR %d',0)); % setting the current value
fprintf(SMU,sprintf(':SOUR1:CURR:TRIG %d',0)); % setting the current value after trigger
fprintf(SMU,sprintf(':SENS1:VOLT:PROT %d',Battery.VMax)); % setting the maximum allowed voltage

fprintf(SMU,':SENS1:REM ON'); % 4wire measurement
fprintf(SMU,':FORM:ELEM:SENS VOLT,CURR,TIME'); % store only voltage, current values
fprintf(SMU,':TRIG:ACQ:SOUR TIM'); % triggers are time based
fprintf(SMU,':TRIG:ACQ:COUN INF'); % Number of triggers
fprintf(SMU,sprintf(':TRIG:ACQ:TIM %d', Battery.Ts)); % setting the sampling time
% fprintf(SMU,sprintf(':TRIG:TRAN:DEL %d', 0.1*Battery.Ts));

% ------- Trace buffer -------
fprintf(SMU,':TRAC1:FEED:CONT NEV'); % Disable write Buffer (cant be cleared in next mode)
fprintf(SMU,':TRAC1:CLE'); % Clears trace buffer
fprintf(SMU,':TRAC1:FEED SENS'); % Specifies data to feed
fprintf(SMU,':TRAC1:FEED:CONT NEXT'); % Enables write Buffer

fprintf(SMU,':OUTPUT1 ON'); % turn on the channel
fprintf(SMU,':INIT (@1)'); % trigger
Main.TStart = datetime; % start time of the main
disp(strcat('A Random Dynamic Current Pulse Process STARTED at:', {' '}, datestr(Main.TStart)))
%% Measuring stable condition for 1 min
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
disp(strcat('Application of random steps STARTED at:', {' '}, datestr(datetime)))
Step_counter = 0;
Finish_State = false;

tic
while toc <= ActiveStep_Time && ~Finish_State
    Start_Time = toc;
    Step_counter = Step_counter+1;
    if Step_counter >= length(Current_Level)
        break
    end
    fprintf(SMU,sprintf(':SOUR1:CURR %d',Current_Level(Step_counter))); % setting the current value
    while toc-Start_Time <= Time_Duration((Step_counter)) && toc <= ActiveStep_Time
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
                Finish_State = true;
                break
            end
            % break the process if min voltage (cut-off) is reached
            if strcmp(Direction,'discharge') && Data_Temp(1)<= Battery.VMin
                Finish_State = true;
                break
            end
        end
        pause(Battery.Ts) % wait for the duration of one sample
    end
end
%% Remove the current step and wait to stabilize
fprintf(SMU,sprintf(':SOUR1:CURR %d',0)); % setting the current value to zero
fprintf(SMU,':SOUR1:CURR:RANG:AUTO:LLIM MIN'); % high accuracy measuring
disp(strcat('Application of random steps FINISHED at:', {' '}, datestr(datetime)))
tic
while toc <= Rest_Time_End
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
%% end of single experiment
fprintf(SMU,':ABOR:ACQ (@1)'); % abort data collection
Main.TEnd = datetime;
disp(strcat('Random Dynamic Current Pulse Process FINISHED at:', {' '}, datestr(Main.TEnd)))
fprintf(SMU,':OUTP1 OFF');

Main.Error = query(SMU,':SYST:ERR:ALL?'); % get errors
pause(1)
Main.VI = Bat_SMU_Data_Import(SMU);
fclose(SMU); % End of work at the SMU -------------------------------------

Main.Battery = Battery;
Main = orderfields(Main, {'Battery', 'VI', 'Error', 'TStart', 'TEnd'});

Date_Str = datestr(Main.TEnd,'yymmdd_HHMM');
Main_Name = strcat('M',Date_Str,'_B',num2str(Battery.Item),'_RA');

SaveM([Str_Add,filesep,Main_Name], Main);