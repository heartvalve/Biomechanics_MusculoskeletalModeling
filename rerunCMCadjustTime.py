


# ####################################################################
#                                                                    #
#                   Input                                            #
#                                                                    #
# ####################################################################
# Subject ID
subID = '20121204CONF'
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
    
    """
    
    def __init__(self,subID):
        self.subID = subID
        nuDir = os.getcwd()
        while os.path.basename(nuDir) != 'Northwestern-RIC':
            nuDir = os.path.dirname(nuDir)
        self.subDir = os.path.join(nuDir,'Modeling','OpenSim','Subjects',subID)+'\\'
        self.setupPaths = glob.glob(self.subDir+self.subID+'*__Setup_CMC.xml')
    
    """------------------------------------------------------------"""    
    def updateTime(self,trialName):
        # Read log file
        logFile = open(self.subDir+trialName+'_CMC.log','r')
        logList = logFile.readlines()
        logFile.close()
        # Determine time of failure
        for n in range(-7,0):
            if 'could not find a solution' in logList[n]:
                crashTime = float(logList[n].strip('.\n').split('= ')[1])
                lastOptimizerTime = crashTime-0.001
                break
        # Read mot file to get ending time of cycle
        motLine = linecache.getline(self.subDir+trialName+'_GRF.mot',11)
        lastCycleTime = float(motLine.split('\t')[-1].strip())
        # Continue to update if the whole cycle will be solved
        if lastOptimizerTime >= lastCycleTime:
            status = 'continue'        
            setupTime = str(crashTime+0.009)
            # Update XML
            dom = parse(self.subDir+trialName+'__Setup_CMC.xml')
            dom.getElementsByTagName('final_time')[0].firstChild.nodeValue = setupTime
            xmlString = dom.toxml('UTF-8')
            xmlFile = open(xmlFilePath,'w')
            xmlFile.write(xmlString)
            xmlFile.close()
        else:
            status = 'stop'        
        return status
    
    
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
        # Only continue if CMC run crashed
        if not os.path.exists(self.subDir+trialName+'_CMC_Kinematics_q.sto') and os.path.exists(self.subDir+trialName+'_RRA_Kinematics_q.sto'):
            status = self.updateTime(trialName)
            # Only run if it crashed near the end of the simulation
            if status == 'continue':
                self.executeShell(trialName)
                self.checkIfDone(trialName)
                self.cleanUp()
            else:
                print ('Manually check the status of '+trialName)
    
    """------------------------------------------------------------"""    
    def run(self):
        for setupPath in self.setupPaths:
            setupFileName = os.path.basename(setupPath)
            trialName = setupFileName.split('__Setup_')[0]
            self.runTrial(trialName)

            
            
"""*******************************************************************
*                                                                    *
*                   Script Execution                                 *
*                                                                    *
*******************************************************************"""
if __name__ == '__main__':
    # Create instance of class
    rCMC = rerunCMC(subID)
    # Run code
    rCMC.run()   
