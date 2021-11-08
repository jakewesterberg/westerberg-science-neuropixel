function filelist = getFilesOnDisk(expIDs,rignums,flag_checkforexisting)

% expIDs = {'cosinteroc','brfs'};%'rsvp','cosinteroc'};
% rignum = '022';
% flag_checkforexisting = false;

if ~iscell(expIDs)
    expIDs = {expIDs};
end
if ~iscell(rignums)
    rignums = {rignums};
end

ct = 0; filelist={};
currentFolder = pwd;

for r = 1:length(rignums)
    cd(['/Volumes/DROBO/DATA/NEUROPHYS/rig' rignums{r}])% data path for BR data
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
                        [~,filename,~] = fileparts(datafiles(d).name);
                        filelist{ct,1} = [pwd filesep filename];
                    end
                end
            end
            cd(['/Volumes/DROBO/DATA/NEUROPHYS/rig' rignums{r}])
        end
    end
end
cd(currentFolder)