function [color] = getColor(idx);

COLORS =  [0 .5 1; ...
           .4 .3 .2;...
           .2 .3 .4; ...
           .5 .1 .2;...
           .8 .5 .3;...
           .3 .4 .5;...
           0.3 0.8 0.5;...
           0.7 0.1 0.9;...
           .2 .3 .8];

color = COLORS(idx,:); 

% colors = [colors([1 7 2 4 6 5 3],:)]; 


end