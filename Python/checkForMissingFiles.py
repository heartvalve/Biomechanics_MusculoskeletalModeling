"""
----------------------------------------------------------------------
    checkForMissingFiles.py
----------------------------------------------------------------------
    This class...

    Input:
        Subject ID
    Output:
        Print out of missing files
----------------------------------------------------------------------
    Created by Megan Schroeder
    Last Modified 2014-01-17
----------------------------------------------------------------------
"""


# ####################################################################
#                                                                    #
#                   Input                                            #
#                                                                    #
# ####################################################################
# Subject ID list
subIDs = ['20130401CONM','20130401AHLM','20130221CONF','20130207APRM',
          '20121206CONF','20121205CONM','20121205CONF','20121204CONF',
          '20121204APRM','20121110AHRM','20121108AHRM','20121008AHRM',
          '20120920APRM','20120919APLF','20120912AHRF']
# '20120922AHRM'
# ####################################################################


# Imports
import os
import os.path
import glob


class checkMissing:
    """
    A class to detect missing OpenSim simulation files for a given
    subject.
    """
    
    def __init__(self,subID):
        """
        Create an instance of the class from the subject ID
        """
        # Subject ID
        self.subID = subID
        # Subject directory
        nuDir = os.getcwd()
        while os.path.basename(nuDir) != 'Northwestern-RIC':
            nuDir = os.path.dirname(nuDir)
        self.subDir = os.path.join(nuDir,'Modeling','OpenSim','Subjects',subID)+'\\'
        # Dynamic TRC paths
        self.trcPaths = glob.glob(self.subDir+self.subID+'_*_*_*.trc')   
    
    """------------------------------------------------------------"""
    def checkExts(self,trialName,exts):
        """
        
        """
        for ext in exts:
            if not os.path.exists(self.subDir+trialName+ext):
                print(trialName+ext+' is missing')
    
    """------------------------------------------------------------"""
    def checkScale(self):
        """
        
        """            
        scaleTrial = self.subID+'_0_StaticPose'
        exts = ['.trc','__Setup_Scale.xml','_Scale.log','_Scale.mot','_ScaleSet.xml']
        self.checkExts(scaleTrial,exts)
        # Scaled model
        if not os.path.exists(self.subDir+self.subID+'.osim'):
            print (self.subID+'.osim is missing')
        
    """------------------------------------------------------------"""
    def checkGRFandEMG(self,trialName):
        """
        
        """
        exts = ['_GRF.mot','_ExternalLoads.xml','_EMG.mot']
        self.checkExts(trialName,exts)
    
    """------------------------------------------------------------"""
    def checkIK(self,trialName):
        """
        
        """
        exts = ['__Setup_IK.xml','_IK.log','_IK.mot']
        self.checkExts(trialName,exts)
        
    """------------------------------------------------------------"""
    def checkID(self,trialName):
        """
        
        """
        exts = ['__Setup_ID.xml','_ID.log','_ID.sto']
        self.checkExts(trialName,exts)
    
    """------------------------------------------------------------"""
    def checkRRA(self,trialName):
        """
        
        """
        exts = ['__Setup_RRA.xml','__Setup_RRA_Iterations.xml','_RRA.log',
                '_RRA__Iterations.data','_RRA_Actuation_force.sto',
                '_RRA_Actuation_power.sto','_RRA_Actuation_speed.sto',
                '_RRA_avgResiduals.txt','_RRA_controls.sto','_RRA_controls.xml',
                '_RRA_Kinematics_dudt.sto','_RRA_Kinematics_q.sto',
                '_RRA_Kinematics_u.sto','_RRA_pErr.sto','_RRA_states.sto']
        self.checkExts(trialName,exts)
        
    """------------------------------------------------------------"""
    def checkCMC(self,trialName):
        """
        
        """
        exts = ['__Setup_CMC.xml','_CMC.log','_CMC_Actuation_force.sto',
                '_CMC_Actuation_power.sto','_CMC_Actuation_speed.sto',
                '_CMC_controls.sto','_CMC_controls.xml',
                '_CMC_Kinematics_dudt.sto','_CMC_Kinematics_q.sto',
                '_CMC_Kinematics_u.sto','_CMC_pErr.sto','_CMC_states.sto']
        self.checkExts(trialName,exts)    
    
    
    """------------------------------------------------------------"""
    def run(self):
        """
        Main program to run
        """
        # Check info
        if not os.path.exists(self.subDir+self.subID+'__PersonalInformation.xml'):
            print (self.subID+'__PersonalInformation.xml is missing')
        # Check scale
        self.checkScale()
        # Loop through dynamic trc files
        for trcPath in self.trcPaths:
            # Identify trial name
            trcFileName = os.path.basename(trcPath)
            trialName = trcFileName.split('.trc')[0]
            # Check GRF's and EMG's
            self.checkGRFandEMG(trialName)
            # Check IK
            self.checkIK(trialName)
            # Check ID
            self.checkID(trialName)
            # Check RRA
            self.checkRRA(trialName)
            # Check CMC
            self.checkCMC(trialName)
        # Finished
        print('*****************************************************************')
       

"""*******************************************************************
*                                                                    *
*                   Script Execution                                 *
*                                                                    *
*******************************************************************"""
if __name__ == '__main__':
    # Loop through subject list
    for subID in subIDs:
        # Create instance of class
        checkSub = checkMissing(subID)
        # Run code
        checkSub.run()
              
