

# test.__dict__.keys() -- get attributes


import numpy as np
import matplotlib
import matplotlib.pyplot as plt



def plotResiduals(simulationObj):
    
    fig = plt.figure(figsize=(16,10), dpi=100)
    forces = ('FX','MX','FY','MY','FZ','MZ')
    for (i,fLabel) in enumerate(forces):
        ax = fig.add_subplot(3,2,i+1)
        ax.plot(simulationObj.rra.actuationForce.time, simulationObj.rra.actuationForce[fLabel], color='red', linewidth=2.5, linestyle='-')
        ax.spines['right'].set_color('none')
        ax.spines['top'].set_color('none')
        ax.xaxis.set_ticks_position('bottom')
        ax.yaxis.set_ticks_position('left')
        
        plt.xlim(simulationObj.rra.actuationForce.time.min(), simulationObj.rra.actuationForce.time.max())            
        plt.title(fLabel)
        
        
        ax.axhline(color='black')
        
        #ax.axvline(x=self.grf.cycleTime[0], color='black')
        #ax.axvline(x=self.grf.cycleTime[1], color='black')           
        ax.axvspan(simulationObj.rra.actuationForce.time.min(), simulationObj.grf.cycleTime[0], facecolor='black', alpha=0.85)
        ax.axvspan(simulationObj.grf.cycleTime[1], simulationObj.rra.actuationForce.time.max(), facecolor='black', alpha=0.85)
    
    plt.subplots_adjust(hspace=0.5)        
    plt.show()

# ####################################################################    
    
def plotMuscleForces(simulationObj):

    fig = plt.figure(figsize=(16,10), dpi=100)
    for (i,mLabel) in enumerate(simulationObj.muscles):
    
        mName = mLabel + '_' + simulationObj.leg
        ax = fig.add_subplot(3,4,i+1)
        ax.plot(simulationObj.cmc.actuationForce.time, simulationObj.cmc.actuationForce[mName], color='blue', linewidth=2.5, linestyle='-')
        ax.spines['right'].set_color('none')
        ax.spines['top'].set_color('none')
        ax.xaxis.set_ticks_position('bottom')
        ax.yaxis.set_ticks_position('left')
        
        plt.xlim(simulationObj.cmc.actuationForce.time.min(), simulationObj.cmc.actuationForce.time.max())            
        plt.title(mLabel)
        
        ax.axvspan(simulationObj.cmc.actuationForce.time.min(), simulationObj.grf.cycleTime[0], facecolor='black', alpha=0.85)
        ax.axvspan(simulationObj.grf.cycleTime[1], simulationObj.cmc.actuationForce.time.max(), facecolor='black', alpha=0.85)
        
    plt.subplots_adjust(hspace=0.5)
    # plt.subplots_adjust(wspace=0.5)
    plt.show()
    
# ####################################################################
    
def plotSubjectMuscleForces(subjectObj, simType='Walk'):

    fig = plt.figure(figsize=(16,10), dpi=100)
    
    tempSimulationObj = getattr(subjectObj, 'A_' + simType + '_RepGRF')    
    
    for (i,mLabel) in enumerate(tempSimulationObj.muscles):
    
        ax = fig.add_subplot(3,4,i+1)
                
        u_grf = getattr(subjectObj, 'U_' + simType + '_RepGRF')
        u_kin = getattr(subjectObj, 'U_' + simType + '_RepKIN')
        a_grf = getattr(subjectObj, 'A_' + simType + '_RepGRF')
        a_kin = getattr(subjectObj, 'A_' + simType + '_RepKIN')
                
        # Uninvolved leg (or left leg for controls)
        ax.plot(u_grf.muscleForces.percentCycle, u_grf.muscleForces[mLabel], 
                color='indigo', linewidth=2, linestyle='-', label='Uninvolved')
        ax.plot(u_kin.muscleForces.percentCycle, u_kin.muscleForces[mLabel], 
                color='indigo', linewidth=2, linestyle='--')
        #ax.fill_between(u_grf.muscleForces.percentCycle, u_grf.muscleForces[mLabel], u_kin.muscleForces[mLabel], 
        #                facecolor='indigo', alpha=0.25)
        
        # ACLR leg (or right leg for controls)
        ax.plot(a_grf.muscleForces.percentCycle, a_grf.muscleForces[mLabel], 
                color='green', linewidth=2, linestyle='-', label='ACL-R')
        ax.plot(a_kin.muscleForces.percentCycle, a_kin.muscleForces[mLabel], 
                color='green', linewidth=2, linestyle='--')
        #ax.fill_between(a_grf.muscleForces.percentCycle, a_grf.muscleForces[mLabel], a_kin.muscleForces[mLabel], 
        #                facecolor='green', alpha=0.25)
        
        ax.spines['right'].set_color('none')
        ax.spines['top'].set_color('none')
        ax.xaxis.set_ticks_position('bottom')
        ax.yaxis.set_ticks_position('left')
        
        plt.title(mLabel)
        plt.xlim(0, 100) 
    
    ax.legend(loc='center left', bbox_to_anchor=(1.1, 0.5), fontsize=12)
    plt.subplots_adjust(hspace=0.5)
    plt.subplots_adjust(wspace=0.5)
    plt.show()

