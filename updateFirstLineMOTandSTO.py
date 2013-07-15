"""
----------------------------------------------------------------------
    updateFirstLineMOTandSTO.py
----------------------------------------------------------------------
    This program overwrites the first line of every Scale and IK
    motion (*.mot) file with the current filename.  For example, the
    IK solver will place 'Coordinates' in the first line of the
    output file; this function will replace that with the filename.
    Implemented to make separate files more easily distinguishable
    when being examined in the OpenSim GUI.

    Input argument:
        subID (string)
    Output:
        modified *_Scale.mot file
        modified *_IK.mot files
----------------------------------------------------------------------
    Created by Megan Schroeder
    Last Modified 2013-07-15
----------------------------------------------------------------------
"""


# ####################################################################
#                                                                    #
#                   Input                                            #
#                                                                    #
# ####################################################################
# Subject ID
subID = '20130221CONF'
# ####################################################################


def updateFile(filePath):
    """
    A function that overwrites the first text line of the input
    filepath with the filename.
    """
    fileNameExt = os.path.basename(filePath)
    fileName = os.path.splitext(fileNameExt)[0]
    fileR = open(filePath,'r')
    fileList = fileR.readlines()
    fileR.close()
    fileList[0] = fileName+'\n'
    fileW = open(filePath,'w')
    fileW.writelines(fileList)
    fileW.close()

"""----------------------------------------------------------------"""
def updateScale(subDir):
    """
    A function that updates all of the Scale output files within the
    subject directory.
    """
    motFileList = glob.glob(subDir+'*_Scale.mot')
    for motFilePath in motFileList:
        updateFile(motFilePath)

"""----------------------------------------------------------------"""
def updateIK(subDir):
    """
    A function that updates all of the IK output files within the
    subject directory.
    """
    motFileList = glob.glob(subDir+'*_IK.mot')
    for motFilePath in motFileList:
        updateFile(motFilePath)

"""----------------------------------------------------------------"""
def run(subID):
    """
    The main program invoked from the script to call the other
    subfunctions.
    """
    # Specify the directory based on the subject ID
    nuDir = os.getcwd()
    while os.path.basename(nuDir) != 'Northwestern-RIC':
        nuDir = os.path.dirname(nuDir)
    subDir = os.path.join(nuDir,'Modeling','OpenSim','Subjects',subID)+'\\'
    # Call subfunctions
    updateScale(subDir)
    updateIK(subDir)


# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# Imports
import os
import glob

"""*******************************************************************
*                                                                    *
*                   Script Execution                                 *
*                                                                    *
*******************************************************************"""

# Call the main function
run(subID)
