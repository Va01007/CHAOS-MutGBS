#!/usr/bin/Rscript
args = commandArgs(trailingOnly=TRUE)

if(!require(glue)){install.packages("glue")}
if(!require(chromoMap)){install.packages("chromoMap")}
if(!require(htmlwidgets)){install.packages("htmlwidgets")}

colu <- c("Delet" = "black", "Dupli" = "red", "Trans" = "green", "Inser" = "blue")

Main_bed <-read.delim(args[1], header = TRUE, sep = "\t")
Log_file <-read.delim(args[2], header = TRUE, sep = "\t")

Out_file <- substr(args[1], 0, (nchar(args[1])- 4))

Annotation_dataframe <- data.frame()

for (i_row in 1:nrow(Log_file)) {
  if (Log_file[i_row, 2] == args[1])  {
      Annotation_dataframe <-  rbind(Annotation_dataframe, c(glue("{Log_file[i_row, 2]} | {Log_file[i_row, 3]} {Log_file[i_row, 4]} - {Log_file[i_row, 5]}"), 
                                  Log_file[i_row, 3], Log_file[i_row, 4], 
                                  Log_file[i_row, 5], Log_file[i_row, 1]))
  } 
  else if (Log_file[i_row, 2] != "Pass_line") {
    if (Log_file[i_row, 1] == "Inser") {
      Annotation_dataframe <- rbind(Annotation_dataframe, c(glue("{Log_file[i_row, 2]} | {Log_file[i_row, 3]} {Log_file[i_row, 4]} - {Log_file[i_row, 5]}"), 
                                    Log_file[i_row, 3], Log_file[i_row, 4], 
                                    Log_file[i_row, 5], Log_file[i_row, 1]))
      Main_bed <-  rbind(Main_bed, c(Log_file[i_row, 3], Log_file[i_row, 4], 
                        Log_file[i_row, 5]))
    }
    else if (Log_file[i_row, 1] == "Trans") {
      Annotation_dataframe <- rbind(Annotation_dataframe, c(glue("{Log_file[i_row, 2]} | {Log_file[i_row, 3]} {Log_file[i_row, 4]} - {Log_file[i_row, 5]}"), 
                                                            Log_file[i_row + 1, 3], Log_file[i_row + 1, 4], 
                                                            Log_file[i_row + 1, 5], Log_file[i_row, 1]))
      Log_file[i_row + 1,] <- "Pass_line"  
    } 
    else {
      print("Лол, что это?!")
    }
  }
}

current_colors <- vector()
current_domain <- vector()

for (change_chr in unique(Annotation_dataframe[, 5])) {
  current_colors <- c(current_colors, colu[change_chr])
  current_domain <- c(current_domain, change_chr)
}



#construct graph
map_plot <- chromoMap(ch.files = Main_bed, data.files = Annotation_dataframe, ploidy = 1, segment_annotation = T,
          data_based_color_map = T,
          legend = T,
          chr_color = "gray",
          data_type = "categorical",
          data_colors = current_colors,
          discrete.domain = current_domain,
          lg_x = 40,
          lg_y = 600)
saveWidget(widget = map_plot, selfcontained = TRUE, file = glue("test.html", ))
