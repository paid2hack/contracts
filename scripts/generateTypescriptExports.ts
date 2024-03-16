import fs from 'fs';
import path from 'path';

const outFolder = path.join(__dirname, '../out');
const generatedFolder = path.join(__dirname, '../generated');

const master = JSON.parse(fs.readFileSync(path.join(outFolder, 'Master.sol', 'Master.json'), 'utf8').toString())
const sponsor = JSON.parse(fs.readFileSync(path.join(outFolder, 'Sponsor.sol', 'Sponsor.json'), 'utf8').toString())
const erc20 = JSON.parse(
  fs
    .readFileSync(path.join(outFolder, "IERC20.sol", "IERC20.json"), "utf8")
    .toString()
)

fs.writeFileSync(path.join(generatedFolder, 'exports.ts'), `
  export const masterAbi = ${JSON.stringify(master.abi)} as const;
  export const sponsorAbi = ${JSON.stringify(sponsor.abi)} as const;
  export const erc20Abi = ${JSON.stringify(erc20.abi)} as const;

  export const sponsorBytecode = "${sponsor.bytecode.object}";
`, 'utf-8');

