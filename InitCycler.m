% This is to evaluate if the rest curve is dependent on the current
clear
close all

%% building the battery structure for the storage of the information
Battery = BatteryMaker(2);
%% Setting the Measurement device
SMU_Name = 'B2902A';
%% storage folder
Str_Add = 'InitCycler';
%% Cycle
Battery.Ts = 0.2;
for Cycle = 1:3
    Battery_CCV(SMU_Name, Battery, 'charge', 0.8, Battery.Ts, 30*60, Str_Add); %1A
    pause(30*60)
    Battery_CC(SMU_Name, Battery, 'discharge', 0.5, Battery.Ts, Str_Add)
    pause(5*60)
    Battery_CC(SMU_Name, Battery, 'discharge', 0.1, Battery.Ts, Str_Add)
    pause(5*60)
    Battery_CC(SMU_Name, Battery, 'discharge', 0.05, Battery.Ts, Str_Add)
    pause(10*60)
end