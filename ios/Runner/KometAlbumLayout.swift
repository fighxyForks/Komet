import CoreGraphics

/// Pure album frames. The numbers match `AlbumLayout` in Dart and then scale
/// to the bubble width. Swift does not invent a second grouping rule.
enum KometAlbumLayout {
  private static let canvas: CGFloat = 800
  private static let canvasHeight: CGFloat = 814
  private static let targetHeight: CGFloat = 800 / 3 * 4
  private static let minWidth: CGFloat = 233
  private static let sidePadding: CGFloat = 78
  private static let minRowHeight: CGFloat = 195
  private static let minMiddleWidth: CGFloat = 113
  private static let minCropped: CGFloat = 2 / 3
  private static let maxCropped: CGFloat = 1.7
  private static let orderPenalty: CGFloat = 1.2

  static func frames(ratios: [CGFloat], width: CGFloat) -> [CGRect] {
    let safe = ratios.map { $0.isFinite && $0 > 0 ? $0 : 1 }
    let placed = place(safe)
    guard !placed.isEmpty else { return [] }
    let bounds = placed.reduce(CGRect.null) { $0.union($1) }
    let gridWidth = max(bounds.width, 1)
    let scale = max(width, 1) / gridWidth
    return placed.map { tile in
      CGRect(
        x: (tile.minX - bounds.minX) * scale,
        y: (tile.minY - bounds.minY) * scale,
        width: max(1, tile.width * scale),
        height: max(1, tile.height * scale))
    }
  }

  private static func place(_ ratios: [CGFloat]) -> [CGRect] {
    let count = ratios.count
    if count == 0 { return [] }
    if count == 1 {
      return [CGRect(x: 0, y: 0, width: canvas, height: canvas / ratios[0])]
    }
    let panorama = ratios.contains { $0 > 2 }
    if !panorama && count <= 4 {
      let shape = ratios.map { orientation($0) }.joined()
      switch count {
      case 2: return placeTwo(ratios, shape)
      case 3: return placeThree(ratios, shape)
      case 4: return placeFour(ratios, shape)
      default: break
      }
    }
    return placeRows(ratios)
  }

  private static func orientation(_ ratio: CGFloat) -> String {
    if ratio > 1.2 { return "w" }
    if ratio < 0.8 { return "n" }
    return "q"
  }

  private static func average(_ ratios: [CGFloat]) -> CGFloat {
    guard !ratios.isEmpty else { return 1 }
    return ratios.reduce(0, +) / CGFloat(ratios.count)
  }

  private static func least(_ values: [CGFloat]) -> CGFloat {
    values.reduce(CGFloat.greatestFiniteMagnitude, min)
  }

  private static func placeTwo(_ ratios: [CGFloat], _ shape: String) -> [CGRect] {
    let stacked = shape == "ww"
      && average(ratios) > 1.4 * (canvas / canvasHeight)
      && ratios[0] - ratios[1] < 0.2
    if stacked {
      let height = least([canvas / ratios[0], canvas / ratios[1], canvasHeight / 2])
      return [
        CGRect(x: 0, y: 0, width: canvas, height: height),
        CGRect(x: 0, y: height, width: canvas, height: height),
      ]
    }
    if shape == "ww" || shape == "qq" {
      let tile = canvas / 2
      let height = least([tile / ratios[0], tile / ratios[1], canvasHeight])
      return [
        CGRect(x: 0, y: 0, width: tile, height: height),
        CGRect(x: tile, y: 0, width: tile, height: height),
      ]
    }
    var second = max(0.4 * canvas, canvas / ratios[0] / (1 / ratios[0] + 1 / ratios[1]))
    var first = canvas - second
    if first < minWidth {
      second -= minWidth - first
      first = minWidth
    }
    let height = min(canvasHeight, min(first / ratios[0], second / ratios[1]))
    return [
      CGRect(x: 0, y: 0, width: first, height: height),
      CGRect(x: first, y: 0, width: second, height: height),
    ]
  }

  private static func placeThree(_ ratios: [CGFloat], _ shape: String) -> [CGRect] {
    if shape.hasPrefix("n") {
      let thirdHeight = min(canvasHeight / 2, ratios[1] * canvas / (ratios[2] + ratios[1]))
      let secondHeight = canvasHeight - thirdHeight
      let rightWidth = max(
        minWidth,
        min(canvas / 2, min(thirdHeight * ratios[2], secondHeight * ratios[1])))
      let leftWidth = min(canvasHeight * ratios[0] + sidePadding, canvas - rightWidth)
      return [
        CGRect(x: 0, y: 0, width: leftWidth, height: canvasHeight),
        CGRect(x: leftWidth, y: 0, width: rightWidth, height: secondHeight),
        CGRect(x: leftWidth, y: secondHeight, width: rightWidth, height: thirdHeight),
      ]
    }
    let firstHeight = min(canvas / ratios[0], canvasHeight * 0.66)
    let half = canvas / 2
    let secondHeight = max(
      minRowHeight,
      min(canvasHeight - firstHeight, min(half / ratios[1], half / ratios[2])))
    return [
      CGRect(x: 0, y: 0, width: canvas, height: firstHeight),
      CGRect(x: 0, y: firstHeight, width: half, height: secondHeight),
      CGRect(x: half, y: firstHeight, width: half, height: secondHeight),
    ]
  }

