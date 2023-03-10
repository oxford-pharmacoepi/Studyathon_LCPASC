# Create zip file
zipName <- paste0(db.name,"_Results")
tempDir <- zipName
tempDirCreated <- FALSE
if (!dir.exists(tempDir)) {
  dir.create(tempDir)
  tempDirCreated <- TRUE
}

start <- Sys.time()

# Start log
log_file <- paste0(tempDir, "/log.txt")
# Think what to do if already there. Overwrite, append?
logger <- create.logger()
logfile(logger) <- log_file
level(logger) <- "INFO"

# Read initial cohorts
if (readInitialCohorts){
  info(logger, 'INSTANTIATING INITIAL COHORTS')
  cdm <- cdmFromCon(db, cdm_database_schema, 
                    writeSchema = results_database_schema)
  source(here("1_InitialCohorts", "InstantiateStudyCohorts.R"), local=TRUE)
  info(logger, 'GOT INITIAL COHORTS')
} else {
  info(logger, 'INITIAL COHORTS ALREADY INSTANTIATED')
  initialCohortSet <- CDMConnector::readCohortSet(
    here::here("1_InitialCohorts", "Jsons")) %>%
    dplyr::mutate(cohort_name = substr(cohort_name, 5, nchar(cohort_name)))
  cdm <- cdmFromCon(
    db, cdm_database_schema, writeSchema = results_database_schema,
    cohortTables = "studyathon_lcpasc")
  info(logger, 'INITIAL COHORTS READ')
}

# Instantiate study cohorts
if(getStudyCohorts) {
  info(logger, 'GETTING STUDY COHORTS')
  source(here("2_StudyCohorts","GetStudyCohorts.R"), local = TRUE)
  info(logger, 'GOT STUDY COHORTS')
}

# Objective 1: Incidence and Prevalence
if(doIncidencePrevalence) {
  info(logger, 'GETTING INCIDENCE AND PREVALENCE')
  source(here("3_IncidencePrevalence","WP1_code.R"), local = TRUE)
  info(logger, 'GOT INCIDENCE AND PREVALENCE')
}

# Objective 2a: Characterisation
if(doCharacterisation || doDrugUtilisation || doTreatmentPatterns) {
  info(logger, 'DOING LARGE-SCALE CHARACTERISATION, DRUG UTILISATION AND/OR TREATMENT PATTERNS')
  source(here("4_Characterisation","WP2_code.R"), local = TRUE)
  info(logger, 'FINISHED LARGE-SCALE CHARACTERISATION, DRUG UTILISATION AND/OR TREATMENT PATTERNS')
}

# Objective 3a: Clustering
if(doClustering) {
  info(logger, 'PERFORMING LCA CLUSTERING AND NETWORK ANALYSIS')
  source(here("5_Clustering","WP3_code.R"), local = TRUE)
  info(logger, 'FINISHED LCA CLUSTERING AND NETWORK ANALYSIS')
}

# Objective 3c: Trajectories
if(doTrajectories) {
  info(logger, 'STUDYING TRAJECTORIES')
  source(here("6_Trajectories","Trajectories.R"), local = TRUE)
  info(logger, 'FINISHED TRAJECTORIES')
}

# Preliminary plots
#if(createPlots) {
#  info(logger, 'PLOTTING RESULTS')
#  source(here("7_Plots","Plots.R"), local = TRUE)
#  info(logger, 'RESULTS PLOTTED')
#}

zip::zip(zipfile = file.path(output.folder, paste0(zipName, ".zip")),
         files = list.files(tempDir, full.names = TRUE))
if (tempDirCreated) {
  unlink(tempDir, recursive = TRUE)
}
info(logger, 'SAVED RESULTS IN THE OUTPUT FOLDER')

print("Done!")
print("If all has worked, there should now be a zip file with your results
      in the output folder to share")
print("Thank you for running the study!")
Sys.time() - start
readLines(log_file)
