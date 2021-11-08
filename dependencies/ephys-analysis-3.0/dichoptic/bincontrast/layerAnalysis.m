%% Layer Analysis: works with bincontrast.m workspace
% Retrive the number of units in each V1 layer
clear layerLengths SDF RESP *LAY*

layers = {'supra','granular','infra'};
layerLengths = [0;0;0];

for u = 1:length(IDX)
    if IDX(u).depth(2) >4
        layerLengths(1) = layerLengths(1)+1;
    elseif IDX(u).depth(2) >= 0 && IDX(u).depth(2) <= 4
        layerLengths(2) = layerLengths(2) + 1;
    elseif IDX(u).depth(2) < 0
        layerLengths(3) = layerLengths(3) + 1;
    end
end

% Layer Analysis
% monocular
monCond = {'DE_PS','NDE_PS','DE_NS','NDE_NS'};
for m = 1:4
    for L = 1:size(layers,2)
        SDF = nan(size(UNIT.MON.DE_PS.SDF,1),size(UNIT.MON.DE_PS.SDF,2),layerLengths(L));
        RESP = nan(size(UNIT.MON.DE_PS.RESP,1),size(UNIT.MON.DE_PS.RESP,2),layerLengths(L));
        count = 0;
        for u = 1:length(IDX) %number of units
            switch layers{L}
                case 'supra'
                    if IDX(u).depth(2) > 4
                        count = count+1;
                        SDF(:,:,count) = UNIT.MON.(monCond{m}).SDF(:,:,u);
                        RESP(:,:,count) = UNIT.MON.(monCond{m}).RESP(:,:,u);
                    end
                case 'granular'
                    if IDX(u).depth(2) >= 0 && IDX(u).depth(2) <= 4
                        count = count+1;
                        SDF(:,:,count) = UNIT.MON.(monCond{m}).SDF(:,:,u);
                        RESP(:,:,count) = UNIT.MON.(monCond{m}).RESP(:,:,u);
                    end
                case 'infra'
                    if IDX(u).depth(2) < 0
                        count = count+1;
                        SDF(:,:,count) = UNIT.MON.(monCond{m}).SDF(:,:,u);
                        RESP(:,:,count) = UNIT.MON.(monCond{m}).RESP(:,:,u);
                    end
            end
            
            % Organize data into Lay structure
            % dimensions: contrast x time x units
            % layers are (L)
            LAY.MON.(monCond{m})(L).SDF = SDF;
            LAY.MON.(monCond{m})(L).RESP = RESP;
        end
    end
end
clear SDF RESP

% binocular
binCond = {'PS','NS'}; % can also be used for DI conditions
for b = 1:2 % number of binocular stimulus conditions
    for L = 1:size(layers,2)
        SDF = nan(size(UNIT.BIN.PS.SDF,1),size(UNIT.BIN.PS.SDF,2),layerLengths(L));
        RESP = nan(size(UNIT.BIN.PS.RESP,1),size(UNIT.BIN.PS.RESP,2),layerLengths(L));
        count = 0;
        for u = 1:length(IDX)
            switch layers{L}
                case 'supra'
                    if IDX(u).depth(2) > 4
                        count = count+1;
                        SDF(:,:,count) = UNIT.BIN.(binCond{b}).SDF(:,:,u);
                        RESP(:,:,count) = UNIT.BIN.(binCond{b}).RESP(:,:,u);
                    end
                case 'granular'
                    if IDX(u).depth(2) >= 0 && IDX(u).depth(2) <= 4
                        count = count+1;
                        SDF(:,:,count) = UNIT.BIN.(binCond{b}).SDF(:,:,u);
                        RESP(:,:,count) = UNIT.BIN.(binCond{b}).RESP(:,:,u);
                    end
                case 'infra'
                    if IDX(u).depth(2) < 0
                        count = count+1;
                        SDF(:,:,count) = UNIT.BIN.(binCond{b}).SDF(:,:,u);
                        RESP(:,:,count) = UNIT.BIN.(binCond{b}).RESP(:,:,u);
                    end
            end
            
            % Organize data into Lay structure
            % dimensions: contrast x time x units
            % layers are (L)
            LAY.BIN.(binCond{b})(L).SDF = SDF;
            LAY.BIN.(binCond{b})(L).RESP = RESP;
        end
    end
end

clear SDF RESP
% Dichoptic conditions
try
    diCond = {'PS','NS'}; %
    for d = 1:2 % number of dichoptic stimulus conditions
        for L = 1:size(layers,2)
            SDF = nan(size(UNIT.DI.PS.SDF,1),size(UNIT.DI.PS.SDF,2),layerLengths(L));
            RESP = nan(size(UNIT.DI.PS.RESP,1),size(UNIT.DI.PS.RESP,2),layerLengths(L));
            
            count = 0;
            for u = 1:length(IDX)
                switch layers{L}
                    case 'supra'
                        if IDX(u).depth(2) > 4
                            count = count+1;
                            SDF(:,:,count) = UNIT.DI.(diCond{d}).SDF(:,:,u);
                            RESP(:,:,count) = UNIT.DI.(diCond{d}).RESP(:,:,u);
                        end
                    case 'granular'
                        if IDX(u).depth(2) >= 0 && IDX(u).depth(2) <= 4
                            count = count+1;
                            SDF(:,:,count) = UNIT.DI.(diCond{d}).SDF(:,:,u);
                            RESP(:,:,count) = UNIT.DI.(diCond{d}).RESP(:,:,u);
                        end
                    case 'infra'
                        if IDX(u).depth(2) < 0
                            count = count+1;
                            SDF(:,:,count) = UNIT.DI.(diCond{d}).SDF(:,:,u);
                            RESP(:,:,count) = UNIT.DI.(diCond{d}).RESP(:,:,u);
                        end
                end
                
                % Organize data into Lay structure
                % dimensions: contrast x time x units
                % layers are (L)
                LAY.DI.(diCond{d})(L).SDF = SDF;
                LAY.DI.(diCond{d})(L).RESP = RESP;
            end
        end
    end
catch
    disp('DI not found');
end

clear b binCond count d diCond L m monCond RESP SDF
