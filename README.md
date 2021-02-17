# imaging-ephys-analysis
This repo houses analyses for several different types of neural data and related behavior, written as part of experiments that seek to understand how absence seizures begin, and how sensory processing and seizures interact. Bonus! I've included some descriptions of the hardware/software I built to run these experiments. 

## inVivoMultistream
Analyze simultaneous EEG and calcium imaging data and measure seizure-related and sensory-evoked calcium activity. 

To Do: 
* add example data
* add calcium imaging ROI clustering
* add deconvolution
* add event extraction
* add event-related metrics

## fitAxonCa
Test whether single event calcium activity in axons follows the same fluorescent response profile expected for GCaMP6s (rapid rise, exponential decay with tau ~1s).

## pupilPrediction
Analyze simultaneous pupillometry and EEG data. Extract pupil coordinates from video with DeepLabCut (cite), plot against EEG, and measure pupil dynamics in the pre-seizure period.

To Do: 
* add example data
* add plot-against-EEG
* add pre-seizure analysis

## rigBuilding
Documentation for hardware setup and code snippets to run experiments. Right now, this is mainly useful for hLab members running new experiments on the rigs I built, but please ping me if you have questions.

* **InVivoMultistream:** Record EEG, calcium activity, treadmill running, pupillometry video, and trigger sensory stimuli for awake in vivo experiments. 

* **InterfaceImaging:** Record multiunit extracellular data and simultaneous calcium imaging in brain slices. 
