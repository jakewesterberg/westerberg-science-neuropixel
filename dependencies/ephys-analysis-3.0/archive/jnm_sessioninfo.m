function [ jnmi ] = jnm_sessioninfo( jnmDate )
%jnm_sessioninfo.m
%Jake Westerberg
%Vanderbilt University
%Nov 8, 2016
%v2.0.0
%   

% mnky = monkey name
% date = date file was recorded
% pSte = area recorded from { bank1, bank2, etc }
% pNum = number of probes in session
% pCnl = number of channels per probe [ p1, p2, etc ]
% pSpc = spacing between channels per probe [ p1 spacing (um), p2 spacing (um), etc ]
% pDep = depth of 4c/5 boundary in channels from top per probe [ p1 depth, p2 depth, etc ]
%    IF there is another field pDep[File Ident] (ex pDepROM), then that applies to that file type.
% pLoc = location of probe in grid following Jake's numbering scheme ( only confirmed for 160831+ )
%     [ p1x, p1y; p2x, p2y; etc ]
% pDst = distance between probes if there were two probes (mm) 
%     3 probe example --> [p1-p1, p1-p2, p1-p3; p2-p1, p2-p2, p2-p3; p3-p1, p3-p2, p3-p3 ]
% pMpd = probe mapped that day using the suite [ p1, ... pn ]
% badc = bad channels THIS IS NOT FIXED. DOES NOT FUNCTION. HAVE NOT DECIDED ON DIFFERENTIATING PROBES
% note = notes for the day
% 
% Anything ending with 'f' is the file extension of the file to use in analyses...
%     This is only confirmed in rsd and evp files.
% ALSO if it ends in a 2, it was an alternate file I was testing. If there was more than one
%     good file, it will be in cell form. {file num 1, file num 2, etc }
% 
% 3 letter task identifiers
% 
% rsd = resting state data (darkrest)
% evp = evoked potential
% rom = receptive field orientation tuning (rfori)
% rfm = receptive field mapping (dotmapping)
% rsz = receptive field size tuning (rfsize)
% rsf = receptive field spatial frequency tuning (rfsf)
% dom = drifting receptive field orientation tuning (drfori)
% dbr = (dbrfs)
% brs = (brfs)
% mci = (mcosinteroc)
% cid = (cinterocdrft)
% dmi = (dmcosinteroc)