  private static func placeFour(_ ratios: [CGFloat], _ shape: String) -> [CGRect] {
    if shape.hasPrefix("w") {
      let topHeight = min(canvas / ratios[0], canvasHeight * 0.66)
      let rowHeight = canvas / (ratios[1] + ratios[2] + ratios[3])
      var left = max(minWidth, min(canvas * 0.4, rowHeight * ratios[1]))
      var right = max(max(minWidth, canvas * 0.33), rowHeight * ratios[3])
      var middle = canvas - left - right
      if middle < minMiddleWidth {
        let deficit = minMiddleWidth - middle
        middle = minMiddleWidth
        left -= deficit / 2
        right -= deficit / 2
      }
      let bottom = max(minRowHeight, min(canvasHeight - topHeight, rowHeight))
      return [
        CGRect(x: 0, y: 0, width: canvas, height: topHeight),
        CGRect(x: 0, y: topHeight, width: left, height: bottom),
        CGRect(x: left, y: topHeight, width: middle, height: bottom),
        CGRect(x: left + middle, y: topHeight, width: right, height: bottom),
      ]
    }
    let column = min(canvasHeight / (1 / ratios[1] + 1 / ratios[2] + 1 / ratios[3]), canvasHeight)
    let maxCell = canvasHeight * 0.33
    let first = min(maxCell, max(minWidth, column / ratios[1]))
    let second = min(maxCell, max(minWidth, column / ratios[2]))
    let third = canvasHeight - first - second
    let leftWidth = min(canvasHeight * ratios[0] + sidePadding, canvas - column)
    return [
      CGRect(x: 0, y: 0, width: leftWidth, height: canvasHeight),
      CGRect(x: leftWidth, y: 0, width: column, height: first),
      CGRect(x: leftWidth, y: first, width: column, height: second),
      CGRect(x: leftWidth, y: first + second, width: column, height: third),
    ]
  }

  private static func placeRows(_ ratios: [CGFloat]) -> [CGRect] {
    let wide = average(ratios) > 1.1
    let cropped = ratios.map { ratio -> CGFloat in
      let biased = wide ? max(1, ratio) : min(1, ratio)
      return min(maxCropped, max(minCropped, biased))
    }
    let lines = rows(cropped, narrow: average(ratios) < 0.85)
    var tiles: [CGRect] = []
    var start = 0
    var top: CGFloat = 0
    for size in lines {
      let end = start + size
      let lineHeight = rowHeight(cropped, start, end)
      let height = max(minRowHeight, lineHeight)
      var left: CGFloat = 0
      for index in start..<end {
        let tileWidth = index == end - 1 ? canvas - left : cropped[index] * lineHeight
        tiles.append(CGRect(x: left, y: top, width: tileWidth, height: height))
        left += tileWidth
      }
      top += height
      start = end
    }
    return tiles
  }

  private static func rows(_ cropped: [CGFloat], narrow: Bool) -> [Int] {
    let count = cropped.count
    if count < 2 { return [count] }
    var best: [Int]?
    var bestScore = CGFloat.greatestFiniteMagnitude
    func consider(_ lines: [Int]) {
      let score = layoutScore(cropped, lines)
      if score < bestScore {
        bestScore = score
        best = lines
      }
    }
    if count > 1 {
      for first in 1..<count {
        let second = count - first
        if first > 3 || second > 3 { continue }
        consider([first, second])
      }
    }
    if count > 2 {
      for first in 1..<(count - 1) {
        for second in 1..<(count - first) {
          let third = count - first - second
          if first > 3 || second > (narrow ? 4 : 3) || third > 3 { continue }
          consider([first, second, third])
        }
      }
    }
    if count > 3 {
      for first in 1..<(count - 2) {
        for second in 1..<(count - first - 1) {
          for third in 1..<(count - first - second) {
            let fourth = count - first - second - third
            if first > 3 || second > 3 || third > 3 || fourth > 3 { continue }
            consider([first, second, third, fourth])
          }
        }
      }
    }
    return best ?? [count]
  }

  private static func layoutScore(_ cropped: [CGFloat], _ lines: [Int]) -> CGFloat {
    var total: CGFloat = 0
    var lowest = CGFloat.greatestFiniteMagnitude
    var start = 0
    for size in lines {
      let height = rowHeight(cropped, start, start + size)
      total += height
      lowest = min(lowest, height)
      start += size
    }
    var score = abs(total - targetHeight)
    for index in 0..<(lines.count - 1) where lines[index] > lines[index + 1] {
      score *= orderPenalty
      break
    }
    if lowest < minWidth { score *= 1.5 }
    return score
  }

  private static func rowHeight(_ cropped: [CGFloat], _ start: Int, _ end: Int) -> CGFloat {
    var sum: CGFloat = 0
    if start < end {
      for index in start..<end { sum += cropped[index] }
    }
    return canvas / max(sum, 0.01)
  }
}
