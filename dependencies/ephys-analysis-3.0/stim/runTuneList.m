clear; close all

analysis     = 'BMC_BM 2021';
flag_checkforexisting = false;
flag_UseRigDir        = true;

%% TuneList setup
% load everything in from TuneList
TuneList = importTuneList(4);  % change the input argument (1, 2 or 3)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this selection restricts which days you look at to gather files. 
% The penetration must have one of the
% tasks. From there, you can select which
% tasks you want to look at later (down
% below)
                               
% % case {1,'all di tasks','dionly','ditasks'}
% % ditasks = {'cosinteroc','mcosinteroc','dmcosinteroc','brfs','dbrfs', 'rsvp'};
% %
% % case {2,'brfs','Brock'} % Brock
% % ditasks = {'brfs'};
% %
% % case {3, 'brock_blake'} % Brock Blake
% % ditasks = {'cosinteroc','mcosinteroc','brfs'};
% % 
% % case {4, 'BMC_BM 2021'} % 2021 Recordings in 021 Rig
% % ditasks = {'bminteroc','bmcBRFS'};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    
% cut down TuneList to only analyze files from a given RIGDIR if needed for testing.    
if flag_UseRigDir
    global RIGDIR
    list = dir([RIGDIR]);
    dirlist = cellfun(@(x,y) sprintf('%s_%s',x,y),TuneList.Datestr,TuneList.Monkey,'UniformOutput',false);

    I = ismember(dirlist,{list.name}); % logical output
     fields = fieldnames(TuneList);
        for f = 1:length(fields)
            TuneList.(fields{f})(~I) = [];
        end
end

errct = 0;
%% Save Path


% setup save path
switch analysis
    case {'diSTIM','hyper-dMUA','BMC_BM 2021'}
        global STIMDIR
        if ~isempty(STIMDIR)
            varsavepath  = STIMDIR;
        else
            sprintf('/Volumes/LaCie/Dichoptic Project/vars/%s_%s/',analysis,datestr(now,'mmmdd'));
        end
    case 'offlineBRAutoSort'
        varsavepath  = sprintf('/Volumes/Drobo2/DATA/NEUROPHYS/AutoSort-ed/');
    case {'list','ss'}
        varsavepath = [];
    otherwise
        varsavepath  = sprintf('/Volumes/Drobo2/USERS/Michele/Dichoptic/%s_%s/',analysis,datestr(now,'mmmdd'));
end
if ~isempty(varsavepath) && ~exist(varsavepath,'dir')
    mkdir(varsavepath);
end

% setup paradigm filelist
switch analysis
    case 'BMC_BM 2021'
        paradigm = {'bminteroc'};
    case 'diSTIM' % These are the paradigms to pull out into filelist
        paradigm = {...
            'rfori','rfsf','rfsize',... 'drfori','rfsfdrft',...
            'cosinteroc','mcosinteroc','brfs',...'dmcosinteroc',...'rsvp'
            };
    case 'hyper-dMUA'
        paradigm = {'evp'};
    case 'quick_ditiming_ana' % July 25, 2016
        paradigm = {'mcosinteroc'};
    case 'getRF'
        paradigm     = {'dotmapping'};
    case 'offlineBRAutoSort'
        paradigm = {'dotmapping'};%,'rfori','rfsf','rfsfdrft','mcosinteroc','rfsize','evp','mcosinteroc'    'cosinteroc'    'brfs' ,'rsvp','dmcosinteroc'};
        %  paradigm = {'mcosinteroc'    'cosinteroc'    'brfs' ,'rsvp' };
        % paradigm = {'rfsfdrft'};
        %fn=fieldnames(TuneList);
        %paradigm = fn([14 16:end-3]);
        %paradigm = {'dmcosinteroc'};
    case 'V1Limits'
        paradigm = {'dotmapping','rfori'};
        clear ALIGN
    case 'list'
        %paradigm = {'rfori','rfsize','mcosinteroc','brfs','rsvp'};%paradigm = {'rfori','rfsize','mcosinteroc','brfs'};
        %paradigm = {'rfori','mcosinteroc','rsvp'};
        paradigm = {'dmcosinteroc'};
    case 'fftdriftana'
        paradigm = {'drfori', 'rfsfdrft'};
    case 'ss'
        fn=fieldnames(TuneList);
        paradigm = fn([14 16:end-3 end-1]);
    otherwise
        paradigm     = {'rfori'};
end



