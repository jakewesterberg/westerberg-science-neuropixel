clear 

didir = '/Volumes/Drobo2/USERS/Michele/Dichoptic/diSTIM_Aug18/';


sortdir = '/Volumes/Drobo2/DATA/NEUROPHYS/KiloSort-ed/';
autodir = '/Volumes/Drobo2/DATA/NEUROPHYS/AutoSort-ed/';

list = dir([didir...
    '*_STIM.mat']);

mode = 'nev';

ct=0; clear filesto*
for i = 1:length(list)
    clear STIM
    load([didir list(i).name])
    
        
    filelist = STIM.filelist;
    
    for f = 1:length(filelist)
        
        filename = filelist{f};
        [~,BRdatafile,~] = fileparts(filename);
        
        switch mode
            case 'ss'
                if strcmp('160212_I_brfs001',BRdatafile)
                    continue
                end
                
                if exist([sortdir BRdatafile '/ss.mat'],'file')
                    if exist([sortdir BRdatafile '/' BRdatafile '.ns6.dat'],'file')
                        delete([sortdir BRdatafile '/' BRdatafile '.ns6.dat'])
                    end
                    continue
                elseif exist([sortdir BRdatafile '/rez.mat'],'file') ...
                        || ~exist([sortdir BRdatafile '/rez.mat'],'file') 
                    ct = ct+1;
                    filestosort{ct,1}=filename;
%                     ct = ct+1;
%                     fprintf('\ncreating and saving ss structure for %s...',BRdatafile)
%                     ss = KiloSort2SpikeStruct([sortdir BRdatafile],1);
%                     fprintf('done!\n')
%                     clear ss
%                     delete([sortdir BRdatafile '/' BRdatafile '.ns6.dat'])
                end
            case 'nev'
                if ~exist([autodir BRdatafile '.ppnev'],'file')
                    ct = ct+1;
                    filestoconvert{ct,1}=BRdatafile;
%                     fprintf('\ncreating and saving ppNEV for %s...',BRdatafile)
%                     [ppNEV, WAVES] = offlineBRAutoSort(filename);
%                     save([autodir BRdatafile '.ppnev'],'ppNEV','WAVES','-mat','-v7.3')
%                     fprintf('done!\n')
%                     clear ppNEV WAVES
                end
        end
    end
end