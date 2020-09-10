% This function is considered as a standard test to evaluate battery
% behavior with the same condition
% It brings it to the initial point and discharges with the nominal current
function Battery_StandardTest(Battery)
%% Setting the Measurement device
SMU_Name = 'B2902A';
%% storage folder
Str_Add = ['Data',filesep,'StandardTest'];
%% Main process
Battery_Initialize(SMU_Name, Battery, Str_Add, 'Full'); % bring battery to the Init point
% calculation of the best sample time
Dis_Rate = Battery.IStandardRatio; % <<<<<<<<<<<<<<<<<<< rate of discharge
Dis_Current = Dis_Rate*Battery.Capacity;
Max_Capacity = 1.1*Battery.Capacity*3600; % Max capacity considering 10% extra than nominal
Battery.Ts = 0.01*ceil((100*Max_Capacity/Dis_Current)/95000);
% Do discharge with the standard rate
Battery_CC(SMU_Name, Battery, 'discharge', Dis_Rate, Battery.Ts, Str_Add)