# ####################################################################

def plotGroupMuscleForces(groupObj, simType='Walk', cycle='A'):

    font = {'family': 'serif',
            'weight': 'normal',
            'size'  :  12}

    matplotlib.rc('font', **font)
        
    fig = plt.figure(figsize=(16,10), dpi=100)
    colors = ['red','blue','yellow','green','indigo','orange','fuschia','aqua','chartreuse']
    subplots = [None]*10
    
    subjectObjs = []
    for key, value in groupObj.__dict__.iteritems():
        if 'Subject' in value.__class__.__name__:
            subjectObjs.append(getattr(groupObj, key))
    subjectObjs = sorted(subjectObjs, key=lambda subjectObj: subjectObj.subID)
    
    for (i,subjectObj) in enumerate(subjectObjs):
        
        simulationObjGRF = getattr(subjectObj, cycle + '_' + simType + '_RepGRF')
        simulationObjKIN = getattr(subjectObj, cycle + '_' + simType + '_RepKIN')
        
        for (j,mLabel) in enumerate(simulationObjGRF.muscles):
            
            if i == 0:
                subplots[j] = fig.add_subplot(3,4,j+1)
                ax = subplots[j]
                ax.spines['right'].set_color('none')
                ax.spines['top'].set_color('none')
                ax.xaxis.set_ticks_position('bottom')
                ax.yaxis.set_ticks_position('left')
                plt.xlabel('% Cycle')
                plt.ylabel('Muscle Force (N)')
                plt.xlim(0, 100)
                ax.yaxis.set_label_coords(-0.225, 0.5)
                plt.title(mLabel)
            else:
                ax = subplots[j]
            try:
                ax.plot(simulationObjGRF.muscleForces.percentCycle, simulationObjGRF.muscleForces[mLabel], 
                        color=colors[i], linewidth=2, linestyle='-', label=subjectObj.subID)
            except:
                if j == 0:
                    print 'Problem with ' + subjectObj.subID + '_' + cycle + '_' + simType + '_RepGRF'
                else:
                    pass
            try:
                ax.plot(simulationObjKIN.muscleForces.percentCycle, simulationObjKIN.muscleForces[mLabel], 
                        color=colors[i], linewidth=2, linestyle='--')
            except:
                if j == 0:
                    print 'Problem with ' + subjectObj.subID + '_' + cycle + '_' + simType + '_RepKIN'
                else:
                    pass
        
            
    ax.legend(loc='center left', bbox_to_anchor=(1.1, 0.5), fontsize=12)
    plt.subplots_adjust(hspace=0.5)
    plt.subplots_adjust(wspace=0.5)
    plt.show()
        
            
# ####################################################################

def plotGroupMuscleForcesSideToSide(groupObj, simType='Walk'):

    """
    font = {'family': 'serif',
            'weight': 'normal',
            'size'  :  12}

    matplotlib.rc('font', **font)
        
    fig = plt.figure(figsize=(16,10), dpi=100)
    subplots = [None]*10
    
    subjectObjs = []
    for key, value in groupObj.__dict__.iteritems():
        if 'Subject' in value.__class__.__name__:
            subjectObjs.append(getattr(groupObj, key))
    subjectObjs = sorted(subjectObjs, key=lambda subjectObj: subjectObj.subID)
    
    for (i,subjectObj) in enumerate(subjectObjs):
        
        simulationObjGRF = getattr(subjectObj, cycle + '_' + simType + '_RepGRF')
        simulationObjKIN = getattr(subjectObj, cycle + '_' + simType + '_RepKIN')
        
        for (j,mLabel) in enumerate(simulationObjGRF.muscles):
            
            if i == 0:
                subplots[j] = fig.add_subplot(3,4,j+1)
                ax = subplots[j]
                ax.spines['right'].set_color('none')
                ax.spines['top'].set_color('none')
                ax.xaxis.set_ticks_position('bottom')
                ax.yaxis.set_ticks_position('left')
                plt.xlabel('% Cycle')
                plt.ylabel('Muscle Force (N)')
                plt.xlim(0, 100)
                ax.yaxis.set_label_coords(-0.225, 0.5)
                plt.title(mLabel)
            else:
                ax = subplots[j]
            try:
                ax.plot(simulationObjGRF.muscleForces.percentCycle, simulationObjGRF.muscleForces[mLabel], 
                        color=colors[i], linewidth=2, linestyle='-', label=subjectObj.subID)
            except:
                if j == 0:
                    print 'Problem with ' + subjectObj.subID + '_' + cycle + '_' + simType + '_RepGRF'
                else:
                    pass
            try:
                ax.plot(simulationObjKIN.muscleForces.percentCycle, simulationObjKIN.muscleForces[mLabel], 
                        color=colors[i], linewidth=2, linestyle='--')
            except:
                if j == 0:
                    print 'Problem with ' + subjectObj.subID + '_' + cycle + '_' + simType + '_RepKIN'
                else:
                    pass
        
            
    ax.legend(loc='center left', bbox_to_anchor=(1.1, 0.5), fontsize=12)
    plt.subplots_adjust(hspace=0.5)
    plt.subplots_adjust(wspace=0.5)
    plt.show()
    """
