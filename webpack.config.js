const path = require("path");
const glob = require("glob");
const UglifyJsPlugin = require("uglifyjs-webpack-plugin");
const CopyWebpackPlugin = require("copy-webpack-plugin");

module.exports = (env, options) => ({
  mode: options.mode || "production",
  devtool: options.mode === "development" ? "source-map" : false,
  optimization: {
    minimizer: [
      new UglifyJsPlugin({ cache: true, parallel: true, sourceMap: false })
    ]
  },
  entry: {
    uploader: "./assets/js/uploader.js"
  },
  output: {
    filename: "[name].js",
    path: path.resolve(__dirname, "priv/static/js")
  },
  module: {
    rules: [
      {
        test: /\.(js|jsx)$/,
        exclude: /node_modules/,
        use: {
          loader: "babel-loader"
        }
      },
      {
        test: /\.css$/i,
        exclude: /\.lazy\.css$/i,
        use: ["style-loader", "css-loader"]
      }
    ]
  },
  plugins: [new CopyWebpackPlugin([{ from: "assets/static/", to: "../" }])],
  resolve: {
    extensions: [".js", ".jsx", ".json"]
  }
});
