%converts PWM signal from rotary encoder/arduino to speed (m/s)
%detects signal peaks above noise floor using findpeaks 

%input arguments: 
%   adcIn:     1xn vector from open ephys analog input channel with rotary
%              encoder data (n=number of samples in recording)
%   sampRate:  sampling rate of adcIn (Hz)

%output arguments:
%   timeOut:   timestamp vector for speed values
%   speedOut:  treadmill speed (m/s)
            
%background: 
%The rotary encoder ticks 1024 times/revolution.
%Ticks get counted up into 100ms bins by arduino and sent as a PWM 5V
%signal to an analog in channel on the open ephys acquisition box. For
%example, a half rotation occurring during a single bin would look like a
%10ms pulse (50% duty cycle for 20ms bin). 

function[timeOut,speedOut]=ball_speed(adcIn,sampRate)

%treadmill diameter
ballDiamInch=6;
inchToM=.0254;
%constants dependent on arduino code that converts rotary encoder's gray 
%code to pwm
pwmPeriod=1/122;
pingRate=122;
countMultiplier=4;
pwmFull=255;


%ball circumference in meters
ballDiamM=ballDiamInch*inchToM;
ballCirc=pi*ballDiamM;
%distance traveled per increment measured by encoder
ballInc=ballCirc/1024;

%detect rising and falling edges
dBall=diff(adcIn);
ts=(linspace(1,length(adcIn),length(adcIn))-1)/sampRate;
dts=(linspace(1,length(dBall),length(dBall))-1)/sampRate;
[~,tRisingInd]=findpeaks(dBall,'MinPeakProminence',1);
[~,tFallingInd]=findpeaks(-dBall,'MinPeakProminence',1);
tRising=dts(tRisingInd);
tFalling=dts(tFallingInd);

%make sure that we only take differences between complete pwm measurements.
% In other words, the data don't start or end midway through a pwm pulse
if ~isempty(tRising)
    if tRising(1)<tFalling(1)
        if length(tRising)==length(tFalling)
            counts=tFalling-tRising;
        else
            counts=tFalling-tRising(1:end-1);
        end
    else
        if length(tRising)==length(tFalling)
            counts=tFalling(2:end)-tRising(1:end-1);
        else
            counts=tFalling(2:end)-tRising;
        end
    end
else
    counts=0;
end

%convert rising/falling edges to speed based on pwm and ball circumference
duty=ceil(counts/pwmPeriod/countMultiplier*pwmFull);
speed=duty*ballInc*pingRate;

% incorporate speeds into a vector where speed-free regions are set to zero.
% histcounts finds speed-related times closest to new sampling
% vector, corrects for multiple speed values binned together, and 
% builds a new vector based on gaps in the difference between rise times. 
maxtime=round(ts(end)*pingRate);
spvec=(0:maxtime+1)/pingRate;

[counts,edges]=histcounts(dts(tRisingInd),spvec);
cmerge=find(counts>1);
counts(cmerge)=counts(cmerge)-1;
counts(cmerge-1)=counts(cmerge-1)+1;
c2=find(counts>1);
tRisingIndNew=tRisingInd;
speedNew=speed;
for i=1:numel(c2)
    counts(c2(i))=1;
    findmin=abs(edges(i)-dts(tRisingIndNew));
    [~,ind]=sort(findmin);
    indToRemove=ind(2);
    tRisingIndNew=tRisingIndNew([1:indToRemove-1,indToRemove+1:end]);
    speedNew=speedNew([1:indToRemove-1,indToRemove+1:end]);
end

posCounts=find(counts==1);
newSpeedVec=zeros(1,numel(edges));
newSpeedVec(posCounts)=speedNew;
timeOut=edges;
speedOut=newSpeedVec;
