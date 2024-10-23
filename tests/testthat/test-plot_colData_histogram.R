test_that("plot gets made", {
        small_example_dataset <- sce_calcn(small_example_dataset)
    expect_error(
        plot_colData_histogram((small_example_dataset), return_plotly = TRUE),
        NA
    )
})
