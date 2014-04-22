"""
----------------------------------------------------------------------
    updateFirstLineMOT.py
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
    Last Modified 2013-07-16
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


# Imports
import os
import glob


class updateMOT:
    """
    A class associated with updating Scale and IK mot files, such that
    when previewed in the OpenSim GUI, they will display the specific
    filename, rather than a generic 'Coordinates'.
    """
    
    def __init__(self,subID):
        """
        Method to create an instance of the updateMOTandSTO class.
        Attributes include the subject ID (input) and the subject
        directory.
        """
        self.subID = subID
        nuDir = os.getcwd()
        while os.path.basename(nuDir) != 'Northwestern-RIC':
            nuDir = os.path.dirname(nuDir)
        self.subDir = os.path.join(nuDir,'Modeling','OpenSim','Subjects',subID)+'\\'
    
    """------------------------------------------------------------"""
    def updateFile(self,filePath):
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

    """------------------------------------------------------------"""
    def updateScale(self):
        """
        A function that updates all of the Scale output files within the
        subject directory.
        """
        motFileList = glob.glob(self.subDir+'*_Scale.mot')
        for motFilePath in motFileList:
            self.updateFile(motFilePath)

    """------------------------------------------------------------"""
    def updateIK(self):
        """
        A function that updates all of the IK output files within the
        subject directory.
        """
        motFileList = glob.glob(self.subDir+'*_IK.mot')
        for motFilePath in motFileList:
            self.updateFile(motFilePath)

    """------------------------------------------------------------"""
    def run(self):
        """
        Main program invoked via script execution.
        """
        self.updateScale()
        self.updateIK()

        
"""*******************************************************************
*                                                                    *
*                   Script Execution                                 *
*                                                                    *
*******************************************************************"""
if __name__ == '__main__':
    # Create instance of class
    updateM = updateMOT(subID)
    # Run code
    updateM.run()
