import os
import re
import linecache
import time

#import pandas as pd
import numpy as np
import matplotlib.pyplot as plt




def get_subjectDir(subID):

    # Subject directory
    nuDir = os.getcwd()
    while os.path.basename(nuDir) != 'Northwestern-RIC':
        nuDir = os.path.dirname(nuDir)
    subDir = os.path.join(nuDir, 'Modeling', 'OpenSim', 'Subjects', subID) + '\\'
    return subDir

    
def readData(filePath, hLines):           
    # Names
    dataTxt = linecache.getline(filePath, hLines)
    names = dataTxt.rstrip().split('\t')
    nameStr = (',').join(names)
    linecache.clearcache()
    # Data
    data = np.loadtxt(filePath, skiprows=hLines)
    dataList = [data[:,col] for col in range(np.size(data, axis=1))]
    return nameStr, dataList

        
class trc:

    def __init__(self, subID, simName):
    
        # TRC path
        trcPath = get_subjectDir(subID) + subID + '_' + simName + '.trc'
        # Get marker names
        markerTxt = linecache.getline(trcPath, 4)
        self.names = markerTxt.rstrip().split('\t')[2::3]
        linecache.clearcache()
        # Read marker data 
        markerData = np.loadtxt(trcPath, skiprows=6)
        # Frame numbers
        self.frameNum = markerData[:,0]
        # Time
        self.frameTime = markerData[:,1]
        # X data
        self.x = markerData[:,2::3]
        # Y data
        self.y = markerData[:,3::3]
        # Z data
        self.z = markerData[:,4::3]

   
class grf:

    def __init__(self, subID, simName):
    
        # GRF path
        grfPath = get_subjectDir(subID) + subID + '_' + simName + '_GRF.mot'
        # Get header information
        grfFile = open(grfPath,'r')
        grfList = grfFile.readlines()
        grfFile.close()
        # Cycle frames
        self.cycleFrames = map(int, grfList[8].rstrip().split('\t')[1:])
        # Cycle samples
        self.cycleSamples = map(int, grfList[9].rstrip().split('\t')[1:])
        # Cycle time
        self.cycleTime = map(float, grfList[10].rstrip().split('\t')[1:])
        # Column headers
        colHeads = [hStr.upper() for hStr in grfList[13].rstrip().split('\t')[1:]]        
        newNames = [re.sub(r'GROUND_FORCE([LR])_V([XYZ])', r'\1F\2', hStr) for hStr in colHeads]
        newNames = [re.sub(r'GROUND_FORCE([LR])_P([XYZ])', r'\1C\2', hStr) for hStr in newNames]
        self.names = [re.sub(r'GROUND_TORQUE([LR])_([XYZ])', r'\1M\2', hStr) for hStr in newNames]
        # Read grf data
        grfData = np.loadtxt(grfPath, skiprows=14)
        # Sample time
        self.sampleTime = grfData[:,0]
        # Data
        grfData = np.delete(grfData, 0, 1)
        # Replace zeros with NaN in COP
        rCOP = ['RCX','RCY','RCZ']
        rZeroInd = grfData[:,self.names.index('RCX')] == 0
        for cop in rCOP:
            grfData[rZeroInd,self.names.index(cop)] = np.nan
        lCOP  = ['LCX','LCY','LCZ']
        lZeroInd = grfData[:,self.names.index('LCX')] == 0
        for cop in lCOP:
            grfData[lZeroInd,self.names.index(cop)] = np.nan
        # Assign data
        self.data = grfData

        
class ik:

    def __init__(self, subID, simName):
    
        # IK path
        ikPath = get_subjectDir(subID) + subID + '_' + simName + '_IK.mot'
        # Get DOF names
        dofTxt  = linecache.getline(ikPath, 11)
        self.names = dofTxt.rstrip().split('\t')[1:]
        linecache.clearcache()
        # Read data
        dofData = np.loadtxt(ikPath, skiprows=11)
        # Time
        self.time = dofData[:,0]
        # Data
        self.data = dofData[:,1:]
        
        
class id:

    def __init__(self, subID, simName):
        
        # ID path
        idPath = get_subjectDir(subID) + subID + '_' + simName + '_ID.sto'
        # Get DOF names
        dofTxt  = linecache.getline(idPath, 7)
        self.names = dofTxt.rstrip().split('\t')[1:]
        linecache.clearcache()
        # Read data
        dofData = np.loadtxt(idPath, skiprows=7)
        # Time
        self.time = dofData[:,0]
        # Data
        self.data = dofData[:,1:]
        
    
