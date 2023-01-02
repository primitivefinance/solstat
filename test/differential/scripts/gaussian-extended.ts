export const erfc = function (x) {
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

export const ierfc = function (x) {
  if (x >= 2) {
    return -100
  }
  if (x <= 0) {
    return 100
  }

  var xx = x < 1 ? x : 2 - x
  var t = Math.sqrt(-2 * Math.log(xx / 2))

  var r = -0.70711 * ((2.30753 + t * 0.27061) / (1 + t * (0.99229 + t * 0.04481)) - t)

  for (var j = 0; j < 2; j++) {
    var err = erfc(r) - xx
    r += err / (1.12837916709551257 * Math.exp(-(r * r)) - r * err)
  }

  var output = x < 1 ? r : -r
  return output
}
