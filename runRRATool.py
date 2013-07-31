"""
----------------------------------------------------------------------
    runRRATool.py
----------------------------------------------------------------------
    This class can be used to easily run the OpenSim Residual
    Reduction Tool in the background for all dynamic trials for a
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
from runTools import rra


class runRRATool:
    """
    A class to run the RRA Tool for a given subject from existing 
    Setup files.
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
        # RRA
        rraTool = rra(self.subID)
        rraTool.run()


"""*******************************************************************
*                                                                    *
*                   Script Execution                                 *
*                                                                    *
*******************************************************************"""
if __name__ == '__main__':
    # Loop through subject list
    for subID in subIDs:
        # Create instance of class
        runRRA = runRRATool(subID)
        # Run code
        runRRA.run()
