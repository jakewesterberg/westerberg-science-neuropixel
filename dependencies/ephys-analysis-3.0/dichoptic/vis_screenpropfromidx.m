clear

didir = '/Volumes/LaCie/Dichoptic Project/vars/diSTIM_Aug24/';
load([didir 'IDX_Oct7a.mat']);

SDF = 'SDF';

deltaC = 1
    
    if deltaC == 0
        c = [0 0];
        mstr = '[full contrast, blank]';
        dstr = '[full contrast, full contrast]';
        eyestr = 'DE at full contrast, NDE at full';
    else
        c = [3 2];
        mstr = '[1/2 contrast, blank]';
        dstr = '[1/2 contrast, full contrast]';
        eyestr = 'DE at 1/2 contrast, NDE at full';
    end
    
    % setup SDF vars
    clear *Mo* *Bi* *Di* *Oi* DEPTH TM
    for i = 1:length(IDX);
        Mo(i,:) = IDX(i).(SDF)(1+c(1), :);
        Bi(i,:) = IDX(i).(SDF)(2+c(1), :);
        Di(i,:) = IDX(i).(SDF)(3+c(1), :);
        
        dBi(i,:) = IDX(i).(SDF)( 9+c(2), :);
        dDi(i,:) = IDX(i).(SDF)(10+c(2), :);
        
        DEPTH(i,:) =  IDX(i).depth(2);
        TM(i,:)    =  IDX(i).tm;
    end
    
    % extract good unints based on condition
    clear good
    goodBi  = ~all(isnan(dBi)');
    goodDi  = ~all(isnan(dDi)');
    goodAll = goodDi & goodBi;
    goodEither = goodDi | goodBi;
    
     kls     = [IDX.kls];


PEN = unique({IDX(goodEither & kls).penetration})';

SCREEN = nan(length(PEN),5);
for i = 1:length(PEN)
   
    clear STIM
    load([didir PEN{i} '.mat'],'STIM')
    
    gotbhv = false;
    for j = 1:length(STIM.filelist)
        clear BHV bhv
        bhv = [STIM.filelist{j} '.bhv'];
        if exist(bhv,'file')
            try
                BHV = concatBHV(bhv);
                ahaha
                SCREEN(i,:) = [...
                    BHV.VideoRefreshRate ...
                    BHV.ScreenXresolution ...
                    BHV.ScreenYresolution ...
                    BHV.ViewingDistance ...
                    BHV.PixelsPerDegree];
                
             
                
                
                gotbhv = true;
            catch err
                ajakaka
            end
            if gotbhv
                break
            end
        end
    end
end

[nanunique(SCREEN(:,2)) nanunique(SCREEN(:,3))]

%%

attnses = ([IDX.redun] == 0 & [IDX.atana] == 1);
clear PEN
PEN = unique({IDX(goodEither & kls & attnses).penetration})';

ATTN = nan(6,length(PEN));
for i = 1:length(PEN)
    
    clear STIM
    load([didir PEN{i} '.mat'],'STIM')
    
    gotbhv = false;
    filelist = STIM.filelist(strcmp(STIM.paradigm,'rsvp_color'));
    
    for j = 1:length(filelist)
        
        clear BHV bhv
        bhv = [filelist{j} '.bhv'];
        
        if exist(bhv,'file')
            
            BHV = concatBHV(bhv);
            
            clear EVT
            CN = BHV.CodeNumbers(BHV.TrialError == 0 & BHV.ConditionNumber < 3);
            CT = BHV.CodeTimes(BHV.TrialError == 0 & BHV.ConditionNumber < 3);
            e = 1;
            EVT(e,:) = cellfun(@(x,y) y(x == 8),CN,CT,'UniformOutput',1);
            for ev = 23:28
                e = e + 1;
                EVT(e,:) = cellfun(@(x,y) y(find(x == ev,1)),CN,CT,'UniformOutput',1);
            end
            
            ATTN(:,i) = mean(diff(EVT),2);
            
            gotbhv = true;
        end
        
        if gotbhv
            break
        end
        
    end
    
end


