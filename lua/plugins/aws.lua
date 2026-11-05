return {
  {
    "iamcheyan/aws.nvim",
    event = "VeryLazy",
    cmd = {
      "AwsPicker",
      "AwsCF",
      "AwsS3",
      "AwsCW",
      "AwsLambda",
      "AwsLambdaUpload",
      "AwsLambdaInvoke",
      "AwsLambdaUploadInvoke",
      "AwsLambdaLogs",
      "AwsLambdaLogsStop",
      "AwsACM",
      "AwsSM",
      "AwsAGW",
      "AwsCFront",
      "AwsECS",
      "AwsIAM",
      "AwsVPC",
      "AwsDDB",
    },
    keys = {
      { "<leader>aa", "<cmd>AwsPicker<cr>", desc = "AWS service picker" },
    },
    opts = {
      lambda = {
        auto_deploy = false,
      },
    },
    config = function(_, opts)
      require("aws").setup(opts)
    end,
  },
}
