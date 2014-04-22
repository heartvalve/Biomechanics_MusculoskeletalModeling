"""
----------------------------------------------------------------------
    runCMCinGUI.py
----------------------------------------------------------------------
    This class can be used within the OpenSim GUI to interactively
    run a CMC simulation for a given trial (selected at runtime).
    
    *Currently visualization appears frozen during tool execution, 
    but reappears when tool is finished running.
    
    Input:
        None
    Output:
        CMC simulation results
----------------------------------------------------------------------
    Created by Megan Schroeder
    Last Modified 2013-07-15
----------------------------------------------------------------------
"""


class runCMC:
    """
    A class to interactively run a CMC simulation in the GUI.
    """
    
    def cleanUp(self):
        """
        Cleans up the current state of the GUI by closing any open
        models and motion files.
        """
        # Close any open models
        openModels = getAllModels()
        if len(openModels):
            for model in openModels:
                setCurrentModel(model)
                performAction("FileClose")
        # Wait        
        time.sleep(1)

    """------------------------------------------------------------"""
    def selectTrial(self):
        """
        Displays a dialog box listing all of the trc files in a given
        directory for selection.
        """
        # Select interactively
        self.trcFilePath = utils.FileUtils.getInstance().browseForFilename('.trc','Select the file to run',1)

    """------------------------------------------------------------"""
    def loadAdjustedModel(self):
        """
        Loads the adjusted COM model for the chosen trial into the
        GUI.
        """
        # Load model in GUI
        addModel(self.trcFilePath.replace('.trc','.osim'))
        # Wait
        time.sleep(1)

    """------------------------------------------------------------"""
    def runCMCfromSetupXML(self):
        """
        Creates a CMCTool object from a setup XML file and runs the
        CMC simulaton.
        """
        # Create CMCTool object from setup XML file
        cmcTool = modeling.CMCTool(self.trcFilePath.replace('.trc','__Setup_CMC.xml'))
        # Run 
        cmcTool.run()
            
    """------------------------------------------------------------"""
    def run(self):
        """
        Main program invoked via script execution.
        """
        # Close any open models
        self.cleanUp()
        # Dynamically select file to run
        self.selectTrial()    
        # Add adjusted COM (RRA/CMC) model
        self.loadAdjustedModel()
        # Create CMCTool from XML and run
        self.runCMCfromSetupXML()


# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# Imports
import os
import time
import org.opensim.utils as utils
    
"""*******************************************************************
*                                                                    *
*                   Script Execution                                 *
*                                                                    *
*******************************************************************"""
if __name__ == '__main__':
    # Create instance of class
    rCMC = runCMC()
    # Run code
    rCMC.run()
