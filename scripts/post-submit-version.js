#!/usr/bin/env node
/**
 * Tag the repo with the current Flutter version and build metadata.
 * Usage: node scripts/post-submit-version.js [--push]
 */
const fs = require('fs');
const path = require('path');
const cp = require('child_process');

const root = path.resolve(__dirname, '..');
const pubspecPath = path.join(root, 'pubspec.yaml');
const buildInfoPath = path.join(root, 'versioning', 'build-version.json');

function execSync(cmd, options = {}) {
  return cp.execSync(cmd, { stdio: 'inherit', ...options });
}

function get(cmd) {
  return cp.execSync(cmd).toString().trim();
}

function main() {
  const shouldPush = process.argv.includes('--push');
  const pubspec = fs.readFileSync(pubspecPath, 'utf8');
  const versionMatch = pubspec.match(/version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)/);
  if (!versionMatch) {
    throw new Error('Unable to read version from pubspec.yaml');
  }
  const semver = versionMatch[1];
  const iosBuild = Number(versionMatch[2]);

  const buildInfo = fs.existsSync(buildInfoPath)
    ? JSON.parse(fs.readFileSync(buildInfoPath, 'utf8'))
    : { ios: { buildNumber: iosBuild }, android: { versionCode: iosBuild } };

  const tag = `v${semver}`;
  const message = `Release ${tag} (iOS build ${buildInfo.ios.buildNumber}, Android vc ${buildInfo.android.versionCode})`;

  const branch = get('git rev-parse --abbrev-ref HEAD');
  console.log(`Tagging ${tag} on ${branch}`);
  try {
    execSync(`git tag -a ${tag} -m "${message}"`);
  } catch (error) {
    console.warn('Tag creation failed (maybe exists already):', error.message);
  }

  if (shouldPush) {
    console.log('Pushing tags to origin...');
    execSync('git push --tags');
  } else {
    console.log('Tag created locally. Pass --push to push tags.');
  }
}

main();
