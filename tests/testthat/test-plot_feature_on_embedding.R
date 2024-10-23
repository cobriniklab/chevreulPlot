test_that("plotting works for sce", {
    expect_error(
        plot_feature_on_embedding(small_example_dataset, embedding = "UMAP", features = "Gene_0001"),
        NA
    )
})
