"""
----------------------------------------------------------------------
    writeSetupXMLfromGUI.py
----------------------------------------------------------------------
    This program can be executed from the OpenSim GUI to export all of
    the necessary Setup (*.xml) files for a given subject.  Generic
    model files are based on the input generic model name.  A batch 
    file is also created to execute all of the simulation analyses.
    
    Input arguments:
        subID (string)
        genericModelName (string -- gait2392, Arnold2010)
    Output:
        *__Setup_*.xml files
        *_ExternalLoads.xml files
----------------------------------------------------------------------
    Created by Megan Schroeder
    Last Modified 2013-07-15
----------------------------------------------------------------------
"""


# ####################################################################
#                                                                    #
#                   Inputs                                           #
#                                                                    #
# ####################################################################
# Generic model to use
genericModelName = 'gait2392'
# Subject ID
subID = '20130221CONF'
# ####################################################################


class setupXML:
    """
    A class containing attributes and methods associated with writing
    setup XML files from the OpenSim API. A subject ID and generic
    model name are required to create an instance based on this class.
    """

    def __init__(self,subID,genericModelName):
        """
        Method to create an instance of the setupXML class. Attributes
        include the subject ID, generic model name, subject directory, 
        and generic file directory.
        """
        self.subID = subID
        self.genericModelName = genericModelName
        nuDir = getScriptsDir()
        while os.path.basename(nuDir) != 'Northwestern-RIC':
            nuDir = os.path.dirname(nuDir)
        self.subDir = os.path.join(nuDir,'Modeling','OpenSim','Subjects',subID)+'\\'
        self.genDir = os.path.dirname(os.path.dirname(self.subDir[0:-2]))+'\\GenericFiles\\'
    
    """------------------------------------------------------------"""
    def readPersonalInfoXML(self):
        """
        Reads personal information xml file and adds attriubutes
        associated with the subject's mass, height, and the marker set
        used during the experiment.
        """
        persInfoXML = glob.glob(self.subDir+'*__PersonalInformation.xml')[0]
        dom = parse(persInfoXML)
        self.mass = float(dom.getElementsByTagName('mass')[0].firstChild.nodeValue)
        self.height = float(dom.getElementsByTagName('height')[0].firstChild.nodeValue)
        self.markerSet = dom.getElementsByTagName('markerSet')[0].firstChild.nodeValue
        
    """------------------------------------------------------------"""
    def initializeBat(self):
        """
        Initializes the list of commands to be written to the batch 
        file. This return argument is needed in most later methods.
        """
        commandList = []
        commandList.append('echo off\n')
        commandList.append('set curdir=%cd%\n')
        return commandList
    
    """------------------------------------------------------------"""
    def createSetupXML_Scale(self,commandList):
        """
        Write setup file for scale step. Append to batch file list.
        """
        # Static TRC filename
        trcFileName = self.subID+'_0_StaticPose.trc'
        # Create MarkerData object to read starting and ending times from TRC file
        markerData = modeling.MarkerData(self.subDir+trcFileName)
        timeRange = modeling.ArrayDouble()
        timeRange.setitem(0,markerData.getStartFrameTime())
        timeRange.setitem(1,markerData.getLastFrameTime())
        # Create ScaleTool object
        scaleTool = modeling.ScaleTool(self.genDir+'ScaleTool.xml')
        scaleTool.setName(self.subID)
        # Modify top-level properties
        scaleTool.setPathToSubject(self.subDir)
        scaleTool.setSubjectMass(self.mass)
        scaleTool.setSubjectHeight(self.height)
        # Update GenericModelMaker
        scaleTool.getGenericModelMaker().setModelFileName(self.genDir+self.genericModelName+'.osim')
        scaleTool.getGenericModelMaker().setMarkerSetFileName(self.genDir+self.genericModelName+'_'+self.markerSet+'_Scale_MarkerSet.xml')
        # Update ModelScaler
        scaleTool.getModelScaler().setApply(True)
        scaleOrder = modeling.ArrayStr()
        scaleOrder.setitem(0,'measurements')
        scaleTool.getModelScaler().setScalingOrder(scaleOrder)
        scaleTool.getModelScaler().getMeasurementSet().assign(modeling.MeasurementSet().makeObjectFromFile(self.genDir+self.genericModelName+'_'+self.markerSet+'_Scale_MeasurementSet.xml'))
        scaleTool.getModelScaler().setMarkerFileName(self.subDir+trcFileName)
        scaleTool.getModelScaler().setTimeRange(timeRange)
        scaleTool.getModelScaler().setPreserveMassDist(True)
        scaleTool.getModelScaler().setOutputModelFileName(self.subDir+'TempScaled.osim')
        scaleTool.getModelScaler().setOutputScaleFileName(self.subDir+trcFileName.replace('.trc','_ScaleSet.xml'))
        # Update MarkerPlacer
        scaleTool.getMarkerPlacer().setApply(True)
        scaleTool.getMarkerPlacer().getIKTaskSet().assign(modeling.IKTaskSet(self.genDir+self.genericModelName+'_'+self.markerSet+'_Scale_IKTaskSet.xml'))
        scaleTool.getMarkerPlacer().setStaticPoseFileName(self.subDir+trcFileName)
        scaleTool.getMarkerPlacer().setTimeRange(timeRange)
        scaleTool.getMarkerPlacer().setOutputMotionFileName(self.subDir+trcFileName.replace('.trc','_Scale.mot'))
        scaleTool.getMarkerPlacer().setOutputModelFileName(self.subDir+self.subID+'.osim')
        scaleTool.getMarkerPlacer().setOutputMarkerFileName('')
        # Write changes to XML setup file
        scaleTool.print(self.subDir+trcFileName.replace('.trc','__Setup_Scale.xml'))
        # Prepare command for batch processing        
        commandList.append('scale -S '+trcFileName.replace('.trc','__Setup_Scale.xml')+' > %curdir%\\'+trcFileName.replace('.trc','_Scale.log')+'\n')
        return commandList
        
    """------------------------------------------------------------"""
    def createSetupXML_IK(self,commandList):
        """
        Write setup files for IK step. Append to batch file list.
        """
        # Create InverseKinematicsTool object
        ikTool = modeling.InverseKinematicsTool(self.genDir+'InverseKinematicsTool.xml')
        # Dynamic TRC filenames
        trcFilePathList = glob.glob(self.subDir+self.subID+'_*_*_*.trc')
        # Loop through TRC files
        for trcFilePath in trcFilePathList:
            # TRC filename
            trcFileName = os.path.basename(trcFilePath)
            # Name of tool
            ikTool.setName(os.path.splitext(trcFileName)[0])
            # <IKTaskSet>
            ikTool.getIKTaskSet().assign(modeling.IKTaskSet(self.genDir+self.genericModelName+'_'+self.markerSet+'_IK_IKTaskSet.xml'))
            # <marker_file>
            ikTool.setMarkerDataFileName(trcFilePath)
            # <coordinate_file>
            ikTool.setCoordinateFileName('')
            # Create MarkerData object to read starting and ending times from TRC file
            markerData = modeling.MarkerData(trcFilePath)
            # <time_range>
            ikTool.setStartTime(markerData.getStartFrameTime())
            ikTool.setEndTime(markerData.getLastFrameTime())
            # <output_motion_file>
            ikTool.setOutputMotionFileName(trcFilePath.replace('.trc','_IK.mot'))
            # Write changes to XML setup file
            xmlSetupFilePath = trcFilePath.replace('.trc','__Setup_IK.xml')
            ikTool.print(xmlSetupFilePath)
            # Prepare command for batch processing
            commandList.append('ik -S '+trcFileName.replace('.trc','__Setup_IK.xml')+' > %curdir%\\'+trcFileName.replace('.trc','_IK.log')+'\n')
            #
            # **** Temporary fix for setting model name using XML parsing ****
            dom = parse(xmlSetupFilePath)
            dom.getElementsByTagName('model_file')[0].firstChild.nodeValue = self.subDir+self.subID+'.osim'
            xmlstring = dom.toxml('UTF-8')        
            xmlFile = open(xmlSetupFilePath,'w')
            xmlFile.write(xmlstring)
            xmlFile.close()
        return commandList
            
    """------------------------------------------------------------"""
    def createExternalLoadsXML(self):
        """
        Write XML file specifying external loads from GRF.mot file.
        """
        # Create ExternalLoads object
        extLoads = modeling.ExternalLoads()
        extLoads.assign(modeling.ExternalLoads().makeObjectFromFile(self.genDir+'ExternalLoads.xml'))
        # Dynamic TRC filenames
        trcFilePathList = glob.glob(self.subDir+self.subID+'_*_*_*.trc')
        # Loop through TRC files
        for trcFilePath in trcFilePathList:
            # TRC filename
            trcFileName = os.path.basename(trcFilePath)       
            # Name of object
            extLoads.setName(os.path.splitext(trcFileName)[0])        
            # <datafile>
            extLoads.setDataFileName(trcFilePath.replace('.trc','_GRF.mot'))
            # <external_loads_model_kinematics_file>
            extLoads.setExternalLoadsModelKinematicsFileName(trcFilePath.replace('.trc','_IK.mot'))
            # <lowpass_cutoff_frequency_for_load_kinematics>
            extLoads.setLowpassCutoffFrequencyForLoadKinematics(6)
            # Write changes to XML file
            extLoads.print(trcFilePath.replace('.trc','_ExternalLoads.xml'))
            
    """------------------------------------------------------------"""
    def createSetupXML_ID(self,commandList):
        """
        Write setup files for ID step. Append to batch file list.
        """
        # Create InverseDynamicsTool object
        idTool = modeling.InverseDynamicsTool(self.genDir+'InverseDynamicsTool.xml')
        # <forces_to_exclude>
        excludedForces = modeling.ArrayStr()
        excludedForces.setitem(0,'muscles')
        idTool.setExcludedForces(excludedForces) 
        # <lowpass_cutoff_frequency_for_coordinates>
        idTool.setLowpassCutoffFrequency(-1)
        # Dynamic TRC filenames
        trcFilePathList = glob.glob(self.subDir+self.subID+'_*_*_*.trc')
        # Loop through TRC files
        for trcFilePath in trcFilePathList:
            # TRC filename
            trcFileName = os.path.basename(trcFilePath)
            # Name of tool
            idTool.setName(os.path.splitext(trcFileName)[0])
            # Create Storage object to read starting and ending times from MOT file
            motData = modeling.Storage(trcFilePath.replace('.trc','_GRF.mot'))
            # <time_range>
            idTool.setStartTime(motData.getFirstTime())
            idTool.setEndTime(motData.getLastTime())
            # <external_loads_file>
            idTool.setExternalLoadsFileName(trcFilePath.replace('.trc','_ExternalLoads.xml'))
            # <coordinates_file>
            idTool.setCoordinatesFileName(trcFilePath.replace('.trc','_IK.mot'))
            # ????? .... <output_gen_force_file> .....idTool.getOutputGenForceFileName() -- set ????        
            # Write changes to XML setup file
            xmlSetupFilePath = trcFilePath.replace('.trc','__Setup_ID.xml')
            idTool.print(xmlSetupFilePath)
            # Prepare command for batch processing
            commandList.append('id -S '+trcFileName.replace('.trc','__Setup_ID.xml')+' > %curdir%\\'+trcFileName.replace('.trc','_ID.log')+'\n')
            #
            # **** Temporary fix for setting model name & output force file using XML parsing ****
            dom = parse(xmlSetupFilePath)
            for i in range(len(dom.getElementsByTagName('model_file'))):
                dom.getElementsByTagName('model_file')[i].firstChild.nodeValue = self.subDir+self.subID+'.osim'
            dom.getElementsByTagName('output_gen_force_file')[0].firstChild.nodeValue = trcFileName.replace('.trc','_ID.sto')
            xmlstring = dom.toxml('UTF-8')        
            xmlFile = open(xmlSetupFilePath,'w')
            xmlFile.write(xmlstring)
            xmlFile.close()
        return commandList

    """------------------------------------------------------------"""
    def createSetupXML_RRA(self,commandList):
        """
        Write setup files for RRA step. Append to batch file list.
        """
        # Create RRATool object
        rraTool = modeling.RRATool(self.genDir+'RRATool.xml')
        # <model_file>
        rraTool.setModelFilename(self.subDir+self.subID+'.osim')
        # <replace_force_set>
        rraTool.setReplaceForceSet(True)
        # <force_set_files>
        forceSetFiles = modeling.ArrayStr()
        forceSetFiles.setitem(0,self.genDir+self.genericModelName+'_RRA_ForceSet.xml')
        rraTool.setForceSetFiles(forceSetFiles)
        # <results_directory>
        rraTool.setResultsDir(self.subDir)
        # <output_precision>
        rraTool.setOutputPrecision(20)
        # <solve_for_equilibrium_for_auxiliary_states>
        rraTool.setSolveForEquilibrium(True)
        # <task_set_file>
        rraTool.setTaskSetFileName(self.genDir+self.genericModelName+'_RRA_CMCTaskSet.xml')
        # <constraints_file>
        rraTool.setConstraintsFileName(self.genDir+self.genericModelName+'_RRA_ControlSet.xml')  
        # <lowpass_cutoff_frequency>
        rraTool.setLowpassCutoffFrequency(6)
        # <adjust_com_to_reduce_residuals>
        rraTool.setAdjustCOMToReduceResiduals(True)
        # <adjusted_com_body>
        rraTool.setAdjustedCOMBody('torso')    
        # Dynamic TRC filenames
        trcFilePathList = glob.glob(self.subDir+self.subID+'_*_*_*.trc')
        # Loop through TRC files
        for trcFilePath in trcFilePathList:
            # TRC filename
            trcFileName = os.path.basename(trcFilePath)
            # Name of tool
            rraTool.setName(os.path.splitext(trcFileName)[0]+'_RRA')
            # Create Storage object to read starting and ending times from MOT file
            motData = modeling.Storage(trcFilePath.replace('.trc','_GRF.mot'))
            # <initial_time>
            rraTool.setInitialTime(math.ceil(motData.getFirstTime()*1000)/1000)
            # <final_time>
            rraTool.setFinalTime(math.floor(motData.getLastTime()*1000)/1000)
            # <external_loads_file>
            rraTool.setExternalLoadsFileName(trcFilePath.replace('.trc','_ExternalLoads.xml'))
            # <desired_kinematics_file>
            rraTool.setDesiredKinematicsFileName(trcFilePath.replace('.trc','_IK.mot'))
            # <output_model_file>
            rraTool.setOutputModelFileName(trcFilePath.replace('.trc','__AdjustedCOM.osim'))
            # Write changes to XML file
            rraTool.print(trcFilePath.replace('.trc','__Setup_RRA.xml'))
            # Prepare command for batch processing
            commandList.append('rra -S '+trcFileName.replace('.trc','__Setup_RRA.xml')+' > %curdir%\\'+trcFileName.replace('.trc','_RRA.log')+'\n')
        return commandList
        
    """------------------------------------------------------------"""
    def createSetupXML_CMC(self,commandList):
        """
        Write setup files for CMC step. Append to batch file list.
        """
        # Create CMCTool object
        cmcTool = modeling.CMCTool(self.genDir+'CMCTool.xml')    
        # <force_set_files>
        forceSetFiles = modeling.ArrayStr()
        forceSetFiles.setitem(0,self.genDir+self.genericModelName+'_CMC_ForceSet.xml')
        cmcTool.setForceSetFiles(forceSetFiles)
        # <results_directory>
        cmcTool.setResultsDir(self.subDir)
        # <output_precision>
        cmcTool.setOutputPrecision(20)
        # <maximum_number_of_integrator_steps>
        cmcTool.setMaximumNumberOfSteps(30000)
        # <maximum_integrator_step_size>
        cmcTool.setMaxDT(0.0001)
        # <integrator_error_tolerance>
        cmcTool.setErrorTolerance(1e-006)
        # <task_set_file>
        cmcTool.setTaskSetFileName(self.genDir+self.genericModelName+'_CMC_CMCTaskSet.xml')
        # <constraints_file>
        cmcTool.setConstraintsFileName(self.genDir+self.genericModelName+'_CMC_ControlSet.xml')
        # <lowpass_cutoff_frequency>
        cmcTool.setLowpassCutoffFrequency(-1)
        # Dynamic TRC filenames
        trcFilePathList = glob.glob(self.subDir+self.subID+'_*_*_*.trc')
        # Loop through TRC files
        for trcFilePath in trcFilePathList:
            # TRC filename
            trcFileName = os.path.basename(trcFilePath)
            # Name of tool
            cmcTool.setName(os.path.splitext(trcFileName)[0]+'_CMC')
            # <model_file>
            cmcTool.setModelFilename(trcFilePath.replace('.trc','.osim'))
            # Create Storage object to read starting and ending times from MOT file
            motData = modeling.Storage(trcFilePath.replace('.trc','_GRF.mot'))
            # <initial_time>
            cmcTool.setInitialTime(math.ceil(motData.getFirstTime()*1000)/1000)
            # <final_time>
            cmcTool.setFinalTime(math.floor(motData.getLastTime()*1000)/1000)
            # <external_loads_file>
            cmcTool.setExternalLoadsFileName(trcFilePath.replace('.trc','_ExternalLoads.xml'))
            # <desired_kinematics_file>
            cmcTool.setDesiredKinematicsFileName(trcFilePath.replace('.trc','_RRA_Kinematics_q.sto'))
            # Write changes to XML file
            cmcTool.print(trcFilePath.replace('.trc','__Setup_CMC.xml'))
            # Prepare command for batch processing
            commandList.append('cmc -S '+trcFileName.replace('.trc','__Setup_CMC.xml')+' > %curdir%\\'+trcFileName.replace('.trc','_CMC.log')+'\n')
        return commandList
        
    """------------------------------------------------------------"""
    def writeCommandsToBat(self,commandList):
        """
        Write contents of batch file list to file.
        """
        batFile = open(self.subDir+'Run.bat','w')
        batFile.writelines(commandList)
        batFile.close()

    """***************************************************************
    *                                                                *
    *                   Main Function Definition                     *
    *                                                                *
    ***************************************************************"""
    def run(self):
        """
        The main program invoked to call the other subfunctions.
        """
        # Get subject specific information from file
        self.readPersonalInfoXML()
        # Initialize the batch file
        commandList = self.initializeBat()
        # Create the setup file used to run the scale step
        commandList = self.createSetupXML_Scale(commandList)
        # Create the setup file(s) used to run the IK step
        commandList = self.createSetupXML_IK(commandList)
        # Create the external loads file(s) used for all kinetic analyses
        self.createExternalLoadsXML()
        # Create the setup file(s) used to run the ID step
        commandList = self.createSetupXML_ID(commandList)
        # Create the setup file(s) used to run the RRA step
        commandList = self.createSetupXML_RRA(commandList)
        # Create the setup file(s) used to run the CMC step    
        commandList = self.createSetupXML_CMC(commandList)
        # Write batch file
        self.writeCommandsToBat(commandList)


# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# Imports
import os
import glob
import math
from xml.dom.minidom import parse
    
"""*******************************************************************
*                                                                    *
*                   Script Execution                                 *
*                                                                    *
*******************************************************************"""
if __name__ == '__main__':
    # Create instance of class
    osim = setupXML(subID,genericModelName)
    # Run code
    osim.run()
    