library('move')
library('foreach')
library('ggplot2')
library('geosphere')
library('sf')
library('grid')
library('gridExtra')
library('reshape2')

Sys.setenv(tz="GMT")

rFunction = function(time_now=NULL, time_dur=NULL, posi_lon=NULL, posi_lat=NULL, data, ...) { #dont give id selection option, but decide that only plot those with data in the time_dur window
  
  if (is.null(time_now)) time_now <- Sys.time() else time_now <- as.POSIXct(time_now)
  
  data_spl <- move::split(data)
  ids <- namesIndiv((data))
  if (is.null(time_dur))
  {
    time_dur <- 10
    logger.info("You did not provide a time duration for your plot. It is set to 10 days by default.")
  }
  time0 <- time_now - as.difftime(time_dur,units="days")
  
  g <- list()
  k <- 1
  for (i in seq(along=ids))
  {
    datai <- data_spl[[i]]
    datai_t <- datai[timestamps(datai)>time0 & timestamps(datai)<time_now]
    if (length(datai_t)>0)
    {
      g[[k]] <- list()
      nsd <-(distVincentyEllipsoid(coordinates(datai_t),coordinates(datai_t)[1,])/1000)^2
      nsd.df <- data.frame(nsd,"timestamp"=timestamps(datai_t))
      g[[k]][[1]] <- ggplot(nsd.df,aes(x=timestamp,y=nsd)) +
        ylab("net square displacement (km)") + 
        geom_line(colour=4) +
        labs(title = paste("individual:",ids[i])) +
        theme(plot.margin=grid::unit(c(0,2,0,2), "cm"))

      days <- unique(as.Date(timestamps(datai_t)))
      n_day <- foreach(dayi = days, .combine=c) %do% {
          length(which(as.Date(timestamps(datai_t))==dayi))
        }
      displ_day <- foreach(dayi = days, .combine=c) %do% {
          ix <- which(as.Date(timestamps(datai_t))==dayi)
          if (!(1 %in% ix)) ix <- c(min(ix)-1,ix) #add last position before this day
          if (length(ix)>1) sum(distVincentyEllipsoid(coordinates(datai_t[ix,])),na.rm=TRUE)/1000 else 0
        }
      
      if (is.null(posi_lon)) 
        {
        lonZ <- coordinates(datai_t)[1,1] 
        logger.info("You did not provide a position longitude. The first position of each animal is used for reference.")
        } else lonZ <- posi_lon
        
      if (is.null(posi_lat))
        {
        latZ <- coordinates(datai_t)[1,2] 
        logger.info("You did not provide a position latitude. The first position of each animal is used for reference.")
        } else latZ <- posi_lat
      
      avgdaily_dist2posi <- foreach(dayi = days, .combine=c) %do% {
          ix <- which(as.Date(timestamps(datai_t))==dayi)
          mean(distVincentyEllipsoid(coordinates(datai_t[ix,]),c(lonZ,latZ))/1000,rm.na=TRUE)
      }
      
      dailyprop <- data.frame("day"=days,n_day,displ_day,avgdaily_dist2posi)
      
      dailyprop.df <- melt(dailyprop, measure.vars = names(dailyprop)[2:4])
        
        g[[k]][[2]] <- ggplot(dailyprop.df, aes(x = day, y = value)) +
          geom_line(aes(color = variable),show.legend=FALSE) +
          facet_grid(variable ~ ., scales = "free_y") +
          geom_bar(stat="identity",colour="grey",width=0.3) +
          theme(plot.margin=grid::unit(c(1,2,0,2), "cm"))
        k <- k+1
        
      } else logger.info(paste0("There are no locations available in the requested time window for individual ",ids[i]))
    }

    #pdf(paste0(Sys.getenv(x = "APP_ARTIFACTS_DIR", "/tmp/"),"MorningReport_NSDdailyProp.pdf"),onefile=TRUE,paper="a4")
    #pdf("MorningReport_NSDdailyProp.pdf",onefile=TRUE,paper="a4")
    #for (i in seq(along=g))
    #{
    #  do.call("grid.arrange",g[[i]])
    #}
    #dev.off()
    
  return(data)
}
