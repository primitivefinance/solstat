# SolStat

SolStat is a math library written in solidity for statistical function approximations. The library is modeled off of algorithms from [Numerical Recipies](https://e-maxx.ru/bookz/files/numerical_recipes.pdf), which originate from the [Handbook of Mathematical Functions](https://personal.math.ubc.ca/~cbm/aands/abramowitz_and_stegun.pdf) which are implemented in several libraries like the [Gaussian](https://github.com/errcw/gaussian) JS library. This library is consists of two primary components, `Bisection.sol` and `Gaussian.sol`. These approximation algorithms have been used for research, development, and testing at [Primitive](https://primitive.xyz/). The motivation of the development of this library is grounded in the support of the the RMM-01 trading function. RMM-01 trading function utilizes the irrational normal cumulative distribution function, which needs to be approximated to acceptable accuracy bounds. For more information on the details of this trading function please see the [whitepaper](https://primitive.xyz/whitepaper-rmm-01.pdf).

Since a markov processes have a gaussian stationary distribution, and price paths are commonly modeled with markovian proccesses, we believe that the greater community will find value in this library.

## Differential Testing

In addition to unit tests, We leveraged [foundry](https://github.com/foundry-rs/foundry)'s support of differential testing for this library. This library used differential testing against the javascript gaussian library to detect anomalies and varying bugs. This library used differential testing against the javascript gaussian library to detect anomalies and varying bugs. This helped us to be confident in the performance and implementation of the library.
