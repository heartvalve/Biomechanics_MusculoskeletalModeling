"""
----------------------------------------------------------------------
    runToolsParallel.py
----------------------------------------------------------------------
    This module contains classes for running OpenSim simulation steps:
    Scale, Inverse Kinematics, Inverse Dynamics, Residual Reduction,
    and Computed Muscle Control.  After the module is imported,
    instances of classes can be created from the subject ID.
    Simulation steps can be executed by invoking the 'run' methods.
    
    All OpenSim tools inherit attributes and methods from the
    superclass, with subclass specific variations as necessary for the
    individual tools.
    
    This module also contains a class for iterating the RRA step of 
    the simulation, which requires importing the NumPy module.
----------------------------------------------------------------------
    Created by Megan Schroeder
    Last Modified 2013-08-20
----------------------------------------------------------------------
"""


# Imports
import os
import glob
import subprocess
import time
import shutil
import linecache
from xml.dom.minidom import parse
import numpy as np


class openSimTool:
    """
    A superclass with attributes and methods associated with running
    OpenSim tools.
    """

    def __init__(self,subID,trialName,toolName):
        """
        Create an instance of the class from the subject ID, trial
        name and tool name. Add the subject directory and other
        attributes that may be updated by the subclasses.
        """
        # Subject ID
        self.subID = subID
        # Subject directory
        nuDir = os.getcwd()
        while os.path.basename(nuDir) != 'Northwestern-RIC':
            nuDir = os.path.dirname(nuDir)
        self.subDir = os.path.join(nuDir,'Modeling','OpenSim','Subjects',subID)+'\\'
        # Trial name
        self.trialName = trialName
        # Tool name
        self.toolName = toolName
        # File to check
        self.checkFile = 'unknown'
        # Simulation wait time
        self.sleepTime = 1

    """------------------------------------------------------------"""
    def copySetupXMLToSubFolder(self):
        """
        Update the Setup XML file output / results tag(s), save file
        in a new temporary directory
        """
        # Create temporary folder
        os.mkdir(self.subDir+self.trialName)
        # Parse XML
        dom = parse(self.subDir+self.trialName+'__Setup_'+self.toolName+'.xml')
        # Update element
        if self.toolName == 'Scale':
            dom.getElementsByTagName('output_model_file')[0].firstChild.nodeValue = self.subDir+self.trialName+'\\TempScaled.osim'
            dom.getElementsByTagName('output_model_file')[1].firstChild.nodeValue = self.subDir+self.trialName+'\\'+self.checkFile
        elif self.toolName == 'IK':
            dom.getElementsByTagName('output_motion_file')[0].firstChild.nodeValue = self.subDir+self.trialName+'\\'+self.checkFile
        elif self.toolName == 'RRA' or self.toolName == 'CMC':
            dom.getElementsByTagName('results_directory')[0].firstChild.nodeValue = self.subDir+self.trialName+'\\'
            if self.toolName == 'RRA':
                dom.getElementsByTagName('output_model_file')[0].firstChild.nodeValue = self.subDir+self.trialName+'\\'+self.trialName+'__AdjustedCOM.osim'
        # Write new file in temporary folder
        xmlString = dom.toxml('UTF-8')
        xmlFile = open(self.subDir+self.trialName+'\\'+self.trialName+'__Setup_'+self.toolName+'.xml','w')
        xmlFile.write(xmlString)
        xmlFile.close()

    """------------------------------------------------------------"""
    def executeShell(self):
        """
        Run the tool via the command prompt.
        """
        # Open subprocess in current directory
        subprocess.Popen((self.toolName.lower()+' -S '+self.trialName+'__Setup_'+self.toolName+'.xml > '+self.subDir+self.trialName+'\\'+self.trialName+'_'+self.toolName+'.log'), shell=True, cwd=(self.subDir+self.trialName))

    """------------------------------------------------------------"""
    def checkIfDone(self):
        """
        Check if the simulation is finished.
        """
        # Starting time
        startTime = time.time()
        # Check file existence
        while True:
            # Check for simulation result file
            if os.access(self.subDir+self.trialName+'\\'+self.checkFile,os.F_OK):  # wrong for scale!
                time.sleep(self.sleepTime)
                break
            # Timeout if simulation is not finished after 2 minutes
            elif (time.time()-startTime) > 120:
                print ('Check status of '+self.trialName+'_'+self.toolName.upper()+'.')
                break
            # Wait
            else:
                time.sleep(self.sleepTime)

    """------------------------------------------------------------"""
    def cleanUp(self):
        """
        Delete unnecessary files created during the simulation run.
        """
        try:
            # Delete
            os.remove(self.subDir+self.trialName+'\\err.log')
            os.remove(self.subDir+self.trialName+'\\out.log')
            if self.toolName == 'Scale':
                os.remove(self.subDir+self.trialName+'\\TempScaled.osim')
        except:
            pass

    """------------------------------------------------------------"""
    def moveResultsToMainFolder(self):
        """
        Move the simulation results to the main subject directory.
        """
        # Delete setup file
        os.remove(self.subDir+self.trialName+'\\'+self.trialName+'__Setup_'+self.toolName+'.xml')
        # Rename result files
        allFiles = os.listdir(self.subDir+self.trialName+'\\')
        for fName in allFiles:
            os.rename(self.subDir+self.trialName+'\\'+fName, self.subDir+fName)
        # Delete (empty) trial folder
        os.rmdir(self.subDir+self.trialName)
        # Brief pause
        time.sleep(1)

    """------------------------------------------------------------"""
    def run(self):
        """
        Main program to run the tool for an individual trial.
        """
        self.copySetupXMLToSubFolder()
        self.executeShell()
        self.checkIfDone()
        self.cleanUp()
        self.moveResultsToMainFolder()

