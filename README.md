# Beta

> This library is in beta. It's not ready for production.

![](https://visitor-badge.laobi.icu/badge?page_id=solstat) [![](https://github.com/primitivefinance/solstat/actions/workflows/ci.yaml/badge.svg)](https://github.com/primitivefinance/solstat/actions/workflows/ci.yaml) [![](https://dcbadge.vercel.app/api/server/primitive?style=flat)](https://discord.gg/primitive) [![Twitter Badge](https://badgen.net/badge/icon/twitter?icon=twitter&label)](https://twitter.com/primitivefi) 

# SolStat

SolStat is a Math library written in solidity for statistical function approximations. The library is composed of two core libraries; Gaussian.sol, and Invariant.sol. We will go over each of these libraries and their testing suites. We at Primitive use these libraries to support development with RMM-01s unique trading function, which utilizes the cumulative distribution function (CDF) of the normal distribution denoted by the greek capital letter Phi($\Phi$) in the literature [1,2]. You may recognize the normal or Gaussian distribution as the bell curve. This distribution is significant in modeling real-valued random numbers of unknown distributions. Within the RMM-01 trading function and options pricing, the CDF is used to model random price movement of a Markov process. Since price paths are commonly modeled with markovian proccesses, we believe that the greater community will find value in this library.

## How to use

Requirements: forge, node >=v16.0.0

```
yarn install
forge install
yarn build
forge test
```

To compute values using the gaussian.js library, you can use this commmand in the cli:

```
yarn cli --cdf {value}
yarn cli --pdf {value}
yarn cli --ppf {value}
```

## Irrational Functions

The primary reason for utilizing these approximation algorithms is that computers have trouble expressing irrational functions. This is because irrational numbers have an infinite number of decimals. Some examples of irrational numbers are $\pi$ and $\sqrt(2)$. This only becomes a challenge when we try to compute these numbers. This is because computers don't have an infinite amount of memory. Thus mathematicians and computer scientists have developed a variety of approximation algorithms to achieve varying degrees of speed and accuracy when approximating these irrational functions. These algorithms are commonly iterative and achieve greater accuracy with more iterations.

## Computational Constraints

In classical computing, our computational resources have become [abundant](https://en.wikipedia.org/wiki/Moore%27s_law), allowing us the liberty to iterate these algorithms to achieve our desired accuracy. However, the [Ethereum Virtual Machine (EVM)](https://ethereum.org/en/developers/docs/evm/) has a necessary monetary cost of computation. This computational environment has monetarily motivated developers to find efficient algorithms and hacks to reduce their applications' computational overhead (and thus the cost of computation).

## `Gaussian.sol`

This contract implements a number of functions important to the gaussian distributions. Importantly all these implementations are only for a mean $\mu = 0$ and variance $\sigma = 1$. These implementations are based on the [Numerical Recipes](https://e-maxx.ru/bookz/files/numerical_recipes.pdf) textbook and its C implementation. [Numerical Recipes](https://e-maxx.ru/bookz/files/numerical_recipes.pdf) cites the original text by Abramowitz and Stegun, "[Handbook of Mathematical Functions](https://personal.math.ubc.ca/~cbm/aands/abramowitz_and_stegun.pdf)," which should be read to understand these unique functions and the implications of their numerical approximations. This implementation was also inspired by the [javascript Gausian library](https://github.com/errcw/gaussian), which implements the same algorithm.

### Cumulative Distribution Function

The implementation of the CDF aproximation algorithm takes in a random variable $x$ as a single parameter. The function depends on a special helper functions known as the error function `erf`. The error function’s identity is `erfc(-x) = 2 - erfc(x)` and has a small collection of unique properties:

erfc(-infinity) = 2

erfc(0) = 1

erfc(infinity) = 0

The reference implementation for the error function is on p221 of Numerical Recipes in section C 2e. A helpful resource is this [wolfram notebook](https://mathworld.wolfram.com/Erfc.html).

### Probability Density Function

The library also supports an approximation of the Probability Density Function(PPF) which is mathematically interpeted as $Z(x) = \frac{1}{\sigma\sqrt{2\pi}}e^{\frac{-(x - \mu)^2}{2\sigma^2}}$. This implementation has a maximum error bound of of $1.2e-7$ and can be refrenced in this [wofram notebook](https://mathworld.wolfram.com/ProbabilityDensityFunction.html).

### Percent Point Function / Quantile Function

Furthermore we implemented aproximation algorithms for the Percent Point Function(PPF) sometimes known as the inverse CDF or the quantile function. The function is mathmatically defined as $D(x) = \mu - \sigma\sqrt{2}(ierfc(2x))$, has a maximum error of `1.2e-7`, and depends on the inverse error function `ierf` which satisfies `ierfc(erfc(x)) = erfc(ierfc(x))`. The invers error function, defined as `ierfc(1 - x) = ierf(x)`, has a domain of in the interval $0 < x < 2$ and has some unique properties:

ierfc(0) = infinity

ierfc(1) = 0

ierfc(2) = - infinity

## `Invariant.sol`

`Invariant.sol` is a contract used to compute the invariant of the RMM-01 trading function such that we compute $y$ in $y = K\Phi(\Phi^{⁻¹}(1-x) - \sigma\sqrt(\tau)) + k$. Notice how we need to compute the normal CDF of a quantity. For a more detailed perspective on the trading function, please see the whitepaper. This is an example of how we have used this library for our research, development, and testing of RMM-01. The function reverts if $x$ is greater than one and simplifies to $K(1+x) + k$ when $\tau$ is zero (at expiry). The function takes in five parameters
`R_x`: The reserves of token $x$ per unit of liquidity, always within the bounds of $[0,1]$.
`stk`: The strike price of the pool.
`vol`: the implied volatility of the pool denoted by the lowercase greek letter sigma in finance literature.
`tau`: The time until the pool expires. Once expired, there can be no swaps.
`inv`: The current invariant given `R_x`.
The function then returns the quantity of token y per unit of liquidity denoted `R_y`, which is always within the bounds of $[0, stk]$. This is a clear example of how one would use this library.

## Differential Testing with Foundry

We leveraged foundry's support of differential testing for this library. Differential testing is a popular technique that seeds inputs to different implementations of the same application and detects differences in their execution. Differential testing is an excellent complement to traditional software testing as it is well suited to detect semantic errors. This library used differential testing against the javascript gaussian library to detect anomalies and varying bugs. This helped us to be confident in the performance and implementation of the library.

[1]: [Replicating Market Makers](https://arxiv.org/pdf/2103.14769.pdf)

[2]: [Replicating Portfolios: Contstructing Permissionless Derivatives](https://arxiv.org/pdf/2205.09890.pdf)
