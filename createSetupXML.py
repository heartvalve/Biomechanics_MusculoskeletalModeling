"""
----------------------------------------------------------------------
    createSetupXML.py
----------------------------------------------------------------------
    Doc...


    To Do:
        createSetupXML_IK -- <model_file> -- has temp fix
        createSetupXML_ID -- <model_file> -- has temp fix
                          -- <output_gen_force_file> -- has temp fix

----------------------------------------------------------------------
    Created by Megan Schroeder
    Last Modified 2013-06-25
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

"""*******************************************************************
*                                                                    *
*                   SubFunction Definitions                          *
*                                                                    *
*******************************************************************"""
def getGenericDirectory(subDir):
    genDir = {}
    genDir['Rel'] = '..\\..\\GenericFiles\\'
    genDir['Full'] = os.path.dirname(os.path.dirname(subDir[0:-2]))+'\\GenericFiles\\'
    return genDir
    
"""----------------------------------------------------------------"""
def readPersonalInfoXML(subDir):
    persInfoXML = glob.glob(subDir+'*__PersonalInformation.xml')[0]
    dom = parse(persInfoXML)
    persInfo = {}
    persInfo['subID'] = dom.getElementsByTagName('PersonalInfo')[0].getAttribute('name')
    persInfo['mass'] = float(dom.getElementsByTagName('mass')[0].firstChild.nodeValue)
    persInfo['height'] = float(dom.getElementsByTagName('height')[0].firstChild.nodeValue)
    persInfo['markerSet'] = dom.getElementsByTagName('markerSet')[0].firstChild.nodeValue
    return persInfo
    
"""----------------------------------------------------------------"""
def createSetupXML_Scale(genericModelName,genDir,subDir,persInfo):
    # Static TRC filename
    trcFileName = persInfo['subID']+'_0_StaticPose.trc'
    # Create MarkerData object to read starting and ending times from TRC file
    markerData = modeling.MarkerData(subDir+trcFileName)
    timeRange = modeling.ArrayDouble()
    timeRange.setitem(0,markerData.getStartFrameTime())
    timeRange.setitem(1,markerData.getLastFrameTime())
    # Create ScaleTool object
    scaleTool = modeling.ScaleTool(genDir['Full']+'ScaleTool.xml')
    scaleTool.setName(persInfo['subID'])
    # Modify top-level properties
    scaleTool.setPathToSubject(subDir)
    scaleTool.setSubjectMass(persInfo['mass'])
    scaleTool.setSubjectHeight(persInfo['height'])
    # Update GenericModelMaker
    scaleTool.getGenericModelMaker().setModelFileName(genDir['Rel']+genericModelName+'_simbody.osim')
    scaleTool.getGenericModelMaker().setMarkerSetFileName(genDir['Rel']+genericModelName+'_'+persInfo['markerSet']+'_Scale_MarkerSet.xml')
    # Update ModelScaler
    scaleTool.getModelScaler().setApply(True)
    scaleOrder = modeling.ArrayStr()
    scaleOrder.setitem(0,'measurements')
    scaleTool.getModelScaler().setScalingOrder(scaleOrder)
    scaleTool.getModelScaler().getMeasurementSet().assign(modeling.MeasurementSet().makeObjectFromFile(genDir['Full']+genericModelName+'_'+persInfo['markerSet']+'_Scale_MeasurementSet.xml'))
    scaleTool.getModelScaler().setMarkerFileName(trcFileName)
    scaleTool.getModelScaler().setTimeRange(timeRange)
    scaleTool.getModelScaler().setPreserveMassDist(True)
    scaleTool.getModelScaler().setOutputModelFileName('TempScaled.osim')
    scaleTool.getModelScaler().setOutputScaleFileName(trcFileName.replace('.trc','_ScaleSet.xml'))
    # Update MarkerPlacer
    scaleTool.getMarkerPlacer().setApply(True)
    scaleTool.getMarkerPlacer().getIKTaskSet().assign(modeling.IKTaskSet(genDir['Full']+genericModelName+'_'+persInfo['markerSet']+'_Scale_IKTaskSet.xml'))
    scaleTool.getMarkerPlacer().setStaticPoseFileName(trcFileName)
    scaleTool.getMarkerPlacer().setTimeRange(timeRange)
    scaleTool.getMarkerPlacer().setOutputMotionFileName(trcFileName.replace('.trc','.mot'))
    scaleTool.getMarkerPlacer().setOutputModelFileName(persInfo['subID']+'__Simbody.osim')
    scaleTool.getMarkerPlacer().setOutputMarkerFileName('')
    # Write changes to XML setup file
    scaleTool.print(subDir+trcFileName.replace('.trc','__Setup_Scale.xml'))
    # Prepare command for batch processing
    commandList = []
    commandList.append('echo off\n')
    commandList.append('set curdir=%cd%\n')
    commandList.append('scale -S '+trcFileName.replace('.trc','__Setup_Scale.xml')+' > %curdir%\\'+trcFileName.replace('.trc','_Scale.log')+'\n')
    return commandList
    
"""----------------------------------------------------------------"""
def createSetupXML_IK(genericModelName,genDir,subDir,persInfo,commandList):
    # Create InverseKinematicsTool object
    ikTool = modeling.InverseKinematicsTool(genDir['Full']+'InverseKinematicsTool.xml')
    # ???? .... <model_file> .... ikTool.setModel(Model)  ????
    # Dynamic TRC filenames
    trcFilePathList = glob.glob(subDir+persInfo['subID']+'_*_*_*.trc')
    # Loop through TRC files
    for trcFilePath in trcFilePathList:
        # TRC filename
        trcFileName = os.path.basename(trcFilePath)
        # Name of tool
        ikTool.setName(os.path.splitext(trcFileName)[0])
        # <IKTaskSet>
        ikTool.getIKTaskSet().assign(modeling.IKTaskSet(genDir['Full']+genericModelName+'_'+persInfo['markerSet']+'_IK_IKTaskSet.xml'))
        # <marker_file>
        ikTool.setMarkerDataFileName(trcFileName)
        # <coordinate_file>
        ikTool.setCoordinateFileName('')
        # Create MarkerData object to read starting and ending times from TRC file
        markerData = modeling.MarkerData(trcFilePath)
        # <time_range>
        ikTool.setStartTime(markerData.getStartFrameTime())
        ikTool.setEndTime(markerData.getLastFrameTime())
        # <output_motion_file>
        ikTool.setOutputMotionFileName(trcFileName.replace('.trc','_IK.mot'))
        # Write changes to XML setup file
        xmlSetupFilePath = trcFilePath.replace('.trc','__Setup_IK.xml')
        ikTool.print(xmlSetupFilePath)
        # Prepare command for batch processing
        commandList.append('ik -S '+trcFileName.replace('.trc','__Setup_IK.xml')+' > %curdir%\\'+trcFileName.replace('.trc','_IK.log')+'\n')
        #
        # **** Temporary fix for setting model name using XML parsing ****
        dom = parse(xmlSetupFilePath)
        dom.getElementsByTagName('model_file')[0].firstChild.nodeValue = persInfo['subID']+'__Simbody.osim'
        xmlstring = dom.toxml('UTF-8')        
        xmlFile = open(xmlSetupFilePath,'w')
        xmlFile.write(xmlstring)
        xmlFile.close()
    return commandList
        
"""----------------------------------------------------------------"""
def createExternalLoadsXML(genDir,subDir,persInfo):
    # Create ExternalLoads object
    extLoads = modeling.ExternalLoads()
    extLoads.assign(modeling.ExternalLoads().makeObjectFromFile(genDir['Full']+'ExternalLoads.xml'))
    # Dynamic TRC filenames
    trcFilePathList = glob.glob(subDir+persInfo['subID']+'_*_*_*.trc')
    # Loop through TRC files
    for trcFilePath in trcFilePathList:
        # TRC filename
        trcFileName = os.path.basename(trcFilePath)       
        # Name of object
        extLoads.setName(os.path.splitext(trcFileName)[0])        
        # <datafile>
        extLoads.setDataFileName(trcFileName.replace('.trc','.mot'))
        # <external_loads_model_kinematics_file>
        extLoads.setExternalLoadsModelKinematicsFileName(trcFileName.replace('.trc','_IK.mot'))
        # <lowpass_cutoff_frequency_for_load_kinematics>
        extLoads.setLowpassCutoffFrequencyForLoadKinematics(-1)
        # Write changes to XML file
        extLoads.print(trcFilePath.replace('.trc','_ExternalLoads.xml'))
        
"""----------------------------------------------------------------"""
def createSetupXML_ID(genDir,subDir,persInfo,commandList):
    # Create InverseDynamicsTool object
    idTool = modeling.InverseDynamicsTool(genDir['Full']+'InverseDynamicsTool.xml')
    # ????? .... <model_file> .... idTool.setModel(Model)  ????
    # <forces_to_exclude>
    excludedForces = modeling.ArrayStr()
    excludedForces.setitem(0,'muscles')
    idTool.setExcludedForces(excludedForces) 
    # <lowpass_cutoff_frequency_for_coordinates>
    idTool.setLowpassCutoffFrequency(-1)
    # Dynamic TRC filenames
    trcFilePathList = glob.glob(subDir+persInfo['subID']+'_*_*_*.trc')
    # Loop through TRC files
    for trcFilePath in trcFilePathList:
        # TRC filename
        trcFileName = os.path.basename(trcFilePath)
        # Name of tool
        idTool.setName(os.path.splitext(trcFileName)[0])
        # Create Storage object to read starting and ending times from MOT file
        motData = modeling.Storage(trcFilePath.replace('.trc','.mot'))
        # <time_range>
        idTool.setStartTime(motData.getFirstTime())
        idTool.setEndTime(motData.getLastTime())
        # <external_loads_file>
        idTool.setExternalLoadsFileName(trcFileName.replace('.trc','_ExternalLoads.xml'))
        # <coordinates_file>
        idTool.setCoordinatesFileName(trcFileName.replace('.trc','_IK.mot'))
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
            dom.getElementsByTagName('model_file')[i].firstChild.nodeValue = persInfo['subID']+'__Simbody.osim'
        dom.getElementsByTagName('output_gen_force_file')[0].firstChild.nodeValue = trcFileName.replace('.trc','_ID.sto')
        xmlstring = dom.toxml('UTF-8')        
        xmlFile = open(xmlSetupFilePath,'w')
        xmlFile.write(xmlstring)
        xmlFile.close()
    return commandList

"""----------------------------------------------------------------"""
def createSetupXML_RRA(genericModelName,genDir,subDir,persInfo,commandList):
    # Create RRATool object
    rraTool = modeling.RRATool(genDir['Full']+'RRATool.xml')
    # <model_file>
    rraTool.setModelFilename(persInfo['subID']+'__Simbody.osim')
    # <replace_force_set>
    rraTool.setReplaceForceSet(True)
    # <force_set_files>
    forceSetFiles = modeling.ArrayStr()
    forceSetFiles.setitem(0,genDir['Rel']+genericModelName+'_RRA_ForceSet.xml')
    rraTool.setForceSetFiles(forceSetFiles)
    # <output_precision>
    rraTool.setOutputPrecision(20)
    # <solve_for_equilibrium_for_auxiliary_states>
    rraTool.setSolveForEquilibrium(True)
    # <task_set_file>
    rraTool.setTaskSetFileName(genDir['Rel']+genericModelName+'_RRA_CMCTaskSet.xml')
    # <constraints_file>
    rraTool.setConstraintsFileName(genDir['Rel']+genericModelName+'_RRA_ControlSet.xml')  
    # <adjust_com_to_reduce_residuals>
    rraTool.setAdjustCOMToReduceResiduals(True)
    # <adjusted_com_body>
    rraTool.setAdjustedCOMBody('torso')    
    # Dynamic TRC filenames
    trcFilePathList = glob.glob(subDir+persInfo['subID']+'_*_*_*.trc')
    # Loop through TRC files
    for trcFilePath in trcFilePathList:
        # TRC filename
        trcFileName = os.path.basename(trcFilePath)
        # Name of tool
        rraTool.setName(os.path.splitext(trcFileName)[0])
        # Create Storage object to read starting and ending times from MOT file
        motData = modeling.Storage(trcFilePath.replace('.trc','.mot'))
        # <initial_time>
        rraTool.setInitialTime(motData.getFirstTime())
        # <final_time>
        rraTool.setFinalTime(motData.getLastTime())
        # <external_loads_file>
        rraTool.setExternalLoadsFileName(trcFileName.replace('.trc','_ExternalLoads.xml'))
        # <desired_kinematics_file>
        rraTool.setDesiredKinematicsFileName(trcFileName.replace('.trc','_IK.mot'))
        # <output_model_file>
        rraTool.setOutputModelFileName(persInfo['subID']+'__Simbody_AdjustedCOM.osim')
        # Write changes to XML file
        rraTool.print(trcFilePath.replace('.trc','__Setup_RRA.xml'))
        # Prepare command for batch processing
        commandList.append('rra -S '+trcFileName.replace('.trc','__Setup_RRA.xml')+' > %curdir%\\'+trcFileName.replace('.trc','_RRA.log')+'\n')
    return commandList
    
"""----------------------------------------------------------------"""
def createSetupXML_CMC(genericModelName,genDir,subDir,persInfo,commandList):
    # Create CMCTool object
    cmcTool = modeling.CMCTool(genDir['Full']+'CMCTool.xml')
    # <model_file>
    cmcTool.setModelFilename(persInfo['subID']+'__Simbody_AdjustedCOM.osim')
    # <force_set_files>
    forceSetFiles = modeling.ArrayStr()
    forceSetFiles.setitem(0,genDir['Rel']+genericModelName+'_CMC_ForceSet.xml')
    cmcTool.setForceSetFiles(forceSetFiles)
    # <output_precision>
    cmcTool.setOutputPrecision(20)
    # <maximum_number_of_integrator_steps>
    cmcTool.setMaximumNumberOfSteps(30000)
    # <maximum_integrator_step_size>
    cmcTool.setMaxDT(0.0001)
    # <integrator_error_tolerance>
    cmcTool.setErrorTolerance(1e-006)
    # <task_set_file>
    cmcTool.setTaskSetFileName(genDir['Rel']+genericModelName+'_CMC_CMCTaskSet.xml')
    # <constraints_file>
    cmcTool.setConstraintsFileName(genDir['Rel']+genericModelName+'_CMC_ControlSet.xml')
    # Dynamic TRC filenames
    trcFilePathList = glob.glob(subDir+persInfo['subID']+'_*_*_*.trc')
    # Loop through TRC files
    for trcFilePath in trcFilePathList:
        # TRC filename
        trcFileName = os.path.basename(trcFilePath)
        # Name of tool
        cmcTool.setName(os.path.splitext(trcFileName)[0])
        # Create Storage object to read starting and ending times from MOT file
        motData = modeling.Storage(trcFilePath.replace('.trc','.mot'))
        # <initial_time>
        cmcTool.setInitialTime(motData.getFirstTime())
        # <final_time>
        cmcTool.setFinalTime(motData.getLastTime())
        # <external_loads_file>
        cmcTool.setExternalLoadsFileName(trcFileName.replace('.trc','_ExternalLoads.xml'))
        # <desired_kinematics_file>
        cmcTool.setDesiredKinematicsFileName(trcFileName.replace('.trc','_RRA_Kinematics_q.sto'))
        # Write changes to XML file
        cmcTool.print(trcFilePath.replace('.trc','__Setup_CMC.xml'))
        # Prepare command for batch processing
        commandList.append('cmc -S '+trcFileName.replace('.trc','__Setup_CMC.xml')+' > %curdir%\\'+trcFileName.replace('.trc','_CMC.log')+'\n')
    return commandList
    
"""----------------------------------------------------------------"""
def writeCommandsToBat(subDir,commandList):
    batFile = open(subDir+'Run.bat','w')
    batFile.writelines(commandList)
    batFile.close()

"""*******************************************************************
*                                                                    *
*                   Main Function Definition                         *
*                                                                    *
*******************************************************************"""
def main(genericModelName,subDir):
    # Reference generic file directory
    genDir = getGenericDirectory(subDir)
    # Get subject specific information from file
    persInfo = readPersonalInfoXML(subDir)
    # Create the setup file used to run the scale step
    commandList = createSetupXML_Scale(genericModelName,genDir,subDir,persInfo)
    # Create the setup file(s) used to run the IK step
    commandList = createSetupXML_IK(genericModelName,genDir,subDir,persInfo,commandList)
    # Create the external loads file(s) used for all kinetic analyses
    createExternalLoadsXML(genDir,subDir,persInfo)
    # Create the setup file(s) used to run the ID step
    commandList = createSetupXML_ID(genDir,subDir,persInfo,commandList)
    # Create the setup file(s) used to run the RRA step
    commandList = createSetupXML_RRA(genericModelName,genDir,subDir,persInfo,commandList)
    # Create the setup file(s) used to run the CMC step    
    commandList = createSetupXML_CMC(genericModelName,genDir,subDir,persInfo,commandList)
    # Write batch file
    writeCommandsToBat(subDir,commandList)
    
"""*******************************************************************
*                                                                    *
*                   Script Execution                                 *
*                                                                    *
*******************************************************************"""
# Imports
import org.opensim.utils as utils
import os
import glob
from xml.dom.minidom import parse
# Subject directory
nuDir = getScriptsDir()
while os.path.basename(nuDir) != 'Northwestern-RIC':
    nuDir = os.path.dirname(nuDir)
subDir = os.path.join(nuDir,'My Box Files','Modeling','OpenSim','Subjects',subID)+'\\'
# Call main function
main(genericModelName,subDir)
