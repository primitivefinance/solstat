import hre from 'hardhat'
import { expect } from 'chai'
import { formatEther } from 'ethers/lib/utils'

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
  console.log({ t, r })
  return x >= 0 ? r : 2 - r
}

var getInput = function (t, z) {
  return (
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
}

describe('Gaussian', function () {
  it('gets erfc', async function () {
    const math = await (await hre.ethers.getContractFactory('TestGaussian')).deploy()
    const x = -1
    const z = Math.abs(x)
    const expected = erfc(x)
    const t = 1 / (1 + z / 2)
    const k = getInput(t, z)
    const exp = Math.exp(k)
    const r = t * exp
    const output = x < 1 ? r : -r
    console.log({ t, k, exp, r, output })
    const parsed = BigInt(x * 1e18)
    const actual = await math.erfc(parsed)
    console.log({ parsed, actual, expected })
    expect(+formatEther(actual)).to.be.eq(expected)
  })
})
