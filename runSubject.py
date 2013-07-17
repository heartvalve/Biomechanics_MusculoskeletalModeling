


# ####################################################################
#                                                                    #
#                   Input                                            #
#                                                                    #
# ####################################################################
# Subject ID
subIDs = ['20121205CONM']
# ####################################################################


# Imports
import os
import time
from runTools import *
#from updateFirstLineMOT import *
#from iterateRRAadjustMass import *
#from rerunCMCadjustTime import *


class runSubject:

    def __init__(self,subID):
        self.subID = subID
        nuDir = os.getcwd()
        while os.path.basename(nuDir) != 'Northwestern-RIC':
            nuDir = os.path.dirname(nuDir)
        self.subDir = os.path.join(nuDir,'Modeling','OpenSim','Subjects',subID)+'\\'
        self.startTime = time.time()
    
    
    def run(self):
        
        #scaleTool = scale(self.subID)
        #scaleTool.run()
        #ikTool = ikin(self.subID)
        #ikTool.run()
        #updateNames = updateMOT(self.subID)
        #updateNames.run()
        #idTool = idyn(self.subID)
        #idTool.run()        
        #rraTool = rra(self.subID)
        #rraTool.run()
        #iterRRA = iterateRRA(self.subID)
        #iterRRA.run()
        
        cmcTool = cmc(self.subID)
        cmcTool.run()
        
        print (self.subID+' is finished -- elapsed time is '+str(int(float(time.time()-self.startTime)/float(60)))+' minutes.')
    

if __name__ == '__main__':
    # Loop through subject list
    for subID in subIDs:
        # Create instance of class
        runSub = runSubject(subID)
        # Run code
        runSub.run()
