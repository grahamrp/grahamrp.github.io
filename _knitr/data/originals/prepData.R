# Process 2014 and 2015 data from original source spreadsheets to one table

# Connect to Excel .xlsx workbooks and extract Institution tables
require(XLConnect)
wb2014 <- loadWorkbook("data/originals//Undergraduate Guardian University Guide 2014.xlsx")
wb2015 <- loadWorkbook("data/originals//Undergraduate Guardian University Guide 2015.xlsx")
table2014 <- readWorksheet(wb2014, sheet = "Institutions", header = TRUE, startRow = 2, endCol = 13)
table2015 <- readWorksheet(wb2015, sheet = "Institution", header = TRUE, startRow = 3)
rm(wb2014, wb2015)

# ---- Parse 2015 Table ----
# parse column 1 of 2015 results (containing last 3 years ranks separated by  → arrows)
# split out column 1 into 3 column matrix
mat <- matrix(unlist(strsplit(table2015$Ranking, " → ")), ncol = 3, byrow = TRUE)
table2015$Ranking <- NULL  # dump composite column
df <- as.data.frame(mat)
colnames(df) <- c('rank2013','rank2014','rank2015')
table2015 <- cbind(df, table2015)
rm(df, mat);
# convert to numeric
table2015$rank2013 <- as.numeric(as.character(table2015$rank2013))
table2015$rank2014 <- as.numeric(as.character(table2015$rank2014))
table2015$rank2015 <- as.numeric(as.character(table2015$rank2015))

# ---- Parse 2014 Table ----
# convert first two columns to numeric (introducing NAs)
table2014[,1] <- sapply(table2014[,1], as.numeric)
# column 2 has ' characters that need stripping out before conversion 
table2014[, 2] <- as.numeric(sub("\'", "", table2014[, 2]))  

# ---- Rename columns to be shorter ----
names(table2014) <- c('rank12.14','rank13.14','rank14.14','inst','score.14','nss.teach.14',
                      'nss.all.14','spend.14','ssr.14','career.14','value.14','tariff.14',
                      'nss.feedback.14')
names(table2015) <- c('rank13.15','rank14.15','rank15.15','inst','score.15','nss.teach.15',
                      'nss.all.15','spend.15','ssr.15','career.15','value.15','tariff.15',
                      'nss.feedback.15')

# attempt to match institutions from both datasets
table2015[is.na(match(table2015$Institution, table2014$Institution)),]
# South Wales is not matched, nor is University Campus Suffolk

require(dplyr)
both <- left_join(table2015, table2014, by = 'inst')
# remove 2014 rankings that are also covered by 2015 (even though sometimes they differ slightly)
both$rank13.14 <- NULL
both$rank14.14 <- NULL

# set rownames to be Institution names
rownames(both) <- both$inst

# remove South Wales (no data before 2015)
both <- subset(both, inst != 'South Wales')

#---- Save 'both' to disk
save(both, file = 'data/prepared.dat')
