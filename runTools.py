"""
----------------------------------------------------------------------
    runTools.py
----------------------------------------------------------------------
    This module contains classes for running OpenSim simulation steps:
    Scale, Inverse Kinematics, Inverse Dynamics, Residual Reduction,
    and Computed Muscle Control.  After the module is imported,
    instances of classes can be created from the subject ID.
    Simulation steps can be executed by invoking the 'run' methods.
----------------------------------------------------------------------
    Created by Megan Schroeder
    Last Modified 2013-07-23
----------------------------------------------------------------------
"""


# Imports
import os
import glob
import subprocess
import time
import shutil
import sys


# ####################################################################

class scale:
    """
    A class to run the Scale tool using an existing Setup file.
    """

    def __init__(self,subID):
        """
        Create an instance of the class from the subject ID and add
        the subject directory and static trial name.
        """
        # Subject ID
        self.subID = subID
        # Subject directory
        nuDir = os.getcwd()
        while os.path.basename(nuDir) != 'Northwestern-RIC':
            nuDir = os.path.dirname(nuDir)
        self.subDir = os.path.join(nuDir,'Modeling','OpenSim','Subjects',subID)+'\\'
        # Static pose trial
        self.trialName = self.subID+'_0_StaticPose'

    """------------------------------------------------------------"""
    def executeShell(self):
        """
        Run the tool via the command prompt.
        """
        # Open subprocess in current directory
        subprocess.Popen(('scale -S '+self.trialName+'__Setup_Scale.xml > '+self.subDir+self.trialName+'_Scale.log'),
                         shell=True, cwd=self.subDir)

    """------------------------------------------------------------"""
    def checkIfDone(self):
        """
        Check if the simulation is finished.
        """
        # Starting time
        startTime = time.time()
        while True:
            # Check for simulation result file
            if os.access(self.subDir+self.subID+'.osim',os.F_OK):
                time.sleep(1)
                break
            # Throw an error and exit the program if simulation is not finished after 2 minutes
            elif (time.time()-startTime) > 120:
                print ('Check status of '+self.subID+' scaling.')
                sys.exit()
            # Wait
            else:
                time.sleep(1)

    """------------------------------------------------------------"""
    def cleanUp(self):
        """
        Delete unnecessary files created during the simulation run.
        """
        try:
            # Delete
            os.remove(self.subDir+'TempScaled.osim')
            os.remove(self.subDir+'err.log')
            os.remove(self.subDir+'out.log')
        except:
            pass

    """------------------------------------------------------------"""
    def run(self):
        """
        Main program to run the tool.
        """
        self.executeShell()
        self.checkIfDone()
        self.cleanUp()

# ####################################################################

class ikin:
    """
    A class to run the IK (inverse kinematics) tool using an existing
    Setup file for all trials for a given subject.
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
        # All IK Setup files for the subject
        self.setupPaths = glob.glob(self.subDir+self.subID+'*__Setup_IK.xml')

    """------------------------------------------------------------"""
    def executeShell(self,trialName):
        """
        Run the tool via the command prompt.
        """
        # Open subprocess in current directory
        subprocess.Popen(('ik -S '+trialName+'__Setup_IK.xml > '+self.subDir+trialName+'_IK.log'),
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
            if os.access(self.subDir+trialName+'_IK.mot',os.F_OK):
                time.sleep(1)
                break
            # Throw an error and exit the program if simulation is not finished after 2 minutes
            elif (time.time()-startTime) > 120:
                print ('Check status of '+trialName+' IK.')
                sys.exit()
            # Wait
            else:
                time.sleep(1)

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

# ####################################################################

class idyn:
    """
    A class to run the ID (inverse dynamics) tool using an existing
    Setup file for all trials for a given subject.
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
        # All ID Setup files for the subject
        self.setupPaths = glob.glob(self.subDir+self.subID+'*__Setup_ID.xml')

    """------------------------------------------------------------"""
    def executeShell(self,trialName):
        """
        Run the tool via the command prompt.
        """
        # Open subprocess in current directory
        subprocess.Popen(('id -S '+trialName+'__Setup_ID.xml > '+self.subDir+trialName+'_ID.log'),
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
            if os.access(self.subDir+trialName+'_ID.sto',os.F_OK):
                time.sleep(1)
                break
            # Throw an error and exit the program if simulation is not finished after 2 minutes
            elif (time.time()-startTime) > 120:
                print ('Check status of '+trialName+' ID.')
                sys.exit()
            # Wait
            else:
                time.sleep(1)

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

# ####################################################################

class rra:
    """
    A class to run the RRA tool using an existing Setup file for all
    trials for a given subject.
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
        # All RRA Setup filse for the subject
        self.setupPaths = glob.glob(self.subDir+self.subID+'*__Setup_RRA.xml')

    """------------------------------------------------------------"""
    def executeShell(self,trialName):
        """
        Run the tool via the command prompt.
        """
        # Open subprocess in current directory
        subprocess.Popen(('rra -S '+trialName+'__Setup_RRA.xml > '+self.subDir+trialName+'_RRA.log'),
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
            if os.access(self.subDir+trialName+'_RRA_controls.xml',os.F_OK):
                time.sleep(1)
                break
            # Timeout after 2 minutes and display a message to the user
            elif (time.time()-startTime) > 120:
                print ('Check status of '+trialName+'_RRA.')
            # Wait
            else:
                time.sleep(5)

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

# ####################################################################

class cmc:
    """
    A class to run the CMC tool using an existing Setup file for all
    trials for a given subject.
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
        # Check if RRA run has been completed; then run CMC
        if os.path.exists(self.subDir+trialName+'_RRA_Kinematics_q.sto'):
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
