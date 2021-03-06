# Calculate individual fitness for each patch
PatchFit = function(p, states, fx, n0, npatch, nstg, tf, P, pred) {
  # start all patches off with a good year
  fit = matrix(NA, nrow=(tf-1), ncol=3) 
  state = c(1,1)
  # k= number of possible states
  k=dim(P)[1]
  
  Nt = n0 # starting population 
  
  for(i in 1:(tf-1)) {
    # determine the environmental state for each patch
    state[1] = sample(1:k,size=1, prob = P[,state[1]])
    state[2] = sample(1:k,size=1, prob = P[,state[2]])
    
    # pull out the parameters so you can put them in a matrix
    st = c(states[state[1],], states[state[2],])
    J = st[c(1, 3)]
    s1= st[c(2, 4)]
    
    A <- matrix(c(0, fx[1], 0, 0, 
                  J[1]*p*pred,s1[1],J[2]*p,0, 
                  0, 0, 0,fx[2],  
                  J[1]*(1-p)*pred,0, J[2]*(1-p),s1[2]), nrow=4, ncol=4, byrow=TRUE) 
    Nt1= A %*% Nt
    A1 = matrix(c(0, fx[1],J[1]*pred,s1[1]), nrow=2, ncol=2, byrow=TRUE)
    A2 = matrix(c(0, fx[2],J[2],s1[2]), nrow=2, ncol=2, byrow=TRUE)
    # store metapopulation growth rate, patch growth rates, juv survival
    # and adult survival to calculate fitness later
    fit[i,1] = (lambda(A)) 
    fit[i,2] = (lambda(A1))
    fit[i,3] = (lambda(A2))
    Nt=Nt1
  }
  
  # calculate average survival and growth rates
aves = colSums(log(fit))/nrow(fit)
  
  # calculate within-patch fitness and population level fitness
 # fits= c(1,2, 3,4)
  #fits[1] = aves[4]*aves[8]/aves[6]
  #fits[2] = aves[5]*aves[9]/aves[7]
  #fits[3] = aves[10]*aves[2]/aves[3] 
 # fits[4] = aves[1]*aves[2]/aves[3] 
  return(aves)
}

test = PatchFit(p=.5, states, fx, n0, npatch, nstg, tf=100, P, pred=.5)

tf=10000
fitout = ldply(pred, function(pred2){
  r2.0 = foreach(i=1:21, .combine=rbind) %dopar% PatchFit(p=p[i], states=states, fx=fx, n0=n0, npatch=2, nstg=2, tf=tf, P=P,  pred=pred2)

  return(r2.0) 
})

fitout2 = data.frame(both=fitout[,1], one=fitout[,2], two=fitout[,3])
fitout2$p = rep(p,6)
fitout2$predation = c(rep("100%",21), rep("80%",21), rep("60%",21), rep("40%",21), rep("20%",21), rep("0%",21))

fitout3 = melt(fitout2,  id.vars=c("p","predation"), variable.name= "patch", value.name="fitness")
g = ggplot(fitout3, aes(x=as.numeric(p), y=value, color=predation))+ geom_line(aes(lty=variable)) 
g + labs(x="proportion of juvs trapped", y="stochastic log(lambda)")
h = ggplot(fitout3, aes(x=as.numeric(p), y=value, color=predation))+ geom_line() + facet_wrap(.~predation)

r2.0 = foreach(i=1:6, .combine=rbind) %dopar% PatchFit(p=.5, states=states, fx=fx, n0=n0, npatch=2, nstg=2, tf=tf, P=P,  pred=pred[i])
r2.01 = data.frame(pred=pred, both=r2.0[,1], one=r2.0[,2], two=r2.0[,3])
r2.01$geoave = (r2.01$one+r2.01$two)/2
r2.01$arave = log((exp(r2.01$one)+exp(r2.01$two))/2)
r2.02 = melt(r2.01, id.vars="pred", variable_name="patch")

r = ggplot(r2.02, aes(x=pred, y=value, color=patch))+geom_line()
r