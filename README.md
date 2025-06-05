
<!-- README.md is generated from README.Rmd. Please edit that file -->

# chevreulPlot

This package enables plotting of single cell RNA datasets processed as
SingleCellExperiments

A demo with a developing human retina scRNA-seq dataset from Shayler et
al. is available
<a href="https://cobrinik-1.saban-chla.usc.edu/shinyproxy/app/chevreul" target="_blank" rel="noopener noreferrer">here</a>

This package includes a set of Shiny apps for interactive exploration of
single cell RNA sequencing (scRNA-seq) datasets processed as
<a href="https://bioconductor.org/packages/devel/bioc/vignettes/SingleCellExperiment/inst/doc/intro.html" target="_blank" rel="noopener noreferrer">SingleCellExperiments</a>

chevreulPlot includes tools for:

- Interactive data analysis and visualization

## Installation instructions

chevreulPlot depends on a minimum R version 4.4. chevreulPlot loads the
[Bioconductor](http://bioconductor.org/) package

[`chevreulProcess`](https://github.com/cobriniklab/chevreulProcess)

which enables standardized processing of SingleCellExperiments.

`chevreulPlot` depends on a minimum R version \>=4.4 Get the latest
stable `R` release from [CRAN](http://cran.r-project.org/). Then install
`chevreulPlot` and its dependencies using the following code:

``` r
install.packages("BiocManager")
BiocManager::install("chevreulPlot")
```

## Run clustering on a single object

By default clustering will be run at ten different resolutions between
0.2 and 2.0. Any resolution can be specified by providing the resolution
argument as a numeric vector.

``` r
data("small_example_dataset")

clustered_sce <- sce_clustering_workflow(small_example_dataset,
    experiment_name = "sce_hu_trans",
    organism = "human"
)
```

## Get a first look at a processed dataset using an interactive shiny app

``` r
minimalChevreulApp(small_example_dataset)
```

### Troubleshooting installation

#### Dependency management

When installing an R package like chevreulPlot with many dependencies,
conflicts with existing installations can arise. This is a common issue
in R package management. Here are some strategies to address this
problem:

1.  Consider
    <a href="https://rstudio.github.io/renv/articles/renv.html" target="_blank" rel="noopener noreferrer">renv</a>
    for dependency management. This tool creates isolated environments
    for each project, ensuring that package versions don’t conflict
    across different projects.

2.  Use the conflicted Package The
    <a href="https://conflicted.r-lib.org" target="_blank" rel="noopener noreferrer">conflicted</a>
    package provides an alternative conflict resolution strategy. It
    makes every conflict an error, forcing you to choose which function
    to use

#### Slow internet connection

When installing R packages on slow internet connections, several issues
can arise, particularly with larger packages or when using functions
like remotes::install_github(). Here are some strategies to address
bandwidth-related problems:

Set a longer timeout for downloads: `options(timeout = 9999999)`

Specify the download method: `options(download.file.method = "libcurl")`

## Transcript-level quantification

For transcript-level analysis, users must incorporate transcript-level
data into the SingleCellExperiment object as an alternative experiment
before initiating the chevreulProcess processing pipeline. This step is
crucial for enabling detailed exploration at the transcript level.

Transcripts may be quantified using any of several available methods,
including alignment-free methods best used with well-annotated
transcriptomes (Salmon, Kallisto), alignment-based methods best used to
detect novel isoforms (StringTie2), or long-read methods for use with
long-read sequencing data (IsoQuant).

## Integration implementation

The `sce_integrate()` function in chevreulProcess implements integration
(batch correction) of scRNA-seq datasets by using the
<a href="https://bioconductor.org/packages/devel/bioc/vignettes/batchelor/inst/doc/correction.html" target="_blank" rel="noopener noreferrer">batchelor</a>
package.

It accepts a list of SingleCellExperiment objects as input for
integration and stores the corresponding batch information in a metadata
field named ‘batch’. By default, it employs batchelor’s
`correctExperiments` function to preserve pre-existing data structures
and metadata from input SingleCellExperiment objects within the
integrated output.

## Hardware requirements

Recommended minimum hardware requirements for running chevreulPlot are
as follows:

- RAM: A minimum of 16 GB RAM is recommended for initial analysis.
  However, for larger datasets or more complex analyses, 64 GB or more
  is advisable.
- CPU: Having multiple cores can be beneficial for parallel processing.
- Storage: Sufficient storage space is necessary, especially for
  temporary files. The exact amount depends on the size of your datasets
- R Version: Chevruel requires R version 4.4 or greater

It’s important to note that these requirements can vary based on the
size and complexity of your dataset. As the number of cells increases,
so do the hardware requirements. For instance: A dataset with around
8,000 cells can be analyzed with 8 GB of RAM. For larger datasets or
more complex analyses, 64-128 GB of RAM can be beneficial.

## Learn More

To learn more about the usage of Bioconductor tools for single-cell
RNA-seq analysis. Consult the book
<a href="https://bioconductor.org/books/release/OSCA/" target="_blank" rel="noopener noreferrer">Orchestrating
Single-Cell Analysis with Bioconductor</a>. The book walks through
common workflows for the analysis of single-cell RNA-seq data
(scRNA-seq). This book will show you how to make use of cutting-edge
Bioconductor tools to process, analyze, visualize, and explore scRNA-seq
data
