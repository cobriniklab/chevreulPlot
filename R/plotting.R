#' Plot Metadata Variables
#'
#' Plots static or interactive plot where each point represents a cell metadata
#' variable whose position on the map depends on cell embeddings 
#' determined by the reduction technique used
#'
#' @param object A SingleCellExperiment object
#' @param embedding The dimensional reduction technique to be used
#' @param group Name of one or more metadata columns to group (color) cells by
#' @param dims Dimensions to plot, must be a two-length numeric vector
#' @param highlight A list of vectors of cells to highlight
#' @param return_plotly Convert plot to interactive web-based graph
#' @param ... extra parameters passed to ggplot
#'
#' @return a ggplot
#' @export
#'
#' @examples
#' 
#' data(small_example_dataset)
#' 
#' # static mode
#' plot_colData_on_embedding(small_example_dataset, "Mutation_Status", return_plotly = FALSE)
plot_colData_on_embedding <- function(object, group = "batch", 
                     embedding = "UMAP", dims = c(1, 2), 
                     highlight = NULL,  
                     return_plotly = FALSE, ...) {
    metadata <- get_colData(object)
    key <- rownames(metadata)

    dims <- as.numeric(dims)

    d <- plotReducedDim(object = object, dimred = embedding, 
                        ncomponents = 2, color_by = group, ...) +
        aes(key = key, cellid = key) +
        # theme(legend.text=element_text(size=10)) +
        NULL

    if(!return_plotly) return(d)

    plotly_plot <- ggplotly(d, tooltip = "cellid", height = 500) |>
        plotly_settings() |>
        toWebGL() |>
        identity()
    
    return(plotly_plot)
}


#' Plotly settings
#'
#' Change settings of a plotly plot
#'
#' @param plotly_plot  A plotly plot
#' @param width Default set to '600'
#' @param height Default set to '700'
#'
#' @return a plotly plot with altered settings
plotly_settings <- function(plotly_plot, width = 600, height = 700) {
    plotly_plot |>
        layout(dragmode = "lasso") |>
        config(toImageButtonOptions = list(format = "svg", 
                                           filename = "myplot", 
                                           width = width, height = height)) |>
        identity()
}

#' Plot Violin plot
#'
#' Plots a Violin plot of a single data (gene expression, metrics, etc.)
#' grouped by a metadata variable
#'
#' @param object A SingleCellExperiment object
#' @param group_by Variable to group (color) cells by
#' @param plot_vals plot values
#' @param features Features to plot
#' @param experiment Name of experiment to use, defaults to active experiment
#' @param ... extra parameters passed to ggplot2
#'
#' @return a violin plot
#' @export
#' @examples
#' data("tiny_sce")
#' plot_violin(tiny_sce, "Prep.Method", features = "NRL")
#' 
plot_violin <- function(object, group_by = "batch", 
                        plot_vals = NULL, features = "NRL", 
                        experiment = "gene", ...) {
    if (is.null(plot_vals)) {
        plot_vals <- unique(get_colData(object)[[group_by]])
        plot_vals <- plot_vals[!is.na(plot_vals)]
    }
    object <- object[, get_colData(object)[[group_by]] %in% plot_vals]
    vln_plot <- plotExpression(
        object, features = features, x = group_by, color_by = group_by) + 
        geom_boxplot(width = 0.2) + NULL
    print(vln_plot)
}

#' Plot Feature
#'
#' Plots gene or transcript expression overlaid on a given embedding.
#'
#' @param object A SingleCellExperiment object
#' @param embedding Dimensional reduction technique to be used
#' @param features Feature to plot
#' @param dims Dimensions to plot, must be a two-length numeric vector
#' @param return_plotly return plotly object
#' @param ... additional arguments passed to plotReduceDim
#'
#' @return an embedding colored by a feature of interest
#' @export
#' @examples
#' 
#' data(small_example_dataset)
#' plot_feature_on_embedding(small_example_dataset, embedding = "UMAP", 
#' features = "Gene_0001")
#'
plot_feature_on_embedding <- function(object, embedding = c("UMAP", "PCA", "TSNE"), 
                         features, dims = c(1, 2), return_plotly = FALSE, ...) {
    embedding <- match.arg(embedding)
    
    embedding <- toupper(embedding)

    metadata <- get_colData(object)
    key <- rownames(metadata)

    dims <- as.numeric(dims)

    fp <- plotReducedDim(object = object, color_by = features, 
                         dimred = embedding, ...) +
        aes(key = key, cellid = key, alpha = 0.7)

    if (!return_plotly) return(fp)

    plotly_plot <- ggplotly(fp, tooltip = "cellid", height = 500) |>
        plotly_settings() |>
        toWebGL() |>
        identity()

    return(plotly_plot)
}

