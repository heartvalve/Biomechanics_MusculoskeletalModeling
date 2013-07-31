"""
----------------------------------------------------------------------
    runCMCTool.py
----------------------------------------------------------------------
    This class can be used to easily run the OpenSim Computed Muscle
    Control Tool in the background for all dynamic trials for a given
    subject or list of subjects.

    Input:
        Subject ID
    Output:
        Simulation results
----------------------------------------------------------------------
    Created by Megan Schroeder
    Last Modified 2013-07-30
----------------------------------------------------------------------
"""


# ####################################################################
#                                                                    #
#                   Input                                            #
#                                                                    #
# ####################################################################
# Subject ID list
subIDs = ['20130221CONF']
# ####################################################################


# Imports
import time
from runTools import cmc


class runCMCTool:
    """
    A class to run the CMC Tool for a given subject from existing 
    Setup files.
    """

    def __init__(self,subID):
        """
        Create an instance of the class from the subject ID and add
        the starting time.
        """
        # Subject ID
        self.subID = subID
        # Starting time
        self.startTime = time.time()

    """------------------------------------------------------------"""
    def run(self):
        """
        Main program to run the tool for a given subject.
        """
        # CMC
        cmcTool = cmc(self.subID)
        cmcTool.run()
        # Display message to user
        print (self.subID+' is finished -- elapsed time is '+str(int(float(time.time()-self.startTime)/float(60)))+' minutes.')


"""*******************************************************************
*                                                                    *
*                   Script Execution                                 *
*                                                                    *
*******************************************************************"""
if __name__ == '__main__':
    # Loop through subject list
    for subID in subIDs:
        # Create instance of class
        runCMC = runCMCTool(subID)
        # Run code
        runCMC.run()
