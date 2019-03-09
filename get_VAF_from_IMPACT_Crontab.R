#library
library(data.table)
library(dplyr)
library(plyr)
library(stringr)
library(gsheet)
specify_decimal <- function(x, k) format(round(x, k), nsmall=k)
"%ni%"<-Negate("%in%")

############################################################################################################################################################################
#Pathology data aquisition
############################################################################################################################################################################

impact_qc_metrics<-read.table("/ifs/res/taylorlab/chavans/WES_sample_selection/MASTER_SAMPLE_LIST_deid.txt", fill = T, header = T, stringsAsFactors = F, sep = "\t")
hemepact_qc_metrics<-read.table("/ifs/res/taylorlab/chavans/WES_sample_selection/Deidentified_HEME_Sample_List.txt", fill = T, header = T, stringsAsFactors = F, sep = "\t")
pathology_qc_metrics<-rbind(impact_qc_metrics, hemepact_qc_metrics, fill = TRUE)
head(pathology_qc_metrics); dim(pathology_qc_metrics)
res <- pathology_qc_metrics %>% 
              dplyr::mutate(`AF_>=0.15_Exonic`=ifelse(Median_Exonic_Mutation_VAF>=0.15,1,0), 
                             `AF_>=0.15_Silent`=ifelse(Median_Silent_Mutation_VAF>=0.15,1,0)) %>%
              select(DMP.Sample.ID = DMP_ASSAY_ID, Median_Exonic_Mutation_VAF, Median_Silent_Mutation_VAF, `AF_>=0.15_Exonic`, `AF_>=0.15_Silent`)
head(res)
dim(res)
write.table(res, '/ifs/res/taylorlab/chavans/WES_sample_selection/Deidentified_IMPACT_HEME_Sample_List.CCS.txt', row.names = F, quote = F, append = F, sep = "\t")

############################################################################################################################################################################
##Query google sheet and keep a back-up file
############################################################################################################################################################################

url <- 'docs.google.com/spreadsheets/d/1K_CNufFracneU9xHub2KnwhTP0LMKf-N-tS62bjVbLc'
query <- read.csv(text=gsheet2text(url, format='csv'), stringsAsFactors=FALSE)
print(query$DMP.Sample.ID)
write.table(query,'/ifs/res/taylorlab/chavans/WES_sample_selection/DMPids_Results_GoogleSheet_Since030119.txt.bkp', row.names = F, quote = F, append = T)

############################################################################################################################################################################
## Actual processing, get VAF or claim missing data
############################################################################################################################################################################

missing_in_path<-setdiff(unique(query$DMP.Sample.ID),unique(res$DMP.Sample.ID))
print(length(missing_in_path))

if(length(missing_in_path) >=1){
  print(paste("Missing",missing_in_path))
  write.table(paste("Samples missing in the metrics file:", missing_in_path), '/ifs/res/taylorlab/chavans/home/log/daily_wes_sample_selection.log', row.names = F, quote = F, append = T)
}
query = query %>% select(DMP.Sample.ID, Request.Date, Tracking.ID, Principal.Investigator, Data.Analyst, Study.Name, Tumor.Type)
subset_res = left_join(query,res,by=c("DMP.Sample.ID")) 
dim(subset_res)
subset_res = subset_res %>% mutate(.,`AF_>=0.15_Exonic`=ifelse(query$DMP.Sample.ID %in% missing_in_path,"Missing_Data",`AF_>=0.15_Exonic`), 
           `AF_>=0.15_Silent`=ifelse(query$DMP.Sample.ID %in% missing_in_path,"Missing_Data",`AF_>=0.15_Silent`)) %>% distinct(.)
dim(subset_res)
print(subset_res)
results = '/ifs/res/taylorlab/chavans/WES_sample_selection/DMPids_Results_GoogleSheet_Since030119.txt'
write.table(subset_res, results, row.names = F, quote = F, append = F, sep = "\t")
############################################################################################################################################################################


