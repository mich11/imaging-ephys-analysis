'''
testing whether axonal calcium signals can be 
approximated with an exponential decay, as for 
somatic signals. 
Unitary calcium events were first extracted with 
wdetecta (https://huguenard-lab.stanford.edu/wdetecta.php) 
and manually curated in clampfit (hence the use of pyabf)

design choices:
calculated baseline offset using only the 1s prior to 
event onset to prevent preceding events from interfering
with baseline value

temporal window over which to compute the decay is hard-set
because I had a guess about the decay kinetics based on the 
fluorophore. Could pull this out to an input arg to make the 
function more general

'''

import pyabf
import matplotlib.pyplot as plt
import numpy as np
from scipy.optimize import curve_fit

def exponential (x,a,b):
	return a*np.exp(b*x)

def fit_abf (fname="ExampleData/m678_f5_r3dA_curated.abf",tstart=12,samprate=8.41):
	"""Fits exponential decay to mean trace from event sweeps in abf file.

	Input arguments:
	fname: path to abf file to be analyzed
	tstart: event start time (seconds)
	samprate: sampling rate (Hz)

	Returns: 
	pars: fit params for exponential
	tau: decay time constant

	Plots: 
	Upper panel: Mean trace (black), fitted curve (red), and individual sweeps (gray)
	Lower panel: residuals of fitted curve
	"""
	abf = pyabf.ABF(fname)
	sx = abf.sweepX*1000
	sweepMat = np.zeros([np.size(sx),abf.sweepCount])
	ymaxpre = np.zeros([abf.sweepCount,1])
	yminpre = np.zeros([abf.sweepCount,1])
	print(abf.sweepCount)

	'''
	for each trace, offset and scale
	then average across traces, compute exponential fit,
	and plot average, fit, and individual traces 
	'''
	fig = plt.figure()
	ax = plt.subplot2grid((3,1),(0,0),rowspan=2)
	ax2 = plt.subplot2grid((3,1),(2,0))
	tpre = tstart-1
	for stmp in abf.sweepList:
		abf.setSweep(stmp)
		preind1 = np.sum((sx-tpre)<0)-1
		preind2 = np.sum((sx-tstart)<0)-1
		yoffset = np.mean(abf.sweepY[preind1:preind2])
		sy = abf.sweepY-yoffset

		ax.plot(sx-tstart, sy, color='0.7')
		ax.set_xlim(-10,15)

		sweepMat[:,stmp]=sy
		ymaxpre[stmp]=max(sy[preind1:preind2+round(samprate*4)])
		yminpre[stmp]=min(sy[preind1:preind2+round(samprate*4)])

	msweep = np.mean(sweepMat,1);
	ymax = max(ymaxpre)*1.25;
	ymin = min(yminpre)*1.5;
	ax.plot(sx-tstart,msweep,color='black')
	ax.set_title(fname)
	ax.set_xlabel('time (s)')
	ax.set_ylim([ymin, ymax])

	mmax = np.argmax(msweep[preind2:preind2+round(samprate)])+preind2

	mpost = msweep[mmax:mmax+round(samprate*4)-2]
	xpost = sx[mmax:mmax+round(samprate*4)-2]-tstart
	xpost2 = xpost - min(xpost)
	pars, cov = curve_fit(f=exponential,xdata=xpost2,ydata=mpost,p0=[0,0],bounds=(-np.inf,np.inf))
	stdevs = np.sqrt(np.diag(cov))
	residuals = mpost - exponential(xpost,*pars)
	print(pars)
	tau = 1/pars[1]

	ax.plot(xpost,exponential(xpost2,*pars),color='red')
	ax2.set_title('residuals')
	ax2.set_xlabel('time (s)')
	ax2.scatter(xpost,residuals)
	plt.tight_layout()


	plt.show()
	return pars, tau

if __name__ == '__main__':
	fit_abf(fname="ExampleData/m678_f5_r3dA_curated.abf",tstart=12,samprate=8.41)
