"""
----------------------------------------------------------------------
    iterateRRAadjustMass.py
----------------------------------------------------------------------
    A class to repeatedly run the RRA tool until the suggested mass 
    adjustment is below a predefined threshold or a maximum number of
    iterations is reached.
    
    Input:
        Subject ID
    Output:
        Simulation results
        RRA iteration log
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
# Subject ID
subID = '20130221CONF'
# ####################################################################


# Imports
import os
import glob
import subprocess
import time
import linecache
import shutil
from xml.dom.minidom import parse
import numpy


class iterateRRA:
    """
    A class to repeatedly run the RRA tool in OpenSim until the 
    suggested mass adjustment is below a preset tolerance.
    """
    
    def __init__(self,subID):
        """
        Create an instance of the class from the subject ID and add
        the subject directory and other static attributes.
        """
        # Subject ID
        self.subID = subID
        # Subject directory
        nuDir = os.getcwd()
        while os.path.basename(nuDir) != 'Northwestern-RIC':
            nuDir = os.path.dirname(nuDir)
        self.subDir = os.path.join(nuDir,'Modeling','OpenSim','Subjects',subID)+'\\'
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
    def createReport(self,trialName):
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
        logFile = open(self.subDir+trialName+'_RRA__Iterations.data','w')
        logFile.writelines(logReport)
        logFile.close()
    
    """------------------------------------------------------------"""
    def updateSetupXML(self,xmlFilePath,trialName):
        """
        Update the Setup XML file <model_file> tag and rename file.
        """
        # Parse XML
        dom = parse(xmlFilePath)
        # Update element
        dom.getElementsByTagName('model_file')[0].firstChild.nodeValue = self.subDir+trialName+'.osim'
        # Overwrite existing file
        xmlString = dom.toxml('UTF-8')
        xmlFile = open(xmlFilePath.replace('.xml','_Iterations.xml'),'w')
        xmlFile.write(xmlString)
        xmlFile.close()
    
    """------------------------------------------------------------"""
    def updateModelName(self,trialName):
        """
        Update the model name in the OSIM file.
        """
        # Parse XML
        dom = parse(self.subDir+trialName+'__AdjustedCOM.osim')
        # Update element attribute
        dom.getElementsByTagName('Model')[0].attributes.item(0).value = trialName
        # Overwrite existing file
        xmlString = dom.toxml('UTF-8')
        xmlFile = open(self.subDir+trialName+'__AdjustedCOM.osim','w')
        xmlFile.write(xmlString)
        xmlFile.close()
    
    """------------------------------------------------------------"""
    def updateReport(self,trialName,nIter):
        """
        Update the summary report file.
        """
        # Initialize Report
        logReport = [str(nIter-1)]        
        # Read simulation log file
        logFile = open(self.subDir+trialName+'_RRA.log','r')
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
        residuals = numpy.loadtxt(self.subDir+trialName+'_RRA_Actuation_force.sto',skiprows=23,usecols=(1,2,3,4,5,6))
        maxResiduals = residuals.__abs__().max(0)
        rmsResiduals = numpy.sqrt(numpy.sum(numpy.square(residuals),0)/numpy.size(residuals,0))
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
        txtline = linecache.getline(self.subDir+trialName+'_RRA_pErr.sto',7)
        headerList = txtline.rstrip().split('\t')
        posErrNames = headerList[1:]
        linecache.clearcache()
        # (Column indices to remove -- after removing first column)
        removeIndices = [posErrNames.index('subtalar_angle_r'),posErrNames.index('mtp_angle_r'),posErrNames.index('subtalar_angle_l'),posErrNames.index('mtp_angle_l')]
        removeIndices.reverse()
        for k in removeIndices:
            del posErrNames[k]
        # Load position errors as an array
        posErrors = numpy.loadtxt(self.subDir+trialName+'_RRA_pErr.sto',skiprows=7)        
        # Remove columns
        posErrors = numpy.delete(posErrors,0,1)
        for k in removeIndices:
            posErrors = numpy.delete(posErrors,k,1)
        maxPosErr = posErrors.__abs__().max(0)
        rmsPosErr = numpy.sqrt(numpy.sum(numpy.square(posErrors),0)/numpy.size(posErrors,0))
        # Unit conversions
        for k in range(len(posErrNames)):
            if posErrNames[k] == 'pelivs_tx' or posErrNames[k] == 'pelvis_ty' or posErrNames[k] == 'pelvis_tz':
                # Convert from m to cm
                maxPosErr[k]*=100
                rmsPosErr[k]*=100                
            else:
                # Convert from rad to deg
                maxPosErr[k]*=180/numpy.pi
                rmsPosErr[k]*=180/numpy.pi                
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
        logFile = open(self.subDir+trialName+'_RRA__Iterations.data','a')
        logFile.write(logReportLine)
        logFile.close()                
            
    """------------------------------------------------------------"""
    def adjustModelMass(self,trialName):
        """
        Adjust the masses of the bodies in the model.
        """
        # Read log file
        logFile = open(self.subDir+trialName+'_RRA.log','r')
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
        dom = parse(self.subDir+trialName+'__AdjustedCOM.osim')
        bodies = dom.getElementsByTagName('Body')
        for bodyElem in bodies:
            name = bodyElem.attributes.item(0).value
            bodyElem.getElementsByTagName('mass')[0].firstChild.nodeValue = massProps[name]
        # Write to new file
        xmlString = dom.toxml('UTF-8')
        xmlFile = open(self.subDir+trialName+'.osim','w')
        xmlFile.write(xmlString)
        xmlFile.close()
    
    """------------------------------------------------------------"""
    def runRRA(self,trialName):
        """
        Run the RRA tool and return the status of the simulation.
        """
        # Clean up previous trial output (if necessary)
        try:
            os.remove(self.subDir+trialName+'_RRA.log')
            os.remove(self.subDir+trialName+'__AdjustedCOM.osim')
            os.remove(self.subDir+'err.log')
            os.remove(self.subDir+'out.log')
        except:
            pass
        rraSpecifiers = ('Actuation_force.sto','Actuation_power.sto','Actuation_speed.sto',                         
                         'Kinematics_dudt.sto','Kinematics_q.sto','Kinematics_u.sto',
                         'avgResiduals.txt','controls.sto','controls.xml','pErr.sto','states.sto')
        for fspec in rraSpecifiers:
            try:
                os.remove(self.subDir+trialName+'_RRA_'+fspec)
            except:
                break        
        # Run RRA simulation via command prompt
        subprocess.Popen(('rra -S '+trialName+'__Setup_RRA_Iterations.xml > '+self.subDir+trialName+'_RRA.log'), shell=True, cwd=self.subDir)
        startTime = time.time()
        while True:
            # Check for simulation result file
            if os.access(self.subDir+trialName+'_RRA_controls.xml',os.F_OK):
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
    def getDeltaMass(self,trialName):
        """
        Read the total suggested change in mass from the log file.
        """
        # Read log file
        logFile = open(self.subDir+trialName+'_RRA.log','r')
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
    def run(self):
        """
        Main program to run the algorithm.
        """
        # Setup files
        xmlFileList = glob.glob(self.subDir+self.subID+'*__Setup_RRA.xml')
        # Loop through different files
        for xmlFilePath in xmlFileList:
            # XML filename
            xmlFileName = os.path.basename(xmlFilePath)
            # Trial Name
            trialName = xmlFileName.split('__Setup_RRA.xml')[0]
            # Initialize log file
            self.createReport(trialName)            
            # Update the setup file
            self.updateSetupXML(xmlFilePath,trialName)
            # Update the model name
            self.updateModelName(trialName)
            # Initialize loop
            n = 1
            dMass = 1
            # Only loop for the maximum number of iterations
            while n <= self.maxIter:
                # If the suggested mass change is greater than the threshold
                if abs(dMass) > self.tolerance:
                    # Write results of previous run to the log
                    self.updateReport(trialName,n)
                    # Adjust model based on previous simulation run
                    self.adjustModelMass(trialName)
                    # Run the simulation
                    status = self.runRRA(trialName)
                    # Check the outcome - mass change
                    if status == 'passed':
                        dMass = self.getDeltaMass(trialName)
                        n+=1
                    else:
                        print (trialName+' has failed -- check status manually.')
                        break
                else:
                    #print (trialName+' is complete.')
                    # Write results of final run to the log
                    self.updateReport(trialName,n)
                    # Remove adjusted model
                    os.remove(self.subDir+trialName+'__AdjustedCOM.osim')
                    try:
                        os.remove(self.subDir+'err.log')
                        os.remove(self.subDir+'out.log')
                    except:
                        pass
                    break
                
 
"""*******************************************************************
*                                                                    *
*                   Script Execution                                 *
*                                                                    *
*******************************************************************"""
if __name__ == '__main__':
    # Create instance of class
    iRRA = iterateRRA(subID)
    # Run code
    iRRA.run()   