for s = 1:length(TuneList.Penetration) 
    clearvars -except list STIM0 RATIO ALIGN ERR s TuneList flag_checkforexisting varsavepath paradigm analysis errct
    
    clear header el penetration
    penetration = TuneList.Penetration{s};
    if strcmp(penetration,'151222_E_eD')
        warning('no bhv found for 151222. Check on Drobo after restart')
        continue
    end
    header = TuneList.Penetration{s}(1:end-3);
    el     = TuneList.Penetration{s}(end-1:end);
%     if flag_checkforexisting && (~strcmp(analysis,'diSTIM') && ~strcmp(analysis,'offlineBRAutoSort') &&  ~strcmp(analysis,'V1Limits') && ~strcmp(analysis,'ss') )%&& exist([varsavepath header '_' el '.mat'],'file')
%         error('flag_checkforexisting working?')
%         continue
%     end
    
    disp(s);
    disp(TuneList.Penetration{s});
    
    clear sortdirection
    sortdirection = TuneList.SortDirection{s};
    
    clear drobo
    switch TuneList.Drobo(s)
        case 1
            drobo = 'Drobo';
        otherwise
            drobo = sprintf('Drobo%u',TuneList.Drobo(s));
    end
    
    % build session filelist
    ct = 0; filelist = {};
    for p = 1:length(paradigm)
        
        if strcmp(paradigm{p},'rsvp')
            tf =     strcmp('ori', getRSVPTaskType(TuneList.Datestr{s}));
            if tf
                continue
            end
        end
        
        clear exp
        exp = TuneList.(paradigm{p}){s};
        for d = 1:length(exp)
            ct = ct + 1;
            global RIGDIR
            if ~isempty(RIGDIR)
                filelist{ct,1} = strcat(...
                    RIGDIR,...
                    TuneList.Datestr{s},'_',TuneList.Monkey{s},filesep,...
                    TuneList.Datestr{s},'_',TuneList.Monkey{s},'_',paradigm{p},sprintf('%03u',exp(d)));                
            else
                filelist{ct,1} = sprintf('/Volumes/%s/Data/NEUROPHYS/rig%03u/%s_%s/%s_%s_%s%03u',...
                    drobo,TuneList.Rig(s),TuneList.Datestr{s},TuneList.Monkey{s},TuneList.Datestr{s},TuneList.Monkey{s},paradigm{p},exp(d));
            end
        end
    end
    
    if isempty(filelist)
        warning('Filelist was empty')
        continue
    end
    
    switch analysis
        
        case 'BMC_BM 2021'
              
            if flag_checkforexisting && exist([varsavepath penetration '.mat'],'file')
                warning('STIM exists. Penetration skipped')
                continue
            end
            
            % get info from TuneList
            clear idx pn
            idx = find(strcmp(TuneList.Datestr,header(1:6)));
            pn  = find(strcmp(TuneList.Penetration(idx),penetration));
            
            % get TPs (timepoints)
            clear STIM V1 STIM0
            V1 = TuneList.Structure{s};
            STIM = diTP(filelist,V1);
            STIM.V1   = V1;
            STIM.penetration = penetration;
            
            % diCheck
            [pass, message] = diCheck(STIM);
            STIM.message = message;
            if ~pass
                errct = errct +1;
                ERR{errct,1} = header;
                ERR{errct,2} = el;
                ERR{errct,3} = message;
                save([varsavepath 'ERR'],'ERR','s','TuneList')
            end
            % photodiode trigger
            trigger = 'custom';
            
            if str2double(penetration(1:2)) > 19 % if this file is newer than 2019
                [STIM,fails] = diPT_2021(STIM,trigger);
            else
                [STIM,fails] = diPT(STIM);
            end
            
            if any(fails)
                errct = errct +1;
                ERR{errct,1} = header;
                ERR{errct,2} = el;
                ERR{errct,3} = 'fail photodiode trigger';
                save([varsavepath 'ERR'],'ERR','s','TuneList')
                continue
            end
            % V1 lim
            STIM.rmch = TuneList.BadBtmCh(idx(pn));
            
            if str2double(penetration(1:2)) > 19
                global RIGDIR
                cd(RIGDIR)
                tempV1limInfo = load('ref_v1lim.mat');
                STIM.el_labels    =  tempV1limInfo.el_labels;
                STIM.depths       =  tempV1limInfo.depths;        
                STIM.v1lim         = tempV1limInfo.v1lim;
                warning('V1Limits for data after 2021 are not yet implemented -BM')
                
            else 
                STIM = diV1Lim(STIM,pn);
                if ~strcmp(STIM.penetration,penetration)
                    error('penetrations are messed up')
                end
            end
            
            STIM.rank = TuneList.Rank(idx(pn));
            % check stimulus overlap
            % %             if all(STIM.overlap(~strcmp(STIM.task,'rfsize')) < 0.9)
            % %                 warning('BMC commented out rfsize overlap error... 6-29-2020')
            % %
            % %             end
            
            
            % Save STIM structure 
            save([varsavepath STIM.penetration '.mat'],...
                'STIM', '-v7.3')
            clear STIM
            
        
        case {'diSTIM','hyper-dMUA'}
            
