
"""
Created on Mon Jul 07 14:59:03 2014

@author: derricw 
modified by JMS
modified by PMF 6/18/19

Reads frames from Manta camera using opencv (cv2).
Optionally waits for folder creation event to sync with 
Open-Ephys data collection.

"""

from pymba import *
import numpy as np
import cv2
import time
import sys
import os
from concurrent import futures
from examples.camera.display_frame import display_frame
executor = futures.ThreadPoolExecutor(max_workers = 3)

# todo add more colours
PIXEL_FORMATS_CONVERSIONS = {
    'BayerRG8': cv2.COLOR_BAYER_RG2RGB,
}

#========================================================
def captureImg():
    global frame
    frame.queueFrameCapture()
    frame.waitFrameCapture(5000)
    img = np.ndarray(buffer=frame.getBufferByteData(),
                     dtype=np.uint8,
                     shape=(frame.height, frame.width, frame.pixel_bytes))
    return img

def saveImg(img,counter):
    name = "{0:0=5d}".format(counter)
    print("saving frame" + name)
    cv2.imwrite(name + ".jpg", img)

#===========================================================

def waitToCapture(directory):
    # wait for a subfolder creation in the rootfolder "directory"
    prechange = [files for files in os.listdir( directory )]
    while True:
        postchange = [files for files in os.listdir( directory )]
        change = [files for files in postchange if not files in prechange]
        if change:
            break
    print(change)
    return change

def changeDirectory(directory):
    if not os.path.isdir(directory):
        os.mkdir(directory)
    os.chdir(directory)


#========================================================
count = 0
framecount = []
timestamp = []
outdir = input("Output directory: ")
waiting = int(input("wait for subfolder? [1/0] "))
changeDirectory(outdir)
# check for changes in root directory
if waiting == 1:
    print('Waiting for action')
    newdir = waitToCapture(outdir)
    outdir = outdir + '\\' + newdir[0] # concatenate the newly detected subfolder
    timestamp.append( time.time() ) # append the time of the folder initialization...for synching the camera
    framecount.append(count) # frame 0 will be the start of the folder...no frames collected yet

# concatenate a "video" subfolder for storage
outdir = outdir + '\\' + 'video' # make a new subfolder to store the images and .csv file
changeDirectory(outdir)

cv2.namedWindow("Video")

with Vimba() as vimba:
    time.sleep(0.2)

    camera_ids = vimba.camera_ids()
    print("Camera found: " + camera_ids[0])

    #c0 = vimba.camera(camera_ids[0])
    c0 = vimba.camera(0)
    c0.open()

    # set camera settings
    #===============================================
    c0.PixelFormat = "Mono8"  
    #c0.AcquisitionMode = 'Continuous'
    #c0.TriggerSource = "Freerun" # change for hardware control
    c0.ExposureTimeAbs = 50000.0
    c0.AcquisitionFrameRateAbs = 20
    c0.BinningVertical = 2 
    c0.BinningHorizontal = 2
    #c0.Gain = 10 # uncomment to set gain
    h=c0.feature('Height').value
    w=c0.feature('Width').value
    print("image size " + str(h) + " x " +str(w))

    # initialize the frame
    c0.arm('SingleFrame')
    #c0.start_frame_acquisition()

    # loop continuously
    cv2.namedWindow("Video",flags=cv2.WINDOW_OPENGL)
    #===============================================
    while True:
        count += 1
        # get the image
        frame=c0.acquire_frame()
        img = frame.buffer_data_numpy()

        # append framecount and current time stamp to running list
        timestamp.append(time.time())
        framecount.append(count)

        # save the image to the folder
        executor.submit(saveImg, img, count)

        # display every 2nd frame to increase speed
        if count % 2 == 0:
            cv2.imshow("Video", img)
            key = cv2.waitKey(1) & 0xFF
            if key == ord("q"):
                break

    # save timestamp and framecount and close Camera
    #==========================================================
    print
    print("Frames displayed: %i" % count)
    print("Average framerate: " + str(count / (timestamp[-1] - timestamp[0])))
    print
    print("saving timestamps...")
    filename = outdir.split("\\")[-1] + "_videodata.csv"
    np.savetxt(filename, np.c_[timestamp,framecount], fmt='%10.2f %06d', delimiter = ',')

    c0.disarm()
    c0.close()
    cv2.destroyAllWindows()
