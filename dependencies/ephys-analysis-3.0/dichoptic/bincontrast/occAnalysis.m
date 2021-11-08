%% OccAnalysis 2
% Description: 

% Script choices
groups = 3;
method = 'abs'; 


clear occValues *OCC* occGroups I2 I B occLengths
for i = 1:length(IDX)
occValues(i,1) = IDX(i).occ(3);
end

% sort ocularity values by absolute distance from zero
switch method
    case 'abs'
        [B,I] = sort(occValues,'ComparisonMethod','abs');
    case 'directional' 
        [B,I] = sort(occValues);
end

% get rid of units with NaNs
missing = ismissing(B);
tooLarge = abs(B) > 1.5;
adj_I = I; % adjusted I
adj_I(missing | tooLarge) = [];

varc = @(oldvar) mat2cell(oldvar(:), [fix(numel(oldvar)/groups) *[ones(groups-1,1)]', numel(oldvar)-(groups-1)*fix(numel(oldvar)/groups)], 1);     % Create New Matrix From Original Vector
occGroups = varc(adj_I); % rows are: low med high

occLengths = nan(groups,1);
for s = 1:length(occLengths)
occLengths(s) = numel(occGroups{s,1});
end


% Create data matrices 
% monocular
monCond = {'DE_PS','NDE_PS','DE_NS','NDE_NS'};

clear m o SDF RESP *OCC*
for m = 1:length(monCond)
    for o = 1:size(occGroups,1)
        SDF = nan(size(UNIT.MON.DE_PS.SDF,1),size(UNIT.MON.DE_PS.SDF,2),occLengths(o));
        RESP = nan(size(UNIT.MON.DE_PS.RESP,1),size(UNIT.MON.DE_PS.RESP,2),occLengths(o));
        for u = 1:length(occGroups{o,1})
            SDF(:,:,u) = UNIT.MON.(monCond{m}).SDF(:,:,occGroups{o,1}(u));
            RESP(:,:,u) = UNIT.MON.(monCond{m}).RESP(:,:,occGroups{o,1}(u));
        end
        OCC.MON.(monCond{m})(o).SDF = SDF;
        OCC.MON.(monCond{m})(o).RESP = RESP;
    end
end
clear SDF RESP m monCond

binCond = {'PS','NS'};

% binocular
clear b O SDF RESP
for b = 1:length(binCond)
    for o = 1:size(occGroups,1)
        SDF = nan(size(UNIT.BIN.PS.SDF,1),size(UNIT.BIN.PS.SDF,2),occLengths(o));
        RESP = nan(size(UNIT.BIN.PS.RESP,1),size(UNIT.BIN.PS.RESP,2),occLengths(o));
        for u = 1:length(occGroups{o,1})
            SDF(:,:,u) = UNIT.BIN.(binCond{b}).SDF(:,:,occGroups{o,1}(u));
            RESP(:,:,u) = UNIT.BIN.(binCond{b}).RESP(:,:,occGroups{o,1}(u));
        end
        OCC.BIN.(binCond{b})(o).SDF = SDF;
        OCC.BIN.(binCond{b})(o).RESP = RESP;
    end
end
clear SDF RESP b binCond

% dichoptic
clear d o SDF RESP
diCond = {'PS','NS'};

try
    for d = 1:length(diCond)
        for o = 1:size(occGroups,1)
            SDF = nan(size(UNIT.DI.PS.SDF,1),size(UNIT.DI.PS.SDF,2),occLengths(o));
            RESP = nan(size(UNIT.DI.PS.RESP,1),size(UNIT.DI.PS.RESP,2),occLengths(o));
            for u = 1:length(occGroups{o,1})
                SDF(:,:,u) = UNIT.DI.(diCond{d}).SDF(:,:,occGroups{o,1}(u));
                RESP(:,:,u) = UNIT.DI.(diCond{d}).RESP(:,:,occGroups{o,1}(u));
            end
            OCC.DI.(diCond{d})(o).SDF = SDF;
            OCC.DI.(diCond{d})(o).RESP = RESP;
        end
    end
catch
    disp('Dichoptic data not found');
end

fprintf('OccAnalysis complete - %d Groups created\n',groups)

%clear diCond SDF RESP d o varc tooLarge s monCond groups i I adj_I method missing B u 