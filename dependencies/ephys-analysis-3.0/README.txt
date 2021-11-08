READ ME

MAC, March 2020

stim/ code for making the STIM structure w/ ephys data
dichoptic/ analysis of the STIM structure
utils/ where I will put random stuff you might want

archive/ stuff I don't think you need but I am not ready to delete


Order Of Operations: 

___________________________________________________________________________
%% 1. set up directories

*setup*
sets directories and adds all needed code to path
must input user for your specific computer
OUTPUT: global variables used in other scripts.

___________________________________________________________________________
%% 2. pull out all pertinent time-points from all sessions of interest


*runTuneList* with option, analysis = 'diSTIM'
dependency, importTuneList -> must pass approperate flag/user
makes STIM stucture with stimulus and v1 info (i.e. dpeended on data being 
in the ALIGN directory)
--> The STIM structure is info about the experiement at every pertinent
    timepoint/sample point. i.e. this is every stimulus onset and 
    offset time for each contact and where that contact was in the brain.
- diTP
    --> n.b. diTP is NOT the same as diPT.
    diTP = time points (this has to happen first)
    diPT = photo_trigger
    once STIM.tp_ec (event codes) and STIM.tp_sp (???) are pulled out, then
    that range can be used to find the photodiod's true onset. Therefore,
    the outputs of STIM.tp_ec and STIM.tp_sp are essential for diPT.    
- diCheck
- diPT
    --> diPT.m requires inputs of STIM.tp_sp and STIM.tp_ec so it has a 
    window to search for a treshold-cross. Once the treshold of the photo-
    diode is crossed, this timepoint is saved in STIM.tp_pt. This process
    depends on photoReTriggerSTIM.m, which used to live in MLAnalysisOnline
    as photoReTrigger.m, but was moved to ephys-analysis with the new name.
    
- diV1Lim -> this requires an independent analysis of neural data that is 
not yet streamlined
OUTPUT: STIM variable. Saved in the .mat file in STIMDIR (global assign).
    i.e. Sandbox\STIM\160108_E_eD.mat. Nota bene --> note the *_KLS.mat or 
    *_CSD.mat etc. files.

    STIM
        stimulus and timepoints for all data that day
        V1 limits

___________________________________________________________________________
%% 3. Pull out data - time locked to photo-triggered time-points from #2. 

*diRunDir* - run for a given data-type.
 -- diClusters gets run here IF you want to do KLS analysis. Automated
    matching of SUA between files.
    - Currently, there is an issue within diClusters that prevents 
        diRunDir from pulling out kls. The issue appears to be associated  
        with the correlation method used to cluster units across files.

-diNeuralDat --> this is a function that runs within diRunDir. 
    STIM.tp_pt is used to find onset and offset times of each stimuli. This
    info is used to create the reference window (refwin) and continuous-
    data time-course (sdftm), which is then used to pull data out into the 
    SDF (continuous data) and RESP (binned time-window averages) variables.



___________________________________________________________________________
%% Other info.

https://www.dropbox.com/sh/avsg7ys3n6xsa24/AADZmyhUK80wDzgj4SJNUvy0a?dl=0


Definitions:
auto - autosorted - dMUA
nev - online sorted single units
kls - kilosort
csd - Current Source Density
mua - analog multi-unit. Band pass filtered LFP
lfp - LFP.

__________________________________________________________________________
%% STIM._____ definitions
STIM.monocular - was only one stimulus shown on this trial (or half trial 
for BRFS conditions)
STIM.eye; 1 = both eyes, 2 = ipsi, 3 = contra.
STIM.eyes;  [2 3] or [3 2] doccumenting which eye is main and which eye is
secondary for a given trial.