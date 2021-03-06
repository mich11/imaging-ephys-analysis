%compute df/f from suite2p ROIs
%saves dff and params used to compute dff, baseline f, and baseline noise
%sigma
%use Savitsky-Golay filter and rolling STD as in Ayaz et al, 2019, which
%compared running and somatosensory-evoked responses in L2/3 vs L5

%requires current directory to include:
%iscell.npy (suite2p output)
%Fall.mat (suite2p output)

%input arguments: 
    %sampRate = sampling rate (Hz)
    %varargin{1} = optoional earliest valid time for imaging 
    %varargin{2} = optional last valid time for imaging

%variables saved in dff.mat output file:
%   dff = df/f data for cells defined as ROIs after suite2p pipeline      
%   dffParams = struct of dff parameters
%   sigo = std of df/f data over low-variance baseline window

%dependencies:
%   readNPY (https://github.com/kwikteam/npy-matlab)

%background:
%   I experimented with a few different ways to calculate the baseline
%dff baseline f is lowest 1% after rolling sgolayfilt with 5s window
%5/2020 - added neuropil-subtracted fluorescence _before_ dff (fc2)
%       - added deconvolved spiking output (spk2)

function[]=suite2p_dff(sampRate,varargin)
%unpack ROI info and iscell classification from current directory
%only analyze ROIs classified as regions of interest after curation in
%suite2p GUI
iscell=readNPY('iscell.npy');
ic2=find(iscell(:,1)==1);
%neuropil-corrected response; offset to make all vals positive for df/f
%calculation later
f=load('Fall.mat');
fc=(f.F-min(min(f.F)))-0.7*(f.Fneu-min(min(f.Fneu)));
fc2=fc(ic2,:);
spk2=f.spks(ic2,:);
xtime=0:(numel(fc2(1,:))-1);
xtime=xtime/sampRate;

%Use optional input arguments to crop ca2+ imaging recording time if needed
%e.g. if objective meniscus changes and imaging quality is lost
tStart=xtime(1);
tEnd=xtime(end);
if nargin>1
    if nargin>2
        tEnd=varargin{2};
        indswitch2=find(xtime>=tEnd);
        if ~isempty(varargin{1})
            tStart=varargin{1};
            indswitch1=find(xtime>=varargin{1});
            xtime=xtime(indswitch1:indswitch2)-xtime(indswitch1);
            fc2=fc(ic2,indswitch1:indswitch2);
        else
            xtime=xtime(1:indswitch2);
            fc2=fc2(ic2,1:indswitch2);
        end
    else
        tStart=varargin{1};
        indswitch=find(xtime>=varargin{1});
        xtime=xtime(indswitch:end)-xtime(indswitch);
        fc2=fc(ic2,indswitch:end);
    end
end

%calculate # of samples for rolling std
%stdWinSec = window duration (s)
%needs to be rather short to exclude sparse activity from baseline window
stdWinSec=2;
stdWin=round(stdWinSec/2*sampRate);
stdWin=[stdWin,stdWin];

%set threshold value for rolling std, used to find continuous low-variance
%period. Std values under this percentile will be considered low variance.
sigPerc=50;

%uses helper function to generate df/f and significance threshold --
%comment out dff3a and uncomment one of the earlier dff calculation
%versions to compare. 
for i=1:numel(ic2)
    ftmp=fc2(i,:);
    [bstart(i),bend(i),sigo(i),bo(i),stdthresh(i),rstd(i,:),dff(i,:)]=dff3_quiet(ftmp,stdWin,sigPerc);
end

%plot a few ROI df/fs with baseline variance for sanity check
offset=0;
offset2=.25;
ids=1:10;
figure(3)
hold on
for i=ids
    ytmp=dff(i,:);
    ytmp=ytmp+offset;
    plot(xtime,ytmp);
    yline=[sigo(i),sigo(i)]*5+offset;
    plot([xtime(1),xtime(end)],yline,'Color',[0.5,0.5,0.5]);
    plot([xtime(1),xtime(end)],[offset,offset],'k')
    offset=max(ytmp)+offset2;
end
xlabel('time (s)')
title('Example ROI df/f, baseline, and 3*(baseline std) threshold')

%plot raw fluorescence for a few ROIs, rolling STD, and low variance
%baseline window
offset=0;
offset2=.25;
figure(4)
hold on
for i=ids
    ytmp=fc2(i,:);
    ytmp=ytmp+offset;
    plot(xtime,ytmp);
    yline=[stdthresh(i),stdthresh(i)]+offset+bo(i);
    sdt=rstd(i,:)+offset+bo(i);
    plot(xtime,sdt,'Color',[0.5,0.5,0.5]);
    plot([xtime(1),xtime(end)],yline,'r');
    plot([xtime(1),xtime(end)],[offset,offset]+bo(i),'k')
    scatter(xtime(bstart(i)),stdthresh(i)+offset+bo(i),'g','filled')
    scatter(xtime(bend(i)),stdthresh(i)+offset+bo(i),'g','filled')
    %plot(xtime,rbo(ids(i),:)+offset,'k')
    offset=max(ytmp)+offset2;
end
xlabel('time (s)')
title('10 example ROI f, rolling std, and low var baseline window')

%save dff, baseline std (sigo), parameters used to calculate baseline fluor
% (dffParms) and baseline calculation features (dffFeats)
dffParams.rollStdSec=stdWinSec;
dffParams.basePerc=basePerc;
dffParams.sigPerc=sigPerc;
dffParams.method='quiet';
dffParams.tStart=tStart;
dffParams.tEnd=tEnd;

dffFeats.rollingStdThresh=stdthresh;
dffFeats.baselineMean=bo;
dffFeats.baselineStd=sigo;
dffFeats.baselineStart=bstart;
dffFeats.baselineEnd=bend;
dffFeats.baselineDuration=xtime(bend-bstart);

%note -- as written, does not overwrite existing dff.mat. Written to add
%raw fluorescence data to dff.mat for deconvolution 
if isfile('dff.mat')
    varlist=who('-file','dff.mat');
    if ~ismember('fc2',varlist)
        save('dff.mat','fc2','spk2','sigo','-append')
    end
else
    save('dff.mat','dff','fc2','spk2','sigo','dffParams','dffFeats');
end