switch jnmDate
    
    case '121115'
        jnmi.mnky = 'helga';
        jnmi.date = '121115';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ];
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 17, 13 ];
        jnmi.pLoc = [ 1, 1; 2, 1 ];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.evpf = '002';
        jnmi.rsdf = '002';
        jnmi.fExt = 'ns6';
        
    case '121116'
        jnmi.mnky = 'helga';
        jnmi.date = '121116';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ];
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 14, 14 ];
        jnmi.pLoc = [ 2, -3; 2, -4 ];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.evpf = '002';
        jnmi.rsdf = '002';
        jnmi.fExt = 'ns6';
        
    case '121128'
        jnmi.mnky = 'helga';
        jnmi.date = '121128';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ];
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 14, 17 ];
        jnmi.pLoc = [ 2, -3; 1, -5 ];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.evpf = '001';
        jnmi.rsdf = '001';
        jnmi.fExt = 'ns6';
        
    case '121213'
        jnmi.mnky = 'helga';
        jnmi.date = '121213';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ];
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 14, 17 ];
        jnmi.pLoc = [ 2, -4; -1, -1 ];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.evpf = '001';
        jnmi.rsdf = '001';
        jnmi.fExt = 'ns6';
        
    case '121217'
        jnmi.mnky = 'helga';
        jnmi.date = '121217';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ];
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 16, 19 ];
        jnmi.pLoc = [ -1, 1; -3, -4 ];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.evpf = '001';
        jnmi.rsdf = '001';
        jnmi.fExt = 'ns6';
        
    case '130212'
        jnmi.mnky = 'helga';
        jnmi.date = '130212';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ];
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 16, 19 ];
        jnmi.pLoc = [ 1, 4; 0, 3 ];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.evpf = '001';
        jnmi.rsdf = '001';
        jnmi.fExt = 'ns6';
        
    case '130214'
        jnmi.mnky = 'helga';
        jnmi.date = '130214';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ];
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 14, 20 ];
        jnmi.pLoc = [ 0, 0; 0, 1 ];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.evpf = '001';
        jnmi.rsdf = '001';
        jnmi.fExt = 'ns6';
        
    case '130217'
        jnmi.mnky = 'helga';
        jnmi.date = '130217';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ];
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 15, 11 ];
        jnmi.pLoc = [ 1, -1; 1, -3 ];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.evpf = '001';
        jnmi.rsdf = '001';
        jnmi.fExt = 'ns6';
        
    case '130219'
        jnmi.mnky = 'helga';
        jnmi.date = '130219';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ];
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 14, 13 ];
        jnmi.pLoc = [ 0, -2; 1, -4 ];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.evpf = '002';
        jnmi.rsdf = '002';
        jnmi.fExt = 'ns6';
        
    case '130224'
        jnmi.mnky = 'helga';
        jnmi.date = '130224';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ];
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 15, 20 ];
        jnmi.pLoc = [ -2, -2; 2, 3 ];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.evpf = '001';
        jnmi.rsdf = '001';
        jnmi.fExt = 'ns6';
        
    case '130228'
        jnmi.mnky = 'helga';
        jnmi.date = '130228';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ];
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 17, 15 ];
        jnmi.pLoc = [ -2, -1; 0, -3 ];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.evpf = '001';
        jnmi.rsdf = '001';
        jnmi.fExt = 'ns6';
        
    case '130303'
        jnmi.mnky = 'helga';
        jnmi.date = '130303';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ]; 
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 16, 15 ];
        jnmi.pLoc = [ -1, -3; -1, -4 ];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.evpf = '001';
        jnmi.rsdf = '001';
        jnmi.fExt = 'ns6';
        
    case '130304'
        jnmi.mnky = 'helga';
        jnmi.date = '130304';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ]; 
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 15, 16 ];
        jnmi.pLoc = [ 0, 0; -1, 1 ];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.evpf = '001';
        jnmi.rsdf = '002';
        jnmi.fExt = 'ns6';
        
    case '130305'
        jnmi.mnky = 'helga';
        jnmi.date = '130305';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ]; 
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 14, 14 ];
        jnmi.pLoc = [ -2, -3; -2, -4 ];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.evpf = '001';
        jnmi.rsdf = '002';
        jnmi.fExt = 'ns6';
        
    case '130307'
        jnmi.mnky = 'helga';
        jnmi.date = '130307';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ]; 
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 15, 18 ];
        jnmi.pLoc = [ 3, -1; 3, 2 ];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.evpf = '001';
        jnmi.rsdf = '001';
        jnmi.fExt = 'ns6';
        
    case '130310'
        jnmi.mnky = 'helga';
        jnmi.date = '130310';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ]; 
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 12, 19 ];
        jnmi.pLoc = [ 4, 2; 3, 3 ];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.evpf = '001';
        jnmi.rsdf = '001';
        jnmi.fExt = 'ns6';
        
    case '130312'
        jnmi.mnky = 'helga';
        jnmi.date = '130312';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ]; 
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 15, 20 ];
        jnmi.pLoc = [ 1, 4; 0, 3 ];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.evpf = '001';
        jnmi.rsdf = '001';
        jnmi.fExt = 'ns6';
        
    case '130411'
        jnmi.mnky = 'bohr';
        jnmi.date = '130411';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ]; 
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 13, 15 ];
        jnmi.pLoc = [ 1, 0; 0, 1 ];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.evpf = '005';
        jnmi.rsdf = '003';
        jnmi.fExt = 'ns6';
        
    case '130412'
        jnmi.mnky = 'bohr';
        jnmi.date = '130412';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ]; 
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 16, 16 ];
        jnmi.pLoc = [ 0, -1; 0, 0 ];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.evpf = '004';
        jnmi.rsdf = '002';
        jnmi.fExt = 'ns6';
        
    case '130416'
        jnmi.mnky = 'bohr';
        jnmi.date = '130416';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ]; 
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 16, 14 ];
        jnmi.pLoc = [ 2, 0; 3, 1 ];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.evpf = '001';
        jnmi.rsdf = '002';
        jnmi.fExt = 'ns6';
        
    case '130419'
        jnmi.mnky = 'bohr';
        jnmi.date = '130419';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ]; 
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 15, 17 ];
        jnmi.pDepRSD = [ 19, 21 ];
        jnmi.pLoc = [ -1, -3; 2, -3 ];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.evpf = '004';
        jnmi.rsdf = '002';
        jnmi.fExt = 'ns6';
        
    case '130421'
        jnmi.mnky = 'bohr';
        jnmi.date = '130421';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ]; 
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 12, 11 ];
        jnmi.pLoc = [ -1, -1; -1, 1 ];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.evpf = '001';
        jnmi.rsdf = '001';
        jnmi.fExt = 'ns6';
        
    case '130423'
        jnmi.mnky = 'bohr';
        jnmi.date = '130423';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ]; 
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 14, 15 ];
        jnmi.pLoc = [ -2, 1; -2, 0 ];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.evpf = '002';
        jnmi.rsdf = '010';
        jnmi.fExt = 'ns6';
        
    case '130424'
        jnmi.mnky = 'bohr';
        jnmi.date = '130424';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ]; 
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 15, 16 ];
        jnmi.pLoc = [ -1, 0; 0, -3 ];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.evpf = '001';
        jnmi.rsdf = '001';
        jnmi.fExt = 'ns6';
        
    case '130425'
        jnmi.mnky = 'bohr';
        jnmi.date = '130425';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ]; 
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 16, 15 ];
        jnmi.pLoc = [ 3, 0; 3, 5 ];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.evpf = '003';
        jnmi.rsdf = '002';
        jnmi.fExt = 'ns6';
        
    case '130426'
        jnmi.mnky = 'bohr';
        jnmi.date = '130426';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ]; 
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 14, 9 ];
        jnmi.pLoc = [ 2, 1; 2, 4 ];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.evpf = '001';
        jnmi.rsdf = '002';
        jnmi.fExt = 'ns6';
        
    case '130430'
        jnmi.mnky = 'bohr';
        jnmi.date = '130430';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ]; 
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 12, 12 ];
        jnmi.pLoc = [ -3, -1; -2, -2 ];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.evpf = '001';
        jnmi.rsdf = '001';
        jnmi.fExt = 'ns6';
        
    case '130501'
        jnmi.mnky = 'bohr';
        jnmi.date = '130501';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ]; 
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 11, 9 ];
        jnmi.pLoc = [ 2, -1; 2, 4 ];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.evpf = '001';
        jnmi.rsdf = '001';
        jnmi.fExt = 'ns6';
        
    case '130506'
        jnmi.mnky = 'bohr';
        jnmi.date = '130506';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ]; 
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 12, 12 ];
        jnmi.pLoc = [ -3, 1; -3, 0 ];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.evpf = '001';
        jnmi.rsdf = '001';
        jnmi.fExt = 'ns6';
        
    case '130507'
        jnmi.mnky = 'bohr';
        jnmi.date = '130507';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ]; 
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 13, 15 ];
        jnmi.pLoc = [ -3, -3; 3, -3 ];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.evpf = '003';
        jnmi.rsdf = '001';
        jnmi.fExt = 'ns6';
        
    case '130514'
        jnmi.mnky = 'bohr';
        jnmi.date = '130514';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ]; 
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 16, 18 ];
        jnmi.pLoc = [ 1, -3; 0, -4 ];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.evpf = '001';
        jnmi.rsdf = '001';
        jnmi.fExt = 'ns6';
        
    case '130515'
        jnmi.mnky = 'bohr';
        jnmi.date = '130515';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ]; 
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 16, 14 ];
        jnmi.pLoc = [ 3, 3; 5, 3 ];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.evpf = '002';
        jnmi.rsdf = '002';
        jnmi.fExt = 'ns6';
        
    case '130521'
        jnmi.mnky = 'bohr';
        jnmi.date = '130521';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ]; 
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 14, 13 ];
        jnmi.pLoc = [ 4, 0; 4, -2 ];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.evpf = '002';
        jnmi.rsdf = '001';
        jnmi.fExt = 'ns6';
        
    case '130524'
        jnmi.mnky = 'bohr';
        jnmi.date = '130524';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ]; 
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 16, 16 ];
        jnmi.pLoc = [ 1, -2; 4, -1 ];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.evpf = '004';
        jnmi.rsdf = '002';
        jnmi.fExt = 'ns6';
        
    case '151125'
        jnmi.mnky = 'einstein';
        jnmi.date = '151125';
        jnmi.pSte = { 'V1' };
        jnmi.pNum = 1;
        jnmi.pCnl = [ 24 ]; 
        jnmi.pSpc = [ 100 ];
        jnmi.pDep = [ 14 ];
        jnmi.pLoc = [ NaN, NaN ];
        jnmi.evpf = '001';
        jnmi.rfmf = '005';
        jnmi.romf = '003';
        jnmi.fExt = 'ns6';
        
    case '151203'
        jnmi.mnky = 'einstein';
        jnmi.date = '151203';
        jnmi.pSte = { 'V1' };
        jnmi.pNum = 1;
        jnmi.pCnl = [ 24 ]; 
        jnmi.pSpc = [ 100 ];
        jnmi.pDep = [ 18 ];
        jnmi.pLoc = [ NaN, NaN ];
        jnmi.evpf = '001';
        jnmi.rfmf = '002';
        jnmi.romf = '004';
        jnmi.fExt = 'ns6';
        
    case '151204'
        jnmi.mnky = 'einstein';
        jnmi.date = '151203';
        jnmi.pSte = { 'V1' };
        jnmi.pNum = 1;
        jnmi.pCnl = [ 24 ]; 
        jnmi.pSpc = [ 100 ];
        jnmi.pDep = [ 11 ];
        jnmi.pDepROM = [ 12 ];
        jnmi.pLoc = [ NaN, NaN ];
        jnmi.evpf = '002';
        jnmi.rfmf = '005';
        jnmi.romf = '005';
        jnmi.fExt = 'ns6';
        
    case '151207'
        jnmi.mnky = 'einstein';
        jnmi.date = '151207';
        jnmi.pSte = { 'V1' };
        jnmi.pNum = 1;
        jnmi.pCnl = [ 24 ]; 
        jnmi.pSpc = [ 100 ];
        jnmi.pDep = [ 17 ];
        jnmi.pDepROM = [ 18 ];
        jnmi.pLoc = [ NaN, NaN ];
        jnmi.evpf = '004';
        jnmi.rfmf = '003';
        jnmi.romf = '002';
        jnmi.fExt = 'ns6';
        
    case '151208'
        jnmi.mnky = 'einstein';
        jnmi.date = '151208';
        jnmi.pSte = { 'V1' };
        jnmi.pNum = 1;
        jnmi.pCnl = [ 24 ]; 
        jnmi.pSpc = [ 100 ];
        jnmi.pDep = [ 19 ];
        jnmi.pDepROM = [ 20 ];
        jnmi.pLoc = [ NaN, NaN ];
        jnmi.evpf = '007';
        jnmi.rfmf = '003';
        jnmi.romf = '003';
        jnmi.fExt = 'ns6';  
        
    case '151210'
        jnmi.mnky = 'einstein';
        jnmi.date = '151210';
        jnmi.pSte = { 'V1' };
        jnmi.pNum = 1;
        jnmi.pCnl = [ 24 ]; 
        jnmi.pSpc = [ 100 ];
        jnmi.pDep = [ 14 ];
        jnmi.pLoc = [ NaN, NaN ];
        jnmi.romf = '002';
        jnmi.fExt = 'ns6';
        
    case '151211'
        jnmi.mnky = 'einstein';
        jnmi.date = '151211';
        jnmi.pSte = { 'V1' };
        jnmi.pNum = 1;
        jnmi.pCnl = [ 24 ]; 
        jnmi.pSpc = [ 100 ];
        jnmi.pDep = [ 19 ];
        jnmi.pDepROM = [ 20 ];
        jnmi.pLoc = [ NaN, NaN ];
        jnmi.evpf = '003';
        jnmi.rsdf = '001';
        jnmi.rfmf = '002';
        jnmi.romf = '002';
        jnmi.fExt = 'ns6';
        
    case '151212'
        jnmi.mnky = 'einstein';
        jnmi.date = '151212';
        jnmi.pSte = { 'V1' };
        jnmi.pNum = 1;
        jnmi.pCnl = [ 24 ]; 
        jnmi.pSpc = [ 100 ];
        jnmi.pDep = [ 17 ];
        jnmi.pLoc = [ NaN, NaN ];
        jnmi.evpf = '001';
        jnmi.rfmf = '005';
        jnmi.romf = '005';
        jnmi.fExt = 'ns6';
        
    case '151221'
        jnmi.mnky = 'einstein';
        jnmi.date = '151221';
        jnmi.pSte = { 'V1' };
        jnmi.pNum = 1;
        jnmi.pCnl = [ 24 ]; 
        jnmi.pSpc = [ 100 ];
        jnmi.pDep = [ 11 ];
        jnmi.pDepROM = [ 13 ];
        jnmi.pLoc = [ NaN, NaN ];
        jnmi.evpf = '001';
        jnmi.rfmf = '002';
        jnmi.romf = '001';
        jnmi.fExt = 'ns6';
        
    case '151222'
        jnmi.mnky = 'einstein';
        jnmi.date = '151222';
        jnmi.pSte = { 'V1' };
        jnmi.pNum = 1;
        jnmi.pCnl = [ 24 ]; 
        jnmi.pSpc = [ 100 ];
        jnmi.pDep = [ 13 ];
        jnmi.pDepROM = [ 14 ];
        jnmi.pLoc = [ NaN, NaN ];
        jnmi.evpf = '001';
        jnmi.rfmf = '002';
        jnmi.romf = '003';
        jnmi.fExt = 'ns6';
        
    case '160102'
        jnmi.mnky = 'einstein';
        jnmi.date = '160102';
        jnmi.pSte = { 'V1' };
        jnmi.pNum = 1;
        jnmi.pCnl = [ 32 ]; 
        jnmi.pSpc = [ 100 ];
        jnmi.pDep = [ 18 ];
        jnmi.pDepROM = [20 ];
        jnmi.pLoc = [ NaN, NaN ];
        jnmi.evpf = '001';
        jnmi.rfmf = '002';
        jnmi.romf = '003';
        jnmi.fExt = 'ns6';
        
    case '160104'
        jnmi.mnky = 'einstein';
        jnmi.date = '160104';
        jnmi.pSte = { 'V1' };
        jnmi.pNum = 1;
        jnmi.pCnl = [ 32 ]; 
        jnmi.pSpc = [ 100 ];
        jnmi.pDep = [ 21 ];
        jnmi.pDepROM = [ 22 ];
        jnmi.pLoc = [ NaN, NaN ];
        jnmi.evpf = '001';
        jnmi.rfmf = '002';
        jnmi.romf = '002';
        jnmi.fExt = 'ns6';
        
    case '160108'
        jnmi.mnky = 'einstein';
        jnmi.date = '160108';
        jnmi.pSte = { 'V1' };
        jnmi.pNum = 1;
        jnmi.pCnl = [ 32 ]; 
        jnmi.pSpc = [ 100 ];
        jnmi.pDep = [ 22 ];
        jnmi.pDepROM = [ 23 ];
        jnmi.pLoc = [ NaN, NaN ];
        jnmi.evpf = '002';
        jnmi.rfmf = '004';
        jnmi.romf = '004';
        jnmi.fExt = 'ns6';
        
    case '160115'
        jnmi.mnky = 'einstein';
        jnmi.date = '160115';
        jnmi.pSte = { 'V1' };
        jnmi.pNum = 1;
        jnmi.pCnl = [ 32 ]; 
        jnmi.pSpc = [ 100 ];
        jnmi.pDep = [ 14 ];
        jnmi.pLoc = [ NaN, NaN ];
        jnmi.evpf = '002';
        jnmi.rfmf = '002';
        jnmi.romf = '003';
        jnmi.fExt = 'ns6';
        
    case '160128'
        jnmi.mnky = 'ingrid';
        jnmi.date = '160128';
        jnmi.pSte = { 'V1' };
        jnmi.pNum = 1;
        jnmi.pCnl = [ 32 ]; 
        jnmi.pSpc = [ 100 ];
        jnmi.pDep = [ 28 ];
        jnmi.pLoc = [ NaN, NaN ];
        jnmi.evpf = '002';
        jnmi.rfmf = '002';
        jnmi.romf = '003';
        jnmi.fExt = 'ns6';
        
    case '160130'
        jnmi.mnky = 'ingrid';
        jnmi.date = '160130';
        jnmi.pSte = { 'V1' };
        jnmi.pNum = 1;
        jnmi.pCnl = [ 32 ]; 
        jnmi.pSpc = [ 100 ];
        jnmi.pDep = [ 19 ];
        jnmi.pDepROM = [ 21 ];
        jnmi.pLoc = [ NaN, NaN ];
        jnmi.evpf = '001';
        jnmi.rfmf = '002';
        jnmi.romf = '003';
        jnmi.fExt = 'ns6';
        
    case '160131'
        jnmi.mnky = 'ingrid';
        jnmi.date = '160131';
        jnmi.pSte = { 'V1' };
        jnmi.pNum = 1;
        jnmi.pCnl = [ 32 ]; 
        jnmi.pSpc = [ 100 ];
        jnmi.pDep = [ 17 ];
        jnmi.pDepROM = [ 18 ];
        jnmi.pLoc = [ NaN, NaN ];
        jnmi.evpf = '001';
        jnmi.rfmf = '002';
        jnmi.romf = '003';
        jnmi.fExt = 'ns6';
        
    case '160204'
        jnmi.mnky = 'ingrid';
        jnmi.date = '160204';
        jnmi.pSte = { 'V1' };
        jnmi.pNum = 1;
        jnmi.pCnl = [ 32 ]; 
        jnmi.pSpc = [ 100 ];
        jnmi.pDep = [ 20 ];
        jnmi.pLoc = [ NaN, NaN ];
        jnmi.evpf = '001';
        jnmi.rfmf = '002';
        jnmi.romf = '004';
        jnmi.fExt = 'ns6';
        
    case '160211'
        jnmi.mnky = 'ingrid';
        jnmi.date = '160211';
        jnmi.pSte = { 'V1' };
        jnmi.pNum = 1;
        jnmi.pCnl = [ 32 ]; 
        jnmi.pSpc = [ 100 ];
        jnmi.pDep = [ 21 ];
        jnmi.pLoc = [ NaN, NaN ];
        jnmi.rfmf = '002';
        jnmi.romf = '004';
        jnmi.fExt = 'ns6';
        
    case '160212'
        jnmi.mnky = 'ingrid';
        jnmi.date = '160212';
        jnmi.pSte = { 'V1' };
        jnmi.pNum = 1;
        jnmi.pCnl = [ 32 ]; 
        jnmi.pSpc = [ 100 ];
        jnmi.pDep = [ 18 ];
        jnmi.pLoc = [ NaN, NaN ];
        jnmi.evpf = '001';
        jnmi.romf = '003';
        jnmi.fExt = 'ns6';
        
    case '160418'
        jnmi.mnky = 'einstein';
        jnmi.date = '160418';
        jnmi.pSte = { 'V1' };
        jnmi.pNum = 1;
        jnmi.pCnl = [ 32 ]; 
        jnmi.pSpc = [ 100 ];
        jnmi.pDep = [ 25 ];
        jnmi.pLoc = [ NaN, NaN ];
        jnmi.romf = '003';
        jnmi.fExt = 'ns6';
        
    case '160420'
        jnmi.mnky = 'einstein';
        jnmi.date = '160420';
        jnmi.pSte = { 'V1' };
        jnmi.pNum = 1;
        jnmi.pCnl = [ 32 ]; 
        jnmi.pSpc = [ 100 ];
        jnmi.pDep = [ 25 ];
        jnmi.pLoc = [ NaN, NaN ];
        jnmi.romf = '002';
        jnmi.fExt = 'ns6';
        
    case '160421'
        jnmi.mnky = 'einstein';
        jnmi.date = '160421';
        jnmi.pSte = { 'V1' };
        jnmi.pNum = 1;
        jnmi.pCnl = [ 32 ]; 
        jnmi.pSpc = [ 100 ];
        jnmi.pDep = [ 24 ];
        jnmi.pLoc = [ NaN, NaN ];
        jnmi.romf = '002';
        jnmi.fExt = 'ns6';
        
    case '160422'
        jnmi.mnky = 'einstein';
        jnmi.date = '160422';
        jnmi.pSte = { 'V1' };
        jnmi.pNum = 1;
        jnmi.pCnl = [ 32 ]; 
        jnmi.pSpc = [ 100 ];
        jnmi.pDep = [ 23 ];
        jnmi.pLoc = [ NaN, NaN ];
        jnmi.romf = '003';
        jnmi.fExt = 'ns6';
        
    case '160423'
        jnmi.mnky = 'einstein';
        jnmi.date = '160423';
        jnmi.pSte = { 'V1' };
        jnmi.pNum = 1;
        jnmi.pCnl = [ 32 ]; 
        jnmi.pSpc = [ 100 ];
        jnmi.pDep = [ 22 ];
        jnmi.pLoc = [ NaN, NaN ];
        jnmi.romf = '003';
        jnmi.fExt = 'ns6';
        
    case '160425'
        jnmi.mnky = 'einstein';
        jnmi.date = '160425';
        jnmi.pSte = { 'V1' };
        jnmi.pNum = 1;
        jnmi.pCnl = [ 32 ]; 
        jnmi.pSpc = [ 100 ];
        jnmi.pDep = [ 27 ];
        jnmi.pLoc = [ NaN, NaN ];
        jnmi.romf = '004';
        jnmi.fExt = 'ns6';
        
    case '160427'
        jnmi.mnky = 'einstein';
        jnmi.date = '160427';
        jnmi.pSte = { 'V1' };
        jnmi.pNum = 1;
        jnmi.pCnl = [ 32 ]; 
        jnmi.pSpc = [ 100 ];
        jnmi.pDep = [ 22 ];
        jnmi.pLoc = [ NaN, NaN ];
        jnmi.romf = '002';
        jnmi.fExt = 'ns6';
        
    case '160429'
        jnmi.mnky = 'einstein';
        jnmi.date = '160429';
        jnmi.pSte = { 'V1' };
        jnmi.pNum = 1;
        jnmi.pCnl = [ 32 ]; 
        jnmi.pSpc = [ 100 ];
        jnmi.pDep = [ 25 ];
        jnmi.pLoc = [ NaN, NaN ];
        jnmi.romf = '002';
        jnmi.fExt = 'ns6';
        
    case '160502'
        jnmi.mnky = 'einstein';
        jnmi.date = '160502';
        jnmi.pSte = { 'V1' };
        jnmi.pNum = 1;
        jnmi.pCnl = [ 32 ]; 
        jnmi.pDep = [ 26 ];
        jnmi.pSpc = [ 100 ];
        jnmi.pLoc = [ NaN, NaN ];
        jnmi.romf = '003';
        jnmi.fExt = 'ns6';
        
    case '160505'
        jnmi.mnky = 'einstein';
        jnmi.date = '160505';
        jnmi.pSte = { 'V1' };
        jnmi.pNum = 1;
        jnmi.pCnl = [ 32 ]; 
        jnmi.pSpc = [ 100 ];
        jnmi.pDep = [ 28 ];
        jnmi.pLoc = [ NaN, NaN ];
        jnmi.romf = '002';
        jnmi.fExt = 'ns6';
        
    case '160510'
        jnmi.mnky = 'einstein';
        jnmi.date = '160510';
        jnmi.pSte = { 'V1' };
        jnmi.pNum = 1;
        jnmi.pCnl = [ 32 ]; 
        jnmi.pSpc = [ 100 ];
        jnmi.pDep = [ 29 ];
        jnmi.pLoc = [ NaN, NaN ];
        jnmi.romf = '002';
        jnmi.fExt = 'ns6';
        
    case '160512'
        jnmi.mnky = 'einstein';
        jnmi.date = '160512';
        jnmi.pSte = { 'V1' };
        jnmi.pNum = 1;
        jnmi.pCnl = [ 32 ]; 
        jnmi.pSpc = [ 100 ];
        jnmi.pDep = [ 21 ];
        jnmi.pLoc = [ NaN, NaN ];
        jnmi.romf = '003';
        jnmi.fExt = 'ns6';
        
    case '160523'
        jnmi.mnky = 'einstein';
        jnmi.date = '160523';
        jnmi.pSte = { 'V1' };
        jnmi.pNum = 1;
        jnmi.pCnl = [ 24 ]; 
        jnmi.pSpc = [ 100 ];
        jnmi.pDep = [ 18 ];
        jnmi.pLoc = [ NaN, NaN ];
        jnmi.romf = '002';
        jnmi.fExt = 'ns6';
        
    case '160825'
        jnmi.mnky = 'einstein';
        jnmi.date = '160825';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ]; 
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 16, 18 ];
        jnmi.pLoc = [ 0, 0; 1, 0 ];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.evpf = '003';
        jnmi.rsdf = '006';
        jnmi.fExt = 'ns6';        
        
    case '160831'
        jnmi.mnky = 'einstein';
        jnmi.date = '160831';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ]; 
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 16, 18 ];
        jnmi.pLoc = [ 9, 3; 10, 5 ];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.pMpd = 1 : 2;
        jnmi.evpf = '001';
        jnmi.evpf2 = '002';
        jnmi.rsdf2 = '003';
        jnmi.rsdf = '004';
        jnmi.rfmf = '003';
        jnmi.romf = '002';
        jnmi.domf = '001';
        jnmi.ffExt = 'ns6';
        
    case '160905'
        jnmi.mnky = 'einstein';
        jnmi.date = '160905';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ]; 
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 16, 17 ];
        jnmi.pDepROM = [ 18, 19 ];
        jnmi.pLoc = [ 9, 3; 12, 4 ];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.pMpd = 1 : 2;
        jnmi.evpf = '001';
        jnmi.rsdf = '002';
        jnmi.rfmf = '002';
        jnmi.romf = '001';
        jnmi.domf = '001';
        jnmi.fExt = 'ns6';
        
    case '160908'
        jnmi.mnky = 'einstein';
        jnmi.date = '160908';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ]; 
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 14, 15 ];
        jnmi.pLoc = [ 8,7;9,8];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.pMpd = 2;
        jnmi.evpf = '001';
        jnmi.rsdf = '002';
        jnmi.rfmf = '002';
        jnmi.romf = '001';
        jnmi.domf = '001';
        jnmi.fExt = 'ns6';
        
    case '160922'
        jnmi.mnky = 'einstein';
        jnmi.date = '160922';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ]; 
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 14, 15 ];
        jnmi.pLoc = [ 10,5;11,6];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.pMpd = 1 : 2;
        jnmi.badc = [ 23, 24 ];
        jnmi.evpf = '001';
        jnmi.rsdf = '006';
        jnmi.rfmf = '003';
        jnmi.romf = '002';
        jnmi.rszf = '001';
        jnmi.rsff = '001';
        jnmi.fExt = 'ns6';
        
    case '160923'
        jnmi.mnky = 'einstein';
        jnmi.date = '160923';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ]; 
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 12, 15 ];
        jnmi.pDepROM = [ 14, 16 ];
        jnmi.pLoc = [ 11,8;12,8];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.pMpd = 1 : 2;
        jnmi.bad1 = [ 23, 24 ];
        jnmi.evpf = '002';
        jnmi.rsdf = '003';
        jnmi.nysf = '002';
        jnmi.rfmf = '002';
        jnmi.romf = '002';
        jnmi.fExt = 'ns6';
        
    case '160925'
        jnmi.mnky = 'einstein';
        jnmi.date = '160925';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ]; 
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 16, 16 ];
        jnmi.pLoc = [ 10,6;11,6];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.pMpd = 1 : 2;
        jnmi.badc = [ 23, 24 ];
        jnmi.evpf = '001';
        jnmi.rsdf = '007';
        jnmi.rfmf = '002';
        jnmi.romf = '001';
        jnmi.fExt = 'ns6';
        
    case '160926'
        jnmi.mnky = 'einstein';
        jnmi.date = '160926';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ]; 
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 16, 16 ];
        jnmi.pLoc = [ 11,7;11,8];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.pMpd = 1 : 2;
        jnmi.badc = [ 23, 24 ];
        jnmi.evpf = '001';
        jnmi.rsdf = '006';
        jnmi.rsdf2 = '005';
        jnmi.rfmf = '002';
        jnmi.romf = '002';
        jnmi.rszf = '002';
        jnmi.fExt = 'ns6';
        
    case '160927'
        jnmi.mnky = 'einstein';
        jnmi.date = '160927';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ]; 
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 14, 16 ];
        jnmi.pDepROM = [ 16, 16 ];
        jnmi.pLoc = [ 13,6;13,7];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.pMpd = 1 : 2;
        jnmi.badc = [ 23, 24 ];
        jnmi.evpf = '001';
        jnmi.rsdf = '005';
        jnmi.rfmf = '003';
        jnmi.romf = '001';
        jnmi.romf2 = '002';
        jnmi.rszf = '001';
        jnmi.rsff = '001';
        jnmi.nysf = '004';
        jnmi.nysf2 = '003';
        jnmi.nysf3 = '001';
        jnmi.fExt = 'ns6';
        
    case '160929'
        jnmi.mnky = 'einstein';
        jnmi.date = '160929';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ]; 
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 14, 15 ];
        jnmi.pLoc = [ 12,7;13,7];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.pMpd = 1 : 2;
        jnmi.badc = [ 23, 24 ];
        jnmi.evpf = '001';
        jnmi.rsdf = '006';
        jnmi.rfmf = '003';
        jnmi.romf = '001';
        jnmi.romf2 = '002';
        jnmi.rszf = '001';
        jnmi.rsff = '001';
        jnmi.fExt = 'ns6';
        
    case '161003'
        jnmi.mnky = 'einstein';
        jnmi.date = '161003';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ]; 
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 16, 16 ];
        jnmi.pLoc = [ 8,9;9,9];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.pMpd = 2;
        jnmi.bad1 = [ 23, 24 ];
        jnmi.evpf = '001';
        jnmi.rsdf = '007';
        jnmi.rfmf = '002';
        jnmi.romf = '001';
        jnmi.romf2 = '002';
        jnmi.rszf = '002';
        jnmi.rsff = '001';
        jnmi.fExt = 'ns6';
        
    case '161004'
        jnmi.mnky = 'einstein';
        jnmi.date = '161004';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ]; 
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 14, 15];
        jnmi.pLoc = [ 8,7;9,7];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.pMpd = 1 : 2;
        jnmi.evpf = '001';
        jnmi.rsdf = '003';
        jnmi.rfmf = '003';
        jnmi.romf = '002';
        jnmi.rszf = '002';
        jnmi.rsff = '001';
        jnmi.cidf = '001';
        jnmi.fExt = 'ns6';
        
    case '161005'
        jnmi.mnky = 'einstein';
        jnmi.date = '161005';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ]; 
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 15, 16 ];
        jnmi.pLoc = [ 8,8;9,8];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.pMpd = 1;
        jnmi.evpf = '001';
        jnmi.rsdf = '003';
        jnmi.rfmf = '002';
        jnmi.romf = '003';
        jnmi.domf = '001';
        jnmi.rszf = '001';
        jnmi.rsff = '001';
        jnmi.cidf = {'001','002'};
        jnmi.brsf = '001';
        jnmi.dbrf = '001';
        jnmi.mcif = '001';
        jnmi.fExt = 'ns6';
        
    case '161006'
        jnmi.mnky = 'einstein';
        jnmi.date = '161006';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ]; 
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 14, 15 ];
        jnmi.pLoc = [ 6,8;11,8];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.pMpd = 1 : 2;
        jnmi.evpf = '001';
        jnmi.rsdf = '002';
        jnmi.rfmf = '003';
        jnmi.romf = '001';
        jnmi.rszf = '002';
        jnmi.rsff = '001';
        jnmi.mcif = {'001','002'};
        jnmi.dmif = '001';
        jnmi.fExt = 'ns6';
        
    case '161007'
        jnmi.mnky = 'einstein';
        jnmi.date = '161007';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ]; 
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 16, 17 ];
        jnmi.pDepROM = [ 19, 17 ];
        jnmi.pLoc = [ 7,7;12,7];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.pMpd = 1;
        jnmi.evpf = '001';
        jnmi.rsdf = '004';
        jnmi.rfmf = '003';
        jnmi.romf = '002';
        jnmi.rszf = '001';
        jnmi.rsff = '001';
        jnmi.dbrf = {'003','002'};
        jnmi.brsf = '001';
        jnmi.fExt = 'ns6';
        
    case '161008'
        jnmi.mnky = 'einstein';
        jnmi.date = '161008';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ]; 
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 16, 14 ];
        jnmi.pLoc = [ 6,7;10,7];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.pMpd = 1 : 2;
        jnmi.evpf = '002';
        jnmi.rsdf = '005';
        jnmi.rfmf = '003';
        jnmi.romf = '003';
        jnmi.rszf = '001';
        jnmi.rsff = '001';
        jnmi.dmif = { '001', '002' };
        jnmi.cmif = '001';
        jnmi.fExt = 'ns6';
        
    case '161011'
        jnmi.mnky = 'einstein';
        jnmi.date = '161011';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ]; 
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 14, 16 ];
        jnmi.pLoc = [ 8,8;9,8];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.pMpd = 2;
        jnmi.evpf2 = '001';
        jnmi.evpf = '002';
        jnmi.rsdf2 = '004';
        jnmi.rsdf = '005';
        jnmi.rfmf = '002';
        jnmi.romf = '001';
        jnmi.domf = '001';
        jnmi.rszf = '001';
        jnmi.rsff = '001';
        jnmi.dbrf = {'002','001'};
        jnmi.brsf = '001';
        jnmi.fExt = 'ns6';
        
    case '161012' 
        jnmi.mnky = 'einstein';
        jnmi.date = '161012';
        jnmi.pSte = { 'V1', 'V1' };
        jnmi.pNum = 2;
        jnmi.pCnl = [ 24, 24 ]; 
        jnmi.pSpc = [ 100, 100 ];
        jnmi.pDep = [ 11, 15 ];
        jnmi.pLoc = [ 5,8;6,8];
        jnmi.pDst = dstcalc( jnmi.pLoc, jnmi.pNum );
        jnmi.evpf2 = '001';
        jnmi.evpf = '002';
        jnmi.rsdf2 = '003';
        jnmi.rsdf = '004';
        jnmi.note = 'Could not map RF in either probe.';
        
    otherwise
        jnmi = [];
        
end
end

function [dst] = dstcalc( jnmpts, pNum )
for i = 1 : pNum
    for j = 1 : pNum
       dst( i, j ) = sqrt( ( jnmpts( j, 1 ) - ...
            jnmpts( i, 1 ) )^2 + (jnmpts( j, 2 ) - ...
            jnmpts( i, 2 ) )^2 );
    end
end
end
