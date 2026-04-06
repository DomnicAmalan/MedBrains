const { getDefaultConfig, mergeConfig } = require("@react-native/metro-config");
const path = require("path");

const projectRoot = __dirname;
const monorepoRoot = path.resolve(projectRoot, "../..");

const config = {
  watchFolders: [monorepoRoot],
  resolver: {
    nodeModulesPaths: [
      path.resolve(projectRoot, "node_modules"),
      path.resolve(monorepoRoot, "node_modules"),
    ],
    blockList: [
      new RegExp(path.resolve(monorepoRoot, "apps/web") + "/.*"),
      new RegExp(path.resolve(monorepoRoot, "apps/mobile") + "/.*"),
    ],
  },
};

module.exports = mergeConfig(getDefaultConfig(projectRoot), config);
