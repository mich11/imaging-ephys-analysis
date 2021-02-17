'''
Evaluate DLC network performance for pupil/eyelid coordinate estimation
run after training a network

For hLab members:
run on server S1BF (Ubuntu 18, Tesla P100 GPU)
run in conda environment DLC6, which has GPU support for tensorflow set up
run in /mnt/tempstor/michelle/pupilDLC for correct path for this project
'''

import os, subprocess, deeplabcut
from pathlib import Path
import pandas as pd
import numpy as np
import platform

print("Imported DLC!")

net_type='resnet_50'
augmenter_type='imgaug'
#augmenter_type='default'
path_config_file=os.path.join(os.getcwd(),'pupil-michelle-2020-10-13/config.yaml')

#check path config file
cfg=deeplabcut.auxiliaryfunctions.read_config(path_config_file)
print("Path configuration is ok!")

#make changes to pose_file before training
#if shuffle is not one, change
trainposefile,testposefile,snapfolder=deeplabcut.return_train_network_path(path_config_file,shuffle=1,trainFraction=cfg['TrainingFraction'][0])

dlc_config=deeplabcut.auxiliaryfunctions.read_plainconfig(trainposefile)
print("Successfully read pose_cfg.yaml!")

dlc_config['scale_jitter_up']=1.5

dlc_config['batch_size']=4
dlc_config['displayiters']=50
dlc_config['saveiters']=5000

dlc_config['augmentationprobability']=0.5
dlc_config['elastic_transform']=True
dlc_config['motion_blur']=True
dlc_config['covering']=True
dlc_config['optimizer']="adam"
dlc_config['dataset_type']='imgaug'
dlc_config['multi_step']=[[1e-4, 7500],[5.0e-5,12000],[1e-5,50000]]

deeplabcut.auxiliaryfunctions.write_plainconfig(trainposefile,dlc_config)
print("Successfully wrote pose_cfg.yaml")
#deeplabcut.train_network(path_config_file,displayiters=50,saveiters=5000,allow_growth=True)

deeplabcut.evaluate_network(path_config_file,plotting=True)
#IMPORTANT: check training and testing error here -- if it looks good, then analyze some videos and confirm performance

#first, set vidpath to direct to the videos you want to analyze. videos should be in the project/videos folder to satisfy DLC assumptions.
#e.g., to analyze one video 
vidpath=['/mnt/tempstor/michelle/pupilDLC/pupil-michelle-2020-10-13/videos/807Field10.mp4']
#or, do a list of files separated by commas. The square brackets are important, even for a single file. 
deeplabcut.analyze_videos(path_config_file,vidpath)

#then, create labeled videos
deeplabcut.create_labeled_video(path_config_file,vidpath,draw_skeleton=True)

#then, plot the trajectories
deeplabcut.plot_trajectories(path_config_file,vidpath,videotype=".mp4",showfigures=True)
