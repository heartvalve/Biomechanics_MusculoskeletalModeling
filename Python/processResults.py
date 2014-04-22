"""
----------------------------------------------------------------------
    processResults.py
----------------------------------------------------------------------

----------------------------------------------------------------------
    Created by Megan Schroeder
    Last Modified: 2013-09-04
----------------------------------------------------------------------
"""


# Imports
import os
import re
import linecache
import time
from xml.dom.minidom import parse
from multiprocessing import Pool
from collections import defaultdict

import numpy as np
#import matplotlib.pyplot as plt
from scipy.interpolate import InterpolatedUnivariateSpline


"""*******************************************************************
*                   General Functions                                *
*******************************************************************"""

def get_subjectDir(subID):

    # Subject directory
    nuDir = os.getcwd()
    while os.path.basename(nuDir) != 'Northwestern-RIC':
        nuDir = os.path.dirname(nuDir)
    subDir = os.path.join(nuDir, 'Modeling', 'OpenSim', 'Subjects', subID) + '\\'
    return subDir


def get_modelAndMuscles(subID):

    # Generic model
    dom = parse(get_subjectDir(subID) + subID + '_0_StaticPose__Setup_Scale.xml')
    modelFullPath = dom.getElementsByTagName('model_file')[0].firstChild.nodeValue
    model = os.path.splitext(os.path.basename(modelFullPath))[0]
    # Muscle forces
    if model == 'gait2392':
        muscles = ['vas_med','vas_lat','vas_int','rect_fem',
                   'semimem','semiten','bifemlh','bifemsh',
                   'med_gas','lat_gas']
    else:
        muscles = ['vasmed','vaslat','vasint','recfem',
                   'semimem','semiten','bflh','bfsh',
                   'gasmed','gaslat']
    return model, muscles


def readData(filePath, hLines):

    # Names
    dataTxt = linecache.getline(filePath, hLines)
    names = dataTxt.rstrip().split('\t')
    linecache.clearcache()
    # Data
    data = np.loadtxt(filePath, skiprows=hLines)
    dataList = [data[:,col] for col in range(np.size(data, axis=1))]
    return names, dataList


"""*******************************************************************
*                   Process OpenSim Results                          *
*******************************************************************"""

class TRC:

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

# ####################################################################

class GRF:

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
        names = [re.sub(r'GROUND_TORQUE([LR])_([XYZ])', r'\1M\2', hStr) for hStr in newNames]
        # Read grf data
        grfData = np.loadtxt(grfPath, skiprows=14)
        # Sample time
        self.sampleTime = grfData[:,0]
        # Data
        grfData = np.delete(grfData, 0, 1)
        # Replace zeros with NaN in COP
        rCOP = ['RCX','RCY','RCZ']
        rZeroInd = grfData[:,names.index('RCX')] == 0
        for cop in rCOP:
            grfData[rZeroInd,names.index(cop)] = np.nan
        lCOP  = ['LCX','LCY','LCZ']
        lZeroInd = grfData[:,names.index('LCX')] == 0
        for cop in lCOP:
            grfData[lZeroInd,names.index(cop)] = np.nan
        # Convert to list of columns
        dataList = [grfData[:,col] for col in range(np.size(grfData, axis=1))]
        # Assign data
        self.data = dict(zip(names,dataList))

# ####################################################################

class IK:

    def __init__(self, subID, simName):

        # IK path
        ikPath = get_subjectDir(subID) + subID + '_' + simName + '_IK.mot'
        # Get DOF names
        dofTxt  = linecache.getline(ikPath, 11)
        names = dofTxt.rstrip().split('\t')[1:]
        linecache.clearcache()
        # Read data
        dofData = np.loadtxt(ikPath, skiprows=11)
        # Time
        self.time = dofData[:,0]
        # Data
        dataList = [dofData[:,col] for col in range(1,np.size(dofData, axis=1))]
        self.data = dict(zip(names,dataList))

