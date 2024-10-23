test_that("plotting works", {
    expect_error(
        plot_colData_on_embedding(small_example_dataset, "Mutation_Status", return_plotly = FALSE),
        NA
    )
})
