% This is to have a standard test to evaluate battery behavior over its
% life time
% This includes a complete charge cycle (Neutralizatin) and discharge at
% c-rate=0.1
close all

%% building the battery structure for the storage of the information
Battery = BatteryMaker(2);
%% Setting the Measurement device
SMU_Name = 'B2902A';
%% storage folder
Str_Add = 'BatteryTest';
%% Main process
Battery_Neutralize(SMU_Name, Battery, Str_Add); % bring battery to the standard point
Battery.Ts = 0.25;
Dis_Rate = 0.2; % rate of discharge
Battery_CC(SMU_Name, Battery, 'discharge', Dis_Rate, Battery.Ts, Str_Add)
