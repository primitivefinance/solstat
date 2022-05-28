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
exports.__esModule = true
var fs = __importStar(require('fs'))
var ethers_1 = require('ethers')
var utils_1 = require('ethers/lib/utils')
var erfc = function (x) {
  var z = Math.abs(x)
  var t = 1 / (1 + z / 2)
  var r =
    t *
    Math.exp(
      -z * z -
        1.26551223 +
        t *
          (1.00002368 +
            t *
              (0.37409196 +
                t *
                  (0.09678418 +
                    t *
                      (-0.18628806 +
                        t * (0.27886807 + t * (-1.13520398 + t * (1.48851587 + t * (-0.82215223 + t * 0.17087277))))))))
    )
  return x >= 0 ? r : 2 - r
}
function parse(x) {
  return (0, utils_1.parseEther)(x.toString())._hex
}
function format(x) {
  return +(0, utils_1.formatEther)(x)
}
var data = []
for (var i = 1; i < 130; ++i) {
  var random = (Math.random() * i) % 2
  var input = (0, utils_1.parseEther)(Math.floor(random).toString())
  data.push(input._hex)
}
var outputData = data.map(function (b) {
  return parse(erfc(format(b)))
})
var encodedOutputs = ethers_1.ethers.utils.defaultAbiCoder.encode(['int256[129]'], [outputData])
process.stdout.write(encodedOutputs)
var encodedInputs = ethers_1.ethers.utils.defaultAbiCoder.encode(['int256[129]'], [data])
if (!fs.existsSync('../data/')) {
  fs.mkdirSync('../data/')
}
fs.writeFileSync('../data/output', encodedOutputs)
fs.writeFileSync('../data/input', encodedInputs)
