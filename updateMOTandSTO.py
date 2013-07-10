subID = '20130401CONM'


def updateFile(filePath):
    fileNameExt = os.path.basename(filePath)
    fileName = os.path.splitext(fileNameExt)[0]
    fileR = open(filePath,'r')
    fileList = fileR.readlines()
    fileR.close()
    fileList[0] = fileName+'\n'
    fileW = open(filePath,'w')
    fileW.writelines(fileList)
    fileW.close()


def updateScale(subDir):
    motFileList = glob.glob(subDir+'*_Scale.mot')
    for motFilePath in motFileList:
        updateFile(motFilePath)


def updateIK(subDir):
    motFileList = glob.glob(subDir+'*_IK.mot')
    for motFilePath in motFileList:
        updateFile(motFilePath)


def updateRRA(subDir):
    stoFileList = glob.glob(subDir+'*_RRA_Kinematics_q.sto')
    for stoFilePath in stoFileList:
        updateFile(stoFilePath)


def run(subDir):
    updateScale(subDir)
    updateIK(subDir)
    updateRRA(subDir)


# ***********************

import os
import glob

nuDir = os.getcwd()
while os.path.basename(nuDir) != 'Northwestern-RIC':
    nuDir = os.path.dirname(nuDir)
subDir = os.path.join(nuDir,'Modeling','OpenSim','Subjects',subID)+'\\'


run(subDir)