# ####################################################################

class scale(openSimTool):
    """
    A class to run the Scale tool using an existing Setup file.
    """

    def __init__(self,subID):
        """
        Create an instance of the class from the superclass. Update
        attributes as necessary for subclass.
        """
        openSimTool.__init__(self,subID,subID+'_0_StaticPose','Scale')
        self.checkFile = self.subID+'.osim'

# ####################################################################

class ikin(openSimTool):
    """
    A class to run the IK (inverse kinematics) tool using an existing
    Setup file for a single trial for a given subject.
    """

    def __init__(self,trialName):
        """
        Create an instance of the class from the superclass. Update
        attributes as necessary for subclass.
        """
        openSimTool.__init__(self,trialName.split('_')[0],trialName,'IK')
        self.checkFile = self.trialName+'_IK.mot'

# ####################################################################

class idyn(openSimTool):
    """
    A class to run the ID (inverse dynamics) tool using an existing
    Setup file for a single trial for a given subject.
    """

    def __init__(self,trialName):
        """
        Create an instance of the class from the superclass. Update
        attributes as necessary for subclass.
        """
        openSimTool.__init__(self,trialName.split('_')[0],trialName,'ID')
        self.checkFile = self.trialName+'_ID.sto'

# ####################################################################

class rra(openSimTool):
    """
    A class to run the RRA tool using an existing Setup file for a
    single trial for a given subject.
    """

    def __init__(self,trialName):
        """
        Create an instance of the class from the superclass. Update
        attributes as necessary for subclass.
        """
        openSimTool.__init__(self,trialName.split('_')[0],trialName,'RRA')
        self.checkFile = self.trialName+'_RRA_controls.xml'
        self.sleepTime = 5
    
    """------------------------------------------------------------"""
    def run(self):
        """
        Overwrite the superclass method to run the tool without
        moving the files out of the subfolder.
        """
        self.copySetupXMLToSubFolder()
        self.executeShell()
        self.checkIfDone()
        self.cleanUp()

# ####################################################################

