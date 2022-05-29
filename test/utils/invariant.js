'use strict'
var __importDefault =
  (this && this.__importDefault) ||
  function (mod) {
    return mod && mod.__esModule ? mod : { default: mod }
  }
exports.__esModule = true
exports.invariant =
  exports.getX =
  exports.getY =
  exports.formatArgs =
  exports.format =
  exports.parse =
  exports.YEAR =
    void 0
var utils_1 = require('ethers/lib/utils')
var gaussian_1 = __importDefault(require('gaussian'))
exports.YEAR = 31556952
function parse(args) {
  return {
    x: BigInt(args.x * 1e18),
    K: BigInt(args.K * 1e18),
    o: BigInt(args.o * 1e18),
    t: BigInt(args.t * exports.YEAR),
  }
}
exports.parse = parse
function format(x) {
  return +(0, utils_1.formatEther)(x)
}
exports.format = format
function formatArgs(args) {
  return {
    x: +(0, utils_1.formatEther)(args.x),
    K: +(0, utils_1.formatEther)(args.K),
    o: +(0, utils_1.formatEther)(args.o),
    t: parseInt(args.t.toString(16), 16) / exports.YEAR,
  }
}
exports.formatArgs = formatArgs
function getY(args) {
  if (args.t != 0) {
    var y =
      args.K *
      (0, gaussian_1['default'])(0, 1).cdf(
        (0, gaussian_1['default'])(0, 1).ppf(1 - args.x) - args.o * Math.sqrt(args.t)
      )
    return y
  } else {
    return args.K * (1 - args.x)
  }
}
exports.getY = getY
function getX(args) {
  var y = args.x
  var x =
    1 -
    (0, gaussian_1['default'])(0, 1).cdf(
      (0, gaussian_1['default'])(0, 1).ppf((y - 0) / args.K) + args.o * Math.sqrt(args.t)
    )
  return x
}
exports.getX = getX
function invariant(y, args) {
  var y0 = getY(args)
  var k = y - y0
  return k
}
exports.invariant = invariant
