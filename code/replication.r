##########################################################################
# Replication and Extension of:
# Abadie, A., Diamond, A., & Hainmueller, J. (2015). 
# "Comparative Politics and the Synthetic Control Method"
# American Journal of Political Science, 59(2), 495-510.
#
# Original DOI: 10.1111/ajps.12116
# Data Source: Harvard Dataverse (doi:10.7910/DVN/24714)
#
# This replication focuses on:
# 1. Replicating Figure 2: West Germany vs Synthetic West Germany
# 2. Replicating the GDP gap analysis (Figure 3)
# 3. Extension: Sensitivity analysis using different pre-treatment periods
##########################################################################

# Clear workspace and load packages
rm(list = ls())

# Install packages if needed
if (!require("foreign")) install.packages("foreign", repos = "http://cran.us.r-project.org")
if (!require("Synth")) install.packages("Synth", repos = "http://cran.us.r-project.org")

library(foreign)
library(Synth)

# Set working directory to project root
# setwd("/Users/ahmedbakr/Documents/Minerva/CS130/synthetic_control_replication")

# Load Data
d <- read.dta("data/repgermany.dta")

# Examine the data structure
cat("\n=== DATA STRUCTURE ===\n")
cat("Dimensions:", dim(d)[1], "rows,", dim(d)[2], "columns\n")
cat("Variables:", paste(names(d), collapse = ", "), "\n")
cat("Countries:", paste(unique(d$country), collapse = ", "), "\n")
cat("Years:", min(d$year), "-", max(d$year), "\n")
cat("Treatment unit (West Germany) index:", 7, "\n\n")

##########################################################################
# PART 1: REPLICATION OF MAIN ANALYSIS
##########################################################################

cat("\n========================================\n")
cat("PART 1: REPLICATING MAIN ANALYSIS\n")
cat("========================================\n\n")

#---------------------------------------------------------------------------
# Step 1: Data Preparation for Training Model (Cross-Validation)
#---------------------------------------------------------------------------

# Training model uses 1971-1980 as predictor period and 1981-1990 for optimization
dataprep.train <- dataprep(
  foo = d,
  predictors = c("gdp", "trade", "infrate"),
  dependent = "gdp",
  unit.variable = 1,  # index
  time.variable = 3,  # year
  special.predictors = list(
    list("industry", 1971:1980, c("mean")),
    list("schooling", c(1970, 1975), c("mean")),
    list("invest70", 1980, c("mean"))
  ),
  treatment.identifier = 7,  # West Germany
  controls.identifier = unique(d$index)[-7],  # All other OECD countries
  time.predictors.prior = 1971:1980,
  time.optimize.ssr = 1981:1990,
  unit.names.variable = 2,  # country
  time.plot = 1960:2003
)

# Fit training model to get optimal V weights
cat("Fitting training model for V weights...\n")
synth.train <- synth(
  data.prep.obj = dataprep.train,
  Margin.ipop = 0.005,
  Sigf.ipop = 7,
  Bound.ipop = 6
)

#---------------------------------------------------------------------------
# Step 2: Data Preparation for Main Model
#---------------------------------------------------------------------------

# Main model uses 1981-1990 as predictor period and 1960-1989 for optimization
dataprep.main <- dataprep(
  foo = d,
  predictors = c("gdp", "trade", "infrate"),
  dependent = "gdp",
  unit.variable = 1,
  time.variable = 3,
  special.predictors = list(
    list("industry", 1981:1990, c("mean")),
    list("schooling", c(1980, 1985), c("mean")),
    list("invest80", 1980, c("mean"))
  ),
  treatment.identifier = 7,
  controls.identifier = unique(d$index)[-7],
  time.predictors.prior = 1981:1990,
  time.optimize.ssr = 1960:1989,
  unit.names.variable = 2,
  time.plot = 1960:2003
)

# Fit main model using V weights from training model
cat("Fitting main model with cross-validated V weights...\n")
synth.main <- synth(
  data.prep.obj = dataprep.main,
  custom.v = as.numeric(synth.train$solution.v)
)

#---------------------------------------------------------------------------
# Step 3: Generate Synth Tables (Tables 1 & 2)
#---------------------------------------------------------------------------

synth.tables <- synth.tab(
  dataprep.res = dataprep.main,
  synth.res = synth.main
)

# Print country weights (Table 1)
cat("\n=== TABLE 1: COUNTRY WEIGHTS ===\n")
weights_df <- data.frame(
  Country = synth.tables$tab.w[, 2],
  Weight = round(synth.tables$tab.w[, 1], 3)
)
weights_df <- weights_df[order(-weights_df$Weight), ]
print(weights_df[weights_df$Weight > 0.001, ])

