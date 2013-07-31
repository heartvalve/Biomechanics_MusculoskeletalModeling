"""
----------------------------------------------------------------------
    runIKTool.py
----------------------------------------------------------------------
    This class can be used to easily run the OpenSim Inverse
    Kinematics Tool in the background for all dynamic trials for a
    given subject or list of subjects.

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
from runTools import ikin
from updateFirstLineMOT import updateMOT


class runIKTool:
    """
    A class to run the IK Tool for a given subject from existing Setup
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
        # IK
        ikTool = ikin(self.subID)
        ikTool.run()
        # Update first line name in output IK files for later viewing in GUI.
        updateName = updateMOT(self.subID)
        updateName.updateIK()


"""*******************************************************************
*                                                                    *
*                   Script Execution                                 *
*                                                                    *
*******************************************************************"""
if __name__ == '__main__':
    # Loop through subject list
    for subID in subIDs:
        # Create instance of class
        runIK = runIKTool(subID)
        # Run code
        runIK.run()
