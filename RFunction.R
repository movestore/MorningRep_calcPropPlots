library('move2')
library("dplyr")
library('foreach')
library('ggplot2')
library('geosphere')
library('sf')
library('grid')
library('gridExtra')
library('reshape2')

Sys.setenv(tz="UTC")

# data <- readRDS("./data/raw/input2_move2loc_LatLon.rds")
# time_now=max(mt_time(data))
# time_dur=10
# posi_lon=NULL
# posi_lat=NULL


rFunction = function(time_now=NULL, time_dur=NULL, posi_lon=NULL, posi_lat=NULL, data) { 
  
  if (is.null(time_now)) time_now <- Sys.time() else time_now <- as.POSIXct(time_now,format="%Y-%m-%dT%H:%M:%OSZ",tz="UTC")
  
  time0 <- time_now - as.difftime(time_dur,units="days")
  
  dataPlot <-  data %>%
    group_by(mt_track_id()) %>%
    filter(mt_time() >= time0)
  
  if(nrow(dataPlot)>0){
    
    idall <- unique(mt_track_id(data))
    idsel <- unique(mt_track_id(dataPlot))
    if(!identical(idall, idsel)){logger.info(paste0("There are no locations available in the requested time window for track(s): ",paste0(idall[!idall%in%idsel], collapse = ", ")))}
    
    dataPlotTr <- split(dataPlot, mt_track_id(dataPlot))
    gpL <- lapply(dataPlotTr, function(trk){
      
      if (is.null(posi_lon)){lonZ <- st_coordinates(trk)[nrow(trk),1]} else {lonZ <- posi_lon}
      if (is.null(posi_lat)){latZ <- st_coordinates(trk)[nrow(trk),2]} else {latZ <- posi_lat}
      
      ##NSD
      
      nsd <- (distVincentyEllipsoid(st_coordinates(trk),c(lonZ,latZ))/1000)^2
      nsd.df <- data.frame(nsd,"timestamp"=mt_time(trk))
      nsdgg <- ggplot(nsd.df,aes(x=timestamp,y=nsd)) +
        ylab("Net Square Displacement [km]") + 
        xlab("Timestamps") + 
        geom_line(colour=4) +
        labs(title = paste("Track:",unique(mt_track_id(trk)))) +
        theme_bw()+
        theme(plot.margin=grid::unit(c(1,2,1,2), "cm"))
      
      ## daily displacement
      daysObj <- unique(as.Date(mt_time(trk)))
      n_day <- foreach(dayi = daysObj, .combine=c) %do% {
        length(which(as.Date(mt_time(trk))==dayi))
      }
      displ_day <- foreach(dayi = daysObj, .combine=c) %do% {
        ix <- which(as.Date(mt_time(trk))==dayi)
        if (!(1 %in% ix)) ix <- c(min(ix)-1,ix) #add last position before this day
        if (length(ix)>1) sum(distVincentyEllipsoid(st_coordinates(trk[ix,])),na.rm=TRUE)/1000 else 0
      }
      
      
      avgdaily_dist2posi <- foreach(dayi = daysObj, .combine=c) %do% {
        ix <- which(as.Date(mt_time(trk))==dayi)
        mean(distVincentyEllipsoid(st_coordinates(trk[ix,]),c(lonZ,latZ))/1000,rm.na=TRUE)
      }
      
      dailyprop <- data.frame("day"=daysObj,n_day,displ_day,avgdaily_dist2posi)
      dailyprop.df <- melt(dailyprop, measure.vars = names(dailyprop)[2:4])
      var.names <- c(n_day="N Positions", displ_day="Displ. (km)", avgdaily_dist2posi="Dist. to Posi. (km)")
      
      dailygg <- ggplot(dailyprop.df, aes(x = day, y = value)) +
        # geom_line(aes(color = variable),show.legend=FALSE) +
        facet_grid(variable ~ ., scales = "free_y",labeller=labeller(.rows=var.names)) +
        geom_bar(stat="identity",colour="grey",width=0.3) +
        geom_line(aes(color = variable),show.legend=FALSE) +
        ylab("") + 
        xlab("Day") + 
        theme_bw()+
        theme(plot.margin=grid::unit(c(1,2,1,2), "cm"), strip.text.y = element_text(size = 7), axis.text=element_text(size=7))
      
      page_plot <- arrangeGrob(nsdgg, dailygg, ncol = 1, heights = c(0.5, 0.5))
      return(page_plot)
    })
    
    pdf(appArtifactPath("MorningReport_NSDdailyProp.pdf"),  height = 11.69,  width= 8.27)
    # pdf("MorningReport_NSDdailyProp.pdf", height = 11.69,  width= 8.27) 
    for (page in gpL) {
      grid.newpage()
      grid.draw(page)
    }
    dev.off()
    
  }else{logger.info("None of the individuals have data in the requested time window. Thus, no pdf artefact is generated.")}
  
  return(data)
}

