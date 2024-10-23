test_that("object metadata retrieved", {
    expect_type(get_sce_metadata(small_example_dataset), "list")
})
