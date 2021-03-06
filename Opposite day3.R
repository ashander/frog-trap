# Now lets have predation effect the adults AND have the adults be
# the migratory life stage.
source('R/opposite day3 functions.R')

# apply stochastic growth function over all predation levels
resultsSO3 = ldply(pred, function(pred2){
  # calculate stochastic growth rates
  r.0 = foreach(i=1:21, .combine=c) %dopar% fooopp3(p=p[i], pred=pred2, states=states)
  return(r.0)
})

# apply deterministic growth function over all predation levels
resultsDO3 = ldply(pred, function(pred){
  # deterministic growth rate
  r2.0 = sapply(p, Patchopp3, s1=c(ok[2],ok[2]), J=c(ok[1],ok[1]), fx=fx,  pred=pred, simplify=T)
  r2.0 = log(r2.0) # take the log to make it comparable to stochastic rates
  return(r2.0) 
})
allO3 = data.frame(t(rbind(resultsDO3, resultsSO3, p)))
names(allO3) = c(pred,predSt,"p")
write.csv(allO3, file = "adult disppred.csv")

library(reshape2)
allO = melt(allO3, id.vars="p", variable.name= "predation", value.name="lambda")
allO$stoch = rep(NA, 252)
allO$stoch[c(1:126)]="n"
allO$stoch[c(127:252)] = "y"
allO$rate = c(NA, 252)
allO$rate[c(1:21, 127:147)] = 6
allO$rate[c(22:42,  148:168)] = 5
allO$rate[c(43:63 , 169:189 )] = 4
allO$rate[c( 64:84 , 190:210)] = 3
allO$rate[c( 85:105 ,211:231 )] = 2
allO$rate[c( 106:126 ,232:252 )] = 1
allO$rate = ordered(allopp$rate,
                      labels = rev(c("100%", "80%", "60%", "40%", "20%", "0%")))
qplot(data=allO[which(allopp$stoch=="n"),], x=p, y=lambda, color=rate, geom="line") 
# plot stochastic  growth and deterministic
opp3 = ggplot(data=allO, 
            aes(x=p, y=lambda, color=rate, linetype=stoch))
opp3 = opp3+geom_line() + labs(y="population growth rate log(lambda)", x="proportion of each year's total adults \n dispersing to the high predation patch")+
  scale_linetype_manual(name = "model", values=c(2, 1), labels = c("deterministic", "stochastic")) +
  scale_y_continuous(limits=c(-.25, .5)) 
opp3



# Make a function to calculate average sensitivites for a bunch to time runs
# over a bunch of attractiveness values
elsplotO = function(pred) {
  i=1:21
  # Apparently this gets too big for R to handle if you run it for 100,000 time steps, but that doesn't make sense...
  run = laply(i, function(x){
    ru = replicate(100,bigrunopp3(tf=1000, p1=p[x], pred1=pred))
    aaply(ru, 1:2, function(thingy) {sum(thingy)/100})
  },
              .parallel=T)
  
  # Data frame with the elasticity of each non-zero matrix entry
  elsdf = data.frame(p=p, f1=run[, 1,2], j11=run[, 2,1], j21=run[, 2,3], a1=run[, 2,2], 
                     f2=run[, 3,4],  j12=run[, 4,1], j22=run[, 4,3], a2=run[, 4,4])
  library(reshape2)
  elsedf2 = melt(elsdf, id.vars="p", variable.name="stage",value.name="elas")
  elsedf2$patch = rep(NA, 168)
  elsedf2$stage = rep(NA, 168)
  elsedf2$patch[1:84] = "1"
  elsedf2$patch[85:168] = "2"
  elsedf2$stage[1:21]="f"
  elsedf2$stage[22:42]="j1"
  elsedf2$stage[43:63]="j2"
  elsedf2$stage[64:84]="a"
  elsedf2$stage[85:105]="f"
  elsedf2$stage[106:126]="j1"
  elsedf2$stage[127:147]="j2"
  elsedf2$stage[148:168]="a"
  
  # plot the change in elasticities with different ammounts of migration
  el = qplot(data=elsedf2, x=p, y=elas, geom="line", color=stage, linetype = patch,
             xlab="proportion of juveniles moving to \nhigh predation patch (patch1)", ylab="elasticity of log lambdas \n to changes in life stage",
             main=paste("predation = ", pred))
  el
}

