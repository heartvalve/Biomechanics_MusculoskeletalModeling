"""
----------------------------------------------------------------------
    simpleGeneticAlgorithm.py
----------------------------------------------------------------------
    Doc...
    
----------------------------------------------------------------------
    Created by Megan Schroeder
    Last Modified 2013-07-08
----------------------------------------------------------------------
"""


import random
import numpy
import linecache
import os
import time
import subprocess
from xml.dom.minidom import parse


class simpleGA:
    
    def __init__(self):
        self.populationSize = 8
        self.chromosomeLength = 3
        self.pCrossover = 0.8
        self.pMutation = float(1)/float(self.populationSize*2)
        self.maxGen = 300
        self.variableValues = ['1','5','10','20','50','100','500','1000']
        self.variableNames = ['pelvis_tz','pelvis_tx','pelvis_ty','pelvis_tilt','pelvis_list','pelvis_rotation',
                              'hip_flexion_r','hip_adduction_r','hip_rotation_r','knee_angle_r','ankle_angle_r',
                              'hip_flexion_l','hip_adduction_l','hip_rotation_l','knee_angle_l','ankle_angle_l',
                              'lumbar_extension','lumbar_bending','lumbar_rotation']
                              # subtalar_angle_r, mtp_angle_r, subtalar_angle_l, mtp_angle_l --> locked
        self.numChromosomes = len(self.variableNames)
        self.subDir = 'H:\\Northwestern-RIC\\Modeling\\OpenSim\\Subjects\\20130221CONF\\'
        self.trialName = '20130221CONF_A_Walk_RepGRF'
        self.log = self.subDir+self.trialName+'_RRA__GA.data'
        self.summary = self.subDir+self.trialName+'_RRA__GA_Summary.log'

    def createReport(self):
        # Detailed report
        logReport = []
        header1 = ('Generation\tIndividual\tWeights'+'\t'*19+'Max Residual Force'+'\t'*3+'RMS Residual Force'+'\t'*3+'Max Residual Moment'+'\t'*3+'RMS Residual Moment'+'\t'*3+
                   'Max Position Error (cm)'+'\t'*3+'RMS Position Error (cm)'+'\t'*3+'Max Position Error (deg)'+'\t'*16+'RMS Position Error (deg)'+'\t'*16+'Fitness\n')
        logReport.append(header1)
        header2 = '\t'.join(['','']+self.variableNames+['FX','FY','FZ']*2+['MX','MY','MZ']*2+self.variableNames[0:3]*2+self.variableNames[3:]*2+[''])+'\n'
        logReport.append(header2)
        # Write to file
        logFile = open(self.log,'w')
        logFile.writelines(logReport)
        logFile.close()
        # Summary report
        summaryFile = open(self.summary,'w')
        summaryFile.write('\t'.join(['Generation','Average Fitness','Max Fitness','Current Time'])+'\n')
        summaryFile.close()

    def initializePopulation(self):
        self.currentGen = 0
        gen0 = []
        for i in range(self.populationSize):
            parent = ''
            for j in range(self.numChromosomes):
                for k in range(self.chromosomeLength):
                    parent += random.choice(['0','1'])
                parent += '-'
            parent = parent.rstrip('-')
            gen0.append(parent)
        return gen0

    def decode(self,chromosome):
        # Decode a binary string into an integer
        intValue = 0
        numAlleles = range(self.chromosomeLength)
        numAlleles.reverse()
        for i in numAlleles:
            if chromosome[i] == '1':
                intValue = intValue+2**i
        return intValue

    def calculateFitness(self,population):
        rraCMCTaskSetFilePath = 'H:\\Northwestern-RIC\\Modeling\\OpenSim\\GenericFiles\\gait2392_RRA_CMCTaskSet.xml'
        dom = parse(rraCMCTaskSetFilePath)
        cmcJointElements = dom.getElementsByTagName('CMC_Joint')
        fitnesses = []
        logReport = []
        for individual in population:
            logReportLine = [str(self.currentGen),str(population.index(individual)+1)]
            chromosomes = individual.split('-')
            # Write weights to XML
            for i in range(len(chromosomes)):
                index = self.decode(chromosomes[i])
                value = self.variableValues[index]
                name = self.variableNames[i]
                logReportLine.append(value)
                for elem in cmcJointElements:
                    if elem.getAttribute('name') == name:
                        elem.getElementsByTagName('weight')[0].firstChild.nodeValue = ' '+value
                        break
            xmlString = dom.toxml('UTF-8')
            xmlFile = open(rraCMCTaskSetFilePath,'w')
            xmlFile.write(xmlString)
            xmlFile.close()
            # Specify trial
            subDir = self.subDir
            trialName = self.trialName
            # Run simulation
            subprocess.Popen((subDir+'Run.bat'), shell=True, cwd=subDir)
            startTime = time.time()
            while True:
                # Check for simulation result file
                if os.access(subDir+trialName+'_RRA_controls.xml',os.F_OK):
                    break
                # Timeout after 2 minutes if file doesn't exist yet (simulation probably failed)
                elif (time.time()-startTime) > 120:
                    break
                # Wait
                else:
                    time.sleep(5)
            # Process simulation output
            try:
                weightSum = 0
                # Residuals
                txtline = linecache.getline(subDir+trialName+'_RRA_Actuation_force.sto',23)
                headerList = txtline.rstrip().split('\t')
                residualNames = headerList[1:7]
                linecache.clearcache()
                residuals = numpy.loadtxt(subDir+trialName+'_RRA_Actuation_force.sto',skiprows=23,usecols=(1,2,3,4,5,6))
                maxResiduals = residuals.__abs__().max(0)
                rmsResiduals = numpy.sqrt(numpy.sum(numpy.square(residuals),0)/numpy.size(residuals,0))
                ###residuals = numpy.genfromtxt(subDir+trialName+'_RRA_Actuation_force.sto',dtype=float,skip_header=22,usecols=(1,2,3,4,5,6),names=True)
                ###residualNames = residuals.dtype.names
                ###residualsArray = residuals.view((float, len(residuals.dtype.names)))
                for k in range(len(residualNames)):
                    if residualNames[k] == 'FX' or residualNames[k] == 'FY' or residualNames[k] == 'FZ':
                        # Max
                        if maxResiduals[k] <= 10:
                            weightSum+=0.02
                        elif maxResiduals[k] <= 25:
                            weightSum+=0.25
                        else:
                            weightSum+=10
                        # RMS
                        if rmsResiduals[k] <= 5:
                            weightSum+=0.02
                        elif rmsResiduals[k] <= 10:
                            weightSum+=0.25
                        else:
                            weightSum+=10
                    elif residualNames[k] == 'MX' or residualNames[k] == 'MY' or residualNames[k] == 'MZ':
                        # Max
                        if maxResiduals[k] <= 50:
                            weightSum+=0.02
                        elif maxResiduals[k] <= 75:
                            weightSum+=0.25
                        else:
                            weightSum+=10
                        # RMS
                        if rmsResiduals[k] <= 30:
                            weightSum+=0.02
                        elif rmsResiduals[k] <= 50:
                            weightSum+=0.25
                        else:
                            weightSum+=10
                # Position Errors
                txtline = linecache.getline(subDir+trialName+'_RRA_pErr.sto',7)
                headerList = txtline.rstrip().split('\t')
                posErrNames = headerList[1:]
                linecache.clearcache()
                # (Column indices to remove -- after removing first column)
                removeIndices = [posErrNames.index('subtalar_angle_r'),posErrNames.index('mtp_angle_r'),posErrNames.index('subtalar_angle_l'),posErrNames.index('mtp_angle_l')]
                removeIndices.reverse()
                for k in removeIndices:
                    del posErrNames[k]
                posErrors = numpy.loadtxt(subDir+trialName+'_RRA_pErr.sto',skiprows=7)
                posErrors = numpy.delete(posErrors,0,1)
                for k in removeIndices:
                    posErrors = numpy.delete(posErrors,k,1)
                maxPosErr = posErrors.__abs__().max(0)
                rmsPosErr = numpy.sqrt(numpy.sum(numpy.square(posErrors),0)/numpy.size(posErrors,0))
                for k in range(len(posErrNames)):
                    if posErrNames[k] == 'pelivs_tx' or posErrNames[k] == 'pelvis_ty' or posErrNames[k] == 'pelvis_tz':
                        # Convert from m to cm
                        maxPosErr[k]*=100
                        rmsPosErr[k]*=100
                        # Max
                        if maxPosErr[k] <= 2:
                            weightSum+=0.02
                        elif maxPosErr[k] <= 5:
                            weightSum+=0.25
                        elif maxPosErr[k] <= 15:
                            weightSum+=10
                        else:
                            weightSum+=25
                        # RMS
                        if rmsPosErr[k] <= 2:
                            weightSum+=0.02
                        elif rmsPosErr[k] <= 4:
                            weightSum+=0.25
                        else:
                            weightSum+=10
                    else:
                        # Convert from rad to deg
                        maxPosErr[k]*=180/numpy.pi
                        rmsPosErr[k]*=180/numpy.pi
                        # Max
                        if maxPosErr[k] <= 2:
                            weightSum+=0.02
                        elif maxPosErr[k] <= 5:
                            weightSum+=0.25
                        else:
                            weightSum+=10
                        # RMS
                        if rmsPosErr[k] <= 2:
                            weightSum+=0.02
                        elif rmsPosErr[k] <= 5:
                            weightSum+=0.25
                        else:
                            weightSum+=10
                # Update log
                maxResiduals = maxResiduals.tolist()
                rmsResiduals = rmsResiduals.tolist()
                maxPosErr = maxPosErr.tolist()
                rmsPosErr = rmsPosErr.tolist()
                # FX, FY, FZ
                for k in range(3): logReportLine.append(str(maxResiduals[k]))
                for k in range(3): logReportLine.append(str(rmsResiduals[k]))
                # MX, MY, MZ
                for k in range(3,6): logReportLine.append(str(maxResiduals[k]))
                for k in range(3,6): logReportLine.append(str(rmsResiduals[k]))
                # Translations
                for k in range(3): logReportLine.append(str(maxPosErr[k]))
                for k in range(3): logReportLine.append(str(rmsPosErr[k]))
                # Angles
                for k in range(3,len(maxPosErr)): logReportLine.append(str(maxPosErr[k]))
                for k in range(3,len(rmsPosErr)): logReportLine.append(str(rmsPosErr[k]))
                # Individual fitness
                fitnesses.append(1/weightSum)
                logReportLine.append(str(1/weightSum))
                # Remove simulation output files
                try:
                    os.remove(subDir+trialName+'_RRA.log')
                    os.remove(subDir+trialName+'_AdjustedCOM.osim')
                    os.remove(subDir+'err.log')
                    os.remove(subDir+'out.log')
                except:
                    pass
                rraSpecifiers = ('Actuation_force.sto','Actuation_power.sto','Actuation_speed.sto',
                                 'BodyKinematics_acc_global.sto','BodyKinematics_pos_global.sto','BodyKinematics_vel_global.sto',
                                 'Kinematics_dudt.sto','Kinematics_q.sto','Kinematics_u.sto',
                                 'avgResiduals.txt','controls.sto','controls.xml','pErr.sto','states.sto')
                for fspec in rraSpecifiers:
                    try:
                        os.remove(subDir+trialName+'_RRA_'+fspec)
                    except:
                        break
            # If simulation failed
            except:
                fitnesses.append(0.0000000001)
            # Append to log
            logReport.append('\t'.join(logReportLine)+'\n')                        
        # Write to output file
        logFile = open(self.log,'a')
        logFile.writelines(logReport)
        logFile.close()
        # Summary
        summaryFile = open(self.summary,'a')
        summaryFile.write('\t'.join([str(self.currentGen),str(numpy.mean(fitnesses)),str(numpy.max(fitnesses)),time.strftime('%H:%M:%S',time.localtime())])+'\n')
        summaryFile.close()
        # Print to screen
        print ('Generation '+str(self.currentGen)+' is complete. Max fitness is '+str(numpy.max(fitnesses))+'.')
        # Return
        return fitnesses

    def rouletteSelect(self,origPopulation,fitnesses):
        totalFitness = float(sum(fitnesses))
        relFitness = [f/totalFitness for f in fitnesses]
        probIntervals = [sum(relFitness[:i+1]) for i in range(len(relFitness))]
        newPopulation = []
        for j in range(len(origPopulation)):
            r = random.random()
            for (i,individual) in enumerate(origPopulation):
                if r <= probIntervals[i]:
                    newPopulation.append(individual)
                    break
        return newPopulation

    def crossover(self,origPopulation):
        parentIndices = range(self.populationSize)
        # Reorder parents randomly
        random.shuffle(parentIndices)
        # Initialize loop
        i = 0
        newPopulation = []
        while i <= self.populationSize-2:
            # Operate on pairs
            mate1 = origPopulation[i].split('-')
            mate2 = origPopulation[i+1].split('-')
            child1 = []
            child2 = []
            # Loop through chromosomes
            for j in range(self.numChromosomes):
                # Check if pair will crossover (based on crossover probability)
                if random.random() <= self.pCrossover:
                    # Determine crossover location
                    x = random.choice(range(1,self.chromosomeLength))
                    # Crossover
                    child1.append(mate1[j][:x]+mate2[j][x:])
                    child2.append(mate2[j][:x]+mate1[j][x:])
                else:
                    child1.append(mate1[j])
                    child2.append(mate2[j])
            # Append to new population
            newPopulation.append('-'.join(child1))
            newPopulation.append('-'.join(child2))
            # Increment (by 2)
            i+=2
        return newPopulation

    def mutation(self,origPopulation):
        newPopulation = []
        # Loop through individuals
        for parent in origPopulation:
            chromosomeList = parent.split('-')
            child = []
            # Loop through chromosomes
            for chromosome in chromosomeList:
                # Check if mutation will occur (based on mutation probability)
                if random.random() <= self.pMutation:
                    # Determine mutation location
                    x = random.choice(range(self.chromosomeLength))
                    # Mutation
                    alleles = list(chromosome)
                    if alleles[x] == '1':
                        alleles[x] = '0'
                    elif alleles[x] == '0':
                        alleles[x] = '1'
                    # New chromosome
                    child.append(''.join(alleles))
                else:
                    child.append(chromosome)
            # New population
            newPopulation.append('-'.join(child))
        return newPopulation

    def generation(self,origPopulation,origFitnesses):
        # Create a new generation through select, crossover, and mutation
        selectPopulation = self.rouletteSelect(origPopulation,origFitnesses)
        crossoverPopulation = self.crossover(selectPopulation)
        newPopulation = self.mutation(crossoverPopulation)
        # Increment new population
        self.currentGen+=1
        # Calculate fitness of new generation
        newFitnesses = self.calculateFitness(newPopulation)
        return newPopulation,newFitnesses

    def run(self):
        # Initialize log report
        self.createReport()
        # Create new population
        genN = self.initializePopulation()
        fitnesses = self.calculateFitness(genN)
        # Initialize loop
        n = 1
        while n <= self.maxGen:
            if max(fitnesses) < 1:
                # Create a new generation
                genN,fitnesses = self.generation(genN,fitnesses)
                # Increment
                n+=1
            else:
                break

# ******************************************************************************

if __name__ == '__main__':
    # Create instance of class
    sga = simpleGA()
    # Run code
    sga.run()