#' Plot Cluster Marker Genes
#'
#' Plot a dot plot of n marker features grouped by cell metadata
#' available methods are wilcoxon rank-sum test
#'
#' @param object a object
#' @param group_by the metadata variable from which to pick clusters
#' @param num_markers default is 5
#' @param selected_values selected values to display
#' @param return_plotly whether to return an interactive plotly plot
#' @param marker_method "wilcox"
#' @param experiment experiment to plot default gene
#' @param hide_technical whether to exclude mitochondrial or ribosomal genes
#' @param unique_markers whether to plot only unique marker genes for group
#' @param p_val_cutoff cutoff for p value display
#' @param ... extra parameters passed to ggplot2
#'
#' @return a ggplot with marker genes from group_by
#' @export
#' @importFrom forcats fct_na_value_to_level
#'
#' @examples
#' 
#' data(small_example_dataset)
#' plot_marker_features(small_example_dataset, group_by = "gene_snn_res.1")
#'
plot_marker_features <- function(object, group_by = "batch", num_markers = 5, 
                         selected_values = NULL, return_plotly = FALSE, 
                         marker_method = "wilcox", experiment = "gene", 
                         hide_technical = NULL, unique_markers = FALSE, 
                         p_val_cutoff = 1, ...) {
    object <- find_all_markers(object, group_by, experiment = experiment, 
                               p_val_cutoff = p_val_cutoff)
    marker_table <- metadata(object)$markers[[group_by]]
    markers <- marker_table |>
        enframe_markers()
    
    if (!is.null(hide_technical)) {
        markers <- map(markers, c)
        if (hide_technical == "pseudo") {
            markers <- map(markers, ~ .x[!.x %in% pseudogenes[[experiment]]])
        } else if (hide_technical == "mito_ribo") {
            markers <- map(markers, ~ .x[!str_detect(.x, "^MT-")])
            markers <- map(markers, ~ .x[!str_detect(.x, "^RPS")])
            markers <- map(markers, ~ .x[!str_detect(.x, "^RPL")])
        } else if (hide_technical == "all") {
            markers <- map(markers, ~ .x[!.x %in% pseudogenes[[experiment]]])
            markers <- map(markers, ~ .x[!str_detect(.x, "^MT-")])
            markers <- map(markers, ~ .x[!str_detect(.x, "^RPS")])
            markers <- map(markers, ~ .x[!str_detect(.x, "^RPL")])
        }
        min_length <- min(map_int(markers, length))
        markers <- map(markers, head, min_length) |> bind_cols()
    }
    if (unique_markers) {
        markers <- markers |>
            mutate(precedence = row_number()) |>
            pivot_longer(-precedence, names_to = "group", 
                         values_to = "markers") |>
            arrange(markers, precedence) |>
            group_by(markers) |>
            filter(row_number() == 1) |>
            arrange(group, precedence) |>
            drop_na() |>
            group_by(group) |>
            mutate(precedence = row_number()) |>
            pivot_wider(names_from = "group", values_from = "markers") |>
            select(-precedence)
    }
    sliced_markers <- markers |>
        slice_head(n = num_markers) |>
        pivot_longer(everything(), names_to = "group", 
                     values_to = "feature") |>
        arrange(group) |>
        distinct(feature, .keep_all = TRUE) |>
        identity()
    if (!is.null(selected_values)) {
        object <- object[, get_colData(object)[[group_by]] %in% 
                             selected_values]
        sliced_markers <- sliced_markers |>
            filter(group %in% selected_values) |>
            distinct(feature, .keep_all = TRUE)
    }
    vline_coords <- head(cumsum(table(sliced_markers$group)) + 0.5, -1)
    sliced_markers <- pull(sliced_markers, feature)

    object[[group_by]] <- fct_na_value_to_level(factor(object[[group_by]]))
    markerplot <- plotDots(object, features = sliced_markers, 
                           group = group_by) +
        theme(axis.text.x = element_text(size = 10, angle = 45, 
                                         vjust = 1, hjust = 1), 
              axis.text.y = element_text(size = 10)) +
        # scale_y_discrete(position = "left") +
        # scale_x_discrete(limits = sliced_markers) +
        geom_hline(yintercept = vline_coords, linetype = 2) +
        NULL
    if (!return_plotly) return(markerplot)

    plot_height <- (150 * num_markers)
    plot_width <- (100 * length(levels(
        as.factor(get_colData(object)[[group_by]]))))
    markerplot <- ggplotly(markerplot, height = plot_height, 
                           width = plot_width) |>
        plotly_settings() |>
        toWebGL() |>
        identity()
    return(list(plot = markerplot, markers = marker_table))
}

