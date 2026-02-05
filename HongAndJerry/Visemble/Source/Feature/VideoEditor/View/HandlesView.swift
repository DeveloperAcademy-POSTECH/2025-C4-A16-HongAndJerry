import UIKit

final class HandlesView: UIView {
  enum HandleType {
    case left
    case right
  }
  
  private let type: HandleType
  private let chevronImageView = UIImageView()
  private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
  
  init(type: HandleType) {
    self.type = type
    super.init(frame: .zero)
    
    setStyle()
    setUI()
    setLayout()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setStyle() {
    backgroundColor = TrimmingConstants.handleColor
    isUserInteractionEnabled = true
    
    layer.maskedCorners = type == .left
    ? [.layerMinXMinYCorner, .layerMinXMaxYCorner]
    : [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
    layer.cornerRadius = TrimmingConstants.cornerRadius
    
    let imageName = type == .left ? "chevron.compact.left" : "chevron.compact.right"
    chevronImageView.image = UIImage(systemName: imageName)?
      .withConfiguration(UIImage.SymbolConfiguration(weight: .black))
    chevronImageView.tintColor = .black
    chevronImageView.contentMode = .scaleAspectFit
  }
  
  private func setUI() {
    addSubview(chevronImageView)
  }
  
  private func setLayout() {
    let chevronSize: CGFloat = 12
    chevronImageView.snp.makeConstraints {
      $0.center.equalToSuperview()
      $0.width.height.equalTo(chevronSize)
    }
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesBegan(touches, with: event)
    feedbackGenerator.prepare()
    feedbackGenerator.impactOccurred()
  }
}
