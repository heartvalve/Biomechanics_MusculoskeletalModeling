"""
----------------------------------------------------------------------
    createSetupXML.py
----------------------------------------------------------------------
    Doc...


    To Do:
        createSetupXML_Scale -- measurementSet
        createSetupXML_IK -- <model_file>

----------------------------------------------------------------------
    Created by Megan Schroeder
    Last Modified 2013-06-24
----------------------------------------------------------------------
"""


# ####################################################################
# Generic model to use
genericModelName = 'gait2392'
# Subject ID
subID = '20130221CONF'
# ####################################################################
# Imports
import org.opensim.utils as utils
import os
import glob
from xml.dom.minidom import parse
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
    trcFileName = persInfo['subID']+'_01StaticPose.trc'
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
    # .... measurementSet...     measurementSetFilePath = genDir['Full']+genericModelName+'_'+persInfo['markerSet']+'_Scale_MeasurementSet.xml'
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
"""----------------------------------------------------------------"""
def createSetupXML_IK(genericModelName,genDir,subDir,persInfo):
    # Create InverseKinematicsTool object
    ikTool = modeling.InverseKinematicsTool(genDir['Full']+'InverseKinematicsTool.xml')
    # .... <model_file> .... ikTool.setModel(Model)  ????
    # Dynamic TRC filenames
    trcFilePathList = glob.glob(subDir+persInfo['subID']+'_*_*.trc')
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
        # **** Temporary fix for setting model name using XML parsing ****
        dom = parse(xmlSetupFilePath)
        dom.getElementsByTagName('model_file')[0].firstChild.nodeValue = persInfo['subID']+'__Simbody.osim'
        xmlstring = dom.toxml('UTF-8')
        #xmlstring = '\n'.join([line for line in dom.toprettyxml(indent=' '*4,encoding='UTF-8').split('\n') if line.strip()])+'\n'
        xmlFile = open(xmlSetupFilePath,'w')
        xmlFile.write(xmlstring)
        xmlFile.close()
# # """----------------------------------------------------------------"""
# # def createSetupXML_ID():




# # """----------------------------------------------------------------"""
# # def createSetupXML_RRA():




# # """----------------------------------------------------------------"""
# # def createSetupXML_CMC():




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
    createSetupXML_Scale(genericModelName,genDir,subDir,persInfo)
    # Create the setup file(s) used to run the IK step
    createSetupXML_IK(genericModelName,genDir,subDir,persInfo)
    # # # Create the setup file(s) used to run the ID step
    # # createSetupXML_ID()
    # # # Create the setup file(s) used to run the RRA step
    # # createSetupXML_RRA()
    # # # Create the setup file(s) used to run the CMC step
    # # createSetupXML_CMC()
"""*******************************************************************
*                                                                    *
*                   Script Execution                                 *
*                                                                    *
*******************************************************************"""
# Subject directory
nuDir = getScriptsDir()
while os.path.basename(nuDir) != 'Northwestern-RIC':
    nuDir = os.path.dirname(nuDir)
subDir = os.path.join(nuDir,'My Box Files','Modeling','OpenSim','Subjects',subID)+'\\'
# Call main function
main(genericModelName,subDir)
