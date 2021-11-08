clear 
expIDs = {'mcosinteroc','brfs'}; % {'attn','evp','kanizsa'};
rignum = 22;
drobo = 'DROBO';

ct = 0; filelist={};

cd(sprintf('/Volumes/%s/DATA/NEUROPHYS/rig%03u',drobo,rignum))
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
                if strcmp(datafiles(d).name(10),'d')
                    continue
                end
                
                ct = ct+1;
                filelist{ct}= [pwd filesep datafiles(d).name];
            end
        end
        cd(sprintf('/Volumes/%s/DATA/NEUROPHYS/rig%03u',drobo,rignum))
    end
end
filelist = filelist';
filelist = flipud(filelist);

%%
FailedFiles = {};
errct = 0;
flag_combfilter = 1;
flag_checkforexisting = 1;
for eh = 1:3
    switch eh
        case 1
            ehead =  'eD';
        case 2
            ehead =  'eB';
        case 3
            ehead =  'eC';
    end
    
    for i = 1:length(filelist)
        for e = 20:-1:3
            try
                elable = sprintf('%s%02u',ehead,e);
                fprintf('\ni = %u e = %u\nrunning on %s - %s\n',i,e,filelist{i},elable)
                clear tMUA aMUA
                [tMUA, aMUA] = get1MUA(filelist{i},elable,flag_checkforexisting,flag_combfilter);
            catch err
                errct = errct+1;
                ERR{errct} = err;
                FailedFiles{errct,1} = filelist{i};
                FailedFiles{errct,2} = elable;
            end
        end
    end
end
FailedFiles