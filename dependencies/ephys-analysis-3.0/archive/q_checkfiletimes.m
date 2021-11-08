filelist         = getFilesOnDisk({'rfori'},{'022'},0);

for i = 1:length(filelist)
    clear NEV grating BRdatafile
    [~,BRdatafile,~] = fileparts(filelist{i})
    
    switch BRdatafile
        case {'151208_E_mcosinteroc002','151231_I_cosinteroc001'}
            continue
    end
    
    % setup paths
    if ispc
        brdrname = sprintf('Z:\\%s',BRdatafile(1:8));
        mldrname = sprintf('Y:\\%s',BRdatafile(1:8));
    else
        brdrname = sprintf('/Volumes/Drobo/DATA/NEUROPHYS/rig021/%s',BRdatafile(1:8));
        mldrname = brdrname;
    end
    
    if ~isempty(strfind(BRdatafile,'brfs'))
        grating = readBRFS([mldrname filesep BRdatafile '.gBrfsGratings']);
    elseif  ~isempty(strfind(BRdatafile,'cosinteroc'))
        if isempty(strfind(BRdatafile,'m'))
            ext = '.gCOSINTEROCGrating_di';
        else
            ext = '.gMCOSINTEROCGrating_di';
        end
         grating = readgGrating([mldrname filesep BRdatafile ext]);
    elseif ~isempty(strfind(BRdatafile,'rfori'))
        grating = readgGrating([mldrname filesep BRdatafile '.gRFORIGrating_di']);
    end
    
    
    filename = fullfile(brdrname,BRdatafile);
    NEV = openNEV(strcat(filename,'.nev'),'noread','nosave','nomat'); % HAVE TO USE NEV, NS saves stop time
    
    
    
    [allpass, message] =  checkTrMatch(grating,NEV);
    message
     if ~allpass
         error('check file')
     end
    
    
end

% 
% %%
% 
% % load stim info
%     clear grating
%     if ~isempty(strfind(BRdatafile,'brfs'))
%         grating        = readBRFS([mldrname filesep BRdatafile '.gBrfsGratings']);
%         
%         
%         % check if file exists and load NEV
%         filename = fullfile(brdrname,BRdatafile);
%         if exist(strcat(filename,'.nev'),'file') == 2;
%             NEV = openNEV(strcat(filename,'.nev'),'noread','nosave','nomat'); % HAVE TO USE NEV, NS saves stop time
%         else
%             error('the following file does not exist\n%s.nev',filename);
%         end
%         
%         brstart = datenum(NEV.MetaTags.DateTime,'dd-mmm-yyyy HH:MM:SS');
%         mlstart = grating.timestamp(1);
%         
%         if any(unique(abs(diff(grating.trial))) > 1 ) || mlstart < brstart
%             error('bad times')
%         end
%         
%         
%         
%         
%         
%         
%         
%     elseif  ~isempty(strfind(BRdatafile,'cosinteroc'))
%         if isempty(strfind(BRdatafile,'m'))
%             ext = '.gCOSINTEROCGrating_di';
%         else
%             ext = '.gMCOSINTEROCGrating_di';
%         end
%         
%         if ~exist([mldrname filesep BRdatafile ext],'file') 
%             fprintf('-- does not exist \n')
%             continue
%         end
%         
%         grating = readgGrating([mldrname filesep BRdatafile ext]);
%         
%         if any(unique(abs(diff(grating.trial))) > 1 ) 
%             error('bad times')
%         end
%     end