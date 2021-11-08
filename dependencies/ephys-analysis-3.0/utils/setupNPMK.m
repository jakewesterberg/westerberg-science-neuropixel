function setupNPMK(NPMK_folder)

% code to get the desired NPMK directory on path
% will remove other NPMK folders
% Modified from install NPMK
% July 2104 -MAC

% remove prexisting NPMK folders from search path
splitPath = regexp(path, ':', 'split');
for folderIDX = 1:size(splitPath, 2)
    if ~isempty(strfind(splitPath{folderIDX}, 'NPMK'))
        rmpath(splitPath{folderIDX});
    end    
end

% if no NPMK folder is specified, use the one in Documets that is forked from git
if nargin < 1
    NPMK_folder = '/Users/coxm/Documents/fNPMK/NPMK/';
end

% add NPMK and needed subfolders to search path
folderNames = dir(NPMK_folder);
folderNames(1:2) = [];

for folderIDX = 1:size(folderNames, 1)
    addpath(NPMK_folder);
    if folderNames(folderIDX).isdir && folderNames(folderIDX).name(1) ~= '@' && folderNames(folderIDX).name(1) ~= '.'
        addpath(fullfile(NPMK_folder, folderNames(folderIDX).name));
    end    
end