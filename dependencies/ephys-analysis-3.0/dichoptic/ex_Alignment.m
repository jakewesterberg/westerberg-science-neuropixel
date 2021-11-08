clear

header      = '160905_E';
el          = 'eD';
muasignal   = 'aMUA'; 
paradigms = {'evp','rfori','darkrest'};
latencyz   = 3; 
csd_sigma  = 0.05;
pre = 25; 
post = 100;

nevdir = '/Volumes/Drobo2/DATA/NEUROPHYS/AutoSort-ed/';
rfdir = '/Volumes/Drobo2/USERS/Michele/Layer Tuning/getRF/May31_zsr4rfscatter/';


TuneList = importTuneList; clear s
s = strcmp(TuneList.Datestr,header(1:6)) & strcmp(TuneList.Bank,el(2));

clear sortdirection
sortdirection = TuneList.SortDirection{s};

clear drobo
switch TuneList.Drobo(s)
    case 1
        drobo = 'Drobo';
    otherwise
        drobo = sprintf('Drobo%u',TuneList.Drobo(s));
end

brdir = sprintf('/Volumes/%s/Data/NEUROPHYS/rig%03u/%s_%s/',...
    drobo,TuneList.Rig(s),TuneList.Datestr{s},TuneList.Monkey{s});

clear files; 
for p = 1:length(paradigms)
    
    if isempty(TuneList.(paradigms{p}){s})
       continue
    else
        files.(paradigms{p}) = sprintf('%s/%s_%s%03u',brdir,header,paradigms{p},TuneList.(paradigms{p}){s}(1));
    end
    
    
end
paradigms = fieldnames(files);

% get ypos
clear ypos
if any(strcmp(paradigms,'rfori'))
    if ~isempty(strfind(files.rfori,'ori'))
        ext = '.gRFORIGrating_di';
    elseif ~isempty(strfind(files.rfori,'sf'))
        ext = '.gRFSFGrating_di';
    elseif  ~isempty(strfind(files.rfori,'size'))
        ext = '.gRFSIZEGrating_di';
    end
    grating = readgGrating([files.rfori ext]);
    ypos = mode(grating.ypos);
    clear grating ext
else
    ypos = 0;
end



% arrange probe channels
clear NS_header idx el_array
NS_header = openNSx([files.rfori '.ns6'],'noread');
elb = cellfun(@(x) (x(1:4)),{NS_header.ElectrodesInfo.Label},'UniformOutput',0);
prb = sum(~cellfun('isempty',strfind({NS_header.ElectrodesInfo.Label},el)));
idx = zeros(1,prb);
for e = 1:prb
    elable = [el num2str(e,'%02u')];
    idx(e) = find(strcmp(elb,elable));
end
% most superficial channel on top, regardless of number
switch sortdirection
    case 'descending'
        idx = fliplr(idx);
end
% el_array is count from top
el_array = 1:length(idx);
elabel    = elb(idx);