class rra_super:

    def __init__(self, rraPath):

        # Actuators
        fNames, fDataList = readData(rraPath + '_Actuation_force.sto', 23)
        self.actuationForce = np.core.records.fromarrays(fDataList, names=fNames)
        #sNames, sDataList = readData(rraPath + '_Actuation_speed.sto', 23)
        #self.actuationSpeed = np.core.records.fromarrays(sDataList, names=sNames)
        #pNames, pDataList = readData(rraPath + '_Actuation_power.sto', 23)
        #self.actuationPower = np.core.records.fromarrays(pDataList, names=pNames)
        # Controls
        cNames, cDataList = readData(rraPath + '_controls.sto', 7)
        self.controls = np.core.records.fromarrays(cDataList, names=cNames)
        # Kinematics
        qNames, qDataList = readData(rraPath + '_Kinematics_q.sto', 11)
        self.kinematicsCoordinate = np.core.records.fromarrays(qDataList, names=qNames)
        uNames, uDataList = readData(rraPath + '_Kinematics_u.sto', 11)
        self.kinematicsSpeed = np.core.records.fromarrays(uDataList, names=uNames)
        dNames, dDataList = readData(rraPath + '_Kinematics_dudt.sto', 11)
        self.kinematicsAcceleration = np.core.records.fromarrays(dDataList, names=dNames)
        # Position Error
        pNames, pDataList = readData(rraPath + '_pErr.sto', 7)
        self.positionError = np.core.records.fromarrays(pDataList, names=pNames)
        # States
        sNames, sDataList = readData(rraPath + '_states.sto', 7)
        self.states = np.core.records.fromarrays(sDataList, names=sNames)

        
class rra(rra_super):

    def __init__(self, subID, simName):
        
        # RRA path (excluding extension)
        rraPath = get_subjectDir(subID) + subID + '_' + simName + '_RRA'
        # Create instance of class from superclass
        rra_super.__init__(self, rraPath)

  
class cmc(rra_super):

    def __init__(self, subID, simName):

        # CMC path (excluding extension)
        cmcPath = get_subjectDir(subID) + subID + '_' + simName + '_CMC'
        # Create instance of class from superclass
        rra_super.__init__(self, cmcPath)
    
    
        


class simulation:
    """
    
    """
    
    def __init__(self, subID, simName):
        
        # Subject ID
        self.subID = subID
        # Subject directory
        self.subDir = get_subjectDir(subID)
        # Simulation name (without subject ID)
        self.simName = simName
        # TRC
        self.trc = trc(subID, simName)
        # GRF
        self.grf = grf(subID, simName)
        # IK
        self.ik = ik(subID, simName)
        # ID
        self.id = id(subID, simName)
        # RRA
        self.rra = rra(subID, simName)
        # CMC
        self.cmc = cmc(subID, simName)
    
    
    """------------------------------------------------------------"""
    def plotResiduals(self):
        
        fig = plt.figure(figsize=(12,8), dpi=80)
        forces = ('FX','MX','FY','MY','FZ','MZ')
        for (i,fLabel) in enumerate(forces):
            ax = fig.add_subplot(3,2,i+1)
            ax.plot(self.rra.actuationForce.time, self.rra.actuationForce[forces[i]], color='blue', linewidth=2.5, linestyle='-', label=fLabel)
            ax.spines['right'].set_color('none')
            ax.spines['top'].set_color('none')
            ax.xaxis.set_ticks_position('bottom')
            ax.yaxis.set_ticks_position('left')
            
            plt.xlim(self.rra.actuationForce.time.min(), self.rra.actuationForce.time.max())            
            
            # p = plt.axhspan(0.25, 0.75, facecolor='0.5', alpha=0.5)
            
            ax.axhline(color='black')
            ax.axvline(x=self.grf.cycleTime[0], color='black')
            ax.axvline(x=self.grf.cycleTime[1], color='black')            
        plt.show()
    


class subject:
    """
    
    """
    
    def __init__(self, subID):
        
        # Subject ID
        self.subID = subID
        # Subject directory
        self.subDir = get_subjectDir(subID)
        # Start time
        self.startTime = time.time()


class subject_withStairs(subject):

    def __init__(self, subID):
        
        subject.__init__(self, subID)
        self.A_SD2F_RepGRF = simulation(subID, 'A_SD2F_RepGRF')
        self.A_SD2F_RepKIN = simulation(subID, 'A_SD2F_RepKIN')
        self.A_SD2S_RepGRF = simulation(subID, 'A_SD2S_RepGRF')
        self.A_SD2S_RepKIN = simulation(subID, 'A_SD2S_RepKIN')
        self.A_Walk_RepGRF = simulation(subID, 'A_Walk_RepGRF')
        self.A_Walk_RepKIN = simulation(subID, 'A_Walk_RepKIN')
        self.U_SD2F_RepGRF = simulation(subID, 'U_SD2F_RepGRF')
        self.U_SD2F_RepKIN = simulation(subID, 'U_SD2F_RepKIN')
        self.U_SD2S_RepGRF = simulation(subID, 'U_SD2S_RepGRF')
        self.U_SD2S_RepKIN = simulation(subID, 'U_SD2S_RepKIN')
        self.U_Walk_RepGRF = simulation(subID, 'U_Walk_RepGRF')
        self.U_Walk_RepKIN = simulation(subID, 'U_Walk_RepKIN')
        print('Time elapsed: ' + str(int(time.time()-self.startTime)) + ' seconds')
    
    

class x20130221CONF(subject_withStairs):

    def __init__(self):
    
        subject_withStairs.__init__(self, '20130221CONF')
        
        
        

"""
class group:

"""


if __name__ == '__main__':    
    plt.close('all')
    # Create instance of class
    test = x20130221CONF()
    test.A_Walk_RepGRF.plotResiduals()
    

