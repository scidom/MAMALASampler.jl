library(data.table)
library(stringr)

recursive_mean <- function(lastmean, k, x){
  return(((k-1)*lastmean+x)/k)
}

cmd_args <- commandArgs()
CURRENTDIR <- dirname(regmatches(cmd_args, regexpr("(?<=^--file=).+", cmd_args, perl=TRUE)))
ROOTDIR <- dirname(dirname(CURRENTDIR))
OUTDIR <- file.path(ROOTDIR, "output", "one_planet")

# OUTDIR <- "../../output/one_planet"

SAMPLERDIRS <- c("MALA", "AM", "SMMALA", "GAMC")

nsamplerdirs <- length(SAMPLERDIRS)

true_pars <- c(3.93183, 3.04452, 0.141421, 0.141421, 1.5708, 1.0)

nchains <- 10
nmcmc <- 110000
nburnin <- 10000
npostburnin <- nmcmc-nburnin

nmeans <- npostburnin

ci <- c(6, 6, 6, 4)
pi <- 2

submeans <- matrix(data=NA, nrow=nmeans, ncol=nsamplerdirs)
curmeans <- rep(0, nsamplerdirs)

for (j in 1:nsamplerdirs) {
  chains <- t(fread(
    file.path(OUTDIR, SAMPLERDIRS[j], paste("chain", str_pad(ci[j], 2, pad="0"), ".csv", sep="")), sep=",", header=FALSE
  ))

  for (i in 1:nmeans) {
    curmeans[j] <- recursive_mean(curmeans[j], i, chains[i, pi])
    submeans[i, j] <- curmeans[j]
  }
}

# apply(submeans, 2, mean)-true_pars[pi]

cols <- c("green", "blue", "orange", "red")

pdf(file=file.path(OUTDIR, "rv_one_planet_meanplot.pdf"), width=10, height=6)

oldpar <- par(no.readonly=TRUE)

par(fig=c(0, 1, 0, 1), mar=c(2.25, 4, 3.5, 1)+0.1)

plot(
  1:nmeans,
  submeans[, 1],
  type="l",
  ylim=c(3.04, 3.07),
  col=cols[1],
  lwd=2,
  xlab="",
  ylab="",
  cex.axis=1.8,
  cex.lab=1.7,
  yaxt="n"
)

axis(
  2,
  at=seq(3.04, 3.07, by=0.01),
  labels=seq(3.04, 3.07, by=0.01),
  cex.axis=1.8,
  las=1
)

lines(
  1:nmeans,
  submeans[, 2],
  type="l",
  col=cols[2],
  lwd=2
)

lines(
  1:nmeans,
  submeans[, 3],
  type="l",
  col=cols[3],
  lwd=2
)

lines(
  1:nmeans,
  submeans[, 4],
  type="l",
  col=cols[4],
  lwd=2
)

# abline(h=true_pars[pi], lwd=2, col="black")

par(fig=c(0, 1, 0.89, 1), mar=c(0, 0, 0, 0), new=TRUE)

plot.new()

legend(
  "center",
  SAMPLERDIRS,
  lty=c(1, 1, 1, 1),
  lwd=c(5, 5, 5, 5),
  col=cols,
  cex=1.5,
  bty="n",
  text.width=0.125,
  ncol=4
)

par(oldpar)

dev.off()
