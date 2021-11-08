didir = '/Volumes/LaCie/Dichoptic Project/vars/diSTIM_Mar14/';
load([didir 'CRF_April02b.mat'],'CRF');

clearvars -except CRF didir

dicontrast = nanunique([CRF.dicontrast]);
fx = 0:2.5:100;
RESULT = cell(2,4,3); 

for condition = 1:4
    for window = 1:3
        
        fR = nan(length(dicontrast) + 1,length(fx),length(CRF));
        rR = nan(length(dicontrast) + 1,length(fx),length(CRF));
       
        for i = 1:length(CRF);
            
            clear c r
            c = CRF(i).dicontrast;
            r = CRF(i).RESP(:,:,condition,window); % RESP(eye2,eye1,condition, window)
            % r(1,:) = monocular dominant; r(:,1) = monocular non dominant; plot(r')
            
            % check for NAN
            if all(all(isnan(r)))
                continue
            elseif isnan(r(1,1))
                r(1,1) = CRF(i).bl;
            end
            
            clear fY rY
            for ndec = 1:length(c)+1
                
                % get single-crf data
                clear x y
                x = c;
                if ndec > length(c)
                    y = r(:,1);
                else
                    y = r(ndec,:);
                end
                rY(ndec,:) = y;

                % remove nans for fitting
                x(isnan(y)) = [];
                y(isnan(y)) = [];
                
                % fit
                clear crf
                if isempty(y) || length(y) < 3 || ~any(x==0);
                    fY(ndec,:) = nan(size(fx));
                else
                    crf = fmsCRF(x,y); % allowing all params to vary
                    fY(ndec,:) = feval(crf.fun,fx);
                end                
            end
            
            % save fits
            [~,ia,~]=intersect(dicontrast,c,'stable');
            fR(ia,:,i)  = fY(1:end-1,:);
            fR(end,:,i) = fY(end,:);
           
            % save values
            [~,ib,~]=intersect(fx,c*100,'stable');
            rR(ia,ib,i)  = rY(1:end-1,:);
            rR(end,ib,i) = rY(end,:);
            
        end
        
        RESULT{1,condition,window} = rR;
        RESULT{2,condition,window} = fR;
        
    end
    
end

ndecontrast = [dicontrast NaN] .* 100;
save([didir 'CRF_April02b.mat'],'RESULT','fx','ndecontrast','-append');

