#!/usr/bin/env node
/**
 * Bump Flutter app semantic version and platform build numbers.
 * - Updates pubspec.yaml version (build number mirrors iOS build)
 * - Updates versioning/build-version.json
 * - Writes android/app/build.gradle.kts versionCode/versionName
 * - Updates ios/Runner.xcodeproj/project.pbxproj marketing & build versions
 *
 * Usage: node scripts/bump-version.js patch|minor|major [--no-ios] [--no-android]
 */
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const pubspecPath = path.join(root, 'pubspec.yaml');
const buildInfoPath = path.join(root, 'versioning', 'build-version.json');
const gradlePath = path.join(root, 'android', 'app', 'build.gradle.kts');
const pbxprojPath = path.join(root, 'ios', 'Runner.xcodeproj', 'project.pbxproj');

const inc = (version, type) => {
  const parts = version.split('.').map(Number);
  if (parts.length !== 3 || parts.some((n) => Number.isNaN(n))) {
    throw new Error(`Unexpected version format: ${version}`);
  }
  const [major, minor, patch] = parts;
  if (type === 'major') return `${major + 1}.0.0`;
  if (type === 'minor') return `${major}.${minor + 1}.0`;
  return `${major}.${minor}.${patch + 1}`;
};

function replaceAll(content, regex, replace) {
  const result = content.replace(regex, replace);
  if (result === content) {
    throw new Error(`Expected pattern ${regex} not found while updating file.`);
  }
  return result;
}

function main() {
  const type = (process.argv[2] || 'patch').toLowerCase();
  if (!['patch', 'minor', 'major'].includes(type)) {
    throw new Error(`Unknown release type "${type}". Use patch, minor, or major.`);
  }
  const enableIOS = !process.argv.includes('--no-ios');
  const enableAndroid = !process.argv.includes('--no-android');

  const pubspec = fs.readFileSync(pubspecPath, 'utf8');
  const versionMatch = pubspec.match(/version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)/);
  if (!versionMatch) {
    throw new Error('Could not find version in pubspec.yaml');
  }
  const currentVersion = versionMatch[1];
  const currentBuild = parseInt(versionMatch[2], 10);

  const buildInfo = fs.existsSync(buildInfoPath)
    ? JSON.parse(fs.readFileSync(buildInfoPath, 'utf8'))
    : { ios: { buildNumber: currentBuild || 1 }, android: { versionCode: currentBuild || 1 } };

  const newSemver = inc(currentVersion, type);
  if (enableIOS) {
    buildInfo.ios.buildNumber = Number(buildInfo.ios.buildNumber || 0) + 1;
  }
  if (enableAndroid) {
    buildInfo.android.versionCode = Number(buildInfo.android.versionCode || 0) + 1;
  }

  // Update pubspec (Flutter build number mirrors iOS build number)
  const newPubspec = pubspec.replace(
    /version:\s*[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+/,
    `version: ${newSemver}+${buildInfo.ios.buildNumber}`
  );
  fs.writeFileSync(pubspecPath, newPubspec);

  // Persist versioning JSON
  fs.mkdirSync(path.dirname(buildInfoPath), { recursive: true });
  fs.writeFileSync(buildInfoPath, `${JSON.stringify(buildInfo, null, 2)}\n`);

  if (enableAndroid) {
    let gradle = fs.readFileSync(gradlePath, 'utf8');
    gradle = replaceAll(
      gradle,
      /versionCode\s*=\s*\d+/,
      `versionCode = ${buildInfo.android.versionCode}`
    );
    gradle = replaceAll(
      gradle,
      /versionName\s*=\s*"[0-9]+\.[0-9]+\.[0-9]+"/,
      `versionName = "${newSemver}"`
    );
    fs.writeFileSync(gradlePath, gradle);
  }

  if (enableIOS) {
    let pbx = fs.readFileSync(pbxprojPath, 'utf8');
    pbx = replaceAll(
      pbx,
      /MARKETING_VERSION = [0-9]+\.[0-9]+\.?[0-9]*;/g,
      `MARKETING_VERSION = ${newSemver};`
    );
    pbx = replaceAll(
      pbx,
      /CURRENT_PROJECT_VERSION = \d+;/g,
      `CURRENT_PROJECT_VERSION = ${buildInfo.ios.buildNumber};`
    );
    fs.writeFileSync(pbxprojPath, pbx);
  }

  console.log(`Version bumped: ${currentVersion} -> ${newSemver}`);
  console.log(`iOS build number: ${buildInfo.ios.buildNumber}`);
  console.log(`Android versionCode: ${buildInfo.android.versionCode}`);
}

main();