%           
            if flag_checkforexisting && exist([varsavepath penetration '.mat'],'file')
                warning('STIM exists. Penetration skipped')
                continue
            end
            
            if strcmp(penetration,'170724_I_eD')
                warning('penetration skipped. Problems with NS packet size in photoReTriggerSTIM. Salvage Data later')
                continue
            end
            
            % get info from TuneList
            clear idx pn
            idx = find(strcmp(TuneList.Datestr,header(1:6)));
            pn  = find(strcmp(TuneList.Penetration(idx),penetration));
            
           % get TPs
            clear STIM V1 STIM0
            V1 = TuneList.Structure{s};
            STIM = diTP(filelist,V1);
            STIM.V1   = V1;
            STIM.penetration = penetration;
            
            % diCheck
            [pass, message] = diCheck(STIM);
            STIM.message = message;
            if ~pass 
                errct = errct +1;
                ERR{errct,1} = header;
                ERR{errct,2} = el;
                ERR{errct,3} = message;
                save([varsavepath 'ERR'],'ERR','s','TuneList')
            end
            
            % photodiode trigger
            [STIM,fails] = diPT(STIM); 
            if any(fails)
                errct = errct +1;
                ERR{errct,1} = header;
                ERR{errct,2} = el;
                ERR{errct,3} = 'fail photodiode trigger';
                save([varsavepath 'ERR'],'ERR','s','TuneList')
                continue
            end
            
            % V1 lim
            STIM.rmch = TuneList.BadBtmCh(idx(pn));
            
            if str2double(penetration(1:2)) > 19 % we will put these in manually for files after 2019, for now
                warning('V1 limits need to be input manually');
                STIM.rf_xyr = [];
                STIM.overlap = [];
                STIM.el_labels = [];
                STIM.depths = [];
                STIM.v1lim = [nan, nan, nan];
            else
                STIM = diV1Lim(STIM,pn);
                if ~strcmp(STIM.penetration,penetration)
                    error('penetrations are messed up')
                end
                STIM.rank = TuneList.Rank(idx(pn));
                
                % check stimulus overlap
                if all(STIM.overlap(~strcmp(STIM.task,'rfsize')) < 0.9)
                    warning('BMC commented out rfsize overlap error... 6-29-2020')
                    %                 errct = errct +1;
                    %                 ERR{errct,1} = header;
                    %                 ERR{errct,2} = el;
                    %                 ERR{errct,3} = 'stimulus overlap < 90% on ALL trials';
                    %                 save([varsavepath 'ERR'],'ERR','s','TuneList')
                    %                 continue
                end
            end
            