# ####################################################################

class ID:

    def __init__(self, subID, simName):

        # ID path
        idPath = get_subjectDir(subID) + subID + '_' + simName + '_ID.sto'
        # Get DOF names
        dofTxt  = linecache.getline(idPath, 7)
        names = dofTxt.rstrip().split('\t')[1:]
        linecache.clearcache()
        # Read data
        dofData = np.loadtxt(idPath, skiprows=7)
        # Time
        self.time = dofData[:,0]
        # Data
        dataList = [dofData[:,col] for col in range(1,np.size(dofData, axis=1))]
        self.data = dict(zip(names,dataList))

# ####################################################################

class RRAsuper:

    def __init__(self, rraPath):

        try:
            # Actuators
            fNames, fDataList = readData(rraPath + '_Actuation_force.sto', 23)
            self.actuationForce = dict(zip(fNames,fDataList))
            # Controls
            cNames, cDataList = readData(rraPath + '_controls.sto', 7)
            self.controls = dict(zip(cNames,cDataList))
            # Kinematics
            qNames, qDataList = readData(rraPath + '_Kinematics_q.sto', 11)
            self.kinematicsCoordinate = dict(zip(qNames,qDataList))
            uNames, uDataList = readData(rraPath + '_Kinematics_u.sto', 11)
            self.kinematicsSpeed = dict(zip(uNames,uDataList))
            dNames, dDataList = readData(rraPath + '_Kinematics_dudt.sto', 11)
            self.kinematicsAcceleration = dict(zip(dNames,dDataList))
            # Position Error
            pNames, pDataList = readData(rraPath + '_pErr.sto', 7)
            self.positionError = dict(zip(pNames,pDataList))
            # States
            sNames, sDataList = readData(rraPath + '_states.sto', 7)
            self.states = dict(zip(sNames,sDataList))
        except:
            print 'Unable to find file(s) in ' + rraPath

# ####################################################################

class RRA(RRAsuper):

    def __init__(self, subID, simName):

        # RRA path (excluding extension)
        rraPath = get_subjectDir(subID) + subID + '_' + simName + '_RRA'
        # Create instance of class from superclass
        RRAsuper.__init__(self, rraPath)
        # Actuators (currently not working for CMC)
        sNames, sDataList = readData(rraPath + '_Actuation_speed.sto', 23)
        self.actuationSpeed = dict(zip(sNames,sDataList))
        pNames, pDataList = readData(rraPath + '_Actuation_power.sto', 23)
        self.actuationPower = dict(zip(pNames,pDataList))

# ####################################################################

class CMC(RRAsuper):

    def __init__(self, subID, simName):

        # CMC path (excluding extension)
        cmcPath = get_subjectDir(subID) + subID + '_' + simName + '_CMC'
        # Create instance of class from superclass
        RRAsuper.__init__(self, cmcPath)

"""*******************************************************************
*                   Simulation                                       *
*******************************************************************"""

