"""
----------------------------------------------------------------------
    compareIKandRRAinGUI.py
----------------------------------------------------------------------
    This class can be used within the OpenSim GUI to visually compare
    the kinematic results of an IK and RRA simulation.  Following the
    execution of the program, the two models can be lined up by
    removing the offset of the second model.  Also, the two motions
    (IK and RRA) should be synced within the GUI.  If desired, the GRF
    data can also be associated with the motion.
    
    Input argument:
        subID (string)
    Output:
        visualization in GUI
----------------------------------------------------------------------
    Created by Megan Schroeder
    Last Modified 2013-07-17
----------------------------------------------------------------------
"""


# Imports
import os
import time 
import org.opensim.utils as utils


class compareInGUI:
    """
    A class containing attributes and methods associated with 
    previewing a scaled model and an adjusted COM / mass properties
    model, and associated IK and RRA motions in the GUI.
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
        Displays a dialog box listing all of the trc files in the last
        working directory.
        """
        # Select interactively
        self.trcFilePath = utils.FileUtils.getInstance().browseForFilename('.trc','Select the file to preview',1)
        # Determine directory of chosen file
        self.subDir = os.path.dirname(self.trcFilePath)+'\\'
        # Determine the subject ID
        self.subID = os.path.basename(os.path.dirname(self.trcFilePath))

    """------------------------------------------------------------"""
    def loadStandardModel(self):
        """
        Loads the basic scaled model into the GUI.
        """
        # Load model in GUI
        addModel(self.subDir+self.subID+'.osim')

    """------------------------------------------------------------"""
    def updateStandardModelVisuals(self):
        """
        Updates the visualization properties of the basic model.
        """
        # Handle to current model
        ikModel = getCurrentModel()
        # Color all bodies light blue
        bodySet = ikModel.getBodySet()
        for i in range(ikModel.getNumBodies()):
            body = bodySet.get(i)
            setObjectColor(body,[0.0, 0.4, 1.0]) 
        # Hide muscles
        for i in range(ikModel.getMuscles().getSize()):
            muscle = ikModel.getMuscles().get(i)
            toggleObjectDisplay(muscle,False)
        # Hide markers
        markerSet = ikModel.getMarkerSet()
        for i in range(ikModel.getNumMarkers()):
            marker = markerSet.get(i)
            toggleObjectDisplay(marker,False)

    """------------------------------------------------------------"""
    def loadIKMotion(self):
        """
        Loads the IK motion into the current (basic) model.
        """
        # Load motion file to current model
        loadMotion(self.trcFilePath.replace('.trc','_IK.mot'))
        # Wait
        time.sleep(1)

    """------------------------------------------------------------"""
    def loadAdjustedModel(self):
        """
        Loads the adjusted COM model for the chosen trial into the
        GUI.
        """
        # Load model in GUI
        addModel(self.trcFilePath.replace('.trc','.osim'))

    """------------------------------------------------------------"""
    def loadRRAMotion(self):
        """
        Loads the RRA motion into the adjusted model.
        """
        # Load motion file to current model
        loadMotion(self.trcFilePath.replace('.trc','_RRA_states.sto'))

    """------------------------------------------------------------"""
    def run(self):
        """
        Main program invoked via script execution.
        """
        # Close any open models
        self.cleanUp()
        # Dynamically select file to preview
        self.selectTrial()
        # Load standard (IK) model
        self.loadStandardModel()
        # Update model visualizations
        self.updateStandardModelVisuals()
        # Load IK motion to IK model
        self.loadIKMotion()
        # Add adjusted COM (RRA) model
        self.loadAdjustedModel()
        # Load RRA motion to RRA model
        self.loadRRAMotion()
        # Manually:
        #   Reset model offset to zero
        #   Associate GRF data with RRA data
        #   Sync motions of IK and RRA data 


"""*******************************************************************
*                                                                    *
*                   Script Execution                                 *
*                                                                    *
*******************************************************************"""
if __name__ == '__main__':
    # Create instance of class
    ikVSrra = compareInGUI()
    # Run code
    ikVSrra.run()
