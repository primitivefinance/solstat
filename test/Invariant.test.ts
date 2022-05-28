import { expect } from 'chai'
import { BigNumberish } from 'ethers'
import { formatEther } from 'ethers/lib/utils'
import hre from 'hardhat'

import gaussian from 'gaussian'

interface Args {
  x: number
  K: number
  o: number
  t: number
}

interface ArgsBig {
  x: bigint
  K: bigint
  o: bigint
  t: bigint
}

const YEAR = 31556952

function parse(args: Args): ArgsBig {
  return {
    x: BigInt((args.x as number) * 1e18),
    K: BigInt((args.K as number) * 1e18),
    o: BigInt((args.o as number) * 1e18),
    t: BigInt((args.t as number) * YEAR),
  }
}

function format(x: BigNumberish | bigint): number {
  return +formatEther(x)
}

function getY(args: Args): number {
  if (args.t != 0) {
    const y = args.K * gaussian(0, 1).cdf(gaussian(0, 1).ppf(1 - args.x) - args.o * Math.sqrt(args.t))
    return y
  } else {
    return args.K * (1 - args.x)
  }
}

function getX(args: Args): number {
  const y = args.x
  const x = 1 - gaussian(0, 1).cdf(gaussian(0, 1).ppf((y - 0) / args.K) + args.o * Math.sqrt(args.t))
  return x
}

function invariant(y: number, args: Args): number {
  const y0 = getY(args)
  const k = y - y0
  return k
}

describe('Invariant', function () {
  it('gets y', async function () {
    const contract = await (await hre.ethers.getContractFactory('TestInvariant')).deploy()
    let args = { x: 0.5, K: 1, o: 1, t: 0 }
    let actual = await contract.getY(parse(args))
    let expected = getY(args)
    expect(format(actual)).to.be.eq(expected)

    args = { x: 0.5, K: 1, o: 1, t: 1 }
    actual = await contract.getY(parse(args))
    expected = getY(args)
    expect(format(actual)).to.be.closeTo(expected, 1e-10)

    args = { x: 0.5, K: 1, o: 1, t: -1 }
    await expect(contract.getY(parse(args))).to.be.reverted
  })

  it('gets invariant', async function () {
    const contract = await (await hre.ethers.getContractFactory('TestInvariant')).deploy()
    let args = { x: 0.308537538726, K: 1, o: 1, t: 0 }
    let y = 0.308537538726
    let yp = BigInt(y * 1e18)
    let actual = await contract.invariant(yp, parse(args))
    let expected = invariant(y, args)
    expect(format(actual)).to.be.closeTo(expected, 1e-10)

    args = { x: 0.308537538726, K: 1, o: 1, t: 1 }
    actual = await contract.invariant(yp, parse(args))
    expected = invariant(y, args)
    expect(format(actual)).to.be.closeTo(expected, 1e-10)
    expect(format(actual)).to.be.closeTo(0, 1e-7)

    console.log({ invariant: format(actual) })

    args = { x: 0.308537538726, K: 1, o: 1, t: -1 }
    await expect(contract.invariant(yp, parse(args))).to.be.reverted
  })

  it('gets x', async function () {
    const contract = await (await hre.ethers.getContractFactory('TestInvariant')).deploy()
    let args = { x: 0.308537538726, K: 1, o: 1, t: 1 }
    let y = 0.308537538726
    let actual = await contract.getX(parse(args))
    let expected = getX(args)
    expect(format(actual)).to.be.closeTo(expected, 1e-7)
    expect(format(actual)).to.be.closeTo(y, 1e-7)
    console.log({ x: format(actual), expected })
  })
})
