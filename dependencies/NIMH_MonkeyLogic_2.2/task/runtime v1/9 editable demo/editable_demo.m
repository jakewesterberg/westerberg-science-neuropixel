hotkey('x', 'escape_screen(); assignin(''caller'',''continue_'',false);');

boolean1 = true;
boolean2 = [false true];
boolean3 = [true false true];
boolean4 = [false true false true];
boolean5 = [true false true false true];
boolean6 = [false true false true false true];
filename = 'editable_demo.m';
dirname = '9 editable demo';
color1 = [1 0 0];
color2 = [1 1 0];
category = {'Type 1','Type 2','Type 3','Type 1'};  % the last element is the selected category
range1 = [0 1000 100 500];                         % the last number is the chosen value
num1 = 1;
num2 = [1 2];
num3 = [1 2 3];
num4 = [1 2 3 4];
num5 = [1 2 3 4 5];
num6 = [1 2 3 4 5 6];

editable('boolean1','boolean2','boolean3','boolean4','boolean5','boolean6', ...  % logicals do not need a type specifier
    '-file','filename', ...
    '-dir','dirname', ...
    '-color',{'color1','color2'}, ...              % use curly braces to set types for multiple variables
    '-category','category', ...
    '-range','range1', ...
    'num1','num2','num3','num4','num5','num6');

dashboard(1,'This is a demo for editables. You can bring up the editable window in the Pause menu.',[0 1 0]);
dashboard(2,'Press x key to stop.',[0 1 0]);
dashboard(3,['Filename: ' filename]);
dashboard(4,['Directory: ' dirname]);
dashboard(5,sprintf('Color1: %.3f  %.3f  %.3f',color1),color1);
dashboard(6,sprintf('Color2: %.3f  %.3f  %.3f',color2),color2);
dashboard(7,['Categoty: ' category{end}]);
dashboard(8,sprintf('Range: %d',range1(end)));

idle(3000);
set_iti(0);
