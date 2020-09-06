% This is to find the Voc of the battery at different SoC
% It is measured by applying a discharge step after a short rest time
% Step discharges the battery for 1 hour and then stores data for 4000 s of
% the rest period of the battery
% This is continued till the Vmin is reached.
% Afterwards, the current is reduced stepwise and repeated
close all

%% building the battery structure for the storage of the information
Battery = BatteryMaker(2);
%% Setting the Measurement device
SMU_Name = 'B2902A';
%% storage folder
Str_Add = 'VocMeasure';
%% bring battery to the standard point
Battery_Neutralize(SMU_Name, Battery, Str_Add); 

%% Apply steps till the Vmin is reached

End_Reached = false;
while ~End_Reached
    [~,End_Reached] = Battery_Step_Rest(SMU_Name, Battery, 'discharge', 50e-3, Str_Add);
end

End_Reached = false;
while ~End_Reached
    [~,End_Reached] = Battery_Step_Rest(SMU_Name, Battery, 'discharge', 25e-3, Str_Add);
end

End_Reached = false;
while ~End_Reached
    [~,End_Reached] = Battery_Step_Rest(SMU_Name, Battery, 'discharge', 10e-3, Str_Add);
end

End_Reached = false;
while ~End_Reached
    [~,End_Reached] = Battery_Step_Rest(SMU_Name, Battery, 'discharge', 5e-3, Str_Add);
end