#' Plot Read Count
#'
#' Draw a box plot for read count data of a metadata variable
#'
#' @param object A object
#' @param group_by Metadata variable to plot. Default set to "nCount_RNA"
#' @param fill_by Variable to color bins by. Default set to "batch"
#' @param yscale Scale of y axis. Default set to "linear"
#' @param return_plotly whether to return an interactive plotly plot
#'
#' @return a histogram of read counts
#' @export
#'
#' @examples
#' 
#' data(small_example_dataset)
#' small_example_dataset <- sce_calcn(small_example_dataset)
#' # static plot
#' plot_colData_histogram((small_example_dataset), return_plotly = FALSE)
plot_colData_histogram <- function(object, group_by = NULL, fill_by = NULL, 
                           yscale = "linear", return_plotly = FALSE) {
    group_by <- group_by %||% paste0("nCount_", mainExpName(object))
    fill_by <- fill_by %||% paste0("nCount_", mainExpName(object))
    
    sce_tbl <- rownames_to_column(
        get_colData(object), "SID") |> select(SID, 
                                                     !!as.symbol(group_by), 
                                                     !!as.symbol(fill_by))
    rc_plot <- ggplot(sce_tbl, aes(x = reorder(SID, -!!as.symbol(group_by)), 
                                      y = !!as.symbol(group_by), 
                                      fill = !!as.symbol(fill_by))) +
        geom_bar(position = "identity", stat = "identity") +
        theme(axis.text.x = element_blank()) +
        labs(title = group_by, x = "Sample") +
        NULL
    if (yscale == "log") {
        rc_plot <- rc_plot + scale_y_log10()
    }
    if (!return_plotly) return(rc_plot)
    
    rc_plot <- ggplotly(rc_plot, tooltip = "cellid", height = 500) |>
        plotly_settings() |>
        toWebGL() |>
        identity()
}