%             
            save([varsavepath STIM.penetration '.mat'],...
                'STIM', '-v7.3')
            clear STIM
            
                                            
        case 'ss'
            
            sortdir = '/Volumes/Drobo2/DATA/NEUROPHYS/KiloSort-ed/';

            for f = 1:length(filelist)
                
                filename = filelist{f};
                [~,BRdatafile,~] = fileparts(filename);
                
                if flag_checkforexisting && ...
                        exist([sortdir BRdatafile '/ss.mat'],'file')
                    continue
                elseif exist([sortdir BRdatafile '/rez.mat'],'file')
                        fprintf('\ncreating and saving ss structure for %s...',BRdatafile)
                        ss = KiloSort2SpikeStruct([sortdir BRdatafile],1);
                        fprintf('done!\n')
                        clear ss
                end
            end
        
        case 'fftdriftana'
            
            %limdir = '/Volumes/Drobo2/USERS/Michele/Dichoptic/V1Limits_Jul31/';
            %load([limdir TuneList.Penetration{s} '.mat'],'v1lim');
            
            
            output   = fftdriftana(filelist{1});
            if isempty(output)
                continue
            end
                   
            datatype = fieldnames(output);
            L4 = TuneList.SinkBtm(s); % electrode label number

            for d = 1:length(datatype)
                probe   = cellfun(@(x) x(1:2), output.(datatype{d}).elabel,'UniformOutput',0);
                elnum    = cellfun(@(x) str2double(x(3:4)), output.(datatype{d}).elabel);
                I = strcmp(probe,el);
                elnum = elnum(I);
                output.(datatype{d}).f0 = output.(datatype{d}).f0(I);
                output.(datatype{d}).fnot = output.(datatype{d}).fnot(I);
                
                clear y
                switch sortdirection
                    case 'ascending'
                        y = L4 - elnum;
                    case 'descending'
                        y = elnum - L4;
                end
                
                output.(datatype{d}).y=y;
                output.(datatype{d}).s = ones(size(y)); 
                output.(datatype{d}).s(:) = s; 
                output.(datatype{d})=rmfield(output.(datatype{d}),'elabel');
            end
            
            if ~exist('RATIO','var')
                RATIO = output;
            else
                
                for d = 1:length(datatype);
                    RATIO.(datatype{d}).f0 = ...
                        cat(1,RATIO.(datatype{d}).f0,output.(datatype{d}).f0);
                    RATIO.(datatype{d}).fnot = ...
                        cat(1,RATIO.(datatype{d}).fnot,output.(datatype{d}).fnot);
                    RATIO.(datatype{d}).y = ...
                        cat(1,RATIO.(datatype{d}).y,output.(datatype{d}).y);
                     RATIO.(datatype{d}).s = ...
                        cat(1,RATIO.(datatype{d}).s,output.(datatype{d}).s);
                end
            end

        case 'quick_ditiming_ana'
            % July 25, 2016
            
            clear nev_sig limfile
            
            limfile = ['/Volumes/Drobo2/USERS/Michele/Dichoptic/V1Limits_Jul24/' header '_' el '.mat'];
            if ~exist(limfile,'file')
                continue
            end
            load(limfile,'nev_sig')
            
            
            STIM = getDiTPs(filelist);
                     
        case 'V1Limits'
            clearvars -except paradigm flag_* sortdirection ALIGN analysis errct filelist varsavepath header el TuneList s
            
            if flag_checkforexisting ...
                    && exist([varsavepath header '_' el '.mat'],'file')
                
                load([varsavepath header '_' el '.mat'],'v1lim','elabel')
                
                
            else
                dots = cellfun(@(x) ~isempty(strfind(x,'dotmapping')),filelist); % logical index of dotmapping files from "filelist"
                
                EV = getEVOKED(filelist(~dots),el,sortdirection,'nev',0);
                
                RF = getRF(filelist(dots),el,sortdirection,{'auto'});
                
                rfdatatype = 'nev_zsr';
                crit0 = 1;
                dthresh = 0.5;
                flag_nev = 1;
                if ~any(EV.nev_sig)
                    I = [];
                else
                    I = find(EV.nev_sig(:,1),1,'first') - 1 : find(EV.nev_sig(:,1),1,'last') + 1;
                    I(I<1 | I>length(EV.elabel)) = [];
                end
                
                [uRF, xcord, ycord, elabel]= meanRF(RF,rfdatatype);
                [fRF, dRF, rflim]   = fitRF(uRF,xcord,ycord,I,crit0,dthresh,flag_nev);
                
                save([varsavepath header '_' el '.mat'],'EV','RF','rfdatatype','uRF','xcord','ycord','elabel','fRF','dRF','I','dthresh','crit0','-v7.3')
                
                clear v1lim
                if ~any(EV.nev_sig)
                    v1lim = [rflim NaN NaN];
                else
                    v1lim = [rflim...
                        find(EV.nev_sig(:,1),1,'first') ...
                        find(EV.nev_sig(:,1),1,'last') ];
                end
                save([varsavepath header '_' el '.mat'],'v1lim','-append')
                
                
                close all
                plotRF
                h(3) = figure('Position',[0 0 601 874]);
                imagesc(EV.nevtm,1:length(EV.elabel),nanmean(EV.nev_dif,3)'); hold on
                plot(xlim,[v1lim(3) v1lim(3)]-.5,'m')
                plot(xlim,[v1lim(4) v1lim(4)]+.5,'m')
                plot([0 0],ylim,'k');
                set(gca,'TickDir','out','Box','off')
                xlabel('Time (ms)')
                ylabel('Contact from Most Superfical')
                title([header '_' el],'interpreter','none')
                y = colorbar;
                ylabel(y,'Mean Delta Resp. (dMUA in imp./s)')
                saveas(h(1),[varsavepath header '_' el '--rfplot.png'])
                saveas(h(2),[varsavepath header '_' el '--rfsumry.png'])
                saveas(h(3),[varsavepath header '_' el '--dmuaresp.png'])
                %
                
            end
            
            
            
            
            % ALIGN VAR
            ALIGN(r).name  = [header '_' el];
            ALIGN(r).date  = header(1:6);
            ALIGN(r).monk  = header(end);
            ALIGN(r).el    =  el;
            
            
            ALIGN(r).rftop = v1lim(1);
            ALIGN(r).rfbtm = v1lim(2);
            
            ALIGN(r).stimtop = v1lim(3);
            ALIGN(r).stimbtm = v1lim(4);
            
            ALIGN(r).l4i    = TuneList.SinkBtm(s);
            ALIGN(r).l4l    = elabel(TuneList.SinkBtm(s));
            
            ALIGN(r).elabel = elabel;
            
            save([varsavepath header '_' el '.mat'],'ALIGN','-append')
                       
        case 'getTune'
            clear STIM
            STIM  = getTune(filelist,el,sortdirection);
            save([varsavepath header '_' el '.mat'],'STIM')
            
        case 'getRF'
            
            varsavepath = [pwd filesep];
            
            clear RF
            load([varsavepath header '_' el '.mat'],'RF')
            %             RF = getRF(filelist,el,sortdirection);
            %             if isempty(RF)
            %                 continue
            %             end
            
            clear uRF xcord ycord elabel h_color
            datatype = 'nev_zsr';
            [uRF, xcord, ycord, elabel]= meanRF(RF,datatype);
            plotRF
            set(h_color,'CLim',[-1 1]);
            saveas(gcf,[varsavepath header '_' el '--' datatype '.png'])
            close(gcf)
            
            %             clear uRF datatypes
            %             datatypes = {'mua_zsr','nev_zsr','kls_zsr'};
            %             for d = 1:3
            %                 clear datatype
            %                 datatype = datatypes{d};
            %                 [u, x, y, e] = meanRF(RF,datatype);
            %                 uRF.(datatype).u = u;
            %                 uRF.(datatype).x = x;
            %                 uRF.(datatype).y = y;
            %                 uRF.(datatype).e = e;
            %             end
            %             save([varsavepath header '_' el '.mat'],'RF','uRF','-v7.3')
            %
            
        case {'getAlignRespAllEl','stimevoked'}
            ssss
            clear output
            output = getAlignRespAllEl(filelist,sortdirection,el(end),1);
            output.ManualSinkBtm = TuneList.SinkBtm(s);
            save([varsavepath header '_' el '.mat'],'-struct','output')
            
            saveas(gcf,[varsavepath header '_' el '.png'])
            close(gcf)
            
        case 'offlineBRAutoSort'
            for f = 1:length(filelist)
                
                filename = filelist{f};
                [~,BRdatafile,~] = fileparts(filename)
                
                if flag_checkforexisting && ...
                        exist([varsavepath BRdatafile '.ppnev'],'file')
                    continue
                end
                
                tic
                [ppNEV, WAVES] = offlineBRAutoSort(filename);
                save([varsavepath BRdatafile '.ppnev'],'ppNEV','WAVES','-mat','-v7.3')
                toc
                
                
            end
            
        case 'list'
            s
            filelist
            V1 = TuneList.Structure{s};
            pause
            
            
        otherwise
            
            error('need to specify analysis')
    end
    
    %toc
    
end

switch analysis
    
    case 'fftdriftana'
        figure
        ftype = {'f0','fnot'};
        datatype = {'auto','kls'};
        p = 0;
        for d = 1:2
            for f = 1:2
                p = p +1;
                
                y = RATIO.(datatype{d}).y;
                x = RATIO.(datatype{d}).(ftype{f});
                
                
                subplot(2,2,p);
                scatter(x,y)
                axis tight; hold on
                plot(xlim,[0 0],'k');
                plot(xlim,[5 5],':k');
                plot([mean(x) mean(x)],ylim,'m');
                plot([median(x) median(x)],ylim,'g');
                [u, gname] = grpstats(x,y,{'mean','gname'});
                gname = cellfun(@str2double,gname);
                plot(u,gname,'b');
                xlabel(sprintf('f_T_F / %s',ftype{f}))
                ylabel('depth')
                title(datatype{d})
            end
        end
end



