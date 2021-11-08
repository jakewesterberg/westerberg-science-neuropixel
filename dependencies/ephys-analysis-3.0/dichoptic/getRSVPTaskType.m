function type = getRSVPTaskType(datum)

if ischar(datum)
    n = datenum(datum,'yymmdd'); 
else
    n = datum; 
end

if n < datenum('160418','yymmdd');
    type = 'ori';
elseif n < datenum('160922','yymmdd');
    type = 'color';
else
    type = 'redun';
end
