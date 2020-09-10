% This function identifies the battery behavior at slow rates
% these curves can be used as the relation between Vemf-SoC
function Battery_SoCVemf_C(Battery, IdentRate)
%% Setting the Measurement device
SMU_Name = 'B2902A';
%% storage folder
Str_Add = ['Data',filesep,'SoCVemf',filesep,'Continuous'];
%% Go to the Init point
Battery_Initialize(SMU_Name, Battery, Str_Add, 'Full'); 
%% Calculation of the best sample time
Ident_Current = IdentRate*Battery.Capacity;
Max_Capacity = 1.1*Battery.Capacity*3600; % Max capacity considering 10% extra than nominal
MainTs = 0.01*ceil((100*Max_Capacity/Ident_Current)/95000);
Battery.Ts = MainTs;
%% Discharge section
Battery_CC(SMU_Name, Battery, 'discharge', IdentRate, Battery.Ts, Str_Add);
%% Assure battery is empty
pause(30*60) % rest for 1stabilization
Battery.Ts = 0.1;
Battery_CC(SMU_Name, Battery, 'discharge', Battery.IInfiniRatio, Battery.Ts, Str_Add); % discharge with infinitesimal current
Battery_Chirp02(SMU_Name, Battery, Battery.VMin, Str_Add); % destroy hysteresis
pause(60*60) % rest for 1 hour
%% Charge section
Battery.Ts = MainTs; % reload the main sample time to the battery object
Battery_CC(SMU_Name, Battery, 'charge', IdentRate, Battery.Ts, Str_Add);
pause(5*60)
%% Bring the battery to a normal condition
DesireVoltage = Battery.VNom; % 3.7 V
Battery_ShelfReady(Battery, DesireVoltage)
pause(60*60)