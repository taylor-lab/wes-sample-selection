suppressPackageStartupMessages({
  library(data.table)
  library(plyr)
  library(dplyr)
  library(stringr)
})
specify_decimal <- function(x, k) format(round(x, k), nsmall=k)
"%ni%"<-Negate("%in%")

args = commandArgs(TRUE)
if (is.null(args) | length(args)<1) {
  message("Usage: Rscript get_VAF_from_IMPACT.R sample.list")
  quit()
}

pathology_qc_metrics<-fread("/ifs/res/taylorlab/chavans/WES_sample_selection/MASTER_SAMPLE_LIST_deid.txt")
head(pathology_qc_metrics)

query_file = args[1]
sample_ids = fread(query_file, sep = '\t', header=FALSE)
out_file = paste0(gsub(".txt","",query_file),"_res.txt")

head(sample_ids)
names(sample_ids)[1]="DMP Sample ID"

head(pathology_qc_metrics)
sample_ids$`DMP Sample ID` 
missing_in_path<-setdiff(unique(sample_ids$`DMP Sample ID`), unique(pathology_qc_metrics$DMP_ASSAY_ID))

if(length(missing_in_path) >=1){
  print(paste("Missing",missing_in_path))
}

res<-left_join(sample_ids,pathology_qc_metrics,by=c(`DMP Sample ID`="DMP_ASSAY_ID")) %>%
  dplyr::select(everything(sample_ids),Median_Exonic_Mutation_VAF,Median_Silent_Mutation_VAF)

res <- res %>% mutate(`AF_>=0.10_Exonic`=ifelse(Median_Exonic_Mutation_VAF>=0.10,1,0), 
                      `AF_>=0.10_Silent`=ifelse(Median_Silent_Mutation_VAF>=0.10,1,0),
                      `AF_<0.20_Exonic`=ifelse((Median_Exonic_Mutation_VAF<0.20 | is.na(Median_Exonic_Mutation_VAF)==T),"Yes","No"))
res <- res %>% mutate(`AF_>=0.10_Exonic`=ifelse(sample_ids$`DMP Sample ID` %in% missing_in_path,"Missing_Data",`AF_>=0.10_Exonic`), 
                      `AF_>=0.10_Silent`=ifelse(sample_ids$`DMP Sample ID` %in% missing_in_path,"Missing_Data",`AF_>=0.10_Silent`)
)
dim(res)
write.table(res, out_file, sep="\t", row.names=F, quote=F)
