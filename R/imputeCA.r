imputeCA <-function (X, ncp = 2, threshold = 1e-08, maxiter = 1000) 
{
  shrinkCA <- function(X, ncp = 2) {
    P <- as.matrix(X/sum(X))
    Rc <- apply(P, 2, sum)
    Rr <- apply(P, 1, sum)
    S <- t(t((P - Rr %*% t(Rc))/sqrt(Rr))/sqrt(Rc))
    svdRes <- svd(S)
    n <- nrow(X)
    p <- ncol(X)
    sigma2 <- sum(svdRes$d[-c(1:ncp)]^2)/((n - 1) * (p - 1) - (n - 1) * ncp - (p - 1) * ncp + ncp^2)
    lambda.shrinked <- (svdRes$d[1:ncp]^2 - n * (p/min(p, (n - 1))) * sigma2)/svdRes$d[1:ncp]
    if (ncp == 1) recon <- (svdRes$u[, 1] * lambda.shrinked) %*% t(svdRes$v[, 1])
    else recon <- svdRes$u[, 1:ncp] %*% (t(svdRes$v[, 1:ncp]) * lambda.shrinked)
    recon <- sum(X) * (t(t(recon * sqrt(Rr)) * sqrt(Rc)) + Rr %*% t(Rc))
    rownames(recon) <- rownames(X)
    colnames(recon) <- colnames(X)
    res <- list(recon = recon)
    return(res)
  }
  X <- as.matrix(X)
  if (sum(is.na(X)) == 0) 
    stop("No value is missing")
  missing <- which(is.na(X))
  Xhat <- X
  Xhat[missing] <- sample(X[-missing], length(missing), replace = TRUE) + 1
  nb.iter <- 1
  old <- Inf
  objective <- 0
  recon <- Xhat
  while (nb.iter > 0) {
    Xhat[missing] <- recon[missing]
    Xhat[missing][which((Xhat[missing]<=0))]=0
  
    RXhat <- rowSums(Xhat)
    CXhat <- colSums(Xhat)
    if ((sum(RXhat > 1e-06) == nrow(Xhat)) & (sum(CXhat > 
                                                  1e-06) == ncol(Xhat))) 
      recon <- shrinkCA(Xhat, ncp = ncp)$recon
    diff <- Xhat - recon
    diff[missing] <- 0
    objective <- sum((diff^2))
    criterion <- abs(1 - objective/old)
    old <- objective
    nb.iter <- nb.iter + 1
    if (!is.nan(criterion)) {
      if ((criterion < threshold) && (nb.iter > 5)) 
        nb.iter <- 0
      if ((objective < threshold) && (nb.iter > 5)) 
        nb.iter <- 0
    }
    if (nb.iter > maxiter) {
      nb.iter <- 0
      warning(paste("Stopped after ", maxiter, " iterations"))
    }
  }
  completeObs <- X
  completeObs[missing] <- Xhat[missing]

  return(completeObs)
}