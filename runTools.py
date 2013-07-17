
import os
import glob
import subprocess
import time
import shutil
import sys


class scale:

    def __init__(self,subID):
        self.subID = subID
        nuDir = os.getcwd()
        while os.path.basename(nuDir) != 'Northwestern-RIC':
            nuDir = os.path.dirname(nuDir)
        self.subDir = os.path.join(nuDir,'Modeling','OpenSim','Subjects',subID)+'\\'
        self.trialName = self.subID+'_0_StaticPose'
    
    
    def executeShell(self):
        subprocess.Popen(('scale -S '+self.trialName+'__Setup_Scale.xml > '+self.subDir+self.trialName+'_Scale.log'),
                         shell=True, cwd=self.subDir)
    
    
    def checkIfDone(self):
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
                
    
    def cleanUp(self):
        try:
            os.remove(self.subDir+'TempScaled.osim')
            os.remove(self.subDir+'err.log')
            os.remove(self.subDir+'out.log')
        except:
            pass
    
    
    def run(self):
        self.executeShell()
        self.checkIfDone()
        self.cleanUp()

# ####################################################################        

class ikin:

    def __init__(self,subID):
        self.subID = subID
        nuDir = os.getcwd()
        while os.path.basename(nuDir) != 'Northwestern-RIC':
            nuDir = os.path.dirname(nuDir)
        self.subDir = os.path.join(nuDir,'Modeling','OpenSim','Subjects',subID)+'\\'
        self.setupPaths = glob.glob(self.subDir+self.subID+'*__Setup_IK.xml')
    
    
    def executeShell(self,trialName):
        subprocess.Popen(('ik -S '+trialName+'__Setup_IK.xml > '+self.subDir+trialName+'_IK.log'),
                         shell=True, cwd=self.subDir)
    
    
    def checkIfDone(self,trialName):
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
                

    def cleanUp(self):
        try:
            os.remove(self.subDir+'err.log')
            os.remove(self.subDir+'out.log')
        except:
            pass
        
    
    def runTrial(self,trialName):
        self.executeShell(trialName)
        self.checkIfDone(trialName)
        self.cleanUp()
    
    
    def run(self):
        for setupPath in self.setupPaths:
            setupFileName = os.path.basename(setupPath)
            trialName = setupFileName.split('__Setup_')[0]
            self.runTrial(trialName)

# #################################################################### 
            
class idyn:

    def __init__(self,subID):
        self.subID = subID
        nuDir = os.getcwd()
        while os.path.basename(nuDir) != 'Northwestern-RIC':
            nuDir = os.path.dirname(nuDir)
        self.subDir = os.path.join(nuDir,'Modeling','OpenSim','Subjects',subID)+'\\'
        self.setupPaths = glob.glob(self.subDir+self.subID+'*__Setup_ID.xml')
    
    
    def executeShell(self,trialName):
        subprocess.Popen(('id -S '+trialName+'__Setup_ID.xml > '+self.subDir+trialName+'_ID.log'),
                         shell=True, cwd=self.subDir)
    
    
    def checkIfDone(self,trialName):
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
                

    def cleanUp(self):
        try:
            os.remove(self.subDir+'err.log')
            os.remove(self.subDir+'out.log')
        except:
            pass
        
    
    def runTrial(self,trialName):
        self.executeShell(trialName)
        self.checkIfDone(trialName)
        self.cleanUp()
    
    
    def run(self):
        for setupPath in self.setupPaths:
            setupFileName = os.path.basename(setupPath)
            trialName = setupFileName.split('__Setup_')[0]
            self.runTrial(trialName)
            
# #################################################################### 
        
