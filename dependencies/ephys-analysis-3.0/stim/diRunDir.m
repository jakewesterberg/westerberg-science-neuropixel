%% DiRunDir %%
% User inputs:
% Select analysis and datatype. DiNeuralDat analysis runs for different
% types of data.

%%%%%%%%%%%%%%%%%%%%%%%%%%
% Available data types:
% kls - kilosort
% nev - online sorted single units
% auto - autosorted - dMUA
% mua - analog multi-unit. Band pass filtered LFP
% csd - Current Source Density
% lfp - LFP.
%%%%%%%%%%%%%%%%%%%%%%%%%%

clear

ana = {'diNeuralDat','filecheck'};
[analysis, v] = listdlg('PromptString','Choose analysis: ','SelectionMode','single',...
    'ListString',ana,'ListSize',[150,125]);

if v == 0 
    clear
    disp('Canceled');
    return
end
 
data_options = {'auto','kls','mua','nev','csd','lfp'};
[data, v] = listdlg('PromptString','What type of data?','SelectionMode','single',...
    'ListString',data_options, 'ListSize',[150,125]);

if v == 1
    datatype = data_options{data};
else
    clear
    disp('Canceled');
    return
end

if isequal(datatype,'kls')
    task_options = {'mcosinteroc','brfs'};
    [taskIDX, v] = listdlg('PromptString','Select tasks:','SelectionMode','single',...
        'ListString',task_options, 'ListSize',[150,125]);
    
    if v == 1
        global tasks
        tasks = task_options{taskIDX};
        disp('Running....');
    else
        clear
        return
    end
end

clustering = false;  % clustering support not available yet 9/9/20
flag_checkforexisting = false;

global STIMDIR
if ~isempty(STIMDIR)
    didir = STIMDIR; % STIMDIR should contain the STIM structures for sessions of interest. 
else
    didir = '/Volumes/LaCie/Dichoptic Project/vars/diSTIM_Dec12/';
end
cd(didir)
list = dir([didir '2*.mat']); % need a better way to Identify .mat files we need. 
I = cellfun(@length,{list.name}) == 15;
list = list(I);  %creates a list of STIM.mat files 

ct = 0; 
for i = 1:length(list)
    
    switch analysis
        case 1  %diNeuralDat

            tic
            clear STIM RESP SDF sdftm PSTH psthtm CLUST
            load([didir list(i).name],'STIM')
            
            % clustering for kls - BM 5/29/20
            if strcmp(datatype,'kls')    
                
                list(i).name
                
                if strcmp(list(i).name,'151231_E_eD.mat')
                    warning('phy files not found for 151231')
                    continue
                elseif strcmp(list(i).name,'160108_E_eD.mat')
                    warning('phy WHOLE DIRECTORY not found for 160108')
                    continue
                elseif strcmp(list(i).name,'160111_E_eD.mat')
                    warning('phy WHOLE DIRECTORY not found for 160111')
                    continue
                end
                    STIM.units = []; STIM.kls = [];
                    if clustering == true
                        error('Clustering units across files is not yet supported');
                        % fprintf('\nrunning diClusters on %s...',STIM.penetration)
                        % STIM = diClusters(STIM);
                    else
                        clear j count
                        count = 0;
                        for j = 1:length(STIM.filelist)
                            clear filecheck
                            filecheck = contains(STIM.filelist(j),tasks);
                        end
                        if ~filecheck
                            warning(strcat('penetration has no ',tasks,' file'))
                            continue
                        end

                        fprintf('\nrunning importPhy on %s...',STIM.penetration)
                        [STIM,fileError]  = importPhy(STIM);
                        if fileError
                            warning('fileError is true')
                            continue
                        end
                    end
                    save([didir list(i).name],...
                        'STIM','-append')
                    fprintf('...DONE!\n')
            end
          
            datastr = upper(datatype);
            matname = [didir list(i).name(1:end-4) '_' datastr '.mat'];
            
            if flag_checkforexisting &&  exist(matname,'file')
                clear STIM
                continue
            end
            
            % diNeuralDat pulls out the photo-diode triggered data and
            % creates the following variables.
            
            if strcmp(datatype,'kls')
                [RESP, win_ms, SDF, sdftm, PSTH, psthtm, SUA, spktm]= diNeuralDat_usePhy(STIM,datatype,true);
                save(matname,...
                    'STIM','RESP','win_ms','SDF','sdftm','PSTH','psthtm','SUA',...
                    '-v7.3')
            else
                [RESP, win_ms, SDF, sdftm, PSTH, psthtm]= diNeuralDat(STIM,datatype,true);
                save(matname,...
                    'STIM','RESP','win_ms','SDF','sdftm','PSTH','psthtm',...
                    '-v7.3')
            end
            
            toc
            
        case 2 % Filecheck
            clear STIM
            load([didir list(i).name],'STIM')            
            filelist = STIM.filelist;
            for f = 1:length(filelist)
                filename = filelist{f};
                [~,BRdatafile,~] = fileparts(filename);
                
                if ~exist([sortdir BRdatafile '/ss.mat'],'file')
                    ct = ct +1; 
                    MISSING{ct,1} = 'ss';
                    MISSING{ct,2} = BRdatafile;
                    MISSING{ct,3} = filename;
                end
                 if ~exist([autodir BRdatafile '.ppnev'],'file')
                    ct = ct +1; 
                    MISSING{ct,1} = 'ppnev';
                    MISSING{ct,2} = BRdatafile;
                    MISSING{ct,3} = filename;
                end
            
            
            end
            
    end
end

load gong
sound(y,Fs)
