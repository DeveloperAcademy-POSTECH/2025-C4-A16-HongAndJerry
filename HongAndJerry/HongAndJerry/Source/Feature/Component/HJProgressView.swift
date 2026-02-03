import SwiftUI

struct HJProgressView: View {
  let progress: Double
  
  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 12)
        .stroke(Color.gray.opacity(0.3), lineWidth: 8)
      
      RoundedRectangle(cornerRadius: 12)
        .trim(from: 0, to: progress)
        .stroke(Color.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
        .rotationEffect(.degrees(-90))
        .animation(.easeInOut(duration: 0.5), value: progress)
      
      Text("\(Int(progress * 100))%")
        .font(.SUITTitle)
    }
    .frame(width: 150, height: 150)
  }
}