class rra:
    """
    
    """
    
    def __init__(self,subID):
        self.subID = subID
        nuDir = os.getcwd()
        while os.path.basename(nuDir) != 'Northwestern-RIC':
            nuDir = os.path.dirname(nuDir)
        self.subDir = os.path.join(nuDir,'Modeling','OpenSim','Subjects',subID)+'\\'
        self.setupPaths = glob.glob(self.subDir+self.subID+'*__Setup_RRA.xml')    
    
    """------------------------------------------------------------"""
    def executeShell(self,trialName):
        subprocess.Popen(('rra -S '+trialName+'__Setup_RRA.xml > '+self.subDir+trialName+'_RRA.log'),
                         shell=True, cwd=self.subDir)    
    
    """------------------------------------------------------------"""
    def checkIfDone(self,trialName):
        startTime = time.time()
        while True:
            # Check for simulation result file
            if os.access(self.subDir+trialName+'_RRA_controls.xml',os.F_OK):
                time.sleep(1)
                break            
            # Timeout after 2 minutes and display a message to the user
            elif (time.time()-startTime) > 120:
                print ('Check status of '+trialName+' RRA.')
            # Wait
            else:
                time.sleep(5)
    
    """------------------------------------------------------------"""
    def cleanUp(self):
        try:
            os.remove(self.subDir+'err.log')
            os.remove(self.subDir+'out.log')
        except:
            pass        
    
    """------------------------------------------------------------"""
    def runTrial(self,trialName):
        self.executeShell(trialName)
        self.checkIfDone(trialName)
        self.cleanUp()    
    
    """------------------------------------------------------------"""
    def run(self):
        for setupPath in self.setupPaths:
            setupFileName = os.path.basename(setupPath)
            trialName = setupFileName.split('__Setup_')[0]
            self.runTrial(trialName)
  
# ####################################################################
  
class cmc:
    """
    
    """
    
    def __init__(self,subID):
        self.subID = subID
        nuDir = os.getcwd()
        while os.path.basename(nuDir) != 'Northwestern-RIC':
            nuDir = os.path.dirname(nuDir)
        self.subDir = os.path.join(nuDir,'Modeling','OpenSim','Subjects',subID)+'\\'
        self.setupPaths = glob.glob(self.subDir+self.subID+'*__Setup_CMC.xml')
    
    """------------------------------------------------------------"""    
    def executeShell(self,trialName):
        subprocess.Popen(('cmc -S '+trialName+'__Setup_CMC.xml > '+self.subDir+trialName+'_CMC.log'),
                         shell=True, cwd=self.subDir)
    
    """------------------------------------------------------------"""    
    def checkIfDone(self,trialName):
        startTime = time.time()
        while True:
            # Check for simulation result file
            if os.access(self.subDir+trialName+'_CMC_controls.xml',os.F_OK):
                print (trialName+'_CMC is complete.')
                time.sleep(1)
                break            
            # Exit after 20 minutes
            elif (time.time()-startTime) > 1200:
                break
            # Check the log file after 10 minutes have elapsed
            elif (time.time()-startTime) > 600:
                shutil.copy(self.subDir+trialName+'_CMC.log',self.subDir+'temp.log')
                logFile = open(self.subDir+'temp.log','r')
                logList = logFile.readlines()
                logFile.close()
                os.remove(self.subDir+'temp.log')
                status = 'running'
                for n in range(-10,0):                    
                    if 'FAILED' in logList[n]:                
                        print ('Check status of '+trialName+'_CMC.')
                        status = 'failed'
                        break
                if status == 'failed':
                    break
                else:
                    time.sleep(15)
            # Wait
            else:
                time.sleep(10)
    
    """------------------------------------------------------------"""
    def cleanUp(self):
        try:
            os.remove(self.subDir+'err.log')
            os.remove(self.subDir+'out.log')
        except:
            pass
    
    """------------------------------------------------------------"""    
    def runTrial(self,trialName):
        # Check if RRA run has been completed
        if os.path.exists(self.subDir+trialName+'_RRA_Kinematics_q.sto'):
            self.executeShell(trialName)
            self.checkIfDone(trialName)
            self.cleanUp()
    
    """------------------------------------------------------------"""    
    def run(self):
        for setupPath in self.setupPaths:
            setupFileName = os.path.basename(setupPath)
            trialName = setupFileName.split('__Setup_')[0]
            self.runTrial(trialName)
