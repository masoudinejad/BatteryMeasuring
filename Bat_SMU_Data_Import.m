%% This function imports the data from SMU and prepare them for saving
function VI = Bat_SMU_Data_Import(SMU)
Points = query(SMU,':TRAC1:POIN:ACT?');
Points = str2num(Points);
VI_Raw = query(SMU,':FETC:ARR? (@1)'); % read all stored data
VI_Raw = str2num(VI_Raw); % convert VI data to number
VI_Raw = vec2mat(VI_Raw,3); % separate voltage and current data
if Points == size(VI_Raw,1)
    disp('Data read success: 1st round')
else
    pause(10)
    VI_Raw = query(SMU,':FETC:ARR? (@1)'); % read all stored data
    pause(10)
    VI_Raw = str2num(VI_Raw); % convert VI data to number
    VI_Raw = vec2mat(VI_Raw,3); % separate voltage and current data
    
    if Points == size(VI_Raw,1)
        disp('Data read success: 2nd round')
    else
        error('Buffer read problem.')
    end
end
% store VI data into a table
V=VI_Raw(:,1);
I=VI_Raw(:,2);
Time = VI_Raw(:,3);
VI=table(Time,V,I);
VI.Properties.VariableUnits = {'Second','V','A'};