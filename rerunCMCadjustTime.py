"""
----------------------------------------------------------------------
    rerunCMCadjustTime.py
----------------------------------------------------------------------
    A class to rerun the CMC tool with adjusted starting or ending
    times, in case of a crash.

    Adapted from runTools/cmc.

    Input:
        Subject ID (list)
    Output:
        Simulation results
----------------------------------------------------------------------
    Created by Megan Schroeder
    Last Modified 2013-07-23
----------------------------------------------------------------------
"""


# ####################################################################
#                                                                    #
#                   Input                                            #
#                                                                    #
# ####################################################################
# Subject ID list
subIDs = ['20121206CONF','20121205CONF','20121204CONF','20121204APRM',
          '20121008AHRM','20120912AHRF']
# ####################################################################


# Imports
import os
import glob
import subprocess
import time
import linecache
from xml.dom.minidom import parse


class rerunCMC:
    """
    A class to rerun the CMC tool with adjusted starting or ending
    times.
    """

    def __init__(self,subID):
        """
        Create an instance of the class from the subject ID and add
        the subject directory and a list of Setup files.
        """
        # Subject ID
        self.subID = subID
        # Subject directory
        nuDir = os.getcwd()
        while os.path.basename(nuDir) != 'Northwestern-RIC':
            nuDir = os.path.dirname(nuDir)
        self.subDir = os.path.join(nuDir,'Modeling','OpenSim','Subjects',subID)+'\\'
        # All CMC setup files for the subject
        self.setupPaths = glob.glob(self.subDir+self.subID+'*__Setup_CMC.xml')

    """------------------------------------------------------------"""
    def updateTime(self,trialName):
        """
        Determine when the simulation crashed, and update the Setup
        file times if there's an opportunity to still capture the
        entirety of the cycle window.
        """
        # Read log file
        logFile = open(self.subDir+trialName+'_CMC.log','r')
        logList = logFile.readlines()
        logFile.close()
        # Determine time of failure
        for n in range(-7,0):
            # Check if optimizer failed to find a solution
            if 'could not find a solution' in logList[n]:
                # Time in log file
                crashTime = float(logList[n].strip('.\n').split('= ')[1])
                # Last successful solve
                lastOptimizerTime = crashTime-0.001
                # Exit for loop
                break
        # Read mot file to get ending time of cycle
        motLine = linecache.getline(self.subDir+trialName+'_GRF.mot',11)
        lastCycleTime = float(motLine.split('\t')[-1].strip())
        firstCycleTime = float(motLine.split('\t')[-2])
        # Continue to update if the whole cycle will be solved
        if lastOptimizerTime >= lastCycleTime:
            # Set return value
            status = 'continue'
            # CMC look-ahead window is 0.01
            setupTime = str(crashTime+0.009)
            # Update Setup XML
            dom = parse(self.subDir+trialName+'__Setup_CMC.xml')
            dom.getElementsByTagName('final_time')[0].firstChild.nodeValue = setupTime
            xmlString = dom.toxml('UTF-8')
            xmlFile = open(xmlFilePath,'w')
            xmlFile.write(xmlString)
            xmlFile.close()
        # If we can't solve the whole cycle
        else:
            status = 'stop'
            print (trialName+'_CMC crashed after '+str(lastOptimizerTime)+'; cycle window is '+
                   str(firstCycleTime)+' to '+str(lastCycleTime))
        # Return
        return status

    """------------------------------------------------------------"""
    def executeShell(self,trialName):
        """
        Run the tool via the command prompt.
        """
        # Open subprocess in current directory
        subprocess.Popen(('cmc -S '+trialName+'__Setup_CMC.xml > '+self.subDir+trialName+'_CMC.log'),
                         shell=True, cwd=self.subDir)

    """------------------------------------------------------------"""
    def checkIfDone(self,trialName):
        """
        Check if the simulation is finished.
        """
        # Starting time
        startTime = time.time()
        while True:
            # Check for simulation result file
            if os.access(self.subDir+trialName+'_CMC_controls.xml',os.F_OK):
                # Display a message to the user
                print (trialName+'_CMC is complete.')
                # Slight pause
                time.sleep(1)
                # Exit the loop
                break
            # Timeout after 20 minutes
            elif (time.time()-startTime) > 1200:
                break
            # Check the log file after 10 minutes have elapsed
            elif (time.time()-startTime) > 600:
                # Copy the log file to a temporary file
                shutil.copy(self.subDir+trialName+'_CMC.log',self.subDir+'temp.log')
                # Read the log file
                logFile = open(self.subDir+'temp.log','r')
                logList = logFile.readlines()
                logFile.close()
                # Remove the temporary file
                os.remove(self.subDir+'temp.log')
                # Status is running -- will be updated later if different
                status = 'running'
                # Search through the last few lines of the log file
                for n in range(-10,0):
                    # Failed simulation
                    if 'FAILED' in logList[n]:
                        print ('Check status of '+trialName+'_CMC.')
                        status = 'failed'
                        # Exit for loop
                        break
                # Exit while loop if failed
                if status == 'failed':
                    break
                # Wait
                else:
                    time.sleep(15)
            # Wait
            else:
                time.sleep(15)

    """------------------------------------------------------------"""
    def cleanUp(self):
        """
        Delete unnecessary files created during the simulation run.
        """
        try:
            # Delete
            os.remove(self.subDir+'err.log')
            os.remove(self.subDir+'out.log')
        except:
            pass

    """------------------------------------------------------------"""
    def runTrial(self,trialName):
        """
        Main program to run the tool for an individual trial.
        """
        # Only continue if CMC run crashed
        if not os.path.exists(self.subDir+trialName+'_CMC_Kinematics_q.sto'):
            # Check to make sure RRA run has been completed
            if os.path.exists(self.subDir+trialName+'_RRA_Kinematics_q.sto'):
                # Check status of CMC simulation
                status = self.updateTime(trialName)
                # Only run if it crashed near the end of the simulation
                if status == 'continue':
                    self.executeShell(trialName)
                    self.checkIfDone(trialName)
                    self.cleanUp()
                    
    """------------------------------------------------------------"""
    def run(self):
        """
        Main program to run the tool for all trials.
        """
        # Loop through Setup files
        for setupPath in self.setupPaths:
            # Identify trial name
            setupFileName = os.path.basename(setupPath)
            trialName = setupFileName.split('__Setup_')[0]
            # Run individual trial
            self.runTrial(trialName)


"""*******************************************************************
*                                                                    *
*                   Script Execution                                 *
*                                                                    *
*******************************************************************"""
if __name__ == '__main__':
    # Loop through subject list
    for subID in subIDs:
        # Create instance of class
        rCMC = rerunCMC(subID)
        # Run code
        rCMC.run()