# Print predictor balance (Table 2)
cat("\n=== TABLE 2: PREDICTOR BALANCE ===\n")
predictor_balance <- synth.tables$tab.pred
rownames(predictor_balance) <- c("GDP per-capita", "Trade openness",
                                   "Inflation rate", "Industry share",
                                   "Schooling", "Investment rate")
colnames(predictor_balance) <- c("West Germany", "Synthetic", "Sample Mean")
print(round(predictor_balance, 1))

#---------------------------------------------------------------------------
# Step 4: Create Figures
#---------------------------------------------------------------------------

# Calculate synthetic West Germany GDP
synthY0 <- dataprep.main$Y0 %*% synth.main$solution.w
years <- 1960:2003

# Create data frame for plotting
plot_data <- data.frame(
  year = years,
  west_germany = as.vector(dataprep.main$Y1plot),
  synthetic = as.vector(synthY0),
  oecd_mean = aggregate(d$gdp, by = list(d$year), mean, na.rm = TRUE)[, 2]
)

# Calculate gap
plot_data$gap <- plot_data$west_germany - plot_data$synthetic

# Save data for later use
save(plot_data, synth.main, dataprep.main, file = "output/main_results.RData")

#---------------------------------------------------------------------------
# FIGURE 2: West Germany vs Synthetic West Germany
#---------------------------------------------------------------------------

png("output/figure2_replication.png", width = 800, height = 600, res = 100)

par(mar = c(5, 5, 4, 2))
plot(years, plot_data$west_germany,
     type = "l", ylim = c(0, 33000),
     col = "black", lty = "solid", lwd = 2,
     ylab = "Per-capita GDP (PPP, 2002 USD)",
     xlab = "Year",
     main = "Figure 2: Trends in Per-Capita GDP\nWest Germany vs. Synthetic West Germany",
     xaxs = "i", yaxs = "i")

lines(years, plot_data$synthetic, col = "black", lty = "dashed", lwd = 2)
abline(v = 1990, lty = "dotted", col = "gray50")

legend("bottomright",
       legend = c("West Germany", "Synthetic West Germany"),
       lty = c("solid", "dashed"),
       col = c("black", "black"),
       lwd = c(2, 2),
       cex = 0.9, bg = "white")

arrows(1987, 23000, 1989, 23000, col = "black", length = 0.1)
text(1982.5, 23000, "Reunification", cex = 0.9)

dev.off()
cat("\nFigure 2 saved to output/figure2_replication.png\n")

#---------------------------------------------------------------------------
# FIGURE 3: GDP Gap
#---------------------------------------------------------------------------

png("output/figure3_replication.png", width = 800, height = 600, res = 100)

par(mar = c(5, 5, 4, 2))
plot(years, plot_data$gap,
     type = "l", ylim = c(-4500, 4500),
     col = "black", lty = "solid", lwd = 2,
     ylab = "Gap in Per-capita GDP (PPP, 2002 USD)",
     xlab = "Year",
     main = "Figure 3: Per-Capita GDP Gap\nWest Germany minus Synthetic West Germany",
     xaxs = "i", yaxs = "i")

abline(v = 1990, lty = "dotted", col = "gray50")
abline(h = 0, lty = "dotted", col = "gray50")

arrows(1987, 1000, 1989, 1000, col = "black", length = 0.1)
text(1982.5, 1000, "Reunification", cex = 0.9)

dev.off()
cat("Figure 3 saved to output/figure3_replication.png\n")

##########################################################################
# PART 2: EXTENSION - SENSITIVITY ANALYSIS
##########################################################################

cat("\n========================================\n")
cat("PART 2: EXTENSION - SENSITIVITY ANALYSIS\n")
cat("========================================\n\n")

# We will conduct sensitivity analysis by:
# 1. Varying the pre-treatment optimization period
# 2. Performing placebo tests across control countries
# 3. Leave-one-out analysis

#---------------------------------------------------------------------------
# Extension 2.1: Placebo Tests (In-Space Placebo)
#---------------------------------------------------------------------------

cat("Running placebo tests across control countries...\n")
cat("This may take a few minutes...\n\n")

# Store gaps for all countries
storegaps <- matrix(NA, length(years), length(unique(d$index)) - 1)
rownames(storegaps) <- years
co <- unique(d$index)

