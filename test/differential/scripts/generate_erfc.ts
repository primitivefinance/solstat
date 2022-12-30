import * as fs from 'fs'
import { BigNumber, ethers } from 'ethers'
import { formatEther, parseEther } from 'ethers/lib/utils'
import { erfc, ierfc } from './gaussian-extended'
import gaussian from 'gaussian'

const cdf = (x) => {
  return gaussian(0, 1).cdf(x)
}

const ppf = (x) => {
  return gaussian(0, 1).ppf(x)
}

function parse(x) {
  return parseEther(x.toString())._hex
}

function format(x) {
  return +formatEther(x)
}

const DIFFERENTIAL_FUNCTIONS: Key[] = ['erfc', 'ierfc', 'cdf', 'pdf']
type Key = 'erfc' | 'ierfc' | 'cdf' | 'pdf'

const COMPUTE_FN_INPUTS = {
  erfc: function (x) {
    if (typeof x === 'undefined') throw new Error(`Value ${x} is undefined`)
    return parseEther(Math.floor((Math.random() * x) % 2).toString())._hex
  },
}

const COMPUTE_FN_OUTPUTS = {
  erfc: function (x) {
    return parse(erfc(format(x)))
  },
}

COMPUTE_FN_INPUTS['erfc'].bind(COMPUTE_FN_INPUTS)
COMPUTE_FN_OUTPUTS['erfc'].bind(COMPUTE_FN_OUTPUTS)

const DEFAULT_START_INDEX = 1
const DEFAULT_END_INDEX = 130
const DEFAULT_ENCODING_TYPE = ['int256[129]']
const encode = (data: string[]) => ethers.utils.defaultAbiCoder.encode(DEFAULT_ENCODING_TYPE, [data])

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

  const encodedIn = encode(inputs)
  const encodedOut = encode(outputs)

  writeInput(encodedIn, key)
  writeOutput(encodedOut, key)
}

/* var data: string[] = []
for (var i = 1; i < 130; ++i) {
  const random = (Math.random() * i) % 2
  const input = parseEther(Math.floor(random).toString())
  data.push(input._hex)
}
var outputData = data.map((b) => parse(erfc(format(b))))

const encodedOutputs = ethers.utils.defaultAbiCoder.encode(['int256[129]'], [outputData])
process.stdout.write(encodedOutputs)

const encodedInputs = ethers.utils.defaultAbiCoder.encode(['int256[129]'], [data])
if (!fs.existsSync('../data/')) {
  fs.mkdirSync('../data/')
}
fs.writeFileSync('../data/output', encodedOutputs)
fs.writeFileSync('../data/input', encodedInputs) */
