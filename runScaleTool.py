"""
----------------------------------------------------------------------
    runScaleTool.py
----------------------------------------------------------------------
    This class can be used to easily run the OpenSim Scale Tool in the
    background for a given subject or list of subjects.

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
from runTools import scale
from updateFirstLineMOT import updateMOT


class runScaleTool:
    """
    A class to run the Scale Tool for a given subject from an existing
    Setup file.
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
        # Scale
        scaleTool = scale(self.subID)
        scaleTool.run()
        # Update first line name in output Scale file for later viewing in GUI.
        updateName = updateMOT(self.subID)
        updateName.updateScale()


"""*******************************************************************
*                                                                    *
*                   Script Execution                                 *
*                                                                    *
*******************************************************************"""
if __name__ == '__main__':
    # Loop through subject list
    for subID in subIDs:
        # Create instance of class
        runS = runScaleTool(subID)
        # Run code
        runS.run()
