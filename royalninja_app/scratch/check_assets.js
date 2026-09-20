const fs = require('fs');
const path = require('path');

function walk(dir) {
  let results = [];
  const list = fs.readdirSync(dir);
  list.forEach(file => {
    file = path.join(dir, file);
    const stat = fs.statSync(file);
    if (stat && stat.isDirectory()) {
      results = results.concat(walk(file));
    } else if (file.endsWith('.dart')) {
      results.push(file);
    }
  });
  return results;
}

const rootDir = path.resolve(__dirname, '..');
const dartFiles = walk(path.join(rootDir, 'lib'));
const missingAssets = [];

const regex = /["'](assets\/[^"']+)["']/g;

dartFiles.forEach(file => {
  const content = fs.readFileSync(file, 'utf8');
  let match;
  while ((match = regex.exec(content)) !== null) {
    const assetPath = match[1];
    if (assetPath.startsWith('assets/locale') || assetPath.endsWith('/')) continue;
    
    const fullPath = path.join(rootDir, assetPath);
    if (!fs.existsSync(fullPath)) {
      missingAssets.push({
        file: file.replace(rootDir + '/', ''),
        assetPath
      });
    }
  }
});

console.log('===================================================');
console.log('           MISSING ASSETS AUDIT REPORT             ');
console.log('===================================================');
if (missingAssets.length === 0) {
  console.log('✅ ALL ASSETS VALID! No missing image/icon errors found.');
} else {
  console.log(`❌ FOUND ${missingAssets.length} MISSING ASSETS IN CODE:`);
  console.log(JSON.stringify(missingAssets, null, 2));
}
console.log('===================================================');