predO = elsplotO(pred=.5)


fO = foreach (i=1:10, combine=cbind) %dopar% {
  fx1 = c(150*f[i], 150*f[i])
  r =  ldply(p, fooopp3, states1=states, fx=fx1, pred=.5)
  return(r)
}
fO = as.data.frame(fO)
fO$p = p
maxf = apply(fO[,1:10], 2, max)
minf = as.numeric(fO[1,1:10])
maxsf = fO[1:10,]
summaryf = data.frame(levels = seq(.2, 2, by=.2), stage = rep("f", 10), maxlamO=maxf, p = maxsf$p[1:10], ldiff=(maxf-minf))


survO = foreach (i=1:12, combine=cbind) %dopar% {
  states1 <- cbind(states[,1]*surv[i,1], states[,2]*surv[i,2])
  r =  ldply(p, fooopp3, states1=states1, pred=.5)
  return(r)
}

survO2 = as.data.frame(survO)
names(survO2) = surv[,1]
survO2$p = p

survOdat = melt(survO2, id.vars="p")
survOdat$levels = surv[,1]
survOplot = ggplot(survOdat, aes(x=p, y=value)) + geom_line()

maxlamO = apply(survO2[,1:12], 2, max)
minlamO = as.numeric(survO2[1,1:12])
maxsO = survO2[1:12,]
for (i in 1:12) maxsO[i,] = survO2[which(survO2[,i]==maxlamO[i]),]

summaryO = data.frame(levels = surv[,1]/(surv[,1]+surv[,2]), maxs=maxlamO, p = maxsO$p, ldiff=(maxlamO-minlamO))
write.csv(summaryO, file = "summary survivalsO tradeoff.csv")

lamlocalO = qplot(levels, p, data= summaryO, geom="line",xlab= "investment in juves", ylab="migration proportion at \n peak of migration/lambda curve", main = "Proporiton of juves \n migrating that maximizes growth")
lamlocalO


# Graph changes in height of the peak of the lambda curve
lampeakO = qplot(levels, maxlamO, data= summaryO, geom="line",  xlab= "investment in juves", ylab="lambda at \n peak of migration/lambda curve", main = "Maximum growth rate for each  life \n stage at each survival level")
lampeakO
# graph changes in difference between max and min or lambda curve

lamdiffO = qplot(levels, ldiff, data= summaryO, geom="line",xlab= "investment in juves", ylab="δlogλ_sMAX", main = "Predation on adults, adults disperse")

lamdiffO +  scale_y_continuous(limits=c(0, .26))
svg(filename="lamdiff adult predmig.svg", width=6, height=4)
lamdiffO+ scale_y_continuous(limits=c(0, .26)) 
dev.off()

# Add the data from the different scenarios together and plot them
summary$scenario = rep("1", nrow(summary))
summaryads$scenario = rep("2",nrow(summaryads))
summaryopp$scenario = rep("3", nrow(summaryopp))
summaryO$scenario = rep("4", nrow(summaryO))
summarytotal = rbind(summary, summaryads, summaryopp, summaryO)
summarytotal$scenario = as.factor(summarytotal$scenario)

lamdifftot = qplot(levels, ldiff, data = summarytotal, geom="line", color=scenario, xlab="proportional investment in juveniles", ylab= "δlogλ_sMAX")
lamdifftot + scale_color_manual( values=c("red","blue","green","black"), labels = c("juvenile dispersal, \n predation on juveniles", "juvenile dispersal, \n predation on adults", "adult dispersal, \n predation on juveniles", "adult dispersal, \n predtion on adults"))


svg(filename="lamdiff_total.svg", width=8, height=4)
lamdiffO+ scale_y_continuous(limits=c(0, .35)) 
dev.off()