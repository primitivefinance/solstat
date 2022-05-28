'use strict'
var __createBinding =
  (this && this.__createBinding) ||
  (Object.create
    ? function (o, m, k, k2) {
        if (k2 === undefined) k2 = k
        var desc = Object.getOwnPropertyDescriptor(m, k)
        if (!desc || ('get' in desc ? !m.__esModule : desc.writable || desc.configurable)) {
          desc = {
            enumerable: true,
            get: function () {
              return m[k]
            },
          }
        }
        Object.defineProperty(o, k2, desc)
      }
    : function (o, m, k, k2) {
        if (k2 === undefined) k2 = k
        o[k2] = m[k]
      })
var __setModuleDefault =
  (this && this.__setModuleDefault) ||
  (Object.create
    ? function (o, v) {
        Object.defineProperty(o, 'default', { enumerable: true, value: v })
      }
    : function (o, v) {
        o['default'] = v
      })
var __importStar =
  (this && this.__importStar) ||
  function (mod) {
    if (mod && mod.__esModule) return mod
    var result = {}
    if (mod != null)
      for (var k in mod)
        if (k !== 'default' && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k)
    __setModuleDefault(result, mod)
    return result
  }
var __importDefault =
  (this && this.__importDefault) ||
  function (mod) {
    return mod && mod.__esModule ? mod : { default: mod }
  }
exports.__esModule = true
var fs = __importStar(require('fs'))
var ethers_1 = require('ethers')
var utils_1 = require('ethers/lib/utils')
var gaussian_extended_1 = require('../../utils/gaussian-extended')
var gaussian_1 = __importDefault(require('gaussian'))
var evm_bn_1 = require('evm-bn')
var cdf = function (x) {
  return (0, gaussian_1['default'])(0, 1).cdf(x)
}
var ppf = function (x) {
  return (0, gaussian_1['default'])(0, 1).ppf(x)
}
function parse(x) {
  return (0, evm_bn_1.toBn)(x.toString())._hex
}
function format(x) {
  return +(0, utils_1.formatEther)(x)
}
var DIFFERENTIAL_FUNCTIONS = ['erfc', 'ierfc', 'cdf', 'ppf']
var COMPUTE_FN_INPUTS = {
  erfc: function (x) {
    if (typeof x === 'undefined') throw new Error('Value '.concat(x, ' is undefined'))
    return (0, evm_bn_1.toBn)(Math.random().toString())._hex
  },
  ierfc: function (x) {
    if (typeof x === 'undefined') throw new Error('Value '.concat(x, ' is undefined'))
    return (0, evm_bn_1.toBn)(Math.random().toString())._hex
  },
  cdf: function (x) {
    if (typeof x === 'undefined') throw new Error('Value '.concat(x, ' is undefined'))
    return (0, evm_bn_1.toBn)(Math.random().toString())._hex
  },
  ppf: function (x) {
    if (typeof x === 'undefined') throw new Error('Value '.concat(x, ' is undefined'))
    return (0, evm_bn_1.toBn)(Math.random().toString())._hex
  },
}
var COMPUTE_FN_OUTPUTS = {
  erfc: function (x) {
    return parse((0, gaussian_extended_1.erfc)(format(x)))
  },
  ierfc: function (x) {
    return parse((0, gaussian_extended_1.ierfc)(format(x)))
  },
  cdf: function (x) {
    return parse(cdf(format(x)))
  },
  ppf: function (x) {
    return parse(ppf(format(x)))
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
var DEFAULT_START_INDEX = 1
var DEFAULT_END_INDEX = 130
var DEFAULT_ENCODING_TYPE = ['int256[129]']
var encode = function (data) {
  return ethers_1.ethers.utils.defaultAbiCoder.encode(DEFAULT_ENCODING_TYPE, [data])
}
function writeInput(data, key) {
  if (!fs.existsSync('../data/'.concat(key, '/'))) {
    fs.mkdirSync('../data/'.concat(key, '/'))
  }
  fs.writeFileSync('../data/'.concat(key, '/input'), data)
}
function writeOutput(data, key) {
  if (!fs.existsSync('../data/'.concat(key, '/'))) {
    fs.mkdirSync('../data/'.concat(key, '/'))
  }
  fs.writeFileSync('../data/'.concat(key, '/output'), data)
}
function checkSynced() {
  if (!fs.existsSync('../data/')) {
    fs.mkdirSync('../data/')
  }
}
checkSynced()
for (var i in DIFFERENTIAL_FUNCTIONS) {
  var key = DIFFERENTIAL_FUNCTIONS[i]
  if (!(key in COMPUTE_FN_INPUTS)) continue
  if (!(key in COMPUTE_FN_OUTPUTS)) continue
  var inputs = []
  var outputs = []
  for (var i_1 = DEFAULT_START_INDEX; i_1 < DEFAULT_END_INDEX; ++i_1) {
    var inputFunction = COMPUTE_FN_INPUTS[key]
    var outputFunction = COMPUTE_FN_OUTPUTS[key]
    var input = inputFunction(i_1)
    var output = outputFunction(input)
    inputs.push(input)
    outputs.push(output)
  }
  var encodedIn = encode(inputs)
  var encodedOut = encode(outputs)
  writeInput(encodedIn, key)
  writeOutput(encodedOut, key)
}