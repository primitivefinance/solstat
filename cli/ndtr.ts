async function main() {
  const args = process.argv
  const [, , flag, value] = args

  if (value) {
    const y0 = parseFloat(value)
    ndtr(y0)
  } else {
    console.log('No value supplied...')
  }
}

function ndtr(y0: number) {
  let x, x0, z
  let code = 1
  let y = y0

  if (y > 1.0 - 0.13533528323661269189) {
    /* 0.135... = exp(-2) */
    y = 1.0 - y
    code = 0
  }

  let logy = Math.log(y)
  x = Math.sqrt(-2.0 * Math.log(y))
  x0 = x - Math.log(x) / x
  z = 1.0 / x

  console.log({ y0, y, logy, x, x0, z })
}

main().catch((err) => {
  console.error(err)
  process.exit(1)
})