class Simulation:

    """
    - when modifying a view, the original array is modified as well -- transpose is a 'view'
    - 'fancy indexing' creates copies not views
    - flattening an array: 'ravel' method
    - masked arrays for missing data (instead of using NaN for example)
    """


    def __init__(self, subID, simName):

        # Subject ID
        self.subID = subID
        # Subject directory
        self.subDir = get_subjectDir(subID)
        # Simulation name (without subject ID)
        self.simName = simName
        # Model name and muscles
        model, muscles = get_modelAndMuscles(subID)
        self.model = model
        self.muscles = muscles
        # Leg
        simLeg = simName[0]
        if subID[10] == 'N' or subID[10] == 'R':
            if simLeg == 'A':
                self.leg = 'r'
            else:
                self.leg = 'l'
        elif subID[10] == 'L':
            if simLeg == 'A':
                self.leg = 'l'
            else:
                self.leg = 'r'
        # TRC
        self.trc = TRC(subID, simName)
        # GRF
        self.grf = GRF(subID, simName)
        # IK
        self.ik = IK(subID, simName)
        # ID
        self.id = ID(subID, simName)
        # RRA
        self.rra = RRA(subID, simName)
        # CMC
        self.cmc = CMC(subID, simName)
        # Muscle forces
        try:
            musclesWithLeg = [muscle + '_' + self.leg for muscle in self.muscles]
            fullTime = self.cmc.actuationForce['time']
            forceData = np.zeros((101,len(self.muscles)+1))
            forceData[:,0] = np.arange(101)
            forceNames = ['percentCycle']
            for (i,mLabel) in enumerate(musclesWithLeg):
                mFullData = self.cmc.actuationForce[mLabel]
                cycleTimeNorm = np.linspace(self.grf.cycleTime[0], self.grf.cycleTime[1], 101)
                sInterp = InterpolatedUnivariateSpline(fullTime, mFullData)
                mData = sInterp(cycleTimeNorm)
                forceData[:,i+1] = mData
                forceNames.append(mLabel[:-2])
            forceDataList = [forceData[:,col] for col in range(np.size(forceData, axis=1))]
            self.muscleForces = dict(zip(forceNames,forceDataList))
        except:
            print 'Check CMC results for ' + self.subID + '_' + self.simName

"""*******************************************************************
*                   Subject                                          *
*******************************************************************"""

def runParallel(simFullName):

    # Extract subject ID
    subID = simFullName.split('_')[0]
    # Extract simulation descriptor
    simName = simFullName.split('_', 1)[1]
    # Create simulation object
    simObj = Simulation(subID, simName)
    # Return
    return simObj

# ####################################################################

simObjList = []
 
def initializeSimList():
    
    global simObjList
    simObjList = []
    
# ####################################################################
 
def updateSimList(simObj):
    
    global simObjList
    simObjList.append(simObj)
    
# ####################################################################

class Subject:

    def __init__(self, subID):

        # Start time
        self.startTime = time.time()
        # Subject ID
        self.subID = subID
        # Subject directory
        self.subDir = get_subjectDir(subID)

# ####################################################################

class SubjectNoStairs(Subject):

    def __init__(self, subID):
     
        # Create instance of class from superclass
        Subject.__init__(self, subID)        
        # Simulation descriptors
        simDescriptors = ['A_SD2F_RepGRF', 'A_SD2F_RepKIN', 'A_Walk_RepGRF', 'A_Walk_RepKIN', 
                          'U_SD2F_RepGRF', 'U_SD2F_RepKIN', 'U_Walk_RepGRF', 'U_Walk_RepKIN']
        # List of simulation names
        simNames = [subID + '_' + descriptor for descriptor in simDescriptors]
        # Initialize global variable for simulation objects
        initializeSimList()
        # Start worker pool
        pool = Pool(processes=8)
        # Run parallel processes to process simulations and append object to global list
        pool.map_async(runParallel, simNames, callback=updateSimList)
        # Clean up spawned processes
        pool.close()
        pool.join()
        # Add simulations as attributes to subject object
        for simObj in simObjList[0]:
            setattr(self, simObj.simName, simObj)
        # Display message to user
        print 'Time elapsed for processing subject ' + self.subID + ': ' + str(int(time.time()-self.startTime)) + ' seconds'

# ####################################################################