figure
for p = 1:2%1:length(paradigms)
    
    switch paradigms{p}
        case 'darkrest'
            clear NS lfp
            NS  = openNSx([files.(paradigms{p}) '.ns2'],'read');
            lfp = double(NS.Data(idx,:)) ./ 4; % uV
            NS.Data = []; 
          
            % PSD
            L = floor( length( lfp ) / 512 );
            if size( lfp, 2 ) - L * 512 == 0
                L = L - 1;
            end
            for k = 1 : size( lfp, 1 )
                [ jnm( k , : ), freqs ] = jnm_psd( lfp( k, end - ( 512 * L ) : end ), ...
                    512, 1000, 512, 0);
            end
            fmax = find(freqs < 300,1,'last');
            jnm2 = zeros( fmax, size( lfp, 1 ) );
            jnm = jnm.';
            for k = 1:fmax
                jnm2( k, : ) = ( jnm( k, : ) - mean( jnm( k, : ) ) )  ...
                    / mean( jnm( k, : ) ) * 100;
            end
            jnm2 = jnm2.';
            
            subplot(2,6,5)
            imagesc(freqs(1:fmax),el_array, jnm2( :, 1:fmax ) );
            set( gca, 'Box','off','TickDir','out')
            xlabel('Frequency (Hz)')
            ylabel('Electrode # from Top')
            
            cb = colorbar('north');
            ylabel( cb, '% Difference' )
            caxis([-100 100])
            
            % Correlation
            [ jnmcc ] = jnm_ncorr( lfp, 512, 0 );
            
            subplot(2,6,6)
            imagesc(el_array,el_array, jnmcc );
            ylabel('Electrode # from Top')
            ylabel('Electrode # from Top')
            set(gca,'YDir','reverse')
            set(gca,'XDir','normal')
            set( gca, 'Box','off','TickDir','out')
            cb = colorbar('north');
            ylabel(cb, 'R')
            caxis([0 1])

            
        otherwise
            
            clear NEV  
            NEV = openNEV([files.(paradigms{p}) '.nev'],'noread','nomat','nosave');
            
            clear EventSampels EventCodes pEvC pEvT
            EventSampels = NEV.Data.SerialDigitalIO.TimeStamp;
            EventCodes = NEV.Data.SerialDigitalIO.UnparsedData - 128;
            [pEvC, pEvT] = parsEventCodesML(EventCodes,EventSampels);
                 
            clear pEvT_photo phototrigger
            if strcmp(paradigms{p},'evp')
               [pEvT_photo,phototrigger] = pEvtPhoto([files.(paradigms{p})],pEvC,pEvT,ypos,[],[],0,'evp');
            else
                [pEvT_photo,phototrigger] = pEvtPhoto([files.(paradigms{p})],pEvC,pEvT,ypos,[],[],0,'default'); 
            end
            
            clear *MUA
            switch muasignal
                case 'dMUA'
                case 'aMUA'
                    clear Fs NS6
                    
                    % filter settings
                    NS6 = openNSx([files.(paradigms{p}) '.ns6'],'noread');
                    hFs  = double(NS6.MetaTags.SamplingFreq);
                    nyq = hFs/2;
                    hpc = 750;  %high pass cutoff
                    hWn = hpc/nyq;
                    [bwb,bwa] = butter(4,hWn,'high');
                    k = jnm_kernel( 'psp', (20/1000) * hFs );
                    
                    for j = 1:length(elabel)
                        clear dat NS6 e electrode
            
                        e = find(strcmp(cellfun(@(x) x(1:4), {NS_header.ElectrodesInfo.Label},'UniformOutput',0),elabel{j}));
                        electrode = sprintf('c:%u',e);
                        NS6 = openNSx([files.(paradigms{p}) '.ns6'],electrode,'read');
                        dat = double(NS6.Data)'; 
                        
                        if j == 1
                            % preallocation
                            MUA = nan(length(dat),length(elabel));
                        end
                        dat = abs(filtfilt(bwb,bwa,dat));
                        dat = dat ./ 4; % microV;
                        dat = doConv(dat,k);
                        MUA(:,j) = dat; 
                        
                    end
                    
            end
            triggerpoints = cell2mat(pEvT_photo'); 
            triggerpoints = triggerpoints(~isnan(triggerpoints)); 
            [rMUA, muatm] = trigData(MUA, triggerpoints , hFs*pre/1000, hFs*post/1000);
            muatm = 1000 * (muatm ./ hFs); % ms
            
            % delta and zscore 
            dMUA = bsxfun(@minus, rMUA, mean(rMUA(muatm<0,:,:),1)); 
            zMUA = bsxfun(@rdivide, dMUA, std(rMUA(muatm<0,:,:),[],1)); 
            
            subplot(2,6,1 + 6*(p-1))
            dat = mean(zMUA,3); 
            scale = round(max(max(dat))); 
            plotOffsetLine(dat,muatm,scale)
            [~,fname,~] = fileparts(files.(paradigms{p}));
            title(fname,'interpreter','none')
            
            % latency measures
            win = [50 100] ;
            tmlim = (muatm >= win(1) & muatm <= win(2)); 
            tm = muatm(tmlim);
            L = nan(size(zMUA,2),size(zMUA,3)); 
            for x = 1:size(zMUA,2)
                for y = 1:size(zMUA,3)
                    signal = zMUA(tmlim,x,y);
                    %[~,latency]=max(signal);
                    latency = find(signal>latencyz,1,'first');
                    if ~isempty(latency)
                        L(x,y) = tm(latency);
                    end
                end
            end
            subplot(2,6,2 + 6*(p-1))
            plot(nanmean(L,2),el_array)
            set(gca,'Box','off','TickDir','out')
             
            
            % CSD
            clear LFP NS2 EVP *CSD
            NS2  = openNSx([files.(paradigms{p}) '.ns2'],'read');
            LFP = double(NS2.Data(idx,:)) ./ 4; % uV
            NS2.Data = [];
            lFs = double(NS2.MetaTags.SamplingFreq);
            
            [EVP, lfptm] = trigData(LFP', triggerpoints .* (lFs/hFs) , lFs*pre/1000, lFs*post/1000);
            lfptm = 1000 * (lfptm ./ lFs); 
            EVP = EVP ./ 4; % mV
            CSD = calcCSD(EVP) .* 0.4; %nA/mm^3
            CSD = padarray(CSD,[1 0 0],0);
            uCSD = mean(CSD,3);
            fCSD = filterCSD(uCSD,csd_sigma); 
            
            
            subplot(2,6,3 + 6*(p-1)); cla
            dat = uCSD'; 
            scale = max(max(abs(dat)));
            scale = round(scale,-1);
            plotOffsetLine(dat,lfptm,scale)
            
            subplot(2,6,4 + 6*(p-1))
            imagesc(lfptm,el_array(:),fCSD)
            set(gca,'Box','off','TickDir','out')
            colorbar('north')
            set(gca,'CLim',[-0.8 0.8] * max(abs(get(gca,'CLim'))))
            
    end
end
    
    
    
    