pb_counter <- 1
for (k in unique(d$index)[-7]) {
  
  # Training model
  dataprep.pb.train <- dataprep(
    foo = d,
    predictors = c("gdp", "trade", "infrate"),
    dependent = "gdp",
    unit.variable = 1,
    time.variable = 3,
    special.predictors = list(
      list("industry", 1971:1980, c("mean")),
      list("schooling", c(1970, 1975), c("mean")),
      list("invest70", 1980, c("mean"))
    ),
    treatment.identifier = k,
    controls.identifier = co[-which(co == k)],
    time.predictors.prior = 1971:1980,
    time.optimize.ssr = 1981:1990,
    unit.names.variable = 2,
    time.plot = 1960:2003
  )
  
  synth.pb.train <- synth(
    data.prep.obj = dataprep.pb.train,
    Margin.ipop = 0.005, Sigf.ipop = 7, Bound.ipop = 6
  )
  
  # Main model
  dataprep.pb.main <- dataprep(
    foo = d,
    predictors = c("gdp", "trade", "infrate"),
    dependent = "gdp",
    unit.variable = 1,
    time.variable = 3,
    special.predictors = list(
      list("industry", 1981:1990, c("mean")),
      list("schooling", c(1980, 1985), c("mean")),
      list("invest80", 1980, c("mean"))
    ),
    treatment.identifier = k,
    controls.identifier = co[-which(co == k)],
    time.predictors.prior = 1981:1990,
    time.optimize.ssr = 1960:1989,
    unit.names.variable = 2,
    time.plot = 1960:2003
  )
  
  synth.pb.main <- synth(
    data.prep.obj = dataprep.pb.main,
    custom.v = as.numeric(synth.pb.train$solution.v)
  )
  
  storegaps[, pb_counter] <- dataprep.pb.main$Y1 - 
    (dataprep.pb.main$Y0 %*% synth.pb.main$solution.w)
  
  pb_counter <- pb_counter + 1
}

# Add column names
d_ordered <- d[order(d$index, d$year), ]
colnames(storegaps) <- unique(d_ordered$country)[-7]

# Add West Germany gap
storegaps <- cbind(plot_data$gap, storegaps)
colnames(storegaps)[1] <- "West Germany"

#---------------------------------------------------------------------------
# FIGURE 5: RMSPE Ratio Analysis
#---------------------------------------------------------------------------

# Function to compute RMSE
rmse <- function(x) sqrt(mean(x^2))

# Pre-reunification period: 1960-1989 (rows 1-30)
# Post-reunification period: 1990-2003 (rows 31-44)
preloss <- apply(storegaps[1:30, ], 2, rmse)
postloss <- apply(storegaps[31:44, ], 2, rmse)
rmspe_ratio <- postloss / preloss

# Create dataframe for plotting
rmspe_df <- data.frame(
  country = names(rmspe_ratio),
  ratio = as.vector(rmspe_ratio)
)
rmspe_df <- rmspe_df[order(rmspe_df$ratio), ]
rmspe_df$country <- factor(rmspe_df$country, levels = rmspe_df$country)

# Highlight West Germany
rmspe_df$highlight <- ifelse(rmspe_df$country == "West Germany", "West Germany", "Control")

png("output/figure5_rmspe_ratio.png", width = 800, height = 600, res = 100)

par(mar = c(5, 10, 4, 2))

# Create point colors and shapes
point_cols <- rep("black", nrow(rmspe_df))
point_cols[rmspe_df$country == "West Germany"] <- "red"
point_pch <- rep(1, nrow(rmspe_df))
point_pch[rmspe_df$country == "West Germany"] <- 19

dotchart(rmspe_df$ratio,
         labels = as.character(rmspe_df$country),
         xlab = "Post-Period RMSPE / Pre-Period RMSPE",
         main = "Figure 5: Ratio of Post-Reunification RMSPE\nto Pre-Reunification RMSPE",
         pch = point_pch,
         col = point_cols)

dev.off()
cat("Figure 5 saved to output/figure5_rmspe_ratio.png\n")

#---------------------------------------------------------------------------
# Extension 2.2: Placebo Gap Plot (Spaghetti Plot)
#---------------------------------------------------------------------------

png("output/extension_placebo_gaps.png", width = 900, height = 600, res = 100)

par(mar = c(5, 5, 4, 2))

# Plot all control country gaps in gray
plot(years, storegaps[, 1], type = "n",
     ylim = c(-10000, 10000),
     xlab = "Year",
     ylab = "Gap in Per-capita GDP",
     main = "Extension: Placebo Test\nGDP Gaps for West Germany and Control Countries",
     xaxs = "i", yaxs = "i")

# Add gray lines for control countries
for (i in 2:ncol(storegaps)) {
  lines(years, storegaps[, i], col = "gray70", lwd = 0.5)
}

# Add West Germany in bold black
lines(years, storegaps[, 1], col = "black", lwd = 2.5)

