% This program is used to rename a variable in the workspace to a desired name and store it to a specific folder under the same name.
% This funstion takes two inputs:
%   First input is the storage address and desired file name all together as a string
%   Second input is the variable name in the workspace

% -------------------------------------------------------------------------
% A program by Mojtaba.Masoudinejad@tu-dortmund.de
% Last modification: 06.04.2019
% -------------------------------------------------------------------------
function SaveM(FileName, Data)

[fPath, fName, fExt] = fileparts(FileName); % parse the address name combination
% if extension is not given -> define it
if isempty(fExt)  % No '.mat' in FileName
    fExt = '.mat';
end
% If folder address does not exist make it
if ~isempty(fPath)&& ~exist(fPath, 'dir')
    mkdir(fPath)
end
% if file does not exist simply store
if ~exist(fullfile(fPath, [fName, fExt]))
    FinalName = fName;
else % if file exists
    Files = dir(fullfile(fPath,'*.mat')); % get list of all mat files
    OnlyNames = {Files.name}.'; % keep only the names
    % find those names containing desired name string
    ContainingNames = contains(OnlyNames, fName, 'IgnoreCase', true);
    OnlyNames(any(~ContainingNames,2))=[]; % remove all the others
    if length(OnlyNames) == 1 % if only 1 file remain
        FinalName = strcat(fName,'_1'); % add a one at the end and done
    else 
        % remove the file with the exact same name from the list
        OnlyNames(any(strcmp(OnlyNames,strcat(fName,fExt)),2))=[];
        % only file names with numbers are remained
        % remove file-name part of the strings
        Str2Remove = {fExt, strcat(fName,'_')};
        OnlyNumbers = erase(OnlyNames, Str2Remove);
        % convert remaining to numbers
        Numbers = str2double(OnlyNumbers);
        % Find the largest value and add one to it to make the new name
        FinalName = strcat(fName,'_', num2str(max(Numbers)+1));
    end 
end
eval([FinalName '= Data;']); % Data name in the workspace is changed
FileName = fullfile(fPath, [FinalName, fExt]); % File name is made
save(FileName, FinalName); % data stored