class SubjectWithStairs(Subject):

    def __init__(self, subID):

        """
        THINGS TO UNDERSTAND:
        - when adding simulation attributes, why is the list nested (need to call simObjList[0])??
        """        
        
        # Create instance of class from superclass
        Subject.__init__(self, subID)
        # Prepare to process in parallel
        # Simulation descriptors
        simDescriptors = ['A_SD2F_RepGRF', 'A_SD2F_RepKIN', 'A_SD2S_RepGRF', 'A_SD2S_RepKIN',
                          'A_Walk_RepGRF', 'A_Walk_RepKIN', 'U_SD2F_RepGRF', 'U_SD2F_RepKIN',
                          'U_SD2S_RepGRF', 'U_SD2S_RepKIN', 'U_Walk_RepGRF', 'U_Walk_RepKIN']
        # List of simulation names
        simNames = [subID + '_' + descriptor for descriptor in simDescriptors]
        # Initialize global variable for simulation objects
        initializeSimList()
        # Start worker pool
        pool = Pool(processes=12)
        # Run parallel processes to process simulations and append object to global list
        pool.map_async(runParallel, simNames, callback=updateSimList)
        # Clean up spawned processes
        pool.close()
        pool.join()
        # Add simulations as attributes to subject object
        for simObj in simObjList[0]:
            setattr(self, simObj.simName, simObj)
        # Display message to user
        print 'Time elapsed for processing subject ' + self.subID + ': ' + str(int(time.time()-self.startTime)) + ' seconds'

"""*******************************************************************
*                   Group                                            *
*******************************************************************"""

class Group:

    def __init__(self):

        # Group info, cycles, summary
        
        
        # Identify the group attributes that are 'Subjects' and put in a list
        subjectObjs = []
        for key, value in self.__dict__.iteritems():
            if 'Subject' in value.__class__.__name__:
                subjectObjs.append(getattr(self, key))
        # Sort subject list by subject ID     
        subjectObjs = sorted(subjectObjs, key=lambda subjectObj: subjectObj.subID) 
        # All possibilities of cycle types
        cycleNames = ['A_SD2F','A_SD2S','A_Walk','U_SD2F','U_SD2S','U_Walk']
        # Create a nested dictionary
        cycleDict = defaultdict(dict)
        
        """
        THINGS TO CHECK IN DOCUMENTATION
        - method to append(?) an array to an existing array along a specific dimension
        - include percent cycle to mean and standard deviation record arrays
        - better way to make record array, rather than converting to list of columns??
        - should i use record arrays at all, or switch to dictionaries?? -- speed consideration??
        """
        
        # Loop through cycles
        for cycle in cycleNames:
            # Initialize empty 3d array        
            allData = np.zeros((101, 10, len(subjectObjs)*2))
            # Loop through subjects
            indToRemove = []            
            for (i,subjectObj) in enumerate(subjectObjs):                
                try:
                    sortedMuscles = getattr(subjectObj, cycle + '_RepGRF').muscles                
                    for (j,mLabel) in enumerate(sortedMuscles):                        
                        allData[:,j,2*i] = getattr(subjectObj, cycle + '_RepGRF').muscleForces[mLabel]
                except:                    
                    allData[:,j,2*i] = np.nan
                    #indToRemove.append(2*i)
                    print 'Problem with ' + subjectObj.subID + '_' + cycle + '_RepGRF'                         
                try:
                    sortedMuscles = getattr(subjectObj, cycle + '_RepKIN').muscles                  
                    for (j,mLabel) in enumerate(sortedMuscles):                        
                        allData[:,j,2*i+1] = getattr(subjectObj, cycle + '_RepKIN').muscleForces[mLabel]
                except:
                    allData[:,j,2*i+1] = np.nan
                    #indToRemove.append(2*i+1)
                    print 'Problem with ' + subjectObj.subID + '_' + cycle + '_RepKIN'
            """
            # Remove bad subjects
            if len(indToRemove) > 0:
                indToRemove.reverse()
                for i in indToRemove:
                    del allData[:,:,i]
            """
            # Calculate average along third dimension of array (axis 2) for all muscles
            meanData = np.mean(allData, axis=2)
            # Convert to a list of individual columns
            meanDataList = [meanData[:,col] for col in range(np.size(meanData, axis=1))]
            # Calculate standard deviation along third dimension of array (axis 2) for all muscles
            stdevData = np.std(allData, axis=2)
            # Convert to a list of individual columns
            stdevDataList = [stdevData[:,col] for col in range(np.size(stdevData, axis=1))]    
            # Get names of muscles
            forceNames = getattr(subjectObj, cycle + '_RepGRF').muscles
            # Add to nested dictionary first by cycle type
            cycleDict[cycle]['mean'] = dict(zip(forceNames,meanDataList))
            cycleDict[cycle]['stdev'] = dict(zip(forceNames,stdevDataList))
        # Assign summary attribute    
        self.summary = cycleDict
        # Display message to user
        print 'Time elapsed for processing group ' + self.__class__.__name__[:-5] + ': ' + str(int(time.time()-self.startTime)) + ' seconds'

