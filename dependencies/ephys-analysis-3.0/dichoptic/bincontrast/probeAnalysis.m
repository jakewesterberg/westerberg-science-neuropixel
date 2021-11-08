
Pf = fieldnames(PEN);
mf = fieldnames(PEN(1).MON);

for p = 1:length(PEN)
    for m = 1:length(mf)
        temp = nan(size
        temp(:,:,:,p) = PEN(p).MON.(mf{m}).sdf(:,:,:);
    end
end

%%
% DE & NDE

clear e f c
for mon = 1:4  % for DE, NDE
    for f = 1:2:3 % for pc.all and pc.coll
        for c = 1:4 %for contrasts 0, 22, 45, 90
            temp = permute(squeeze(PEN.(Pf{mon}).aMUA.pc.(fn{f})(c,:,:,:)),[3 1 2]); 
            [pAVG.(Pf{mon}).aMUA.pc.(fn{f}).aligned(c,:,:), corticaldepth, ~] = laminarmean(temp,BOL4);
        end
    end
end

% Alignment is going to be a bit tricker because of uneven channels. Hmm. 