class cmc(openSimTool):
    """
    A class to run the CMC tool using an existing Setup file for a
    single trial for a given subject.
    """

    def __init__(self,trialName):
        """
        Create an instance of the class from the superclass.
        """
        openSimTool.__init__(self,trialName.split('_')[0],trialName,'CMC')

    """------------------------------------------------------------"""
    def checkIfDone(self):
        """
        Overwrite the superclass method to check if the simulation is
        finished.
        """
        # Starting time
        startTime = time.time()
        while True:
            # Check for simulation result file
            if os.access(self.subDir+self.trialName+'\\'+self.trialName+'_CMC_controls.xml',os.F_OK):
                # Display a message to the user
                print (self.trialName+'_CMC is complete.')
                # Slight pause
                time.sleep(3)
                # Exit the loop
                break
            # Timeout after 2 hours
            elif (time.time()-startTime) > 7200:
                # Display a message to the user
                print (self.trialName+'_CMC timed out.')
                break
            # Check the log file between 30 seconds and 2 minutes for an exception;
            # and after 10 minutes have elapsed for a failed simulation
            elif ((time.time()-startTime) > 30 and (time.time()-startTime) < 120) or (time.time()-startTime) > 600:
                # Copy the log file to a temporary file
                shutil.copy(self.subDir+self.trialName+'\\'+self.trialName+'_CMC.log',self.subDir+self.trialName+'\\temp.log')
                # Read the log file
                logFile = open(self.subDir+self.trialName+'\\temp.log','r')
                logList = logFile.readlines()
                logFile.close()
                # Remove the temporary file
                os.remove(self.subDir+self.trialName+'\\temp.log')
                # Status is running -- will be updated later if different
                status = 'running'
                # Search through the last few lines of the log file
                for n in range(-10,0):
                    if time.time()-startTime > 600:
                        # Failed simulation
                        if 'FAILED' in logList[n]:
                            print ('Check status of '+self.trialName+'_CMC.')
                            status = 'failed'
                            # Exit for loop
                            break
                    else:
                        # Exception thrown
                        if 'exception' in logList[n]:
                            print ('Exception thrown in '+self.trialName+'_CMC.')
                            status = 'failed'
                            # Exit for loop
                            break
                # Exit outer while loop if failed
                if status == 'failed':
                    break
                # Otherwise, wait
                else:
                    time.sleep(15)
            # Wait
            else:
                time.sleep(15)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

