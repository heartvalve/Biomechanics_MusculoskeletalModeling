"""
----------------------------------------------------------------------
    runIDTool.py
----------------------------------------------------------------------
    This class can be used to easily run the OpenSim Inverse Dynamics
    Tool in the background for all dynamic trials for a given subject
    or list of subjects.

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
from runTools import idyn


class runIDTool:
    """
    A class to run the ID Tool for a given subject from existing Setup
    files.
    """

    def __init__(self,subID):
        """
        Create an instance of the class from the subject ID.
        """
        # Subject ID
        self.subID = subID

    """------------------------------------------------------------"""
    def run(self):
        """
        Main program to run the tool for a given subject.
        """
        # ID
        idTool = idyn(self.subID)
        idTool.run()


"""*******************************************************************
*                                                                    *
*                   Script Execution                                 *
*                                                                    *
*******************************************************************"""
if __name__ == '__main__':
    # Loop through subject list
    for subID in subIDs:
        # Create instance of class
        runID = runIDTool(subID)
        # Run code
        runID.run()
