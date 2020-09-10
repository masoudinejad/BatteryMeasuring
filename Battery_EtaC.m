% This function is to find the discharge curve at different current levels
function Battery_EtaC(Battery, CurrentList)
%% Setting the Measurement device
SMU_Name = 'B2902A';
%% storage folder
Str_Add = ['Data',filesep,'EtaC'];
%% Main process
for Ident_Current = CurrentList
    Battery_StandardTest(Battery) % Run the standard test
    pause(5*60)
    Battery_Initialize(SMU_Name, Battery, Str_Add, 'Full'); % bring battery to the Init point
    % Find the optimal sampling time
    Max_Capacity = 1.1*Battery.Capacity*3600; % Max capacity considering 10% extra than nominal
    Battery.Ts = 0.01*ceil((100*Max_Capacity/Ident_Current)/95000);
    % Find the rate
    Dis_Rate = Ident_Current/Battery.Capacity;
    % do discharge
    Battery_CC(SMU_Name, Battery, 'discharge', Dis_Rate, Battery.Ts, Str_Add)
end
