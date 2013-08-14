"""
----------------------------------------------------------------------
    runCMCToolParallel.py
----------------------------------------------------------------------
    This class can be used to easily run the OpenSim Computed Muscle
    Control Tool in the background using multiple processors for all 
    dynamic trials for a given subject or list of subjects.

    Input:
        Subject ID
    Output:
        Simulation results
----------------------------------------------------------------------
    Created by Megan Schroeder
    Last Modified 2013-08-12
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
import os
import glob
import subprocess
import time
import shutil
import sys
from multiprocessing import Pool
from datetime import datetime
from xml.dom.minidom import parse

# Subject directory (won't work with list of subID's)
nuDir = os.getcwd()
while os.path.basename(nuDir) != 'Northwestern-RIC':
    nuDir = os.path.dirname(nuDir)
subDir = os.path.join(nuDir,'Modeling','OpenSim','Subjects',subIDs[0])+'\\'


# ####################################################################

   
def updateSetupXML(trialName):
    """
    Update the Setup XML file <results_directory> tag, rename
    file, and put in a new temporary directory
    """
    # Create temporary folder
    os.mkdir(subDir+trialName)
    # Parse XML
    dom = parse(subDir+trialName+'__Setup_CMC.xml')
    # Update element
    dom.getElementsByTagName('results_directory')[0].firstChild.nodeValue = subDir+trialName+'\\'
    # Write new file in temporary folder
    xmlString = dom.toxml('UTF-8')
    xmlFile = open(subDir+trialName+'\\'+trialName+'__Setup_CMC.xml','w')
    xmlFile.write(xmlString)
    xmlFile.close()
    return 'done'

"""----------------------------------------------------------------"""
def executeShell(trialName):
    """
    Run the tool via the command prompt.
    """
    # Open subprocess in current directory
    return subprocess.Popen(('cmc -S '+trialName+'__Setup_CMC.xml > '+subDir+trialName+'\\'+trialName+'_CMC.log'), shell=True, cwd=(subDir+trialName))

"""----------------------------------------------------------------"""    
def checkIfDone(trialName):
    """
    Check if the simulation is finished.
    """
    # Starting time
    startTime = time.time()
    while True:
        # Check for simulation result file
        if os.access(subDir+trialName+'\\'+trialName+'_CMC_controls.xml',os.F_OK):
            # Display a message to the user
            print (trialName+'_CMC is complete.')
            # Slight pause
            time.sleep(3)
            # Exit the loop
            break
        # Timeout after 3 hours
        elif (time.time()-startTime) > 10800:
            # Display a message to the user
            print (trialName+'_CMC timed out.')
            break
        # Check the log file between 30 seconds and 2 minutes for an exception; 
        # and after 10 minutes have elapsed for a failed simulation
        elif ((time.time()-startTime) > 30 and (time.time()-startTime) < 120) or (time.time()-startTime) > 600:
            # Copy the log file to a temporary file
            shutil.copy(subDir+trialName+'\\'+trialName+'_CMC.log',subDir+trialName+'\\temp.log')
            # Read the log file
            logFile = open(subDir+trialName+'\\temp.log','r')
            logList = logFile.readlines()
            logFile.close()
            # Remove the temporary file
            os.remove(subDir+trialName+'\\temp.log')
            # Status is running -- will be updated later if different
            status = 'running'
            # Search through the last few lines of the log file
            for n in range(-10,0):
                if time.time()-startTime > 600:
                    # Failed simulation
                    if 'FAILED' in logList[n]:
                        print ('Check status of '+trialName+'_CMC.')
                        status = 'failed'
                        # Exit for loop
                        break
                else:
                    # Exception thrown
                    if 'exception' in logList[n]:
                        print ('Exception thrown in '+trialName+'_CMC.')
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
    return 'done'

"""----------------------------------------------------------------"""
def cleanUp(trialName):
    """
    Delete unnecessary files created during the simulation run.
    """
    try:
        # Delete
        os.remove(subDir+trialName+'\\err.log')
        os.remove(subDir+trialName+'\\out.log')
    except:
        pass
    return 'done'


"""------------------------------------------------------------"""
def runTrial(trialName):
    """
    Main program to run the tool for an individual trial.
    """
    status = updateSetupXML(trialName)
    eshell = executeShell(trialName)
    status = checkIfDone(trialName)
    status = cleanUp(trialName)
    return status
        
# ####################################################################

class runCMCToolParallel:
    """
    
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
        # All CMC Setup files for the subject
        self.setupPaths = glob.glob(self.subDir+self.subID+'*__Setup_CMC.xml')
        # Starting time
        self.startTime = datetime.now()

    """------------------------------------------------------------"""
    def run(self):
        """
        Main program to run the tool for all trials.
        """
        # Loop through Setup files
        trialNames = []
        for setupPath in self.setupPaths:
            # Identify trial name
            setupFileName = os.path.basename(setupPath)
            trialNames.append(setupFileName.split('__Setup_')[0])
        # Run individual trial
        pool = Pool(processes=9)
        pool.map(runTrial, trialNames)

        
"""*******************************************************************
*                                                                    *
*                   Script Execution                                 *
*                                                                    *
*******************************************************************"""
if __name__ == '__main__':
    # Loop through subject list
    for subID in subIDs:
        # Create instance of class
        runCMC = runCMCToolParallel(subID)
        # Run code
        runCMC.run()
        # Display message to user
        d = datetime(1,1,1) + (datetime.now()-runCMC.startTime)
        if d.hour < 1:
            print (subID+' is finished -- elapsed time is %d minutes.' %(d.minute))
        else:
            print (subID+' is finished -- elapsed time is %d hour(s) and %d minute(s).' %(d.hour, d.minute))
  