import SwiftUI

struct RelativeTimeText: View {
  let date: Date

  var body: some View {
    Text(relativeString(from: date))
  }

  private func relativeString(from date: Date) -> String {
    let interval = Date().timeIntervalSince(date)
    if interval < 60 { return "방금 전" }
    let minutes = Int(interval / 60)
    if minutes < 60 { return "\(minutes)m 전" }
    let hours = minutes / 60
    if hours < 24 { return "\(hours)h 전" }
    let days = hours / 24
    return "\(days)d 전"
  }
}
