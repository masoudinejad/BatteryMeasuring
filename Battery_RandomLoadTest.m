% This is to test the battery under a random load signal
% each step value is randomly selected and will remain for a random
% duration ot time before the next step
close all

%% building the battery structure for the storage of the information
Battery = BatteryMaker(2);
%% Setting the Measurement device
SMU_Name = 'B2902A';
%% storage folder
Str_Add = 'RandomLoad';
%% bring battery to the standard point
Battery_Neutralize(SMU_Name, Battery, Str_Add); 
%% Build random profile
PassedIn = 10e3; % Number of steps in 1 round
No_Iterations = 60; % Number of iterations
Min_Current = -35e-3;
Max_Current = 150e-6;
Min_TimePeriod = 1;
Max_TimePeriod = 120;
Current_Level = Min_Current + (Max_Current-Min_Current)*rand(PassedIn*No_Iterations,1);
Time_Duration = Min_TimePeriod + (Max_TimePeriod-Min_TimePeriod)*rand(PassedIn*No_Iterations,1);
%% Do measure
Finish_State = false;
Iter = 0;
while ~Finish_State
    Start_Index = Iter*PassedIn +1;
    [~,Finish_State] = Battery_RandomLoadSingle(SMU_Name, Battery, 'discharge', Current_Level(Start_Index:Start_Index+PassedIn), Time_Duration(Start_Index:Start_Index+PassedIn), Str_Add);
    Iter = Iter+1;
end