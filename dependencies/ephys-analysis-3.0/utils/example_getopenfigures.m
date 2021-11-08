figHandles = get(0,'Children');

for f = 1:length(figHandles)
    h = figHandles(f);
%     c = get(h,'Children');
%     s = (get(c(2),'Title'));
% %     titlestr = s.String;
%     titlestr = strrep(titlestr,': ','_');
%     titlestr = strrep(titlestr,' - ','_');
%     titlestr = strrep(titlestr,' ','');
%     
%     figsavepath = pwd;% '/Volumes/Drobo/USERS/Michele/Analysis Projects/monbrfs/';
%     export_fig([figsavepath filesep num2str(h.Number) '_' titlestr], '-jpg', '-nocrop','-transparent',h)

saveas(h,['/Users/coxm/Dropbox (MLVU)/_SCRUM/' num2str(h.Number)],'png')

end