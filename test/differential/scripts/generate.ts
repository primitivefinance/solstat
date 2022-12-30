import * as fs from 'fs'
import { BigNumber, ethers } from 'ethers'
import { formatEther, parseEther } from 'ethers/lib/utils'
import { erfc, ierfc } from './gaussian-extended'
import gaussian from 'gaussian'
import { toBn } from 'evm-bn'
import {
  Args,
  ArgsBig,
  parse as parseArgs,
  format as formatInvariant,
  formatArgs,
  getY,
  getX,
  invariant,
} from './invariant'

const cdf = (x) => {
  return gaussian(0, 1).cdf(x)
}

const ppf = (x) => {
  return gaussian(0, 1).ppf(x)
}

function parse(x) {
  return toBn(x.toString())._hex
}

function format(x) {
  return +formatEther(x)
}

const DIFFERENTIAL_FUNCTIONS: Key[] = ['erfc', 'ierfc', 'cdf', 'ppf', 'invariant']
type Key = 'erfc' | 'ierfc' | 'cdf' | 'ppf' | 'invariant'

type ArgsInputs = [bigint, bigint, bigint, bigint]

const COMPUTE_FN_INPUTS = {
  erfc: function (x) {
    if (typeof x === 'undefined') throw new Error(`Value ${x} is undefined`)
    return toBn(Math.random().toString())._hex
  },
  ierfc: function (x) {
    if (typeof x === 'undefined') throw new Error(`Value ${x} is undefined`)
    return toBn(Math.random().toString())._hex
  },
  cdf: function (x) {
    if (typeof x === 'undefined') throw new Error(`Value ${x} is undefined`)
    return toBn(Math.random().toString())._hex
  },
  ppf: function (x) {
    if (typeof x === 'undefined') throw new Error(`Value ${x} is undefined`)
    return toBn(Math.random().toString())._hex
  },
  invariant: function (x): InvariantInput {
    x = Math.random()
    let K = getStrike(x)
    let o = getSigma(x)
    let t = getTau(x)
    let y = parse(getQuote(x))
    let args = parseArgs({ x, K, o, t })
    if (typeof x === 'undefined') throw new Error(`Value ${x} is undefined`)
    let argsArray: ArgsInputs = Object.keys(args).map((key) => args[key] as bigint) as ArgsInputs
    return [y, ...argsArray]
  },
}

type InvariantInput = [string, bigint, bigint, bigint, bigint]

function getQuote(x: number): number {
  return x % (Math.pow(2, 128) - 1)
}

function getSigma(x: number): number {
  return 1 + (x % (Math.pow(2, 24) - 1))
}

function getStrike(x: number): number {
  return 1 + (x % (Math.pow(2, 128) - 1))
}

function getTau(x: number): number {
  return x % (Math.pow(2, 32) - 1)
}

const COMPUTE_FN_OUTPUTS = {
  erfc: function (x) {
    return parse(erfc(format(x)))
  },
  ierfc: function (x) {
    return parse(ierfc(format(x)))
  },
  cdf: function (x) {
    return parse(cdf(format(x)))
  },
  ppf: function (x) {
    return parse(ppf(format(x)))
  },
  invariant: function (x: InvariantInput): string {
    let args = { x: x[1], K: x[2], o: x[3], t: x[4] }
    return parse(invariant(format(x[0]), formatArgs(args)))
  },
}

COMPUTE_FN_INPUTS['erfc'].bind(COMPUTE_FN_INPUTS)
COMPUTE_FN_OUTPUTS['erfc'].bind(COMPUTE_FN_OUTPUTS)
COMPUTE_FN_INPUTS['ierfc'].bind(COMPUTE_FN_INPUTS)
COMPUTE_FN_OUTPUTS['ierfc'].bind(COMPUTE_FN_OUTPUTS)
COMPUTE_FN_INPUTS['cdf'].bind(COMPUTE_FN_INPUTS)
COMPUTE_FN_OUTPUTS['cdf'].bind(COMPUTE_FN_OUTPUTS)
COMPUTE_FN_INPUTS['ppf'].bind(COMPUTE_FN_INPUTS)
COMPUTE_FN_OUTPUTS['ppf'].bind(COMPUTE_FN_OUTPUTS)
COMPUTE_FN_INPUTS['invariant'].bind(COMPUTE_FN_INPUTS)
COMPUTE_FN_OUTPUTS['invariant'].bind(COMPUTE_FN_OUTPUTS)

const DEFAULT_START_INDEX = 1
const DEFAULT_END_INDEX = 130
const DEFAULT_ENCODING_TYPE = ['int256[129]']
const INVARIANT_ENCODING_TYPE = ['uint256[5][129]']
const encode = (data: string[], encodeType: string[]) => ethers.utils.defaultAbiCoder.encode(encodeType, [data])

function writeInput(data: string, key: string) {
  if (!fs.existsSync(`../data/${key}/`)) {
    fs.mkdirSync(`../data/${key}/`)
  }
  fs.writeFileSync(`../data/${key}/input`, data)
}

function writeOutput(data: string, key: string) {
  if (!fs.existsSync(`../data/${key}/`)) {
    fs.mkdirSync(`../data/${key}/`)
  }
  fs.writeFileSync(`../data/${key}/output`, data)
}

function checkSynced() {
  if (!fs.existsSync('../data/')) {
    fs.mkdirSync('../data/')
  }
}

checkSynced()

for (const i in DIFFERENTIAL_FUNCTIONS) {
  const key = DIFFERENTIAL_FUNCTIONS[i]

  if (!(key in COMPUTE_FN_INPUTS)) continue
  if (!(key in COMPUTE_FN_OUTPUTS)) continue

  const inputs: string[] = []
  const outputs: string[] = []
  for (let i = DEFAULT_START_INDEX; i < DEFAULT_END_INDEX; ++i) {
    const inputFunction = COMPUTE_FN_INPUTS[key] as Function
    const outputFunction = COMPUTE_FN_OUTPUTS[key] as Function

    const input = inputFunction(i)
    const output = outputFunction(input)

    inputs.push(input)
    outputs.push(output)
  }

  let encodingTypes: string[][] = [] // [input encoding, output encoding]
  switch (key) {
    case 'invariant':
      encodingTypes = [INVARIANT_ENCODING_TYPE, DEFAULT_ENCODING_TYPE]
      break
    default:
      encodingTypes = [DEFAULT_ENCODING_TYPE, DEFAULT_ENCODING_TYPE]
      break
  }

  const encodedIn = encode(inputs, encodingTypes[0])
  const encodedOut = encode(outputs, encodingTypes[1])

  writeInput(encodedIn, key)
  writeOutput(encodedOut, key)
}
