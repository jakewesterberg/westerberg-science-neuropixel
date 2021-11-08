function badobs = getBadObs(BRdatafile)

switch BRdatafile
    case '160211_I_brfs001'
       badobs = [699 406 600:850];
          
    otherwise
        badobs = [];
        
end
if ~isempty(badobs)
    fprintf('\n%s, %0.0f badobs listed\n',BRdatafile,length(badobs))
end


%
% OLD, before I changed indexing to make it resiliant to using/notusing rewarded trials:

% case '151125_E_dotmapping001'
%         badobs = [60 164 87 91];
%     case '151203_E_rfori003'
%         badobs = [156];
%     case '151204_E_dotmapping002'
%         badobs = [18 22 85 170 185 188 217];
%     case '151204_E_dotmapping004'
%         badobs = [198 169 137 20 16 24];
%     case '151206_E_dotmapping001'
%         badobs = 62;
%     case '151208_E_kanizsa001'
%         badobs = 369; 
%     case '151221_E_dotmapping001'
%          badobs = [84 85 86 115 116 117]; 
%     case '160102_E_brfs001'
%         badobs = [0:200 750:1051]; 
%     case '151231_E_rsvp001'
%          badobs = [99]; 
%     case '151211_E_mcosinteroc001'
%         badobs = [300:600];
%     case '160111_E_dotmapping001'
%         badobs = [106];
%     case '160111_E_rfori002'
%         badobs = [375 376];
%     case '160115_E_rfori002'
%         badobs = [309];  