clear

BRdatafile = '151210_E_rsvp001';
extension = 'ns2'; % THIS CODE DOES NOT DOWNSAMPLE OR FILTER DATA
el = 'eD';

Obs = getRsvpTPs(BRdatafile,'ms');
badobs = getBadObs(BRdatafile);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get neural data
[LFP, ~, ~]= getLFP(BRdatafile,extension,el);
%%
clear h    
for stim = 1:10
    
    idx = Obs.sXa == stim & ~Obs.saccade;
    triggerpoints = Obs.tp(idx);
    pre = 100;
    post = 500;
    
    [DAT, TM] = trigData(LFP, triggerpoints , pre, post);
    EVP = median(DAT,3);
    
    figure
   
    % evp
    subplot(1,3,1)
    corticaldepth = 0:-100:size(EVP,2)*-100;
    N = [];
    f_ShadedLinePlotbyDepth(EVP,corticaldepth,TM,N,1)
    title(BRdatafile,'interpreter','none')
    
    subplot(1,3,2)
    CSD = calcCSD(EVP);
    CSD = padarray(CSD,[1 0],NaN,'replicate');
    corticaldepth = 0:-100:size(CSD,2)*-100;
    f_ShadedLinePlotbyDepth(CSD,corticaldepth,TM,N,1)
    title(sprintf('%s, n = %u',Obs.sXa_name{stim},sum(idx)))
    
    subplot(1,3,3)
    CSDf = filterCSD(CSD);
    imagesc(TM,[1:size(CSDf,1)]./10,CSDf); 
    colormap(flipud(jet));
    h(stim) = gca; 
    hold on;
    plot([0 0], ylim,'k')
    c = colorbar;
    


end

climits = get(h,'Clim');
climits = cell2mat(climits);
cl = max(max(abs(climits)));
set(h,'Clim',[-1 1].*cl*.5);