# ####################################################################

class ControlGroup(Group):

    def __init__(self):

        # Start time
        self.startTime = time.time()
        # Add subjects
        #self.x20110622CONM = SubjectNoStairs('20110622CONM')
        #self.x20110927CONM = SubjectNoStairs('20110927CONM')
        #self.x20120306CONF = SubjectNoStairs('20120306CONF')
        self.x20121204CONF = SubjectWithStairs('20121204CONF')
        self.x20121205CONF = SubjectWithStairs('20121205CONF')
        self.x20121205CONM = SubjectWithStairs('20121205CONM')
        self.x20121206CONF = SubjectWithStairs('20121206CONF')
        self.x20130221CONF = SubjectWithStairs('20130221CONF')
        self.x20130401CONM = SubjectWithStairs('20130401CONM')
        # Add generic group attributes
        Group.__init__(self)

# ####################################################################

class HamstringGroup(Group):

    def __init__(self):

        # Start time
        self.startTime = time.time()
        # Add subjects
        #self.x20111130AHLM = SubjectNoStairs('20111130AHLM')
        #self.x20120306AHRF = SubjectNoStairs('20120306AHRF')
        #self.x20120313AHLM = SubjectNoStairs('20120313AHLM')
        #self.x20120403AHLF = SubjectNoStairs('20120403AHLF')
        self.x20120912AHRF = SubjectWithStairs('20120912AHRF')
        self.x20120922AHRM = SubjectWithStairs('20120922AHRM')
        self.x20121008AHRM = SubjectWithStairs('20121008AHRM')
        self.x20121108AHRM = SubjectWithStairs('20121108AHRM')
        self.x20121110AHRM = SubjectWithStairs('20121110AHRM')
        self.x20130401AHLM = SubjectWithStairs('20130401AHLM')
        # Add generic group attributes
        Group.__init__(self)

# ####################################################################

class PatellaGroup(Group):

    def __init__(self):

        # Start time
        self.startTime = time.time()
        # Add subjects
        #self.x20110706APRF = SubjectNoStairs('20110706APRF')
        #self.x20111025APRM = SubjectNoStairs('20111025APRM')
        self.x20120919APLF = SubjectWithStairs('20120919APLF')
        self.x20120920APRM = SubjectWithStairs('20120920APRM')
        self.x20121204APRM = SubjectWithStairs('20121204APRM')
        #self.x20130207APRM = SubjectWithStairs('20130207APRM')
        # Add generic group attributes
        Group.__init__(self)

"""*******************************************************************
*                   Summary                                          *
*******************************************************************"""

class SummaryOpenSim:

    def __init__(self):
    
        # Start time
        self.startTime = time.time()
        # Add groups
        self.Control = ControlGroup()        
        self.HamstringACL = HamstringGroup()
        self.PatellaACL = PatellaGroup()
        # Summary information


        
"""*******************************************************************
*                                                                    *
*                   Script Execution                                 *
*                                                                    *
*******************************************************************"""
if __name__ == '__main__':
    # Create instance of class
    #simData = Simulation('20130221CONF', 'A_Walk_RepGRF')
    #subData = SubjectWithStairs('20130221CONF')
    groupData = ControlGroup()
    #data = SummaryOpenSim()

