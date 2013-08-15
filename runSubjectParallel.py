"""
----------------------------------------------------------------------
    runSubjectParallel.py
----------------------------------------------------------------------
    This program can be used to run all of the OpenSim simulation 
    tools in the background, split over multiple processors, for a 
    given list of subjects.
    
    This program imports and uses the 'runToolsParallel' and 
    'updateFirstLineMOT' custom modules.

    Input:
        Subject ID
    Output:
        Simulation results
----------------------------------------------------------------------
    Created by Megan Schroeder
    Last Modified 2013-08-15
----------------------------------------------------------------------
"""


# ####################################################################
#                                                                    #
#                   Input                                            #
#                                                                    #
# ####################################################################
# Subject ID list
subIDs = ['20130221CONF']
#subIDs = ['20130401CONM','20121205CONM']
#subIDs = ['20130401AHLM','20121206CONF','20121205CONF','20121204CONF',
#          '20121204APRM','20121110AHRM','20121108AHRM','20121008AHRM',
#          '20120922AHRM','20120920APRM','20120919APLF','20120912AHRF']
# ####################################################################


# Imports
import os
import glob
from datetime import datetime
from multiprocessing import Pool

from runToolsParallel import *
from updateFirstLineMOT import updateMOT


def runParallel(trialName):
    """
    Picklable(?) function for running OpenSim tools in parallel.
    """    
    # IK
    ikTool = ikin(trialName)
    ikTool.run()
    # ID
    idTool = idyn(trialName)
    idTool.run()
    # RRA
    rraTool = rra(trialName)
    rraTool.run()
    # Adjust model mass based on RRA results and rerun
    iterRRA = iterateRRA(trialName)
    iterRRA.run()    
    # CMC
    cmcTool = cmc(trialName)
    cmcTool.run()
    return None

# ####################################################################

class runSubject:
    """
    A class to run all of the OpenSim simulation steps for a given
    subject from existing Setup files.
    """

    def __init__(self,subID):
        """
        Create an instance of the class from the subject ID and add
        the subject directory and starting time.
        """
        # Subject ID
        self.subID = subID
        # Subject directory
        nuDir = os.getcwd()
        while os.path.basename(nuDir) != 'Northwestern-RIC':
            nuDir = os.path.dirname(nuDir)
        self.subDir = os.path.join(nuDir,'Modeling','OpenSim','Subjects',subID)+'\\'
        # Starting time
        self.startTime = datetime.now()

    """------------------------------------------------------------"""
    def getTrialNames(self):
        """
        Get all of the dynamic trial names for the subject.
        """
        # Trial names in directory
        trialNames = glob.glob(self.subDir+self.subID+'*_GRF.mot')
        for (i,tN) in enumerate(trialNames):
            trialNames[i] = os.path.basename(tN).split('_GRF')[0]
        return trialNames

    """------------------------------------------------------------"""
    def displayMessage(self):
        """
        Display the amount of time elapsed from the creation of the
        class instance.
        """
        timeDiff = datetime(1,1,1) + (datetime.now()-self.startTime)
        if timeDiff.hour < 1:
            print (self.subID+' is finished -- elapsed time is %d minutes.' %(timeDiff.minute))
        else:
            print (self.subID+' is finished -- elapsed time is %d hour(s) and %d minute(s).' %(timeDiff.hour, timeDiff.minute))

    """------------------------------------------------------------"""
    def run(self):
        """
        Main program to run all of the tools for a given subject.
        """
        # Scale tool
        scaleTool = scale(self.subID)
        scaleTool.run()        
        # Trial names
        trialNames = self.getTrialNames()
        # Start worker pool
        pool = Pool(processes=12)
        # Run parallel processes
        pool.map(runParallel, trialNames)
        # Clean up spawned processes
        pool.close()
        pool.join()
        # Update first line name in output Scale and IK files for later viewing in GUI.
        updateNames = updateMOT(self.subID)
        updateNames.run()
        # Display message to user
        self.displayMessage()


"""*******************************************************************
*                                                                    *
*                   Script Execution                                 *
*                                                                    *
*******************************************************************"""
if __name__ == '__main__':
    # Loop through subject list
    for subID in subIDs:
        # Create instance of class
        runSub = runSubject(subID)
        # Run code
        runSub.run()
