%compute df/f by finding longest low variance period and computes baseline
%f/std there, and then performs df/f with this baseline

%input arguments:
%   ftmp:   fluorescence data
%   xtime:  time vector
%   stdWin: std window duration (samples)
%   sigPerc:    percentile threshold for rolling std

%output arguments:
%   bstart: low variance baseline computation window start
%   bend:   baseline computation window end
%   sigo:   std of df/f data over baseline window
%   bo:     baseline fluorescenc value
%   stdthresh:  threshold for rolled std data
%   sdtmp:  rolling std values
%   dff:    df/f data

function[bstart,bend,sigo,bo,stdthresh,sdtmp,dff]=dff_quiet(ftmp,stdWin,sigPerc)
%compute rolling std
sdtmp=movstd(ftmp,stdWin);
%find longest continuous low-variance period over which to compute
%baseline std
stdthresh=prctile(sdtmp,sigPerc);
hivarinds=find(sdtmp>=stdthresh);
[~,startind]=max(diff(hivarinds));
bstart=hivarinds(startind);
bend=hivarinds(startind+1);
bo=mean(ftmp(bstart:bend));
%compute df/f
dff=(ftmp-bo)./bo;
sigo=std(dff(bstart:bend));
