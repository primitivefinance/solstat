import * as fs from 'fs'
import { BigNumber, ethers } from 'ethers'
import { formatEther, parseEther } from 'ethers/lib/utils'

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
  return parseEther(x.toString())._hex
}

function format(x) {
  return +formatEther(x)
}

var data: string[] = []
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
fs.writeFileSync('../data/input', encodedInputs)
