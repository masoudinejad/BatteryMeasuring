function SaveWithNumber(FileName, Data)
[fPath, fName, fExt] = fileparts(FileName);
if isempty(fExt)  % No '.mat' in FileName
  fExt     = '.mat';
  FileName = fullfile(fPath, [fName, fExt]);
end
if exist(FileName, 'file')
  % Get number of files:
  fDir     = dir(fullfile(fPath, [fName, '*', fExt]));
  fStr     = lower(sprintf('%s*', fDir.name));
  fNum     = sscanf(fStr, [fName, '%d', fExt, '*']);
  if isempty(fNum)
      fNum=0;
  end
  newNum   = max(fNum) + 1;
  NewName = strcat(fName,'_',num2str(newNum));
  
else
    NewName = fName;
end
eval([NewName '= Data;'])
FileName = fullfile(fPath, [NewName, fExt]);
save(FileName, NewName);