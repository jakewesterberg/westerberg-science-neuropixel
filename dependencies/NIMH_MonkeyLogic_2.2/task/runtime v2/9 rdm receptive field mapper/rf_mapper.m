if ~exist('mouse_','var'), error('This demo requires the mouse input. Please enable it in the main menu or try the simulation mode.'); end
hotkey('x', 'escape_screen(); assignin(''caller'',''continue_'',false);');
TrialRecord.MarkSkippedFrames = false;  % skip skipped frame markers

dashboard(4,'Move: Left click + Drag',[0 1 0]);
dashboard(5,'Resize: Right click + Drag',[0 1 0]);
dashboard(6,'Press ''x'' to quit.',[1 0 0]);

% editables
Coherence = 100;
NumDot = 100;
DotSize = 0.15;
DotColor = [1 1 1];
DotShape = {'Square','Circle','Square'};
editable('Coherence','NumDot','DotSize','-color','DotColor','-category','DotShape');

% create scene
rdm1 = RDM_RF_Mapper(mouse_);
rdm1.Position = [0 0];
rdm1.Radius = 5;
rdm1.Coherence = Coherence;
rdm1.NumDot = NumDot;
rdm1.DotSize = DotSize;
rdm1.DotColor = DotColor;
rdm1.DotShape = DotShape{end};
rdm1.InfoDisplay = true;
scene1 = create_scene(rdm1,1);

% task
run_scene(scene1);
idle(50);

% save parameters
bhv_variable('position',rdm1.Position);
bhv_variable('radius',rdm1.Radius);
bhv_variable('direction',fi(rdm1.Direction<0,rdm1.Direction+360,rdm1.Direction));