abline(v = 1990, lty = "dotted", col = "gray30")
abline(h = 0, lty = "dotted", col = "gray30")

legend("bottomleft",
       legend = c("West Germany", "Control Countries"),
       col = c("black", "gray70"),
       lwd = c(2.5, 1),
       cex = 0.9, bg = "white")

dev.off()
cat("Extension placebo gaps figure saved to output/extension_placebo_gaps.png\n")

#---------------------------------------------------------------------------
# Extension 2.3: Pre-Treatment Fit Quality Filter
#---------------------------------------------------------------------------

# Filter countries with good pre-treatment fit (RMSPE < 2x West Germany's)
wg_pre_rmspe <- preloss["West Germany"]
good_fit <- preloss <= (2 * wg_pre_rmspe)

png("output/extension_placebo_filtered.png", width = 900, height = 600, res = 100)

par(mar = c(5, 5, 4, 2))

plot(years, storegaps[, 1], type = "n",
     ylim = c(-6000, 6000),
     xlab = "Year",
     ylab = "Gap in Per-capita GDP",
     main = "Extension: Placebo Test (Filtered)\nCountries with Pre-Treatment RMSPE < 2x West Germany",
     xaxs = "i", yaxs = "i")

# Add gray lines for control countries with good fit
for (i in 2:ncol(storegaps)) {
  if (good_fit[i]) {
    lines(years, storegaps[, i], col = "gray70", lwd = 0.8)
  }
}

# Add West Germany
lines(years, storegaps[, 1], col = "black", lwd = 2.5)

abline(v = 1990, lty = "dotted", col = "gray30")
abline(h = 0, lty = "dotted", col = "gray30")

n_filtered <- sum(good_fit) - 1  # Exclude West Germany
legend("bottomleft",
       legend = c("West Germany", paste0("Control Countries (n=", n_filtered, ")")),
       col = c("black", "gray70"),
       lwd = c(2.5, 1),
       cex = 0.9, bg = "white")

dev.off()
cat("Extension filtered placebo figure saved to output/extension_placebo_filtered.png\n")

#---------------------------------------------------------------------------
# Save all results
#---------------------------------------------------------------------------

# Save RMSPE results
rmspe_results <- data.frame(
  Country = names(preloss),
  Pre_RMSPE = round(preloss, 2),
  Post_RMSPE = round(postloss, 2),
  Ratio = round(rmspe_ratio, 2)
)
rmspe_results <- rmspe_results[order(-rmspe_results$Ratio), ]

write.csv(rmspe_results, "output/rmspe_results.csv", row.names = FALSE)
cat("\nRMSPE results saved to output/rmspe_results.csv\n")

# Save gap data
gap_data <- data.frame(year = years, storegaps)
write.csv(gap_data, "output/gap_data.csv", row.names = FALSE)
cat("Gap data saved to output/gap_data.csv\n")

##########################################################################
# SUMMARY STATISTICS
##########################################################################

cat("\n========================================\n")
cat("SUMMARY OF RESULTS\n")
cat("========================================\n\n")

cat("1. SYNTHETIC CONTROL WEIGHTS:\n")
cat("   Main contributors to synthetic West Germany:\n")
top_weights <- weights_df[weights_df$Weight > 0.01, ]
for (i in 1:min(5, nrow(top_weights))) {
  cat(sprintf("   - %s: %.1f%%\n", 
              top_weights$Country[i], 
              top_weights$Weight[i] * 100))
}

cat("\n2. PRE-TREATMENT FIT:\n")
cat(sprintf("   West Germany Pre-RMSPE: %.2f\n", preloss["West Germany"]))
cat(sprintf("   Average Control Pre-RMSPE: %.2f\n", mean(preloss[-1])))

cat("\n3. POST-TREATMENT EFFECT:\n")
avg_gap_post <- mean(plot_data$gap[plot_data$year >= 1990])
cat(sprintf("   Average GDP gap (1990-2003): $%.0f\n", avg_gap_post))
cat(sprintf("   This represents a %.1f%% loss relative to synthetic\n", 
            100 * avg_gap_post / mean(plot_data$synthetic[plot_data$year >= 1990])))

cat("\n4. STATISTICAL SIGNIFICANCE (Placebo Test):\n")
wg_rank <- which(rmspe_df$country == "West Germany")
cat(sprintf("   West Germany RMSPE ratio rank: %d out of %d\n", 
            nrow(rmspe_df) - wg_rank + 1, nrow(rmspe_df)))
cat(sprintf("   Implied p-value: %.3f\n", wg_rank / nrow(rmspe_df)))

cat("\n========================================\n")
cat("REPLICATION COMPLETE\n")
cat("========================================\n")