class iterateRRA:
    """
    A class to repeatedly run the RRA tool in OpenSim until the 
    suggested mass adjustment is below a preset tolerance.
    """
    
    def __init__(self,trialName):
        """
        Create an instance of the class from the trial name and add
        the subject ID, directory and other static attributes.
        """
        # Trial Name
        self.trialName = trialName
        # Subject ID
        self.subID = trialName.split('_')[0]
        # Subject directory
        nuDir = os.getcwd()
        while os.path.basename(nuDir) != 'Northwestern-RIC':
            nuDir = os.path.dirname(nuDir)
        self.subDir = os.path.join(nuDir,'Modeling','OpenSim','Subjects',self.subID)+'\\'
        # Mass adjustment threshold (in kg)
        self.tolerance = 0.01
        # Maximum number of iterations
        self.maxIter = 7
        # Bodies in model
        self.bodies = ['pelvis','femur_r','tibia_r','talus_r','calcn_r','toes_r',
                       'femur_l','tibia_l','talus_l','calcn_l','toes_l','torso']
        # Degrees of freedom
        self.positionNames = ['pelvis_tz','pelvis_tx','pelvis_ty','pelvis_tilt','pelvis_list','pelvis_rotation',
                              'hip_flexion_r','hip_adduction_r','hip_rotation_r','knee_angle_r','ankle_angle_r',
                              'hip_flexion_l','hip_adduction_l','hip_rotation_l','knee_angle_l','ankle_angle_l',
                              'lumbar_extension','lumbar_bending','lumbar_rotation']

    """------------------------------------------------------------"""
    def createReport(self):
        """
        Initialize the summary report file.
        """
        # Detailed report
        logReport = []
        header1 = ('Iteration\tOriginal Mass'+'\t'*12+'Suggested Mass Change\tNew Center of Mass Location (torso)'+'\t'*3+
                   'Max Residual Force'+'\t'*3+'RMS Residual Force'+'\t'*3+'Avg Residual Force'+'\t'*3+
                   'Max Residual Moment'+'\t'*3+'RMS Residual Moment'+'\t'*3+'Avg Residual Moment'+'\t'*3+
                   'Max Position Error (cm)'+'\t'*3+'RMS Position Error (cm)'+'\t'*3+
                   'Max Position Error (deg)'+'\t'*16+'RMS Position Error (deg)'+'\t'*15+'\n')
        logReport.append(header1)
        header2 = '\t'.join(['']+self.bodies+['']+['X','Y','Z']+['FX','FY','FZ']*3+['MX','MY','MZ']*3+self.positionNames[0:3]*2+self.positionNames[3:]*2)+'\n'
        logReport.append(header2)
        # Write to file
        logFile = open(self.subDir+self.trialName+'\\'+self.trialName+'_RRA__Iterations.data','w')
        logFile.writelines(logReport)
        logFile.close()
    
    """------------------------------------------------------------"""
    def updateSetupXML(self):
        """
        Update the Setup XML file <model_file> tag and rename file.
        """
        # Parse XML
        xmlFilePath = self.subDir+self.trialName+'\\'+self.trialName+'__Setup_RRA.xml'
        dom = parse(xmlFilePath)
        # Update element
        dom.getElementsByTagName('model_file')[0].firstChild.nodeValue = self.subDir+self.trialName+'\\'+self.trialName+'.osim'
        # Overwrite existing file
        xmlString = dom.toxml('UTF-8')
        xmlFile = open(xmlFilePath.replace('.xml','_Iterations.xml'),'w')
        xmlFile.write(xmlString)
        xmlFile.close()
    
    """------------------------------------------------------------"""
    def updateModelName(self):
        """
        Update the model name in the OSIM file.
        """
        # Parse XML
        osimFilePath = self.subDir+self.trialName+'\\'+self.trialName+'__AdjustedCOM.osim'
        dom = parse(osimFilePath)
        # Update element attribute
        dom.getElementsByTagName('Model')[0].attributes.item(0).value = self.trialName
        # Overwrite existing file
        xmlString = dom.toxml('UTF-8')
        xmlFile = open(osimFilePath,'w')
        xmlFile.write(xmlString)
        xmlFile.close()
    
    """------------------------------------------------------------"""
    def updateReport(self,nIter):
        """
        Update the summary report file.
        """
        # Initialize Report
        logReport = [str(nIter-1)]        
        # Read simulation log file
        logFile = open(self.subDir+self.trialName+'\\'+self.trialName+'_RRA.log','r')
        logList = logFile.readlines()
        logFile.close()
        # Loop through text lines (from end)
        rList = range(len(logList))
        rList.reverse()
        for i in rList:
            if 'Recommended mass adjustments' in logList[i]:
                rmaIndex = i
                break
            elif 'Note: Edit the model to make recommended' in logList[i]:
                noteIndex = i
        # Create dictionary mapping bodies to original masses
        massProps = {}
        for i in range(rmaIndex+2,noteIndex-1):
            logLineSplit = logList[i].split()
            massProps[logLineSplit[1][:-1]] = logLineSplit[-5][:-1]
        # Append to report list
        for body in self.bodies:
            logReport.append(massProps[body])
        # Mass change (recommended)
        logReport.append(logList[rmaIndex+1].split(': ')[1].strip())
        # Center of mass (new)
        com = logList[rmaIndex-2].split('~')[1].strip()
        logReport.append(com.split(',')[0][1:])
        logReport.append(com.split(',')[1])
        logReport.append(com.split(',')[2][:-1])
        # Residuals                
        residuals = np.loadtxt(self.subDir+self.trialName+'\\'+self.trialName+'_RRA_Actuation_force.sto',skiprows=23,usecols=(1,2,3,4,5,6))
        maxResiduals = residuals.__abs__().max(0)
        rmsResiduals = np.sqrt(np.sum(np.square(residuals),0)/np.size(residuals,0))
        avgResiduals = residuals.mean(0)
        # Update log
        avgResiduals = avgResiduals.tolist()
        maxResiduals = maxResiduals.tolist()
        rmsResiduals = rmsResiduals.tolist()
        # FX, FY, FZ
        for k in range(3): logReport.append(str(maxResiduals[k]))
        for k in range(3): logReport.append(str(rmsResiduals[k]))
        for k in range(3): logReport.append(str(avgResiduals[k]))
        # MX, MY, MZ
        for k in range(3,6): logReport.append(str(maxResiduals[k]))
        for k in range(3,6): logReport.append(str(rmsResiduals[k]))
        for k in range(3,6): logReport.append(str(avgResiduals[k]))           
        # Position Errors
        txtline = linecache.getline(self.subDir+self.trialName+'\\'+self.trialName+'_RRA_pErr.sto',7)
        headerList = txtline.rstrip().split('\t')
        posErrNames = headerList[1:]
        linecache.clearcache()
        # (Column indices to remove -- after removing first column)
        removeIndices = [posErrNames.index('subtalar_angle_r'),posErrNames.index('mtp_angle_r'),posErrNames.index('subtalar_angle_l'),posErrNames.index('mtp_angle_l')]
        removeIndices.reverse()
        for k in removeIndices:
            del posErrNames[k]
        # Load position errors as an array
        posErrors = np.loadtxt(self.subDir+self.trialName+'\\'+self.trialName+'_RRA_pErr.sto',skiprows=7)        
        # Remove columns
        posErrors = np.delete(posErrors,0,1)
        for k in removeIndices:
            posErrors = np.delete(posErrors,k,1)
        maxPosErr = posErrors.__abs__().max(0)
        rmsPosErr = np.sqrt(np.sum(np.square(posErrors),0)/np.size(posErrors,0))
        # Unit conversions
        for k in range(len(posErrNames)):
            if posErrNames[k] == 'pelivs_tx' or posErrNames[k] == 'pelvis_ty' or posErrNames[k] == 'pelvis_tz':
                # Convert from m to cm
                maxPosErr[k]*=100
                rmsPosErr[k]*=100                
            else:
                # Convert from rad to deg
                maxPosErr[k]*=180/np.pi
                rmsPosErr[k]*=180/np.pi                
        # Update log        
        maxPosErr = maxPosErr.tolist()
        rmsPosErr = rmsPosErr.tolist()        
        # Translations
        for k in range(3): logReport.append(str(maxPosErr[k]))
        for k in range(3): logReport.append(str(rmsPosErr[k]))
        # Angles
        for k in range(3,len(maxPosErr)): logReport.append(str(maxPosErr[k]))
        for k in range(3,len(rmsPosErr)): logReport.append(str(rmsPosErr[k]))
        # Merge logReport list into string
        logReportLine = '\t'.join(logReport)+'\n'                        
        # Append to file
        logFile = open(self.subDir+self.trialName+'\\'+self.trialName+'_RRA__Iterations.data','a')
        logFile.write(logReportLine)
        logFile.close()                
            
    """------------------------------------------------------------"""
    def adjustModelMass(self):
        """
        Adjust the masses of the bodies in the model.
        """
        # Read log file
        logFile = open(self.subDir+self.trialName+'\\'+self.trialName+'_RRA.log','r')
        logList = logFile.readlines()
        logFile.close()
        # Loop through text lines (from end)
        rList = range(len(logList))
        rList.reverse()
        for i in rList:
            if 'Recommended mass adjustments' in logList[i]:
                rmaIndex = i
                break
            elif 'Note: Edit the model to make recommended' in logList[i]:
                noteIndex = i
        # Create dictionary mapping bodies to new masses
        massProps = {}
        for i in range(rmaIndex+2,noteIndex-1):
            logLineSplit = logList[i].split()
            massProps[logLineSplit[1][:-1]] = logLineSplit[-1]
        # Update OSIM model masses accordingly
        dom = parse(self.subDir+self.trialName+'\\'+self.trialName+'__AdjustedCOM.osim')
        bodies = dom.getElementsByTagName('Body')
        for bodyElem in bodies:
            name = bodyElem.attributes.item(0).value
            bodyElem.getElementsByTagName('mass')[0].firstChild.nodeValue = massProps[name]
        # Write to new file
        xmlString = dom.toxml('UTF-8')
        xmlFile = open(self.subDir+self.trialName+'\\'+self.trialName+'.osim','w')
        xmlFile.write(xmlString)
        xmlFile.close()
    
    """------------------------------------------------------------"""
    def cleanUp(self):
        """
        
        """
        # Clean up previous trial output (if necessary)
        try:
            os.remove(self.subDir+self.trialName+'\\'+self.trialName+'_RRA.log')
            os.remove(self.subDir+self.trialName+'\\'+self.trialName+'__AdjustedCOM.osim')
            os.remove(self.subDir+self.trialName+'\\err.log')
            os.remove(self.subDir+self.trialName+'\\out.log')
        except:
            pass
        rraSpecifiers = ('Actuation_force.sto','Actuation_power.sto','Actuation_speed.sto',                         
                         'Kinematics_dudt.sto','Kinematics_q.sto','Kinematics_u.sto',
                         'avgResiduals.txt','controls.sto','controls.xml','pErr.sto','states.sto')
        for fspec in rraSpecifiers:
            try:
                os.remove(self.subDir+self.trialName+'\\'+self.trialName+'_RRA_'+fspec)
            except:
                break
    
    """------------------------------------------------------------"""
    def executeShell(self):
        """
        Run the RRA tool via the command prompt.
        """
        # Open subprocess in current directory
        subprocess.Popen(('rra -S '+self.trialName+'__Setup_RRA_Iterations.xml > '+self.subDir+self.trialName+'\\'+self.trialName+'_RRA.log'), shell=True, cwd=(self.subDir+self.trialName))
        
    """------------------------------------------------------------"""
    def checkIfDone(self):
        """
        Return the status of the simulation
        """
        # Starting time        
        startTime = time.time()
        while True:
            # Check for simulation result file
            if os.access(self.subDir+self.trialName+'\\'+self.trialName+'_RRA_controls.xml',os.F_OK):
                status = 'passed'
                time.sleep(5)
                break
            # Timeout after 2 minutes if file doesn't exist yet (simulation probably failed)
            elif (time.time()-startTime) > 120:
                status = 'failed'
                break
            # Wait
            else:
                time.sleep(5)
        return status
                    
    """------------------------------------------------------------"""
    def getDeltaMass(self):
        """
        Read the total suggested change in mass from the log file.
        """
        # Read log file
        logFile = open(self.subDir+self.trialName+'\\'+self.trialName+'_RRA.log','r')
        logList = logFile.readlines()
        logFile.close()
        # Loop through text lines
        rList = range(len(logList))
        rList.reverse()
        for i in rList:
            if 'Total mass change' in logList[i]:
                dMass = float(logList[i].split()[-1])
                break
        return dMass
    
    """------------------------------------------------------------"""
    def moveResultsToMainFolder(self):
        """
        Move the simulation results to the main directory.
        """
        # Delete files
        os.remove(self.subDir+self.trialName+'\\'+self.trialName+'__AdjustedCOM.osim')
        os.remove(self.subDir+self.trialName+'\\'+self.trialName+'__Setup_RRA.xml')
        try:            
            os.remove(self.subDir+self.trialName+'\\err.log')
            os.remove(self.subDir+self.trialName+'\\out.log')
        except:
            pass
        # Update XML setup file for RRA iterations
        dom = parse(self.subDir+self.trialName+'\\'+self.trialName+'__Setup_RRA_Iterations.xml')
        dom.getElementsByTagName('model_file')[0].firstChild.nodeValue = self.subDir+self.trialName+'.osim'
        dom.getElementsByTagName('results_directory')[0].firstChild.nodeValue = self.subDir
        dom.getElementsByTagName('output_model_file')[0].firstChild.nodeValue = self.subDir+self.trialName+'__AdjustedCOM.osim'
        # Overwrite existing file
        xmlString = dom.toxml('UTF-8')
        xmlFile = open(self.subDir+self.trialName+'\\'+self.trialName+'__Setup_RRA_Iterations.xml','w')
        xmlFile.write(xmlString)
        xmlFile.close()
        # Rename result files
        allFiles = os.listdir(self.subDir+self.trialName+'\\')
        for fName in allFiles:
            os.rename(self.subDir+self.trialName+'\\'+fName, self.subDir+fName)
        # Delete (empty) trial folder
        os.rmdir(self.subDir+self.trialName)
        # Brief pause
        time.sleep(1)
        
    """------------------------------------------------------------"""
    def run(self):
        """
        Main program to run the algorithm.
        """
        # Initialize log file
        self.createReport()            
        # Update the setup file
        self.updateSetupXML()
        # Update the model name
        self.updateModelName()
        # Initialize loop
        n = 1
        dMass = 1
        # Only loop for the maximum number of iterations
        while n <= self.maxIter:
            # If the suggested mass change is greater than the threshold
            if abs(dMass) > self.tolerance:
                # Write results of previous run to the log
                self.updateReport(n)
                # Adjust model based on previous simulation run
                self.adjustModelMass()
                # Clean up previous simulation
                self.cleanUp()
                # Run RRA
                self.executeShell()
                # Check status
                status = self.checkIfDone()
                # Check the outcome - mass change
                if status == 'passed':
                    dMass = self.getDeltaMass()
                    n+=1
                else:
                    print (self.trialName+' has failed -- check status manually.')
                    break
            else:
                # Write results of final run to the log
                self.updateReport(n)
                # Move to outer folder
                self.moveResultsToMainFolder()
                # Exit while loop
                break
                