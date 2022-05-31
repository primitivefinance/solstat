import hre from 'hardhat'

describe('Example', function () {
  it('Deploys the example contract', async function () {
    await (await hre.ethers.getContractFactory('Example')).deploy()
  })
})
