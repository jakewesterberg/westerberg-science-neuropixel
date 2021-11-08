
% Search for BR recordings on MacPro
% MAC 

expIDs = {'cosinteroc'};%'rsvp','cosinteroc'}; 
rignum = '022';
flag_checkforexisting = false; 
savepath = '/Volumes/DROBO/USERS/Michele/preprocessBR/extralp/';
if ~exist(savepath,'dir')
    mkdir(savepath);
end

ct = 0; filelist={};
currentFolder = pwd;
cd(['/Volumes/DROBO/DATA/NEUROPHYS/rig' rignum])% data path for BR data
listing = dir;

for l = 1:length(listing)
    if listing(l).isdir
        cd(listing(l).name)
        
        for e = 1:length(expIDs)
            
            datafiles = dir(sprintf('**%s**.ns6',expIDs{e}));
            if isempty(datafiles)
                continue
            end
           
            for d = 1:length(datafiles)
                if flag_checkforexisting && exist(sprintf('%s%s.mua',savepath,datafiles(d).name(1:end-4)),'file') > 0
                    continue
                else
                    ct = ct+1;
                    filelist{ct}= [pwd filesep datafiles(d).name];
                end
            end
        end
        cd(['/Volumes/DROBO/DATA/NEUROPHYS/rig' rignum])
    end
end
filelist = filelist';
filelist = flipud(filelist); % most recent files first in list
cd(currentFolder)
%%

failedFiles = {};
errors = {};
for i = 1:length(filelist)
    fprintf('\ndata file %u of %u\n',i,length(filelist))
    
    try
        preprocessBR_MUA(filelist{i},savepath)
    catch err
        failedFiles = [failedFiles; filelist(i)];
        errors = [errors; {err}];
        continue
    end
    
    
end
failedFiles
errors
