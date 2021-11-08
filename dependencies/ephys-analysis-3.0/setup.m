function setup(user)

% helper function 
% MAC, Feb 2020
global HOMEDIR RIGDIR AUTODIR SORTDIR ALIGNDIR STIMDIR SAVEDIR CODEDIR

username = getenv('USERNAME');

switch user
    case {'MacPro'}
        error('needs dev')
    
        autodir = '/Volumes/Drobo2/DATA/NEUROPHYS/AutoSort-ed/';
        sortdir = '/Volumes/Drobo2/DATA/NEUROPHYS/KiloSort-ed/';
        aligndir = '/Volumes/LaCie/Dichoptic Project/vars/V1Limits_Aug18/';
        
    case {'mac','michele','MAC'}
        HOMEDIR  = '/Users/ShellyCox/';
        RIGDIR   = '/Users/ShellyCox/Dropbox (Personal)/Sandbox160108/';
        AUTODIR  = '/Users/ShellyCox/Dropbox (Personal)/Sandbox160108/AutoSort-ed/';
        SORTDIR  = '/Users/ShellyCox/Dropbox (Personal)/Sandbox160108/KiloSort-ed/';
        ALIGNDIR = '/Users/ShellyCox/Dropbox (Personal)/Sandbox160108/V1Limits/';
        STIMDIR  = '/Users/ShellyCox/Dropbox (Personal)/Sandbox160108/STIM/';
                    
    case {'jake_mobile'}
        HOMEDIR  = 'C:\Users\jakew\Dropbox\code\jake_neuropixel_workspace\dependencies\';
        RIGDIR   = '';
        AUTODIR  = '';
        SORTDIR  = '';
        ALIGNDIR = '';
        STIMDIR  = 'D:\STIM\';

    case {'brock'}
        HOMEDIR  = 'C:\Users\Brock\Documents\MATLAB\GitHub\';
        RIGDIR   = 'T:\diSTIM - adaptdcos&CRF\Neurophys Data\';
        AUTODIR  = 'T:\diSTIM - adaptdcos&CRF\AutoSort-ed\';
        SORTDIR =  'D:\BMC brfs phy July 2020\';
        ALIGNDIR = 'T:\diSTIM - adaptdcos&CRF\V1Limits\';
        STIMDIR  = 'D:\copy of TEBA 7-14-2020\diSTIM - brfsOnly\STIM - brfs only - importPhy\';
        SAVEDIR  = 'C:\Users\Brock\Documents\MATLAB\Working IDX Dir\PhyTesting\';
        CODEDIR =  'C:\Users\Brock\Documents\MATLAB\GitHub\ephys-analysis\dichoptic\adaptdcos\PhyTesting';
    
    case {'brockSand 2016'}
        HOMEDIR  = 'C:\Users\Brock\Documents\MATLAB\GitHub\';
        RIGDIR   = 'E:\reference day for testing\';
        STIMDIR  = 'E:\reference day for testing\STIM\';
        SAVEDIR  = 'E:\reference day for testing\STIM\';
        
        CODEDIR  = 'C:\Users\Brock\Documents\MATLAB\GitHub\ephys-analysis';
                
        cd(RIGDIR)
      
        
    case {'brockSand 2021'}
        HOMEDIR  = 'C:\Users\Brock\Documents\MATLAB\GitHub\';
        RIGDIR   = 'E:\reference day for testing 2021\';
        STIMDIR  = 'E:\reference day for testing 2021\STIM\';
        SAVEDIR  = 'E:\reference day for testing 2021\STIM\';
        
        CODEDIR  = 'C:\Users\Brock\Documents\MATLAB\GitHub\ephys-analysis';
                
        cd(RIGDIR)
        
        
    case {'brockHdMUA'}
        HOMEDIR  = 'C:\Users\Brock\Documents\MATLAB\GitHub\';
        RIGDIR   = 'T:\SANDBOX diSTIM Pipeline\NeurophysData\';
        AUTODIR  = 'T:\SANDBOX diSTIM Pipeline\AutoSort-ed\';
        SORTDIR  = 'T:\SANDBOX diSTIM Pipeline\KiloSort-ed\';
        ALIGNDIR = 'T:\SANDBOX diSTIM Pipeline\V1Limits\';
        STIMDIR  = 'T:\SANDBOX diSTIM Pipeline\STIM-HdMUA\';
        SAVEDIR  = 'C:\Users\Brock\Documents\MATLAB\Working IDX Dir\HdMUA_test\';

    case {'blakeSSD'}     
        HOMEDIR  = strcat('C:\users\',username,'\Documents\MATLAB\');
        RIGDIR   = 'D:\Raw\';
        AUTODIR  = 'D:\AutoSort-ed\';
        SORTDIR  = 'D:\KiloSort-ed\';
        ALIGNDIR = 'D:\V1Limits\';
        STIMDIR  = 'D:\STIM\stim\';
        SAVEDIR  = 'D:\STIM\csd\';
        
    case {'blakeTeba'}  
        HOMEDIR  = strcat('C:\users\',username,'\Documents\MATLAB\');
        RIGDIR   = 'T:\diSTIM - adaptdcos&CRF\Neurophys Data\';
        AUTODIR  = 'T:\diSTIM - adaptdcos&CRF\AutoSort-ed\';
        SORTDIR  = 'T:\diSTIM - adaptdcos&CRF\KiloSort-ed\';
        ALIGNDIR = 'T:\diSTIM - adaptdcos&CRF\V1Limits\';
        STIMDIR  = 'D:\STIM\new\';
        SAVEDIR  = 'D:\STIM\new\';
        
    case {'blakeTest_2021'}
        HOMEDIR  = strcat('C:\users\',username,'\Documents\MATLAB\');
        RIGDIR   = 'D:\SANDBOX_2021\Raw Data 4\';
        AUTODIR  = '[]';
        SORTDIR  = '[]';
        ALIGNDIR = 'D:\V1Limits\';
        STIMDIR  = 'D:\SANDBOX_2021\STIM\';
        SAVEDIR  = 'D:\SANDBOX_2021\STIM\';
        
    case {'blakeRef_2021'}
        HOMEDIR  = strcat('C:\users\',username,'\Documents\MATLAB\');
        RIGDIR   = 'D:\SANDBOX_2021\Raw Data_Reference\';
        AUTODIR  = '';
        SORTDIR  = '';
        ALIGNDIR = 'D:\V1Limits\';
        STIMDIR  = 'D:\SANDBOX_2021\STIM\';
        SAVEDIR  = 'D:\SANDBOX_2021\STIM\';
       
end


 addpath(...
            [HOMEDIR 'ephys-analysis'],...
            [HOMEDIR 'ephys-analysis' filesep 'stim'],...
            [HOMEDIR 'ephys-analysis' filesep 'stim' filesep 'NPMK'],...
            [HOMEDIR 'ephys-analysis' filesep 'stim' filesep 'NPMK' filesep 'NSx Utilities'],...
            [HOMEDIR 'ephys-analysis' filesep 'utils'],...
            [HOMEDIR 'MLAnalysisOnline'],...
            [HOMEDIR  'MLAnalysisOnline' filesep 'BHV Analysis'])
           
        
end
