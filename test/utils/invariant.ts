import { BigNumberish } from 'ethers'
import { formatEther } from 'ethers/lib/utils'
import gaussian from 'gaussian'

export interface Args {
  x: number
  K: number
  o: number
  t: number
}

export interface ArgsBig {
  x: bigint
  K: bigint
  o: bigint
  t: bigint
}

export const YEAR = 31556952

export function parse(args: Args): ArgsBig {
  return {
    x: BigInt(Math.floor((args.x as number) * 1e18)),
    K: BigInt(Math.floor((args.K as number) * 1e18)),
    o: BigInt(Math.floor((args.o as number) * 1e18)),
    t: BigInt(Math.floor((args.t as number) * YEAR)),
  }
}

export function format(x: BigNumberish | bigint): number {
  return +formatEther(x)
}

export function formatArgs(args: ArgsBig): Args {
  return {
    x: +formatEther(args.x),
    K: +formatEther(args.K),
    o: +formatEther(args.o),
    t: parseInt(args.t.toString(16), 16) / YEAR,
  }
}

export function getY(args: Args): number {
  if (args.t != 0) {
    const y = args.K * gaussian(0, 1).cdf(gaussian(0, 1).ppf(1 - args.x) - args.o * Math.sqrt(args.t))
    return y
  } else {
    return args.K * (1 - args.x)
  }
}

export function getX(args: Args): number {
  const y = args.x
  const x = 1 - gaussian(0, 1).cdf(gaussian(0, 1).ppf((y - 0) / args.K) + args.o * Math.sqrt(args.t))
  return x
}

export function invariant(y: number, args: Args): number {
  const y0 = getY(args)
  const k = y - y0
  return k
}
