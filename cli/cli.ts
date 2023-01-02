import gaussian from 'gaussian'

const cdf = (x) => {
  return gaussian(0, 1).cdf(x)
}

const ppf = (x) => {
  return gaussian(0, 1).ppf(x)
}

const pdf = (x) => {
  return gaussian(0, 1).pdf(x)
}

async function main() {
  const args = process.argv
  const [, , flag, value] = args

  if (value) {
    if (flag && flag === '--cdf') {
      console.log(`cdf: ${cdf(value)}`)
    } else if (flag && flag === '--ppf') {
      console.log(`ppf: ${ppf(value)}`)
    } else if (flag && flag === '--pdf') {
      console.log(`pdf: ${pdf(value)}`)
    } else {
      console.log(`Unknown operation: ${flag}`)
    }
  } else {
    console.log('No value supplied...')
  }
}

main().catch((err) => process.exit(1))
