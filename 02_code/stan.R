library(rstan)
library(doParallel)
registerDoParallel()
rstan_options(auto_write=TRUE)
options(mc.cores=parallel::detectCores())

tumor_experiments <- read.csv("../01_data/data.csv")


tumor_experiments$percent = tumor_experiments$tumors / tumor_experiments$n
tumor_experiments$y <- tumor_experiments$tumors
# n <- tumor_experiments$n
y <- c(0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,
        2,1,5,2,5,3,2,7,7,3,3,2,9,10,4,4,4,4,4,4,4,10,4,4,4,5,11,12,
        5,5,6,5,6,6,6,6,16,15,15,9,4)
n <- c(20,20,20,20,20,20,20,19,19,19,19,18,18,17,20,20,20,20,19,19,18,18,25,24,
       23,20,20,20,20,20,20,10,49,19,46,27,17,49,47,20,20,13,48,50,20,20,20,20,
       20,20,20,48,19,19,19,22,46,49,20,20,23,19,22,20,20,20,52,46,47,24,14)
j <- length(y)



rat_fit = stan(file="test1.stan", data=list(J=j, y=y, n=n),
               iter=1000, chains=4)

print(rat_fit)

rat_sim = rstan::extract(rat_fit)



a <- rat_sim$alpha
b <- rat_sim$beta

contour <- ggplot(data.frame(x=log(a/b), y=log(a+b), a=a, b=b)) +
  # geom_point(aes(x=x, y=y)) +
  geom_density_2d(aes(x=x, y=y))

plot <- ggplot(data.frame(x=log(a/b), y=log(a+b), a=a, b=b)) +
  geom_point(aes(x=x, y=y)) 
  # geom_density_2d(aes(x=x, y=y))

grid.arrange(contour, plot, nrow = 1)


conf_rats <- extract(rat_fit, "theta", probs=c(0.025, 0.5, 0.975))

theta_summary <- summary(rat_fit, pars = c("theta"), probs = c(0.025, 0.5, 0.975))$summary

qq_hier <- data.frame(id=1:length(n), n=n, y=y,
                      low=theta_summary[,"2.5%"], high=theta_summary[,"97.5%"], med=theta_summary[,"50%"], perc=(y/n))

qq_hier$perc <- jitter(qq_hier$perc, amount=0.025)


ggplot(qq_hier, aes(x=perc, y=med, ymin=low, ymax=high)) +
  geom_point() + geom_abline(intercept=0, slope=1) + geom_linerange() +
  theme(aspect.ratio=1) +  labs(x = "Oberserved rate y(i)/n(i)", y = "95% posterior interval for theta_i") 
