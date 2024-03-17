# Paid2Hack contracts

Smart contracts for paid2hack.

## Developer guide

Install pre-requisites:

* [Rust](https://www.rust-lang.org/tools/install)
* [svm-rs](https://github.com/alloy-rs/svm-rs)
* [Foundry](https://book.getfoundry.sh/)
* [Bun](https://bun.sh/)

Then run:

```shell
$ bun i
$ bun prepare
```

To compile the contracts:

```shell
$ bun compile
```

To run tests:

```
$ bun tests
```

### exports.ts

All commands will generate the `generated/exports.ts` file which contains ABI and bytecode to be used by the dapp.

### Deploy to local testnet

In a separate terminal, start a local devnet:

```shell
$ bun devnet
```

Now deploy the contracts:

```shell
$ bun deploy-local
```

_Note: Deployment is done using [CREATE2](). So, if you need to deploy the contracts again, first stop and restart the devnet in the other terminal._

## Deploying to public chains

**NOTE: Use a burner wallet to deploy, don't use your own main wallet!!**

```shell
$ export PRIVATE_KEY="0x..."
$ export RPC_URL="http://..."
$ export CHAIN_ID="..."
$ bun deploy-public
```

## License

AGPLv3 - see [LICENSE.md](LICENSE.md)

Paid2Hack contracts
Copyright (C) 2024  [Paid2Hack](https://github.com/paid2hack)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
