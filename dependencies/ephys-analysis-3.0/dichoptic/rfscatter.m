% notes 



clear

source = '/Volumes/Drobo2/USERS/Michele/Layer Tuning/getRF/May31_zsr4rfscatter/'; 
list = dir([source '*.mat']);

rfcrit0 = 1; % z-score
dthresh = 0.5; % dva

 ct = 0; X = cell(3,1); ECC = []; AREA = []; DIAM = []; 
for i = 1:length(list)

 

    
    clear lim  ecc diam area uRF
    load([source list(i).name],'uRF')
    
    datatypes = {'mua_zsr','nev_zsr','kls_zsr'};
    for d = 1:3
        clear datatype fRF
        datatype = datatypes{d};
        
        clear fRF rflim
        [fRF, ~, rflim]   = fitRF(...
            uRF.(datatype).u,...
            uRF.(datatype).x,...
            uRF.(datatype).y,...
            rfcrit0,dthresh);
        
        clear centroid width
        centroid = fRF(:,1:2);
        width    = fRF(:,3:4);
%         
%         clear bad
%         bad = max(max(uRF.(datatype).u,[],2),[],3) < 2.5;
%         centroid(bad,:) = NaN; 
%         width(bad,:) = NaN; 
%         
        ecc(:,d)    = sqrt(sum(centroid .^2,2)); 
        diam(:,d)   = mean(width,2);
        area(:,d)   = sqrt(pi .* width(:,1) .* width(:,2));
        lim(:,d)    = rflim; 
        
    end
    
    lim = [min(lim(1,:)) max(lim(2,:))];
    if all(isnan(lim))
        continue
    end
    
    
    ECC  = cat(1,ECC,nanmedian(ecc(lim(1):lim(2),:)));
    DIAM = cat(1,DIAM,nanmedian(diam(lim(1):lim(2),:)));
    AREA = cat(1,AREA,nanmedian(area(lim(1):lim(2),:)));
    
    




%%

end

%%

figure; 
scatter(ECC(:,1),AREA(:,1)); hold on
scatter(ECC(:,2),AREA(:,2)); hold on
scatter(ECC(:,3),AREA(:,3)); hold on

legend(datatypes)
xlabel('ecc')
ylabel('sqrt(area)')

set(gca,'TickDir','out'); 
%%

figure; 
scatter(ECC(:,1),DIAM(:,1)); hold on
scatter(ECC(:,2),DIAM(:,2)); hold on
scatter(ECC(:,3),DIAM(:,3)); hold on

legend(datatypes)
xlabel('ecc')
ylabel('diam')

set(gca,'TickDir','out'); 


%%

figure
measure = {'DIAM'};
comp    = {'mua_zsr','nev_zsr'};
lct = 0; clear legendstr lh
for c = 1:2
    for m = 1
        clear dat
        dat = eval(measure{m});
        
        lct = lct + 1;
        
        delta = ...
            dat(:,strcmp(datatypes,comp{c})) - ...
            dat(:,strcmp(datatypes,'kls_zsr'));
        
        delta = delta ./ dat(:,strcmp(datatypes,'kls_zsr'));
        
        delta = delta .* 100;
        
        legendstr{lct} = sprintf('%s(kls v. %s) ',measure{m},(comp{c}(1:3)));
        M = nanmedian(delta);
        CI = bootci(2000,@nanmedian,delta);
        
        lh(lct) = plot(lct,M,'d'); hold on
        plot([lct lct],CI,'Color',get(lh(lct),'Color')); hold on
        
    end
end

set(gca,'TickDir','out','Box','off','Xtick',[]); 
xlim([0.5 4.5])
ylabel('Percent Change'); 
legend(lh,legendstr,'Location','Best')