#' Plot Annotated Complexheatmap from SingleCellExperiment object
#'
#' @param object A SingleCellExperiment object
#' @param features Vector of features to plot. Features can come
#' @param cells Cells to retain
#' @param group.by  Name of one or more metadata columns to annotate columns 
#' by (for example, orig.ident)
#' @param assayName "counts" for raw data "scale.data" for log-normalized data
#' @param experiment experiment to display
#' @param group.bar.height height for group bars
#' @param col_arrangement how to arrange columns whether with a dendrogram 
#' (Ward.D2, average, etc.) or exclusively by metadata category
#' @param column_split whether to split columns by metadata value
#' @param mm_col_dend height of column dendrogram
#' @param ... additional arguments passed to Heatmap
#'
#' @return a complexheatmap
#' @export
#' @examples
#' data("tiny_sce")
#' make_complex_heatmap(tiny_sce)
#' 
make_complex_heatmap <- function(object, features = NULL, group.by = "ident", 
                                 cells = NULL, assayName = "logcounts", 
                                 experiment = NULL, group.bar.height = 0.01, 
                                 column_split = NULL, 
                                 col_arrangement = "ward.D2", 
                                 mm_col_dend = 30, ...) {
    cells <- cells %||% colnames(x = object)
    if (is.numeric(x = cells)) {
        cells <- colnames(x = object)[cells]
    }
    experiment <- experiment %||% mainExpName(object)
    if (!experiment == mainExpName(object)) {
        object <- swapAltExp(object, name = experiment)
    }
    features <- features %||% getTopHVGs(object)
    features <- rev(unique(features))
    possible.features <- rownames(x = assay(object, assayName))
    if (any(!features %in% possible.features)) {
        bad.features <- features[!features %in% possible.features]
        features <- features[features %in% possible.features]
        if (length(x = features) == 0) {
            stop("No requested features found in the ", assayName, 
                 " assay for the ", experiment, " experiment.")
        }
        warning(
            "The following features were omitted as they", 
            " were not found in the ", assay, " assay for the ", 
            experiment, " experiment: ", paste(bad.features, collapse = ", "))
    }
    data <- as.data.frame(x = t(x = as.matrix(
        x = assay(object, assayName)[features, cells, drop = FALSE])))

    if (any(col_arrangement %in% c("ward.D", "single", "complete", "average", 
                                   "mcquitty", "median", "centroid", 
                                   "ward.D2"))) {
        if ("PCA" %in% reducedDimNames(object)) {
            cluster_columns <- reducedDim(object, "PCA") |>
                dist() |>
                hclust(col_arrangement)
        } else {
            message(
                "pca not computed for this dataset; 
                cells will be clustered by displayed features")
            cluster_columns <- 
                function(m) as.dendrogram(agnes(m), method = col_arrangement)
        }
    } else {
        cells <- colData(object)[col_arrangement] |>
            as.data.frame() |>
            arrange(across(all_of(col_arrangement))) |>
            rownames()
        data <- data[cells, ]
        group.by <- base::union(group.by, col_arrangement)
        cluster_columns <- FALSE
    }
    group.by <- group.by %||% "ident"
    groups.use <- colData(object)[group.by] |> as.data.frame()
    groups.use <- groups.use |>
        rownames_to_column("sample_id") |>
        mutate(across(where(is.character), ~ str_wrap(
            str_replace_all(.x, ",", " "), 10))) |>
        mutate(across(where(is.character), as.factor)) |>
        data.frame(row.names = 1) |>
        identity()
    groups.use.factor <- groups.use[map_lgl(groups.use, is.factor)]
    ha_cols.factor <- NULL
    if (length(groups.use.factor) > 0) {
        ha_col_names.factor <- lapply(groups.use.factor, levels)
        ha_cols.factor <- map(ha_col_names.factor, 
                              ~ (hue_pal())(length(.x))) |> 
            map2(ha_col_names.factor, set_names)
    }
    groups.use.numeric <- groups.use[map_lgl(groups.use, is.numeric)]
    ha_cols.numeric <- NULL
    if (length(groups.use.numeric) > 0) {
        numeric_col_fun <- function(myvec, color) {
            colorRamp2(range(myvec), c("white", color))
        }
        ha_col_names.numeric <- names(groups.use.numeric)
        ha_col_hues.numeric <- (hue_pal())(length(ha_col_names.numeric))
        ha_cols.numeric <- map2(groups.use[ha_col_names.numeric], 
                                ha_col_hues.numeric, numeric_col_fun)
    }
    ha_cols <- c(ha_cols.factor, ha_cols.numeric)
    column_ha <- HeatmapAnnotation(df = groups.use, 
                                   height = unit(group.bar.height, "points"), 
                                   col = ha_cols)
    hm <- Heatmap(t(data), name = "log expression", 
                  top_annotation = column_ha, 
                  cluster_columns = cluster_columns, show_column_names = FALSE,
                  column_dend_height = unit(mm_col_dend, "mm"), 
                  column_split = column_split, column_title = NULL, ...)
    return(hm)
}

#' Plot Transcript Composition
#'
#' plot the proportion of reads of a given gene map to each transcript
#'
#' @param object A object
#' @param gene_symbol Gene symbol of gene of interest
#' @param group.by Name of one or more metadata columns to annotate columns by
#' (for example, orig.ident)
#' @param standardize whether to standardize values
#' @param drop_zero Drop zero values
#'
#' @return a stacked barplot of transcript counts
#' @export
#'
#' @examples
#' 
#' data(tiny_sce)
#' plot_transcript_composition(tiny_sce, "NRL")
#'
plot_transcript_composition <- function(object, gene_symbol, 
                                        group.by = "batch", 
                                        standardize = FALSE, 
                                        drop_zero = FALSE) {
    
    data_env <- new.env(parent = emptyenv())
    data("grch38", envir = data_env, package = "chevreulPlot")
    data("grch38_tx2gene", envir = data_env, package = "chevreulPlot")
    grch38 <- data_env[["grch38"]]
    grch38_tx2gene <- data_env[["grch38_tx2gene"]]
    
    transcripts <- grch38 |>
        filter(symbol == gene_symbol) |>
        left_join(grch38_tx2gene, by = "ensgene") |>
        pull(enstxp)
    metadata <- get_colData(object)
    metadata$sample_id <- NULL
    metadata <- metadata |>
        rownames_to_column("sample_id") |>
        select(sample_id, group.by = {{ group.by }})

    transcripts <- transcripts[transcripts %in% 
                                   rownames(altExp(object, "transcript"))]
    
    object <- swapAltExp(object, "transcript")
    
    object <- logNormCounts(object, transform = "none", name = "normcounts")
    
    # object <- logNormCounts(object)
    
    data <- normcounts(object)[transcripts, ] |>
        as.matrix() |>
        t() 

    data <- data |>
        as.data.frame() |>
        rownames_to_column("sample_id") |>
        pivot_longer(cols = starts_with("ENST"), 
                     names_to = "transcript", values_to = "expression") |>
        left_join(metadata, by = "sample_id") |>
        mutate(group.by = as.factor(group.by), 
               transcript = as.factor(transcript))
    data <- group_by(data, group.by, transcript)
    if (drop_zero) {
        data <- filter(data, expression != 0)
    }
    data <- summarize(data, expression = mean(expression))
    position <- ifelse(standardize, "fill", "stack")
    p <- ggplot(data = data, aes(x = group.by, 
                                 y = expression, fill = transcript)) +
        geom_col(position = position) +
        theme_minimal() +
        theme(axis.title.x = element_blank(), 
              axis.text.x = element_text(angle = 45, hjust = 1, 
                                         vjust = 1, size = 12)) +
        labs(title = paste("Mean expression by", group.by, "-", 
                           gene_symbol)) +
        NULL
    return(list(plot = p, data = data))
}


#' Plot All Transcripts
#'
#' plot expression all transcripts for an input gene superimposed on embedding
#'
#' @param object A object
#' @param features gene or vector of transcripts
#' @param embedding umap
#' @param from_gene whether to look up transcripts for an input gene
#' @param ... additional arguments passed to plot_feature_on_embedding
#'
#' @return a list of embedding plots colored by a feature of interest
#' @export
#' @examples
#' data("tiny_sce")
#' plot_all_transcripts(tiny_sce, "NRL", from_gene = TRUE)
#' 
plot_all_transcripts <- function(object, features, 
                                 embedding = "UMAP", 
                                 from_gene = TRUE, ...) {
    if (from_gene) {
        features <- genes_to_transcripts(features)
    }
    features <- features[features %in% rownames(altExp(object, "transcript"))]
    main_dimreds <- reducedDims(object)
    object <- swapAltExp(object, "transcript")
    object <- logNormCounts(object)
    reducedDims(object) <- main_dimreds
    plot_out <- map(paste0(features), ~plot_feature_on_embedding(
        object, embedding = embedding, features = .x, 
        return_plotly = FALSE, ...), ...) |> set_names(features)
    return(plot_out)
}

#' Enframe Cluster Markers
#'
#' @param tbl a tibble of marker genes
#'
#' @return a pivoted tibble of marker genes
enframe_markers <- function(tbl){
    tbl[c("Gene.Name", "Cluster")] |> 
        mutate(rn = row_number()) |>
        pivot_wider(names_from = Cluster, values_from = Gene.Name) |>
        select(-rn) |> 
        mutate(across(everything(), .fns = as.character))
}
