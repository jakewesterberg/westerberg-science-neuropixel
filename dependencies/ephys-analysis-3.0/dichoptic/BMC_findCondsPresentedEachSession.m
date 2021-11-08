% BMC_findCondsPresentedEachSession.m
% Made by MAC on 10/2/19

clear

trlcrit = 1; % min 1, should probl be 5 or 10
usemaxcontrast = 0;


% Computer-specific editable variables 
[ret, hostname] = system('hostname');
if  ispc && ~isempty(strfind(hostname,'DESKTOP-L24RKTD'))
    didir = 'G:\LaCie\diSTIM_Sep23\';
elseif  ~ispc && ~isempty(strfind(hostname,'Brock')) && ~~isempty(strfind(hostname,'MacBook-Air'))
    didir = '/Volumes/LaCie/Dichoptic Project/vars/diSTIM_Sep23/';
elseif  ~ispc && ~isempty(strfind(hostname,'Brocks-MacBook-Air.local'))
    didir = '/Volumes/SfN_2019/diSTIM_Sep23/';
else
    didir = '/Volumes/LaCie/Dichoptic Project/vars/diSTIM_Sep23/';
end

 list = dir([didir '*eD.mat']);
 list(end+1) = dir([didir '*eB.mat']);
ct = 0; 
clear session IDX
% IDX = nan(340,15,13);
for i = 1:length(list)
% load session STIM
    dispname = strcat('dirloop, i=', num2str(i));
    disp(dispname)
    load([didir list(i).name],'STIM')

% Find BRFS trials
    posBrfs = strcmp(STIM.task,'brfs');
    if usemaxcontrast
        maxContrast = STIM.contrast(:,1) == max(STIM.contrast(:,1)) & STIM.contrast(:,1)  == STIM.contrast(:,2);
    else
        maxContrast = true(size(posBrfs));
    end
    
% "Normalize" BRFS tilts across days 
% Establish table with all pertinent varibles and find unique iterations
    % for NaN values (which unique cannot operate on), make them equal to a
    % larger value than possible. In this case, 400.
    nanRemovedSTIMtilt = STIM.tilt;
    nanRemovedSTIMtilt(isnan(STIM.tilt)) = 400;
    brfsTilts = unique(nanRemovedSTIMtilt(posBrfs,:));
    
% Count the "tilts" as a binary-ish system so comparisons can be made acros
% days
% Replace continuous values with 1 (lowest tilt), 2 (highest tilt), 3
% (NaN tilt)
brfsTiltIDX = nanRemovedSTIMtilt;
for nUniqueTilt = 1:length(brfsTilts)
    brfsTiltIDX(nanRemovedSTIMtilt == brfsTilts(nUniqueTilt)) = nUniqueTilt;
end

% Create a table with headers that are easy to read.
brfsAllConditionsWithHeaders = table(...
    STIM.eyes(posBrfs & maxContrast,1),...
    brfsTiltIDX(posBrfs & maxContrast,1),...
    STIM.tiltmatch(posBrfs & maxContrast,:),...
    STIM.soa(posBrfs & maxContrast),...
    STIM.monocular(posBrfs & maxContrast,:),...
    'VariableNames',{'eyes1','tilt1','tiltmatch','soa','monoc'});

[brfsUniqueConditions,~, trialConditionMap] = unique(brfsAllConditionsWithHeaders,'rows');
% Find out how many times this combination occurs accross the session
numOccurences = accumarray(trialConditionMap, 1);
% Find the trial idx for each condition combination
conditionIdx = accumarray(trialConditionMap, find(trialConditionMap), [], @(rows){rows});


IDX(i).brfsUniqueConditions = brfsUniqueConditions;
IDX(i).numOccurences        = numOccurences;
IDX(i).conditionIdx         = conditionIdx;


end

%% Count how many sessions present each condition of interest
% Ignore conditions 1-4 the monocular conditions
% Note - physical alternation not shown.
condition = table(...
    [2   3   2   3   2   3   2   3   2   3   2   3   2   3   2   3  ]',... %eyes1
    [1   1   2   2   1   2   2   1   1   1   2   2   1   2   2   1  ]',... %tilt1
    [1   1   1   1   0   0   0   0   1   1   1   1   0   0   0   0  ]',... %tiltmatch
    [0   0   0   0   0   0   0   0   800 800 800 800 800 800 800 800]',... %soa
    [0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0  ]',... %monoc
'VariableNames',{'eyes1','tilt1','tiltmatch','soa','monoc'});
condition.Properties.RowNames = {'5.1','5.2','6.1','6.2','7.1','7.2','8.1','8.2','9','10','11','12','13','14','15','16'};


for j = 1:size(condition,1) % condition type
    findThisCond = condition(j,:); 
    
    for k = 1:length(list) % searches each session
        searchThisSession = IDX(k).brfsUniqueConditions;
        [sessionWithCondition(k), index(k)] = ismember(findThisCond,searchThisSession,'rows');
    end
    
    %in how many sessions is this condition presented
    nOfSessionForCond(j) = sum(sessionWithCondition);
    
    
end

%%
tbl = zeros(size(condition,1),length(list));
for k = 1:length(list) % searches each session
    searchThisSession = IDX(k).brfsUniqueConditions;
    for  j = 1:size(condition,1)
         findThisCond = condition(j,:); 
        [tf, index] = ismember(findThisCond,searchThisSession,'rows');
        if tf == 1
            tbl(j,k) = IDX(k).numOccurences(index);
        end
    end
end
tbl2 = [sum(tbl(1:2,:)); sum(tbl(3:4,:)); sum(tbl(5:6,:)); sum(tbl(7:8,:)); (tbl(9:end,:))];
%%
figure 
subplot(2,2,3)
imagesc(1:length(list),[5:16],tbl2>=trlcrit); hold on
plot([1:length(list);1:length(list)]+.5,ylim,'k');
plot(xlim,[5:16;5:16]+.5,'k');
%c=colorbar('WestOutside'); colormap('hsv'); ylabel(c,'Trials');
ylabel(sprintf('Condition\nyellow = more than %u trls',trlcrit));  xlabel('Session')
set(gca,'box','off','tickdir','out')
p0=get(gca,'position');a0 = axis; 
subplot(2,2,4);
plot(sum(tbl2>=trlcrit,2),5:16,'k-d')
p=get(gca,'position');
xlabel('Number of Sessions'); ylim(a0(3:4)); grid on
set(gca,'box','off','tickdir','out','position',[p(1) p0(2) p(3) p0(4)],'ydir','reverse')
if usemaxcontrast
    title('only counting max contrast trials')
end
subplot(2,2,1);
plot(1:length(list),sum(tbl2>=trlcrit,1),'k-d')
p=get(gca,'position');
ylabel('Number of Conditions'); xlim(a0(1:2))
set(gca,'box','off','tickdir','out'); grid on
set(gca,'position',[p0(1) p(2) p0(3) p(4)])

